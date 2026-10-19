import { createHash } from 'node:crypto';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
const workspaceRoot = join(root, '..', '..', '..');
const testRoot = join(workspaceRoot, 'artifacts', 't52-handoff-tests');
const fixtureSource = join(root, 'fixtures', 'research-only-handoff');
const checker = join(root, 'check-masrouter-handoff.mjs');
const modelPools = JSON.parse(readFileSync(join(root, 'model-pools.json'), 'utf8'));
let passed = 0;

process.on('exit', () => {
  rmSync(testRoot, { recursive: true, force: true });
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function digest(content) {
  return createHash('sha256').update(content).digest('hex');
}

function fixture() {
  mkdirSync(testRoot, { recursive: true });
  const candidateRoot = mkdtempSync(join(testRoot, 'run-'));
  for (const name of readdirSync(fixtureSource)) {
    cpSync(join(fixtureSource, name), join(candidateRoot, name), { recursive: true });
  }
  return candidateRoot;
}

function readManifest(candidateRoot) {
  return JSON.parse(readFileSync(join(candidateRoot, 'HANDOFF.json'), 'utf8'));
}

function writeManifest(candidateRoot, manifest) {
  writeFileSync(join(candidateRoot, 'HANDOFF.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  const sums = manifest.files.slice().sort((left, right) => {
    if (left.path < right.path) return -1;
    if (left.path > right.path) return 1;
    return 0;
  }).map((file) => `${file.sha256}  ${file.path}`).join('\n') + '\n';
  writeFileSync(join(candidateRoot, 'SHA256SUMS'), sums, 'utf8');
}

function run(candidateRoot) {
  return spawnSync(process.execPath, [checker, '--handoff', candidateRoot], {
    cwd: root,
    encoding: 'utf8'
  });
}

function writeFixtureFile(candidateRoot, manifest, role, content) {
  const file = manifest.files.find((entry) => entry.role === role);
  assert(file !== undefined, `fixture role missing: ${role}`);
  const absolute = join(candidateRoot, ...file.path.split('/'));
  writeFileSync(absolute, content);
  file.sizeBytes = Buffer.byteLength(content);
  file.sha256 = digest(content);
  return file;
}

function expectRejected(name, mutation, expectedMessage) {
  const candidateRoot = fixture();
  try {
    const manifest = readManifest(candidateRoot);
    const rewrite = mutation(manifest, candidateRoot);
    if (rewrite !== false) writeManifest(candidateRoot, manifest);
    const result = run(candidateRoot);
    assert(result.status !== 0, `${name} unexpectedly passed`);
    assert(result.stderr.includes(expectedMessage), `${name} returned an unexpected reason: ${result.stderr}`);
    process.stdout.write(`PASS: ${name} -> ${expectedMessage}\n`);
    passed++;
  } finally {
    rmSync(candidateRoot, { recursive: true, force: true });
  }
}

function expectAccepted(name, mutation) {
  const candidateRoot = fixture();
  try {
    const manifest = readManifest(candidateRoot);
    mutation(manifest, candidateRoot);
    writeManifest(candidateRoot, manifest);
    const result = run(candidateRoot);
    assert(result.status === 0, `${name} failed: ${result.stderr}`);
    const report = JSON.parse(result.stdout);
    assert(report.accepted === true && report.releaseEligibility === 'researchCandidateOnly',
      `${name} report drift`);
    process.stdout.write(`PASS: ${name}\n`);
    passed++;
  } finally {
    rmSync(candidateRoot, { recursive: true, force: true });
  }
}

expectAccepted('valid research-only adaptation handoff', () => {});

expectAccepted('valid single-agent handoff', (manifest) => {
  manifest.candidatePlan.mode = 'single';
  manifest.candidatePlan.assignments = [manifest.candidatePlan.assignments[0]];
  manifest.candidatePlan.estimatedActivationCount = 1;
});

expectAccepted('valid official-reproduction model pool', (manifest, candidateRoot) => {
  const paperModelIds = modelPools.paperCoreModelPool.map((entry) => entry.modelId);
  const models = paperModelIds.map((modelId, index) => ({
    modelId,
    modelVersion: 'paper-protocol',
    registryDigest: `sha256:${String(index + 6).repeat(64)}`
  }));
  const content = `${JSON.stringify({ modelCount: models.length, models }, null, 2)}\n`;
  const file = writeFixtureFile(candidateRoot, manifest, 'modelPoolSnapshot', content);
  manifest.trainingTrack = 'official-reproduction';
  manifest.modelPoolSnapshot = {
    source: 'ModelRegistry',
    snapshotDigest: file.sha256,
    modelCount: models.length,
    models
  };
  manifest.featureEnvelope.sourceDigests.modelPoolSnapshotSha256 = file.sha256;
  manifest.candidateModelSet = models.slice(0, 2).map((model) => ({
    modelId: model.modelId,
    modelVersion: model.modelVersion,
    modelRegistryDigest: model.registryDigest,
    advisoryOnly: true,
    authorizationGranted: false
  }));
});

expectRejected('upstream drift', (manifest) => {
  manifest.upstream.commit = '0'.repeat(40);
}, 'upstream identity drift');

expectRejected('unknown top-level field', (manifest) => {
  manifest.unreviewedClaim = true;
}, 'handoff manifest contains missing or unknown fields');

expectRejected('unknown nested plan field', (manifest) => {
  manifest.candidatePlan.taskId = 'task-control-field';
}, 'candidatePlan contains missing or unknown fields');

expectRejected('encoder weights inclusion', (manifest) => {
  manifest.artifact.includesEncoderWeights = true;
}, 'encoder weights are forbidden');

expectRejected('Python runtime inclusion', (manifest) => {
  manifest.artifact.includesPythonRuntime = true;
}, 'Python runtime is forbidden');

expectRejected('encoder path inclusion', (manifest, candidateRoot) => {
  const content = Buffer.from('encoder-weights');
  const path = 'encoder/weights.bin';
  const absolute = join(candidateRoot, 'encoder', 'weights.bin');
  mkdirSync(dirname(absolute), { recursive: true });
  writeFileSync(absolute, content);
  manifest.files.push({
    path,
    role: 'commands',
    sizeBytes: content.length,
    sha256: digest(content)
  });
}, 'forbidden path segment encoder');

expectRejected('synchronous network in selectPlan', (manifest) => {
  manifest.runtimeIntegration.networkInsideSynchronousSelectPlan = true;
}, 'runtime integration drift: networkInsideSynchronousSelectPlan');

expectRejected('role out of bounds', (manifest) => {
  manifest.candidatePlan.assignments[0].roleId = 'UnknownRole';
}, 'role assignment is not present in the Role Registry snapshot');

expectRejected('role assignment order drift', (manifest) => {
  manifest.candidatePlan.assignments.reverse();
}, 'role assignments must follow Role Registry order');

expectRejected('candidate model out of bounds', (manifest) => {
  manifest.candidateModelSet[0].modelId = 'unknown-model';
}, 'candidate model is not present in the model pool snapshot');

expectRejected('official reproduction model pool drift', (manifest) => {
  manifest.trainingTrack = 'official-reproduction';
}, 'official reproduction model pool drift');

expectRejected('feature schema digest drift', (manifest, candidateRoot) => {
  const content = '{"schemaVersion":"masrouter-feature-v1","drifted":true}\n';
  writeFixtureFile(candidateRoot, manifest, 'featureSchema', content);
}, 'feature schema digest drift');

expectRejected('file digest drift', (manifest, candidateRoot) => {
  const file = manifest.files.find((entry) => entry.role === 'goldenFixtures');
  writeFileSync(join(candidateRoot, ...file.path.split('/')), '{"fixtureId":"research-only-two"}\n');
}, 'file digest drift');

expectRejected('extra unlisted file', (manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, 'unexpected.bin'), 'unexpected');
}, 'handoff contains unlisted or missing files');

