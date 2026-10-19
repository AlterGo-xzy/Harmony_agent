import { createHash } from 'node:crypto';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
const checker = join(root, 'check-mtrouter-handoff.mjs');
const spec = JSON.parse(readFileSync(join(root, 'reproduction-spec.json'), 'utf8'));
let passed = 0;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function digest(buffer) {
  return createHash('sha256').update(buffer).digest('hex');
}

function writeCandidateFile(candidateRoot, path, content) {
  const absolute = join(candidateRoot, ...path.split('/'));
  mkdirSync(dirname(absolute), { recursive: true });
  writeFileSync(absolute, content);
  return {
    path,
    sizeBytes: Buffer.byteLength(content),
    sha256: digest(content)
  };
}

function fixture() {
  const candidateRoot = mkdtempSync(join(root, '.tmp-handoff-'));
  const definitions = [
    ['checkpoint/decision.bin', 'decisionPayload', Buffer.from('decision-payload')],
    ['export/decision-safe.bin', 'safeDecisionExport', Buffer.from('safe-export')],
    ['schemas/feature-v1.json', 'featureSchema', Buffer.from('{"schemaVersion":"1"}\n')],
    ['fixtures/golden.jsonl', 'goldenFixtures', Buffer.from('{"fixtureId":"one"}\n')],
    ['reports/environment.json', 'environmentReport', Buffer.from('{"status":"recorded"}\n')],
    ['reports/training.json', 'trainingReport', Buffer.from('{"state":"smoke"}\n')],
    ['reports/evaluation.json', 'evaluationReport', Buffer.from('{"state":"notRun"}\n')],
    ['LICENSES/MTRouter-MIT.txt', 'sourceLicense', Buffer.from('MIT fixture\n')]
  ];
  const files = definitions.map(([path, role, content]) => ({
    ...writeCandidateFile(candidateRoot, path, content), role
  }));
  const manifest = {
    schemaVersion: '1',
    handoffId: 'fixture-handoff-v1',
    createdAt: '2026-10-18T16:00:00+08:00',
    trainingTrack: 'official-reproduction',
    trainingState: 'smoke',
    repository: {
      sourceCommit: '0123456789abcdef0123456789abcdef01234567',
      dirty: false
    },
    upstream: {
      commit: 'ee9e4573a128c3e54aa8c83800318bfb783c4dfe',
      tree: '6911bcf33bfdd30d6f414c09b5f5d14c5deeb913',
      license: 'MIT'
    },
    artifact: {
      algorithm: 'MTRouter',
      featureSchemaVersion: 'mtrouter-feature-v1',
      decisionParameterCount: 349537,
      includesHistoryEncoderWeights: false,
      includesTokenizerAssets: false,
      includesPythonRuntime: false,
      includesOptimizerState: false,
      historyEncoder: {
        modelId: 'Qwen/Qwen3-Embedding-0.6B',
        dimensions: 1024,
        maximumTokens: 8192,
        deploymentMode: 'external-controlled-service'
      }
    },
    runtimeIntegration: {
      learnedPort: 'LearnedRouterPort',
      learnedEnabledByDefault: false,
      networkInsideSynchronousRoute: false,
      fallback: 'deterministicBaseline'
    },
    modelPool: {
      orderedModelIds: spec.modelPool.map((model) => model.name),
      snapshotSha256: 'a'.repeat(64)
    },
    evidence: {
      paperReproduction: 'notRun',
      pythonReference: 'notRun',
      arktsParity: 'notRun',
      deviceParity: 'notRun',
      shadow: 'notRun',
      canary: 'notRun',
      active: 'notRun'
    },
    threeSeedHeldOutEvaluation: false,
    costIncurredUsd: 0,
    files
  };
  writeManifest(candidateRoot, manifest);
  return candidateRoot;
}

