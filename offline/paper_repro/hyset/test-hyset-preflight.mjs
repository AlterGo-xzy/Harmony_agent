import { cpSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = dirname(fileURLToPath(import.meta.url));
const checker = join(root, 'check-hyset-repro.mjs');
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
    env: { ...process.env, HYSET_REPRO_ROOT: candidateRoot },
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

expectRejected('archive drift', 'upstream-lock.json', (value) => {
  value.repository.archive.sha256 = '0'.repeat(64);
}, 'source archive identity drift');

expectRejected('paper version drift', 'upstream-lock.json', (value) => {
  value.paper.version = 'v1';
}, 'paper identity drift');

expectRejected('pinned source drift', 'upstream-lock.json', (value) => {
  value.pinnedFiles[0].sha256 = '0'.repeat(64);
}, 'pinned source file identities drift');

expectRejected('checkpoint claim drift', 'upstream-lock.json', (value) => {
  value.sourceAudit.checkpoint.status = 'resolved';
}, 'checkpoint identity must remain unresolved');

expectRejected('external storage drift', 'upstream-lock.json', (value) => {
  value.externalSources[0].actualGitMode = '160000';
}, 'external source identity drift');

expectRejected('architecture boundary drift', 'reproduction-spec.json', (value) => {
  value.architectureBoundary.hardEligibilityRemainsAuthoritative = false;
}, 'harmony_agent tool-set architecture boundary drift');

expectRejected('paper target drift', 'reproduction-spec.json', (value) => {
  value.evaluation.paperTargets[1].compAt5Mean = 100;
}, 'Qwen paper targets drift');

expectRejected('execution claim drift', 'reproduction-spec.json', (value) => {
  value.execution.checkpointDownloaded = true;
}, 'zero-execution source preflight');

expectRejected('unknown field drift', 'reproduction-spec.json', (value) => {
  value.unreviewed = true;
}, 'reproduction spec fields drift');

process.stdout.write(`Tests run: ${passed}, Failure: 0, Error: 0, Pass: ${passed}, Ignore: 0\n`);
