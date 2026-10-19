import {
  createHash,
  createPrivateKey,
  createPublicKey,
  sign as signBytes,
  verify as verifyBytes
} from 'node:crypto';
import {
  existsSync,
  readFileSync,
  renameSync,
  statSync,
  unlinkSync,
  writeFileSync
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const PACKAGE_SCHEMA_VERSION = '1';
const CONTRACT_SCHEMA_VERSION = '1';
const SIGNATURE_ALGORITHM = 'Ed25519';
const RELEASED_LIFECYCLES = new Set(['canary', 'active', 'rolledBack']);
const ARTIFACT_KINDS = new Set(['checkpoint', 'policy', 'workflow']);
const MANIFEST_FIELDS = new Set([
  'schemaVersion', 'contractType', 'artifactId', 'artifactKind', 'algorithm', 'artifactVersion',
  'sourceCommit', 'sourceLicense', 'trainingDataLineage', 'modelAndProviderSnapshotJson',
  'featureSchemaVersion', 'runtimeCompatibility', 'artifactDigest', 'checkpointDigest',
  'paperReproductionResultsJson', 'portParityResultsJson', 'harmonyAgentBenchResultsJson',
  'lifecycleStatus', 'approvalStatus', 'approvedBy', 'approvedAt', 'signedManifestDigest',
  'signatureAlgorithm', 'signingKeyId', 'signatureBase64', 'signedAt', 'rollbackTargetDigest'
]);
const PACKAGE_FIELDS = new Set(['packageSchemaVersion', 'manifest', 'payloadEncoding', 'payloadBase64']);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function isPlainObject(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function assertKnownFields(value, allowed, path) {
  assert(isPlainObject(value), `${path} must be an object`);
  for (const key of Object.keys(value)) {
    assert(allowed.has(key), `${path}.${key} is not supported`);
  }
}

function requireText(value, path) {
  assert(typeof value === 'string' && value.trim().length > 0, `${path} must not be empty`);
}

function requireSha256(value, path) {
  assert(typeof value === 'string' && /^sha256:[0-9a-f]{64}$/.test(value),
    `${path} must be a lowercase full sha256 digest`);
}

function requireTimestamp(value, path) {
  assert(typeof value === 'string' &&
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/.test(value),
  `${path} must be an ISO-8601 timestamp with an explicit time zone`);
}

function requireJsonObjectText(value, path, requireNonEmpty) {
  requireText(value, path);
  let parsed;
  try {
    parsed = JSON.parse(value);
  } catch {
    throw new Error(`${path} must encode valid JSON`);
  }
  assert(isPlainObject(parsed), `${path} must encode a JSON object`);
  if (requireNonEmpty) assert(Object.keys(parsed).length > 0, `${path} must not encode an empty object`);
}

function requireUniqueTextArray(value, path) {
  assert(Array.isArray(value) && value.length > 0, `${path} must be a non-empty array`);
  const seen = new Set();
  for (let index = 0; index < value.length; index += 1) {
    const entry = value[index];
    requireText(entry, `${path}[${index}]`);
    assert(!seen.has(entry), `${path} must not contain duplicate entries`);
    seen.add(entry);
  }
}

function requireCanonicalBase64(value, path) {
  requireText(value, path);
  assert(/^[A-Za-z0-9+/]+={0,2}$/.test(value) && value.length % 4 === 0,
    `${path} must use base64 encoding`);
  assert(Buffer.from(value, 'base64').toString('base64') === value, `${path} must use canonical base64 encoding`);
}

function validateManifest(manifest, options = {}) {
  const final = options.final === true;
  assertKnownFields(manifest, MANIFEST_FIELDS, 'manifest');
  assert(manifest.schemaVersion === CONTRACT_SCHEMA_VERSION, 'manifest.schemaVersion is not supported');
  assert(manifest.contractType === 'ArtifactManifest', 'manifest.contractType must be ArtifactManifest');
  requireText(manifest.artifactId, 'manifest.artifactId');
  assert(ARTIFACT_KINDS.has(manifest.artifactKind), 'manifest.artifactKind is not supported');
  requireText(manifest.algorithm, 'manifest.algorithm');
  requireText(manifest.artifactVersion, 'manifest.artifactVersion');
  assert(typeof manifest.sourceCommit === 'string' &&
    /^([0-9a-f]{40}|[0-9a-f]{64})$/.test(manifest.sourceCommit),
  'manifest.sourceCommit must be a lowercase full commit id');
  requireText(manifest.sourceLicense, 'manifest.sourceLicense');
  requireUniqueTextArray(manifest.trainingDataLineage, 'manifest.trainingDataLineage');
  requireJsonObjectText(manifest.modelAndProviderSnapshotJson, 'manifest.modelAndProviderSnapshotJson', true);
  requireText(manifest.featureSchemaVersion, 'manifest.featureSchemaVersion');
  requireUniqueTextArray(manifest.runtimeCompatibility, 'manifest.runtimeCompatibility');
  requireJsonObjectText(manifest.paperReproductionResultsJson,
    'manifest.paperReproductionResultsJson', true);
  requireJsonObjectText(manifest.portParityResultsJson, 'manifest.portParityResultsJson', true);
  requireJsonObjectText(manifest.harmonyAgentBenchResultsJson,
    'manifest.harmonyAgentBenchResultsJson', true);
  assert(RELEASED_LIFECYCLES.has(manifest.lifecycleStatus),
    'manifest.lifecycleStatus must be canary, active, or rolledBack for a signed package');
  assert(manifest.approvalStatus === 'approved', 'manifest.approvalStatus must be approved');
  requireText(manifest.approvedBy, 'manifest.approvedBy');
  requireTimestamp(manifest.approvedAt, 'manifest.approvedAt');
  requireTimestamp(manifest.signedAt, 'manifest.signedAt');
  assert(manifest.signatureAlgorithm === SIGNATURE_ALGORITHM,
    `manifest.signatureAlgorithm must be ${SIGNATURE_ALGORITHM}`);
  requireText(manifest.signingKeyId, 'manifest.signingKeyId');
  if (manifest.lifecycleStatus === 'rolledBack') {
    requireSha256(manifest.rollbackTargetDigest, 'manifest.rollbackTargetDigest');
  } else {
    assert(manifest.rollbackTargetDigest === undefined,
      'manifest.rollbackTargetDigest is only valid for rolledBack artifacts');
  }
  if (final) {
    requireSha256(manifest.artifactDigest, 'manifest.artifactDigest');
    if (manifest.checkpointDigest !== undefined && manifest.checkpointDigest !== '') {
      requireSha256(manifest.checkpointDigest, 'manifest.checkpointDigest');
      assert(manifest.checkpointDigest === manifest.artifactDigest,
        'manifest.checkpointDigest must match manifest.artifactDigest');
    }
    requireSha256(manifest.signedManifestDigest, 'manifest.signedManifestDigest');
    requireCanonicalBase64(manifest.signatureBase64, 'manifest.signatureBase64');
    if (manifest.lifecycleStatus === 'rolledBack') {
      assert(manifest.rollbackTargetDigest !== manifest.artifactDigest,
        'manifest.rollbackTargetDigest must identify a different artifact');
    }
  } else {
    assert(manifest.artifactDigest === undefined || manifest.artifactDigest === '' ||
      /^sha256:[0-9a-f]{64}$/.test(manifest.artifactDigest),
    'manifest.artifactDigest must be empty or a lowercase full sha256 digest before packaging');
    assert(manifest.signedManifestDigest === undefined || manifest.signedManifestDigest === '',
      'manifest.signedManifestDigest must be empty before packaging');
    assert(manifest.signatureBase64 === undefined || manifest.signatureBase64 === '',
      'manifest.signatureBase64 must be empty before packaging');
  }
}

export function canonicalize(value) {
  if (value === null) return 'null';
  if (typeof value === 'string' || typeof value === 'boolean') return JSON.stringify(value);
  if (typeof value === 'number') {
    assert(Number.isFinite(value), 'canonical JSON does not allow non-finite numbers');
    return Object.is(value, -0) ? '0' : JSON.stringify(value);
  }
  if (Array.isArray(value)) return `[${value.map((entry) => canonicalize(entry)).join(',')}]`;
  assert(isPlainObject(value), 'canonical JSON only accepts plain objects, arrays, and JSON primitives');
  const keys = Object.keys(value).sort();
  return `{${keys.map((key) => `${JSON.stringify(key)}:${canonicalize(value[key])}`).join(',')}}`;
}

export function sha256(bytes) {
  return `sha256:${createHash('sha256').update(bytes).digest('hex')}`;
}

function signedProjection(manifest) {
  const projection = {};
  for (const key of Object.keys(manifest)) {
    if (key !== 'signedManifestDigest' && key !== 'signatureBase64') projection[key] = manifest[key];
  }
  return projection;
}

function readJson(path, label) {
  let parsed;
  try {
    parsed = JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    throw new Error(`${label} must contain valid JSON`);
  }
  assert(isPlainObject(parsed), `${label} must contain a JSON object`);
  return parsed;
}

function writeNewFileAtomically(outputPath, text) {
  assert(!existsSync(outputPath), 'output already exists');
  const parent = dirname(outputPath);
  assert(existsSync(parent) && statSync(parent).isDirectory(), 'output parent directory does not exist');
  const temporaryPath = `${outputPath}.tmp-${process.pid}`;
  assert(!existsSync(temporaryPath), 'temporary output already exists');
  try {
    writeFileSync(temporaryPath, text, { encoding: 'utf8', flag: 'wx', mode: 0o600 });
    renameSync(temporaryPath, outputPath);
  } catch (error) {
    if (existsSync(temporaryPath)) unlinkSync(temporaryPath);
    throw error;
  }
}

export function packArtifact(options) {
  const manifestPath = resolve(options.manifestPath);
  const payloadPath = resolve(options.payloadPath);
  const privateKeyPath = resolve(options.privateKeyPath);
  const outputPath = resolve(options.outputPath);
  requireText(options.keyId, 'keyId');
  assert(existsSync(payloadPath) && statSync(payloadPath).isFile(), 'payload file does not exist');
  const manifest = readJson(manifestPath, 'manifest input');
  manifest.signatureAlgorithm = SIGNATURE_ALGORITHM;
  manifest.signingKeyId = options.keyId;
  validateManifest(manifest, { final: false });
  const payload = readFileSync(payloadPath);
  const payloadDigest = sha256(payload);
  if (manifest.artifactDigest !== undefined && manifest.artifactDigest !== '') {
    assert(manifest.artifactDigest === payloadDigest, 'manifest.artifactDigest does not match the payload');
  }
  manifest.artifactDigest = payloadDigest;
  if (manifest.artifactKind === 'checkpoint') manifest.checkpointDigest = payloadDigest;
  const projectionBytes = Buffer.from(canonicalize(signedProjection(manifest)), 'utf8');
  manifest.signedManifestDigest = sha256(projectionBytes);
  const privateKey = createPrivateKey(readFileSync(privateKeyPath));
  assert(privateKey.asymmetricKeyType === 'ed25519', 'private key must be Ed25519');
  manifest.signatureBase64 = signBytes(null, projectionBytes, privateKey).toString('base64');
  validateManifest(manifest, { final: true });
  const artifactPackage = {
    packageSchemaVersion: PACKAGE_SCHEMA_VERSION,
    manifest,
    payloadEncoding: 'base64',
    payloadBase64: payload.toString('base64')
  };
  const packageText = `${canonicalize(artifactPackage)}\n`;
  writeNewFileAtomically(outputPath, packageText);
  return {
    artifactId: manifest.artifactId,
    artifactDigest: manifest.artifactDigest,
    signedManifestDigest: manifest.signedManifestDigest,
    signingKeyId: manifest.signingKeyId,
    signatureAlgorithm: manifest.signatureAlgorithm,
    packageSha256: sha256(Buffer.from(packageText, 'utf8'))
  };
}

export function verifyArtifact(options) {
  const packagePath = resolve(options.packagePath);
  const publicKeyPath = resolve(options.publicKeyPath);
  requireText(options.expectedKeyId, 'expectedKeyId');
  const packageBytes = readFileSync(packagePath);
  const artifactPackage = readJson(packagePath, 'artifact package');
  assert(`${canonicalize(artifactPackage)}\n` === packageBytes.toString('utf8'),
    'artifact package is not canonical JSON');
  assertKnownFields(artifactPackage, PACKAGE_FIELDS, 'package');
  assert(artifactPackage.packageSchemaVersion === PACKAGE_SCHEMA_VERSION,
    'package.packageSchemaVersion is not supported');
  assert(artifactPackage.payloadEncoding === 'base64', 'package.payloadEncoding must be base64');
  requireCanonicalBase64(artifactPackage.payloadBase64, 'package.payloadBase64');
  const manifest = artifactPackage.manifest;
  validateManifest(manifest, { final: true });
  assert(manifest.signingKeyId === options.expectedKeyId, 'manifest.signingKeyId does not match expectedKeyId');
  const payload = Buffer.from(artifactPackage.payloadBase64, 'base64');
  assert(sha256(payload) === manifest.artifactDigest, 'artifact payload digest mismatch');
  const projectionBytes = Buffer.from(canonicalize(signedProjection(manifest)), 'utf8');
  assert(sha256(projectionBytes) === manifest.signedManifestDigest, 'signed manifest digest mismatch');
  const publicKey = createPublicKey(readFileSync(publicKeyPath));
  assert(publicKey.asymmetricKeyType === 'ed25519', 'public key must be Ed25519');
  const signature = Buffer.from(manifest.signatureBase64, 'base64');
  assert(verifyBytes(null, projectionBytes, publicKey, signature), 'artifact signature verification failed');
  return {
    artifactId: manifest.artifactId,
    artifactKind: manifest.artifactKind,
    lifecycleStatus: manifest.lifecycleStatus,
    artifactDigest: manifest.artifactDigest,
    signedManifestDigest: manifest.signedManifestDigest,
    signingKeyId: manifest.signingKeyId,
    signatureAlgorithm: manifest.signatureAlgorithm,
    packageSha256: sha256(packageBytes)
  };
}

function parseOptions(args) {
  const values = new Map();
  assert(args.length % 2 === 0, 'options must use --name value pairs');
  for (let index = 0; index < args.length; index += 2) {
    const name = args[index];
    assert(name.startsWith('--'), 'option names must start with --');
    assert(!values.has(name), `duplicate option ${name}`);
    values.set(name, args[index + 1]);
  }
  return values;
}

function requiredOption(values, name) {
  const value = values.get(name);
  requireText(value, name);
  return value;
}

function runCli(argv) {
  const command = argv[0];
  const values = parseOptions(argv.slice(1));
  if (command === 'pack') {
    assert(values.size === 5,
      'pack requires --manifest, --payload, --private-key, --key-id, and --output');
    return packArtifact({
      manifestPath: requiredOption(values, '--manifest'),
      payloadPath: requiredOption(values, '--payload'),
      privateKeyPath: requiredOption(values, '--private-key'),
      keyId: requiredOption(values, '--key-id'),
      outputPath: requiredOption(values, '--output')
    });
  }
  if (command === 'verify') {
    assert(values.size === 3, 'verify requires --package, --public-key, and --expected-key-id');
    return verifyArtifact({
      packagePath: requiredOption(values, '--package'),
      publicKeyPath: requiredOption(values, '--public-key'),
      expectedKeyId: requiredOption(values, '--expected-key-id')
    });
  }
  throw new Error('command must be pack or verify');
}

const invokedPath = process.argv[1] === undefined ? '' : pathToFileURL(resolve(process.argv[1])).href;
if (invokedPath === import.meta.url) {
  try {
    process.stdout.write(`${JSON.stringify(runCli(process.argv.slice(2)), null, 2)}\n`);
  } catch (error) {
    process.stderr.write(`artifact-tool error: ${error instanceof Error ? error.message : 'unknown error'}\n`);
    process.exitCode = 1;
  }
}