function writeManifest(candidateRoot, manifest) {
  writeFileSync(join(candidateRoot, 'HANDOFF.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
  const sums = manifest.files.slice().sort((left, right) => {
    if (left.path < right.path) return -1;
    if (left.path > right.path) return 1;
    return 0;
  })
    .map((file) => `${file.sha256}  ${file.path}`).join('\n') + '\n';
  writeFileSync(join(candidateRoot, 'SHA256SUMS'), sums, 'utf8');
}

function readManifest(candidateRoot) {
  return JSON.parse(readFileSync(join(candidateRoot, 'HANDOFF.json'), 'utf8'));
}

function run(candidateRoot) {
  return spawnSync(process.execPath, [checker, '--handoff', candidateRoot], {
    cwd: root,
    encoding: 'utf8'
  });
}

function expectRejected(name, mutation, expectedMessage) {
  const candidateRoot = fixture();
  try {
    const manifest = readManifest(candidateRoot);
    mutation(manifest, candidateRoot);
    writeManifest(candidateRoot, manifest);
    const result = run(candidateRoot);
    assert(result.status !== 0, `${name} unexpectedly passed`);
    assert(result.stderr.includes(expectedMessage), `${name} returned an unexpected reason: ${result.stderr}`);
    passed++;
  } finally {
    rmSync(candidateRoot, { recursive: true, force: true });
  }
}

const validRoot = fixture();
try {
  const result = run(validRoot);
  assert(result.status === 0, `valid handoff failed: ${result.stderr}`);
  const report = JSON.parse(result.stdout);
  assert(report.accepted === true && report.releaseEligibility === 'researchCandidateOnly',
    'valid handoff report drift');
  passed++;
} finally {
  rmSync(validRoot, { recursive: true, force: true });
}

const adaptationRoot = fixture();
try {
  const manifest = readManifest(adaptationRoot);
  manifest.trainingTrack = 'harmony-agent-adaptation';
  manifest.modelPool.orderedModelIds = ['model-z', 'model-a'];
  manifest.artifact.decisionParameterCount = 349473;
  writeManifest(adaptationRoot, manifest);
  const result = run(adaptationRoot);
  assert(result.status === 0, `valid adaptation handoff failed: ${result.stderr}`);
  passed++;
} finally {
  rmSync(adaptationRoot, { recursive: true, force: true });
}

expectRejected('upstream drift', (manifest) => {
  manifest.upstream.commit = '0'.repeat(40);
}, 'upstream identity drift');

expectRejected('encoder inclusion', (manifest) => {
  manifest.artifact.includesHistoryEncoderWeights = true;
}, 'history encoder weights are forbidden');

expectRejected('synchronous network', (manifest) => {
  manifest.runtimeIntegration.networkInsideSynchronousRoute = true;
}, 'runtime integration drift: networkInsideSynchronousRoute');

expectRejected('runtime claim', (manifest) => {
  manifest.evidence.arktsParity = 'passed';
}, 'training repository cannot claim arktsParity');

expectRejected('path traversal', (manifest) => {
  manifest.files[0].path = '../decision.bin';
}, 'file path must be safe and relative');

expectRejected('digest drift', (manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, ...manifest.files[0].path.split('/')), 'tampered-payload');
}, 'file digest drift');

expectRejected('unlisted file', (_manifest, candidateRoot) => {
  writeFileSync(join(candidateRoot, 'unexpected.bin'), 'unexpected');
}, 'handoff contains unlisted or missing files');

expectRejected('oversized decision payload', (manifest, candidateRoot) => {
  const content = Buffer.alloc(5242881, 7);
  const file = manifest.files.find((entry) => entry.role === 'decisionPayload');
  writeFileSync(join(candidateRoot, ...file.path.split('/')), content);
  file.sizeBytes = content.length;
  file.sha256 = digest(content);
}, 'decision payload exceeds application budget');

expectRejected('candidate without evidence', (manifest) => {
  manifest.trainingState = 'candidate';
}, 'candidate requires passed Python reference evidence');

expectRejected('official model order drift', (manifest) => {
  manifest.modelPool.orderedModelIds.reverse();
}, 'official reproduction model pool drift');

expectRejected('unsupported role', (manifest) => {
  manifest.files[0].role = 'historyEncoderWeights';
}, 'unsupported file role');

expectRejected('unknown manifest field', (manifest) => {
  manifest.unreviewedClaim = true;
}, 'handoff manifest contains missing or unknown fields');

expectRejected('evidence without report', (manifest) => {
  manifest.evidence.paperReproduction = 'passed';
}, 'paper reproduction evidence requires paperReproductionReport');

process.stdout.write(`Tests run: ${passed}, Failure: 0, Error: 0, Pass: ${passed}, Ignore: 0\n`);
