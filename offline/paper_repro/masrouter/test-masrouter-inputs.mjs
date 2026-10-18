import { cpSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
const checker = join(root, 'check-masrouter-inputs.mjs');
let passed = 0;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function fixture() {
  const candidateRoot = mkdtempSync(join(tmpdir(), 'masrouter-t51-inputs-'));
  for (const name of readdirSync(root)) {
    if (name.startsWith('.tmp-')) continue;
    cpSync(join(root, name), join(candidateRoot, name), { recursive: true });
  }
  return candidateRoot;
}

function mutate(candidateRoot, fileName, mutation) {
  const path = join(candidateRoot, fileName);
  const value = JSON.parse(readFileSync(path, 'utf8'));
  mutation(value);
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function run(candidateRoot) {
  return spawnSync(process.execPath, [checker], {
    cwd: root,
    env: { ...process.env, MASROUTER_INPUT_ROOT: candidateRoot },
    encoding: 'utf8'
  });
}

function expectRejected(name, fileName, mutation, expectedMessage) {
  const candidateRoot = fixture();
  try {
    mutate(candidateRoot, fileName, mutation);
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
  assert(result.status === 0, `valid input contract failed: ${result.stderr}`);
  passed++;
} finally {
  rmSync(validRoot, { recursive: true, force: true });
}

expectRejected('environment lock claim drift', 'environment-candidates.json', (value) => {
  value.lockStatus = 'locked';
}, 'unresolved dependency cannot be marked locked');

expectRejected('dataset digest claim drift', 'dataset-lock.json', (value) => {
  value.datasets[0].status = 'locked';
}, 'locked dataset requires positive sizeBytes, recordCount, and sha256');

expectRejected('dataset execution readiness drift', 'dataset-lock.json', (value) => {
  value.executionReady = true;
}, 'dataset executionReady must remain false at T51');

expectRejected('paper/source pool merge', 'model-pools.json', (value) => {
  value.paperCoreModelPool[0].modelId = 'gpt-4o-mini';
}, 'paper and source model pools must remain separate');

expectRejected('model revision drift', 'model-pools.json', (value) => {
  value.sourceModelPool[0].revision = 'main';
}, 'model revision must remain unresolved at T51');

expectRejected('price conflict silently resolved', 'price-snapshot-candidate.json', (value) => {
  value.conflicts[0].resolution = 'resolved';
}, 'price conflict must remain explicit and unresolved');

expectRejected('zero-execution claim drift', 'input-contract.json', (value) => {
  value.execution.dependenciesInstalled = true;
}, 'T51 must remain a zero-execution input contract');

expectRejected('required issue removed', 'unresolved-issues.json', (value) => {
  value.issues = value.issues.filter((entry) => entry.id !== 'mmlu-download-module-missing');
  value.issueCount = value.issues.length;
}, 'required unresolved issue missing: mmlu-download-module-missing');

process.stdout.write(`Tests run: ${passed}, Failure: 0, Error: 0, Pass: ${passed}, Ignore: 0\n`);
