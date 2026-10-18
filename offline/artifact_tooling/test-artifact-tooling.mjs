import { generateKeyPairSync } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  rmdirSync,
  unlinkSync,
  writeFileSync
} from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { canonicalize, packArtifact, sha256, verifyArtifact } from './artifact-tool.mjs';

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function expectFailure(action, expectedMessage) {
  let message = '';
  try {
    action();
  } catch (error) {
    message = error instanceof Error ? error.message : 'unknown error';
  }
  assert(message.includes(expectedMessage), `expected failure containing: ${expectedMessage}`);
}

function outputArgument(argv) {
  assert(argv.length === 2 && argv[0] === '--output', 'Use --output <new-directory>.');
  return resolve(argv[1]);
}

function writeCanonical(path, value) {
  writeFileSync(path, `${canonicalize(value)}\n`, 'utf8');
}

const outputRoot = outputArgument(process.argv.slice(2));
assert(!existsSync(outputRoot), 'output directory already exists');
mkdirSync(outputRoot, { recursive: true });
const transient = join(outputRoot, 'transient');
mkdirSync(transient);
const evidencePackagePath = join(outputRoot, 'fixture-artifact-package.json');
const evidencePublicKeyPath = join(outputRoot, 'fixture-public-key.pem');
const privateKeyPath = join(transient, 'test-private-key.pem');
const publicKeyPath = join(transient, 'test-public-key.pem');
const payloadPath = join(transient, 'policy.bin');
const manifestPath = join(transient, 'manifest-input.json');
const packageOnePath = join(transient, 'artifact-one.json');
const packageTwoPath = join(transient, 'artifact-two.json');
const packageCliPath = join(transient, 'artifact-cli.json');
const tamperedPayloadPath = join(transient, 'tampered-payload.json');
const tamperedManifestPath = join(transient, 'tampered-manifest.json');
const tamperedSignaturePath = join(transient, 'tampered-signature.json');
const transientFiles = [
  privateKeyPath, publicKeyPath, payloadPath, manifestPath, packageOnePath, packageTwoPath, packageCliPath,
  tamperedPayloadPath, tamperedManifestPath, tamperedSignaturePath
];
const toolPath = join(resolve(fileURLToPath(new URL('.', import.meta.url))), 'artifact-tool.mjs');

