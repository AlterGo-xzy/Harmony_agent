import { createHash } from 'node:crypto';
import { lstatSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const contractPath = join(scriptRoot, 'handoff-contract.json');
const upstreamLockPath = join(scriptRoot, 'upstream-lock.json');
const reproductionSpecPath = join(scriptRoot, 'reproduction-spec.json');

function fail(message) {
  throw new Error(message);
}

function assert(condition, message) {
  if (!condition) fail(message);
}

function readJson(path, label) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch (error) {
    fail(`${label} is not valid JSON: ${error.message}`);
  }
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isSha256(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

function isFullCommit(value) {
  return typeof value === 'string' && /^([0-9a-f]{40}|[0-9a-f]{64})$/.test(value);
}

function isIsoTimestamp(value) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value)) && /(?:Z|[+-]\d\d:\d\d)$/.test(value);
}

function assertExactKeys(value, expectedKeys, label) {
  assert(isObject(value), `${label} must be an object`);
  const actual = Object.keys(value).sort();
  const expected = expectedKeys.slice().sort();
  assert(JSON.stringify(actual) === JSON.stringify(expected), `${label} contains missing or unknown fields`);
}

function comparePaths(left, right) {
  if (left.path < right.path) return -1;
  if (left.path > right.path) return 1;
  return 0;
}

function fileDigest(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

function safeRelativePath(value) {
  return isText(value) && !isAbsolute(value) && !value.includes('\\') &&
    value !== '.' && !value.startsWith('/') &&
    value.split('/').every((part) => part.length > 0 && part !== '.' && part !== '..');
}

function uniqueTexts(values) {
  return Array.isArray(values) && values.length > 0 &&
    values.every((value) => isText(value)) && new Set(values).size === values.length;
}

function listFiles(root, current = root) {
  const found = [];
  for (const entry of readdirSync(current, { withFileTypes: true })) {
    const absolute = join(current, entry.name);
    const stats = lstatSync(absolute);
    assert(!stats.isSymbolicLink(), `symbolic links are forbidden: ${relative(root, absolute)}`);
    if (stats.isDirectory()) {
      found.push(...listFiles(root, absolute));
    } else {
      assert(stats.isFile(), `non-regular file is forbidden: ${relative(root, absolute)}`);
      found.push(relative(root, absolute).split(sep).join('/'));
    }
  }
  return found.sort();
}

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || index + 1 >= process.argv.length) return undefined;
  return process.argv[index + 1];
}

const handoffArgument = argumentValue('--handoff');
assert(handoffArgument !== undefined, 'usage: node check-mtrouter-handoff.mjs --handoff <directory>');
const handoffRoot = resolve(handoffArgument);
const handoffStats = lstatSync(handoffRoot);
assert(handoffStats.isDirectory() && !handoffStats.isSymbolicLink(), 'handoff must be a regular directory');

const contract = readJson(contractPath, 'handoff contract');
const upstreamLock = readJson(upstreamLockPath, 'upstream lock');
const reproductionSpec = readJson(reproductionSpecPath, 'reproduction spec');
const manifestPath = join(handoffRoot, 'HANDOFF.json');
const sumsPath = join(handoffRoot, 'SHA256SUMS');
const manifest = readJson(manifestPath, 'HANDOFF.json');

assert(contract.schemaVersion === '1', 'handoff contract schema drift');
assert(contract.upstreamCommit === upstreamLock.repository.commit &&
  contract.upstreamTree === upstreamLock.repository.tree, 'handoff contract and upstream lock drift');
assert(contract.upstreamCommit === reproductionSpec.upstreamCommit, 'handoff contract and reproduction spec drift');
assert(contract.sourceLicense === upstreamLock.license.spdx, 'handoff contract license drift');

assertExactKeys(manifest, ['schemaVersion', 'handoffId', 'createdAt', 'trainingTrack', 'trainingState',
  'repository', 'upstream', 'artifact', 'runtimeIntegration', 'modelPool', 'evidence',
  'threeSeedHeldOutEvaluation', 'costIncurredUsd', 'files'], 'handoff manifest');