expectRejected('candidate without Python reference evidence', (manifest) => {
  manifest.trainingState = 'candidate';
}, 'candidate requires passed Python reference evidence');

expectRejected('parity claim', (manifest) => {
  manifest.evidence.arktsParity = 'passed';
}, 'training repository cannot claim arktsParity');

expectRejected('stale SHA256SUMS', (manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, 'SHA256SUMS'), `${'0'.repeat(64)}  wrong\n`);
  return false;
}, 'SHA256SUMS is stale or non-canonical');

expectRejected('oversized decision payload', (manifest, candidateRoot) => {
  const content = Buffer.alloc(5242881, 7);
  writeFixtureFile(candidateRoot, manifest, 'decisionPayload', content);
}, 'decision payload exceeds application budget');

function replaceFeatureSchema(manifest, candidateRoot, content) {
  const file = writeFixtureFile(candidateRoot, manifest, 'featureSchema', content);
  manifest.featureEnvelope.sourceDigests.featureSchemaSha256 = file.sha256;
}

expectRejected('invalid feature schema JSON with matching digest', (manifest, candidateRoot) => {
  replaceFeatureSchema(manifest, candidateRoot, 'NOT JSON');
}, 'featureSchema is not valid JSON');

expectRejected('feature schema must be an object', (manifest, candidateRoot) => {
  replaceFeatureSchema(manifest, candidateRoot, '[]');
}, 'feature schema file must be an object');