let report;
try {
  const keyPair = generateKeyPairSync('ed25519');
  writeFileSync(privateKeyPath, keyPair.privateKey.export({ type: 'pkcs8', format: 'pem' }),
    { mode: 0o600 });
  writeFileSync(publicKeyPath, keyPair.publicKey.export({ type: 'spki', format: 'pem' }),
    { mode: 0o600 });
  writeFileSync(payloadPath, '{"policy":"deterministic-single-first","version":"1"}\n', 'utf8');
  const manifest = {
    schemaVersion: '1',
    contractType: 'ArtifactManifest',
    artifactId: 'mtrouter-policy-fixture-1',
    artifactKind: 'policy',
    algorithm: 'MTRouter',
    artifactVersion: '0.1.0-canary',
    sourceCommit: 'bd8338c11bbb78981d37c408e210197ede9add57',
    sourceLicense: 'MIT',
    trainingDataLineage: ['harmony-agent-bench:system-live:20261017'],
    modelAndProviderSnapshotJson: '{"model":"fixture","provider":"offline"}',
    featureSchemaVersion: 'harmony_agent-router-features-1',
    runtimeCompatibility: ['harmony_agent-runtime>=0.14.0', 'api>=26'],
    artifactDigest: '',
    checkpointDigest: '',
    paperReproductionResultsJson: '{"qualityBasisPoints":7500}',
    portParityResultsJson: '{"matched":12,"total":12}',
    harmonyAgentBenchResultsJson: '{"baselineDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}',
    lifecycleStatus: 'canary',
    approvalStatus: 'approved',
    approvedBy: 'artifact-release-policy-v1',
    approvedAt: '2026-10-18T00:10:00+08:00',
    signedManifestDigest: '',
    signatureAlgorithm: 'Ed25519',
    signingKeyId: 'fixture-release-key',
    signatureBase64: '',
    signedAt: '2026-10-18T00:11:00+08:00'
  };
  writeCanonical(manifestPath, manifest);
  const first = packArtifact({
    manifestPath, payloadPath, privateKeyPath, keyId: 'fixture-release-key', outputPath: packageOnePath
  });
  const second = packArtifact({
    manifestPath, payloadPath, privateKeyPath, keyId: 'fixture-release-key', outputPath: packageTwoPath
  });
  const firstBytes = readFileSync(packageOnePath);
  const secondBytes = readFileSync(packageTwoPath);
  assert(firstBytes.equals(secondBytes), 'repeated packaging must be byte-for-byte deterministic');
  assert(first.packageSha256 === second.packageSha256, 'repeated package digests must match');
  expectFailure(() => packArtifact({
    manifestPath, payloadPath, privateKeyPath, keyId: 'fixture-release-key', outputPath: packageOnePath
  }), 'output already exists');
  const cliPack = spawnSync(process.execPath, [
    toolPath, 'pack', '--manifest', manifestPath, '--payload', payloadPath,
    '--private-key', privateKeyPath, '--key-id', 'fixture-release-key', '--output', packageCliPath
  ], { encoding: 'utf8' });
  assert(cliPack.status === 0, 'CLI pack must succeed');
  const cliPackResult = JSON.parse(cliPack.stdout);
  assert(readFileSync(packageCliPath).equals(firstBytes), 'CLI package must match library package bytes');
  assert(cliPackResult.packageSha256 === first.packageSha256, 'CLI pack digest must match library digest');
  const verified = verifyArtifact({
    packagePath: packageOnePath,
    publicKeyPath,
    expectedKeyId: 'fixture-release-key'
  });
  assert(verified.packageSha256 === first.packageSha256, 'verified package digest must match pack result');
  const cliVerify = spawnSync(process.execPath, [
    toolPath, 'verify', '--package', packageCliPath, '--public-key', publicKeyPath,
    '--expected-key-id', 'fixture-release-key'
  ], { encoding: 'utf8' });
  assert(cliVerify.status === 0, 'CLI verify must succeed');
  const cliVerifyResult = JSON.parse(cliVerify.stdout);
  assert(cliVerifyResult.packageSha256 === verified.packageSha256,
    'CLI verify digest must match library verify digest');
  const originalPackage = JSON.parse(firstBytes.toString('utf8'));

  const payloadTamper = JSON.parse(JSON.stringify(originalPackage));
  const tamperedPayload = Buffer.from(payloadTamper.payloadBase64, 'base64');
  tamperedPayload[0] ^= 1;
  payloadTamper.payloadBase64 = tamperedPayload.toString('base64');
  writeCanonical(tamperedPayloadPath, payloadTamper);
  expectFailure(() => verifyArtifact({
    packagePath: tamperedPayloadPath, publicKeyPath, expectedKeyId: 'fixture-release-key'
  }), 'artifact payload digest mismatch');

  const manifestTamper = JSON.parse(JSON.stringify(originalPackage));
  manifestTamper.manifest.algorithm = 'TamperedRouter';
  writeCanonical(tamperedManifestPath, manifestTamper);
  expectFailure(() => verifyArtifact({
    packagePath: tamperedManifestPath, publicKeyPath, expectedKeyId: 'fixture-release-key'
  }), 'signed manifest digest mismatch');

  const signatureTamper = JSON.parse(JSON.stringify(originalPackage));
  const signature = signatureTamper.manifest.signatureBase64;
  signatureTamper.manifest.signatureBase64 = `${signature.startsWith('A') ? 'B' : 'A'}${signature.slice(1)}`;
  writeCanonical(tamperedSignaturePath, signatureTamper);
  expectFailure(() => verifyArtifact({
    packagePath: tamperedSignaturePath, publicKeyPath, expectedKeyId: 'fixture-release-key'
  }), 'artifact signature verification failed');

  expectFailure(() => verifyArtifact({
    packagePath: packageOnePath, publicKeyPath, expectedKeyId: 'unexpected-key'
  }), 'manifest.signingKeyId does not match expectedKeyId');

  writeFileSync(evidencePackagePath, firstBytes, { flag: 'wx', mode: 0o600 });
  writeFileSync(evidencePublicKeyPath, readFileSync(publicKeyPath), { flag: 'wx', mode: 0o600 });

  report = {
    task: 'T45',
    suite: 'artifact-tooling-self-test',
    result: 'passed',
    checks: {
      deterministicPackageBytes: true,
      outputOverwriteRejected: true,
      cliPackAndVerify: true,
      payloadDigestTamperRejected: true,
      manifestDigestTamperRejected: true,
      signatureTamperRejected: true,
      unexpectedKeyIdRejected: true,
      transientPrivateKeyRemoved: true,
      replayAfterPrivateKeyRemoval: true
    },
    packageSha256: sha256(firstBytes),
    artifactDigest: verified.artifactDigest,
    signedManifestDigest: verified.signedManifestDigest,
    signatureAlgorithm: verified.signatureAlgorithm,
    signingKeyId: verified.signingKeyId,
    publicKeySha256: sha256(readFileSync(publicKeyPath))
  };
} finally {
  for (const file of transientFiles) {
    if (existsSync(file)) unlinkSync(file);
  }
  if (existsSync(transient)) rmdirSync(transient);
}

assert(!existsSync(privateKeyPath), 'transient private key must be removed');
const replay = verifyArtifact({
  packagePath: evidencePackagePath,
  publicKeyPath: evidencePublicKeyPath,
  expectedKeyId: 'fixture-release-key'
});
assert(replay.packageSha256 === report.packageSha256, 'verification must replay after private-key removal');
writeFileSync(join(outputRoot, 'self-test-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