assert(manifest.schemaVersion === contract.schemaVersion, 'handoff schema must be 1');
assert(isText(manifest.handoffId), 'handoffId is required');
assert(isIsoTimestamp(manifest.createdAt), 'createdAt must be an ISO timestamp with timezone');
assert(contract.allowedTrainingTracks.includes(manifest.trainingTrack), 'unsupported trainingTrack');
assert(contract.allowedTrainingStates.includes(manifest.trainingState), 'unsupported trainingState');

assertExactKeys(manifest.repository, ['sourceCommit', 'dirty'], 'repository');
assert(isFullCommit(manifest.repository.sourceCommit), 'repository sourceCommit must be a full commit id');
assert(manifest.repository.dirty === false, 'handoff repository must be clean');
assertExactKeys(manifest.upstream, ['commit', 'tree', 'license'], 'upstream');
assert(manifest.upstream.commit === contract.upstreamCommit &&
  manifest.upstream.tree === contract.upstreamTree &&
  manifest.upstream.license === contract.sourceLicense, 'upstream identity drift');

assertExactKeys(manifest.artifact, ['algorithm', 'featureSchemaVersion', 'decisionParameterCount',
  'includesHistoryEncoderWeights', 'includesTokenizerAssets', 'includesPythonRuntime',
  'includesOptimizerState', 'historyEncoder'], 'artifact');
assert(manifest.artifact.algorithm === contract.algorithm, 'artifact algorithm drift');
assert(isText(manifest.artifact.featureSchemaVersion), 'featureSchemaVersion is required');
assert(manifest.artifact.includesHistoryEncoderWeights === false,
  'history encoder weights are forbidden in the handoff');
assert(manifest.artifact.includesTokenizerAssets === false,
  'tokenizer assets are forbidden in the handoff');
assert(manifest.artifact.includesPythonRuntime === false,
  'Python runtime is forbidden in the handoff');
assert(manifest.artifact.includesOptimizerState === false,
  'optimizer state is forbidden in the handoff');
assertExactKeys(manifest.artifact.historyEncoder,
  ['modelId', 'dimensions', 'maximumTokens', 'deploymentMode'], 'historyEncoder');
assert(manifest.artifact.historyEncoder.modelId === contract.historyEncoder.modelId &&
  manifest.artifact.historyEncoder.dimensions === contract.historyEncoder.dimensions &&
  manifest.artifact.historyEncoder.maximumTokens === contract.historyEncoder.maximumTokens &&
  manifest.artifact.historyEncoder.deploymentMode === contract.historyEncoder.deploymentMode,
  'history encoder identity or deployment drift');

assertExactKeys(manifest.runtimeIntegration, Object.keys(contract.runtimeIntegration), 'runtimeIntegration');
for (const [key, expected] of Object.entries(contract.runtimeIntegration)) {
  assert(manifest.runtimeIntegration[key] === expected, `runtime integration drift: ${key}`);
}

assertExactKeys(manifest.modelPool, ['orderedModelIds', 'snapshotSha256'], 'modelPool');
assert(uniqueTexts(manifest.modelPool.orderedModelIds), 'orderedModelIds must be a unique non-empty list');
assert(isSha256(manifest.modelPool.snapshotSha256), 'model pool snapshot digest is required');
const expectedParameterCount = contract.decisionArchitecture.baseParameterCount +
  contract.decisionArchitecture.perModelResidualParameterCount * manifest.modelPool.orderedModelIds.length;
assert(manifest.artifact.decisionParameterCount === expectedParameterCount,
  'decision parameter count drift');
if (manifest.trainingTrack === 'official-reproduction') {
  const expected = reproductionSpec.modelPool.map((model) => model.name);
  assert(JSON.stringify(manifest.modelPool.orderedModelIds) === JSON.stringify(expected),
    'official reproduction model pool drift');
}

const evidenceFields = ['paperReproduction', 'pythonReference', 'arktsParity', 'deviceParity',
  'shadow', 'canary', 'active'];
assertExactKeys(manifest.evidence, evidenceFields, 'evidence');
for (const field of evidenceFields) {
  assert(contract.allowedEvidenceStates.includes(manifest.evidence[field]), `invalid evidence state: ${field}`);
}
assert(typeof manifest.threeSeedHeldOutEvaluation === 'boolean',
  'threeSeedHeldOutEvaluation must be boolean');