expectRejected('incompatible feature schema version with matching digest', (manifest, candidateRoot) => {
  replaceFeatureSchema(manifest, candidateRoot, '{"schemaVersion":"incompatible-v999"}');
}, 'feature schema file version drift');

expectRejected('unknown feature schema field with matching digest', (manifest, candidateRoot) => {
  replaceFeatureSchema(manifest, candidateRoot, '{"schemaVersion":"masrouter-feature-v1","taskId":"forbidden"}');
}, 'feature schema file contains missing or unknown fields');

const maximumHandoffBytes = JSON.parse(readFileSync(join(root, 'handoff-contract.json'), 'utf8'))
  .applicationBudget.maximumHandoffBytes;

expectRejected('oversized manifest rejected before JSON parsing', (manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, 'HANDOFF.json'), Buffer.alloc(maximumHandoffBytes + 1, 32));
  return false;
}, 'handoff exceeds total size budget');

expectRejected('oversized checksum metadata', (manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, 'SHA256SUMS'), Buffer.alloc(maximumHandoffBytes + 1, 32));
  return false;
}, 'handoff exceeds total size budget');

expectRejected('aggregate budget includes manifest and checksums', (manifest, candidateRoot) => {
  const file = manifest.files.find((entry) => entry.role === 'goldenFixtures');
  const otherBytes = manifest.files.reduce((sum, entry) => sum + (entry === file ? 0 : entry.sizeBytes), 0);
  // Listed bytes alone meet the limit; metadata pushes the package over it.
  writeFixtureFile(candidateRoot, manifest, 'goldenFixtures', Buffer.alloc(maximumHandoffBytes - otherBytes, 32));
}, 'handoff exceeds total size budget');

{
  const candidateRoot = fixture();
  try {
    const result = run(candidateRoot);
    assert(result.status === 0, `size accounting fixture failed: ${result.stderr}`);
    const report = JSON.parse(result.stdout);
    const manifest = readManifest(candidateRoot);
    const expected = manifest.files.reduce((sum, entry) => sum + entry.sizeBytes, 0) +
      statSync(join(candidateRoot, 'HANDOFF.json')).size + statSync(join(candidateRoot, 'SHA256SUMS')).size;
    assert(report.totalHandoffBytes === expected, 'totalHandoffBytes excludes metadata');
    process.stdout.write('PASS: total handoff bytes include metadata\n');
    passed++;
  } finally {
    rmSync(candidateRoot, { recursive: true, force: true });
  }
}

process.stdout.write(`Tests run: ${passed}, Failure: 0, Error: 0, Pass: ${passed}, Ignore: 0\n`);
