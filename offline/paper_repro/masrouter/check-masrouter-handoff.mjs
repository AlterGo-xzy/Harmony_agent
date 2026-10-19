import { createHash } from 'node:crypto';
import { lstatSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const contractPath = join(scriptRoot, 'handoff-contract.json');
const upstreamLockPath = join(scriptRoot, 'upstream-lock.json');
const modelPoolsPath = join(scriptRoot, 'model-pools.json');
const priceSnapshotPath = join(scriptRoot, 'price-snapshot-candidate.json');

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

function isPrefixedSha256(value) {
  return typeof value === 'string' && /^sha256:[0-9a-f]{64}$/.test(value);
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
  assert(JSON.stringify(actual) === JSON.stringify(expected),
    `${label} contains missing or unknown fields`);
}

function uniqueTexts(values) {
  return Array.isArray(values) && values.length > 0 &&
    values.every((value) => isText(value)) && new Set(values).size === values.length;
}

function safeRelativePath(value) {
  return isText(value) && !isAbsolute(value) && !value.includes('\\') && !value.includes(':') &&
    value !== '.' && !value.startsWith('/') &&
    value.split('/').every((part) => part.length > 0 && part !== '.' && part !== '..');
}

function fileDigest(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
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

function isOrderedSubset(candidate, ordered) {
  let cursor = 0;
  for (const value of candidate) {
    while (cursor < ordered.length && ordered[cursor] !== value) cursor++;
    if (cursor >= ordered.length) return false;
    cursor++;
  }
  return true;
}

const contract = readJson(contractPath, 'handoff contract');
const upstreamLock = readJson(upstreamLockPath, 'upstream lock');
const modelPools = readJson(modelPoolsPath, 'T51 model pools');
const priceSnapshot = readJson(priceSnapshotPath, 'T51 price snapshot');

assert(contract.schemaVersion === '1', 'handoff contract schema drift');
assert(contract.upstreamCommit === upstreamLock.repository.commit &&
  contract.upstreamTree === upstreamLock.repository.tree, 'handoff contract and upstream lock drift');
assert(contract.sourceLicense === upstreamLock.license.spdx, 'handoff contract license drift');
assert(contract.algorithm === 'MasRouter', 'handoff contract algorithm drift');
assert(modelPools.upstreamCommit === contract.upstreamCommit, 'T51 model pool commit drift');
assert(priceSnapshot.upstreamCommit === contract.upstreamCommit, 'T51 price snapshot commit drift');
assert(priceSnapshot.costClaimsAllowed === false &&
  priceSnapshot.snapshotStatus !== 'verified', 'T51 price snapshot is not frozen');

const handoffArgument = argumentValue('--handoff');
assert(handoffArgument !== undefined, 'usage: node check-masrouter-handoff.mjs --handoff <directory>');
const handoffRoot = resolve(handoffArgument);
const handoffStats = lstatSync(handoffRoot);
assert(handoffStats.isDirectory() && !handoffStats.isSymbolicLink(),
  'handoff must be a regular directory');

const manifestPath = join(handoffRoot, contract.handoffFiles.manifestName);
const sumsPath = join(handoffRoot, contract.handoffFiles.sumsName);
const manifest = readJson(manifestPath, 'HANDOFF.json');

assertExactKeys(manifest, [
  'schemaVersion', 'handoffId', 'createdAt', 'researchOnly', 'trainingTrack', 'trainingState',
  'repository', 'upstream', 'artifact', 'runtimeIntegration', 'featureEnvelope', 'candidatePlan',
  'candidateModelSet', 'roleRegistrySnapshot', 'modelPoolSnapshot', 'priceSnapshot', 'evidence',
  'costIncurredUsd', 'files'
], 'handoff manifest');
assert(manifest.schemaVersion === contract.schemaVersion, 'handoff schema must be 1');
assert(isText(manifest.handoffId), 'handoffId is required');
assert(isIsoTimestamp(manifest.createdAt), 'createdAt must be an ISO timestamp with timezone');
assert(manifest.researchOnly === true, 'researchOnly must be true');
assert(contract.allowedTrainingTracks.includes(manifest.trainingTrack), 'unsupported trainingTrack');
assert(contract.allowedTrainingStates.includes(manifest.trainingState), 'unsupported trainingState');

assertExactKeys(manifest.repository, ['sourceCommit', 'dirty'], 'repository');
assert(isFullCommit(manifest.repository.sourceCommit), 'repository sourceCommit must be a full commit id');
assert(manifest.repository.dirty === false, 'handoff repository must be clean');
assertExactKeys(manifest.upstream, ['commit', 'tree', 'license'], 'upstream');
assert(manifest.upstream.commit === contract.upstreamCommit &&
  manifest.upstream.tree === contract.upstreamTree &&
  manifest.upstream.license === contract.sourceLicense, 'upstream identity drift');

assertExactKeys(manifest.artifact, [
  'algorithm', 'artifactKind', 'decisionParameterCount', 'includesEncoderWeights',
  'includesTokenizerAssets', 'includesPythonRuntime', 'includesPyTorch',
  'includesOptimizerState', 'includesDatasets', 'includesTrainingLogs',
  'artifactManifestCompatible'
], 'artifact');
assert(manifest.artifact.algorithm === contract.algorithm, 'artifact algorithm drift');
assert(manifest.artifact.artifactKind === contract.releaseBoundary.artifactKind,
  'artifact kind drift');
assert(Number.isSafeInteger(manifest.artifact.decisionParameterCount) &&
  manifest.artifact.decisionParameterCount >= 0, 'decisionParameterCount must be a non-negative integer');
assert(manifest.artifact.includesEncoderWeights === false, 'encoder weights are forbidden in the handoff');
assert(manifest.artifact.includesTokenizerAssets === false, 'tokenizer assets are forbidden in the handoff');
assert(manifest.artifact.includesPythonRuntime === false, 'Python runtime is forbidden in the handoff');
assert(manifest.artifact.includesPyTorch === false, 'PyTorch runtime is forbidden in the handoff');
assert(manifest.artifact.includesOptimizerState === false, 'optimizer state is forbidden in the handoff');
assert(manifest.artifact.includesDatasets === false, 'datasets are forbidden in the handoff');
assert(manifest.artifact.includesTrainingLogs === false, 'training logs are forbidden in the handoff');
assert(manifest.artifact.artifactManifestCompatible === true,
  'artifact must be compatible with the existing ArtifactManifest');

assertExactKeys(manifest.runtimeIntegration, Object.keys(contract.runtimeIntegration),
  'runtimeIntegration');
for (const [key, expected] of Object.entries(contract.runtimeIntegration)) {
  assert(manifest.runtimeIntegration[key] === expected, `runtime integration drift: ${key}`);
}

assertExactKeys(manifest.featureEnvelope, ['featureSchemaVersion', 'encoder', 'sourceDigests'],
  'featureEnvelope');
assert(manifest.featureEnvelope.featureSchemaVersion === contract.featureEnvelope.schemaVersion,
  'feature schema version drift');
assertExactKeys(manifest.featureEnvelope.encoder,
  ['modelId', 'dimensions', 'revision', 'sha256', 'deploymentMode'], 'featureEnvelope.encoder');
assert(manifest.featureEnvelope.encoder.modelId === contract.featureEnvelope.encoderModelId,
  'encoder model drift');
assert(manifest.featureEnvelope.encoder.dimensions === contract.featureEnvelope.encoderDimensions,
  'encoder dimensions drift');
assert(isText(manifest.featureEnvelope.encoder.revision), 'encoder revision is required');
assert(isSha256(manifest.featureEnvelope.encoder.sha256), 'encoder sha256 is required');
assert(manifest.featureEnvelope.encoder.deploymentMode === contract.featureEnvelope.deploymentMode,
  'encoder deployment mode drift');
assertExactKeys(manifest.featureEnvelope.sourceDigests,
  ['upstreamCommit', 'paperSha256', 'featureSchemaSha256', 'roleRegistrySnapshotSha256',
    'modelPoolSnapshotSha256', 'priceSnapshotSha256'], 'featureEnvelope.sourceDigests');
assert(manifest.featureEnvelope.sourceDigests.upstreamCommit === contract.upstreamCommit,
  'feature source commit drift');
assert(manifest.featureEnvelope.sourceDigests.paperSha256 === upstreamLock.paper.pdfSha256,
  'paper digest drift');
for (const key of ['paperSha256', 'featureSchemaSha256', 'roleRegistrySnapshotSha256',
  'modelPoolSnapshotSha256', 'priceSnapshotSha256']) {
  assert(isSha256(manifest.featureEnvelope.sourceDigests[key]),
    `invalid source digest: ${key}`);
}

assertExactKeys(manifest.roleRegistrySnapshot,
  ['source', 'snapshotDigest', 'roleCount', 'roles'], 'roleRegistrySnapshot');
assert(manifest.roleRegistrySnapshot.source === 'RoleRegistry',
  'role registry snapshot source must be RoleRegistry');
assert(isSha256(manifest.roleRegistrySnapshot.snapshotDigest),
  'role registry snapshot digest is required');
assert(Array.isArray(manifest.roleRegistrySnapshot.roles) &&
  manifest.roleRegistrySnapshot.roles.length > 0 &&
  manifest.roleRegistrySnapshot.roles.length <= contract.planConstraints.maximumAssignments,
  'role registry snapshot size is invalid');
assert(manifest.roleRegistrySnapshot.roleCount === manifest.roleRegistrySnapshot.roles.length,
  'role registry count drift');
const roleIds = [];
for (const role of manifest.roleRegistrySnapshot.roles) {
  assertExactKeys(role, ['roleId', 'roleVersion', 'registryDigest'], 'role registry entry');
  assert(isText(role.roleId) && isText(role.roleVersion) && isPrefixedSha256(role.registryDigest),
    'role registry entry identity is invalid');
  assert(!roleIds.includes(role.roleId), `duplicate roleId: ${role.roleId}`);
  roleIds.push(role.roleId);
}

assertExactKeys(manifest.modelPoolSnapshot,
  ['source', 'snapshotDigest', 'modelCount', 'models'], 'modelPoolSnapshot');
assert(manifest.modelPoolSnapshot.source === 'ModelRegistry',
  'model pool snapshot source must be ModelRegistry');
assert(isSha256(manifest.modelPoolSnapshot.snapshotDigest), 'model pool snapshot digest is required');
assert(Array.isArray(manifest.modelPoolSnapshot.models) &&
  manifest.modelPoolSnapshot.models.length > 0, 'model pool snapshot must not be empty');
assert(manifest.modelPoolSnapshot.modelCount === manifest.modelPoolSnapshot.models.length,
  'model pool count drift');
const modelIds = [];
for (const model of manifest.modelPoolSnapshot.models) {
  assertExactKeys(model, ['modelId', 'modelVersion', 'registryDigest'], 'model pool entry');
  assert(isText(model.modelId) && isText(model.modelVersion) &&
    isPrefixedSha256(model.registryDigest), 'model pool entry identity is invalid');
  assert(!modelIds.includes(model.modelId), `duplicate modelId: ${model.modelId}`);
  modelIds.push(model.modelId);
}
const paperCoreIds = modelPools.paperCoreModelPool.map((entry) => entry.modelId);
const sourceIds = modelPools.sourceModelPool.map((entry) => entry.modelId);
if (manifest.trainingTrack === 'official-reproduction') {
  assert(JSON.stringify(modelIds) === JSON.stringify(paperCoreIds),
    'official reproduction model pool drift');
} else {
  for (const modelId of modelIds) {
    assert(sourceIds.includes(modelId), `source model is out of bounds: ${modelId}`);
  }
}

assertExactKeys(manifest.priceSnapshot,
  ['snapshotId', 'snapshotDigest', 'currency', 'unit', 'verified'], 'priceSnapshot');
assert(isText(manifest.priceSnapshot.snapshotId), 'price snapshotId is required');
assert(isSha256(manifest.priceSnapshot.snapshotDigest), 'price snapshot digest is required');
assert(manifest.priceSnapshot.currency === 'USD' && manifest.priceSnapshot.unit === 'per-million-tokens',
  'price snapshot unit drift');
assert(manifest.priceSnapshot.verified === false, 'price snapshot must remain unverified');

assertExactKeys(manifest.candidatePlan, [
  'planVersion', 'mode', 'taskBinding', 'roleRegistryDigest', 'decisionDigest', 'assignments',
  'confidenceBasisPoints', 'estimatedCostMicros', 'estimatedActivationCount'
], 'candidatePlan');
assert(manifest.candidatePlan.planVersion === contract.planConstraints.planVersion,
  'candidate plan version drift');
assert(contract.planConstraints.allowedModes.includes(manifest.candidatePlan.mode),
  'candidate plan mode is unsupported');
assert(manifest.candidatePlan.taskBinding === contract.planConstraints.taskBinding,
  'candidate plan must bind the task at runtime');
assert(isPrefixedSha256(manifest.candidatePlan.roleRegistryDigest) &&
  isPrefixedSha256(manifest.candidatePlan.decisionDigest), 'candidate plan digests are invalid');
assert(manifest.candidatePlan.roleRegistryDigest ===
  `sha256:${manifest.roleRegistrySnapshot.snapshotDigest}`,
  'candidate plan roleRegistryDigest drift');
assert(Array.isArray(manifest.candidatePlan.assignments), 'candidate plan assignments are required');
if (manifest.candidatePlan.mode === 'single') {
  assert(manifest.candidatePlan.assignments.length === contract.planConstraints.singleAssignmentCount,
    'single collaboration requires exactly one role');
} else {
  assert(manifest.candidatePlan.assignments.length >= contract.planConstraints.minimumMultiAssignments,
    'multi collaboration requires at least two roles');
}
assert(manifest.candidatePlan.assignments.length <= contract.planConstraints.maximumAssignments,
  'candidate plan assignments exceed maximumAssignments');
const assignmentRoleIds = [];
for (const assignment of manifest.candidatePlan.assignments) {
  assertExactKeys(assignment, ['roleId', 'roleVersion', 'roleRegistryDigest'],
    'candidate plan assignment');
  assert(isText(assignment.roleId) && isText(assignment.roleVersion) &&
    isPrefixedSha256(assignment.roleRegistryDigest), 'candidate plan assignment identity is invalid');
  const role = manifest.roleRegistrySnapshot.roles.find((entry) => entry.roleId === assignment.roleId);
  assert(role !== undefined, `role assignment is not present in the Role Registry snapshot: ${assignment.roleId}`);
  assert(role.roleVersion === assignment.roleVersion &&
    role.registryDigest === assignment.roleRegistryDigest,
    `role assignment identity drift: ${assignment.roleId}`);
  assert(!assignmentRoleIds.includes(assignment.roleId),
    `duplicate role assignment: ${assignment.roleId}`);
  assignmentRoleIds.push(assignment.roleId);
}
assert(isOrderedSubset(assignmentRoleIds, roleIds), 'role assignments must follow Role Registry order');
assert(Number.isSafeInteger(manifest.candidatePlan.confidenceBasisPoints) &&
  manifest.candidatePlan.confidenceBasisPoints >= contract.planConstraints.confidenceBasisPointsMinimum &&
  manifest.candidatePlan.confidenceBasisPoints <= contract.planConstraints.confidenceBasisPointsMaximum,
  'confidenceBasisPoints is out of range');
assert(Number.isSafeInteger(manifest.candidatePlan.estimatedCostMicros) &&
  manifest.candidatePlan.estimatedCostMicros >= 0, 'estimatedCostMicros is invalid');
assert(manifest.candidatePlan.estimatedActivationCount ===
  manifest.candidatePlan.assignments.length, 'estimatedActivationCount drift');

assert(Array.isArray(manifest.candidateModelSet) && manifest.candidateModelSet.length > 0,
  'candidateModelSet is required');
const candidateModelIds = [];
for (const candidate of manifest.candidateModelSet) {
  assertExactKeys(candidate,
    ['modelId', 'modelVersion', 'modelRegistryDigest', 'advisoryOnly', 'authorizationGranted'],
    'candidate model entry');
  assert(isText(candidate.modelId) && isText(candidate.modelVersion) &&
    isPrefixedSha256(candidate.modelRegistryDigest), 'candidate model identity is invalid');
  const model = manifest.modelPoolSnapshot.models.find((entry) => entry.modelId === candidate.modelId);
  assert(model !== undefined, `candidate model is not present in the model pool snapshot: ${candidate.modelId}`);
  assert(model.modelVersion === candidate.modelVersion &&
    model.registryDigest === candidate.modelRegistryDigest,
    `candidate model identity drift: ${candidate.modelId}`);
  assert(candidate.advisoryOnly === true && candidate.authorizationGranted === false,
    'candidate model selection must remain advisory and unauthorized');
  assert(!candidateModelIds.includes(candidate.modelId),
    `duplicate candidate model: ${candidate.modelId}`);
  candidateModelIds.push(candidate.modelId);
}
assert(isOrderedSubset(candidateModelIds, modelIds),
  'candidate model set must follow Model Registry order');

const evidenceFields = ['paperReproduction', 'pythonReference', 'arktsParity', 'deviceParity',
  'shadow', 'canary', 'active'];
assertExactKeys(manifest.evidence, evidenceFields, 'evidence');
for (const field of evidenceFields) {
  assert(contract.allowedEvidenceStates.includes(manifest.evidence[field]),
    `invalid evidence state: ${field}`);
}
for (const field of ['arktsParity', 'deviceParity', 'shadow', 'canary', 'active']) {
  assert(manifest.evidence[field] === 'notRun', `training repository cannot claim ${field}`);
}
assert(typeof manifest.costIncurredUsd === 'number' && Number.isFinite(manifest.costIncurredUsd) &&
  manifest.costIncurredUsd >= 0, 'costIncurredUsd must be a finite non-negative number');
if (manifest.trainingState === 'smoke') {
  assert(manifest.costIncurredUsd === 0, 'smoke handoff must report zero cost');
}
if (manifest.trainingState === 'candidate') {
  assert(manifest.evidence.pythonReference === 'passed',
    'candidate requires passed Python reference evidence');
  assert(manifest.artifact.decisionParameterCount > 0,
    'candidate requires a positive decisionParameterCount');
}

assert(Array.isArray(manifest.files) && manifest.files.length > 0, 'files list is required');
const paths = [];
const roles = [];
let totalBytes = 0;
let decisionPayload;
const filesByRole = new Map();
for (const file of manifest.files) {
  assertExactKeys(file, ['path', 'role', 'sizeBytes', 'sha256'], 'file entry');
  assert(safeRelativePath(file.path), 'file path must be safe and relative');
  assert(isText(file.role), `file role is required: ${file.path}`);
  assert(contract.allowedFileRoles.includes(file.role), `unsupported file role: ${file.role}`);
  assert(!contract.forbiddenFileRoles.includes(file.role), `forbidden file role: ${file.role}`);
  const lowerPath = file.path.toLowerCase();
  const segments = lowerPath.split('/');
  for (const term of contract.forbiddenPathSegments) {
    for (const segment of segments) {
      assert(!segment.includes(term), `forbidden path segment ${term}: ${file.path}`);
    }
  }
  const lastName = segments[segments.length - 1];
  const dot = lastName.lastIndexOf('.');
  if (dot >= 0) {
    const extension = lastName.slice(dot);
    assert(!contract.forbiddenExtensions.includes(extension),
      `forbidden file extension ${extension}: ${file.path}`);
  }
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
  assert(totalBytes <= contract.applicationBudget.maximumHandoffBytes,
    'handoff exceeds total size budget');
  assert(fileDigest(absolute) === file.sha256, `file digest drift: ${file.path}`);
  if (file.role === 'decisionPayload') {
    assert(decisionPayload === undefined, 'exactly one decisionPayload is allowed');
    decisionPayload = file;
  }
  if (!filesByRole.has(file.role)) filesByRole.set(file.role, []);
  filesByRole.get(file.role).push(file);
}

for (const role of contract.requiredFileRoles) {
  assert(roles.includes(role), `required file role missing: ${role}`);
}
assert(decisionPayload !== undefined, 'decisionPayload is required');
assert(decisionPayload.sizeBytes <= contract.applicationBudget.maximumDecisionPayloadBytes,
  'decision payload exceeds application budget');
for (const role of ['featureSchema', 'roleRegistrySnapshot', 'modelPoolSnapshot', 'priceSnapshot']) {
  assert(filesByRole.get(role).length === 1, `exactly one ${role} file is allowed`);
}

function contentOf(role) {
  const entry = filesByRole.get(role)[0];
  return readJson(resolve(handoffRoot, entry.path), role);
}

const featureSchemaFile = filesByRole.get('featureSchema')[0];
assert(featureSchemaFile.sha256 === manifest.featureEnvelope.sourceDigests.featureSchemaSha256,
  'feature schema digest drift');
const roleRegistryFile = filesByRole.get('roleRegistrySnapshot')[0];
assert(roleRegistryFile.sha256 === manifest.featureEnvelope.sourceDigests.roleRegistrySnapshotSha256,
  'role registry snapshot digest drift');
assert(roleRegistryFile.sha256 === manifest.roleRegistrySnapshot.snapshotDigest,
  'role registry snapshot digest drift');
const roleRegistryContent = contentOf('roleRegistrySnapshot');
assertExactKeys(roleRegistryContent, ['roleCount', 'roles'], 'role registry snapshot file');
assert(roleRegistryContent.roleCount === manifest.roleRegistrySnapshot.roleCount &&
  JSON.stringify(roleRegistryContent.roles) === JSON.stringify(manifest.roleRegistrySnapshot.roles),
  'role registry snapshot file drift');
const modelPoolFile = filesByRole.get('modelPoolSnapshot')[0];
assert(modelPoolFile.sha256 === manifest.featureEnvelope.sourceDigests.modelPoolSnapshotSha256,
  'model pool snapshot digest drift');
assert(modelPoolFile.sha256 === manifest.modelPoolSnapshot.snapshotDigest,
  'model pool snapshot digest drift');
const modelPoolContent = contentOf('modelPoolSnapshot');
assertExactKeys(modelPoolContent, ['modelCount', 'models'], 'model pool snapshot file');
assert(modelPoolContent.modelCount === manifest.modelPoolSnapshot.modelCount &&
  JSON.stringify(modelPoolContent.models) === JSON.stringify(manifest.modelPoolSnapshot.models),
  'model pool snapshot file drift');
const priceFile = filesByRole.get('priceSnapshot')[0];
assert(priceFile.sha256 === manifest.featureEnvelope.sourceDigests.priceSnapshotSha256,
  'price snapshot digest drift');
assert(priceFile.sha256 === manifest.priceSnapshot.snapshotDigest,
  'price snapshot digest drift');
const priceContent = contentOf('priceSnapshot');
assertExactKeys(priceContent, ['snapshotId', 'currency', 'unit', 'verified'], 'price snapshot file');
assert(priceContent.snapshotId === manifest.priceSnapshot.snapshotId &&
  priceContent.currency === manifest.priceSnapshot.currency &&
  priceContent.unit === manifest.priceSnapshot.unit &&
  priceContent.verified === manifest.priceSnapshot.verified,
  'price snapshot file drift');

if (manifest.evidence.paperReproduction !== 'notRun') {
  assert(roles.includes('paperReproductionReport'),
    'paper reproduction evidence requires paperReproductionReport');
}
if (manifest.evidence.pythonReference !== 'notRun') {
  assert(roles.includes('pythonReferenceReport'),
    'Python reference evidence requires pythonReferenceReport');
}
if (manifest.trainingState === 'candidate') {
  assert(roles.includes('pythonReferenceReport'),
    'candidate requires a pythonReferenceReport');
}

const diskFiles = listFiles(handoffRoot)
  .filter((path) => path !== contract.handoffFiles.manifestName && path !== contract.handoffFiles.sumsName);
assert(JSON.stringify(paths.slice().sort()) === JSON.stringify(diskFiles),
  'handoff contains unlisted or missing files');

const expectedSums = manifest.files.slice().sort((left, right) => {
  if (left.path < right.path) return -1;
  if (left.path > right.path) return 1;
  return 0;
}).map((file) => `${file.sha256}  ${file.path}`).join('\n') + '\n';
assert(readFileSync(sumsPath, 'utf8') === expectedSums, 'SHA256SUMS is stale or non-canonical');

const report = {
  schemaVersion: '1',
  contractId: contract.contractId,
  handoffId: manifest.handoffId,
  accepted: true,
  researchOnly: manifest.researchOnly,
  trainingTrack: manifest.trainingTrack,
  trainingState: manifest.trainingState,
  upstreamCommit: manifest.upstream.commit,
  planVersion: manifest.candidatePlan.planVersion,
  mode: manifest.candidatePlan.mode,
  roleCount: manifest.roleRegistrySnapshot.roleCount,
  assignmentCount: manifest.candidatePlan.assignments.length,
  modelCount: manifest.modelPoolSnapshot.modelCount,
  candidateModelCount: manifest.candidateModelSet.length,
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