for (const field of ['arktsParity', 'deviceParity', 'shadow', 'canary', 'active']) {
  assert(manifest.evidence[field] === 'notRun', `training repository cannot claim ${field}`);
}
if (manifest.trainingState === 'candidate') {
  assert(manifest.evidence.pythonReference === 'passed', 'candidate requires passed Python reference evidence');
  assert(manifest.threeSeedHeldOutEvaluation === true, 'candidate requires three-seed held-out evaluation');
}
assert(typeof manifest.costIncurredUsd === 'number' && Number.isFinite(manifest.costIncurredUsd) &&
  manifest.costIncurredUsd >= 0, 'costIncurredUsd must be a finite non-negative number');

assert(Array.isArray(manifest.files) && manifest.files.length > 0, 'files list is required');
const paths = [];
const roles = [];
let totalBytes = 0;
let decisionPayload;
for (const file of manifest.files) {
  assertExactKeys(file, ['path', 'role', 'sizeBytes', 'sha256'], 'file entry');
  assert(isObject(file) && safeRelativePath(file.path), 'file path must be safe and relative');
  assert(isText(file.role), `file role is required: ${file.path}`);
  assert(contract.allowedFileRoles.includes(file.role), `unsupported file role: ${file.role}`);
  assert(Number.isSafeInteger(file.sizeBytes) && file.sizeBytes >= 0, `invalid size: ${file.path}`);
  assert(isSha256(file.sha256), `invalid SHA-256: ${file.path}`);
  assert(!paths.includes(file.path), `duplicate file path: ${file.path}`);
  paths.push(file.path);
  roles.push(file.role);
  const absolute = resolve(handoffRoot, file.path);
  assert(absolute.startsWith(`${handoffRoot}${sep}`), `file escapes handoff root: ${file.path}`);
  const stats = lstatSync(absolute);
  assert(stats.isFile() && !stats.isSymbolicLink(), `file must be regular: ${file.path}`);
  assert(stats.size === file.sizeBytes, `file size drift: ${file.path}`);
  totalBytes += stats.size;
  assert(totalBytes <= contract.applicationBudget.maximumHandoffBytes, 'handoff exceeds total size budget');
  assert(fileDigest(absolute) === file.sha256, `file digest drift: ${file.path}`);
  if (file.role === 'decisionPayload') {
    assert(decisionPayload === undefined, 'exactly one decisionPayload is allowed');
    decisionPayload = file;
  }
}

for (const role of contract.requiredFileRoles) {
  assert(roles.includes(role), `required file role missing: ${role}`);
}
if (manifest.evidence.paperReproduction !== 'notRun') {
  assert(roles.includes('paperReproductionReport'),
    'paper reproduction evidence requires paperReproductionReport');
}
if (manifest.evidence.pythonReference !== 'notRun') {
  assert(roles.includes('pythonReferenceReport'),
    'Python reference evidence requires pythonReferenceReport');
}
assert(decisionPayload !== undefined, 'decisionPayload is required');
assert(decisionPayload.sizeBytes <= contract.applicationBudget.maximumDecisionPayloadBytes,
  'decision payload exceeds application budget');
const diskFiles = listFiles(handoffRoot).filter((path) => path !== 'HANDOFF.json' && path !== 'SHA256SUMS');
assert(JSON.stringify(paths.slice().sort()) === JSON.stringify(diskFiles),
  'handoff contains unlisted or missing files');

const expectedSums = manifest.files.slice().sort(comparePaths)
  .map((file) => `${file.sha256}  ${file.path}`).join('\n') + '\n';
assert(readFileSync(sumsPath, 'utf8') === expectedSums, 'SHA256SUMS is stale or non-canonical');

const report = {
  schemaVersion: '1',
  handoffId: manifest.handoffId,
  accepted: true,
  trainingTrack: manifest.trainingTrack,
  trainingState: manifest.trainingState,
  sourceCommit: manifest.repository.sourceCommit,
  upstreamCommit: manifest.upstream.commit,
  featureSchemaVersion: manifest.artifact.featureSchemaVersion,
  decisionPayload: {
    path: decisionPayload.path,
    sizeBytes: decisionPayload.sizeBytes,
    sha256: decisionPayload.sha256
  },
  fileCount: manifest.files.length,
  totalListedBytes: totalBytes,
  runtimeIntegration: manifest.runtimeIntegration,
  evidence: manifest.evidence,
  releaseEligibility: 'researchCandidateOnly'
};

process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
