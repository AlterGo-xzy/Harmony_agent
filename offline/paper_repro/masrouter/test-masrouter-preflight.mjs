import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
const checker = join(root, 'check-masrouter-repro.mjs');
let passed = 0;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function fixture() {
  const candidateRoot = mkdtempSync(join(root, '.tmp-preflight-'));
  cpSync(join(root, 'upstream-lock.json'), join(candidateRoot, 'upstream-lock.json'));
  cpSync(join(root, 'reproduction-spec.json'), join(candidateRoot, 'reproduction-spec.json'));
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
    env: { ...process.env, MASROUTER_REPRO_ROOT: candidateRoot },
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
  assert(result.status === 0, `valid preflight failed: ${result.stderr}`);
  passed++;
} finally {
  rmSync(validRoot, { recursive: true, force: true });
}

expectRejected('commit drift', 'reproduction-spec.json', (value) => {
  value.upstreamCommit = '0'.repeat(40);
}, 'spec and lock commit must match');

expectRejected('architecture boundary drift', 'reproduction-spec.json', (value) => {
  value.architectureBoundary.singleAgentAlwaysValid = false;
}, 'harmony_agent collaboration boundary drift');

expectRejected('execution claim drift', 'reproduction-spec.json', (value) => {
  value.execution.providerCallsExecuted = true;
}, 'zero-execution preflight');

process.stdout.write(`Tests run: ${passed}, Failure: 0, Error: 0, Pass: ${passed}, Ignore: 0\n`);
