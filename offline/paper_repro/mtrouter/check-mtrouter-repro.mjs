import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const root = process.env.MTR_REPRO_ROOT === undefined ? scriptRoot : resolve(process.env.MTR_REPRO_ROOT);
const lockPath = join(root, 'upstream-lock.json');
const specPath = join(root, 'reproduction-spec.json');
const reportPath = join(root, 'reports', 'preflight-v1.json');

function bytes(path) {
  return readFileSync(path);
}

function json(path) {
  return JSON.parse(bytes(path).toString('utf8'));
}

function digest(path) {
  return `sha256:${createHash('sha256').update(bytes(path)).digest('hex')}`;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function isSha256(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

const lock = json(lockPath);
const spec = json(specPath);

assert(lock.schemaVersion === '1', 'upstream lock schema must be 1');
assert(spec.schemaVersion === '1', 'reproduction spec schema must be 1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.commit), 'upstream commit must be a full Git SHA-1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.tree), 'upstream tree must be a full Git SHA-1');
assert(spec.upstreamCommit === lock.repository.commit, 'spec and lock commit must match');
assert(spec.paperArxivId === lock.paper.arxivId, 'spec and paper arXiv id must match');
assert(lock.repository.archive.url.includes(lock.repository.commit), 'archive URL must pin the commit');
assert(lock.repository.archive.sizeBytes > 0 && isSha256(lock.repository.archive.sha256),
  'source archive digest must be pinned');
assert(lock.license.spdx === 'MIT' && isSha256(lock.license.sha256), 'MIT license digest must be pinned');
assert(lock.paper.version === 'v1' && isSha256(lock.paper.pdfSha256), 'paper v1 digest must be pinned');
assert(lock.repository.releaseTagsObserved === 0, 'unexpected upstream release tag count');
assert(lock.pinnedFiles.length === 2, 'pyproject and README must be pinned');
for (const file of lock.pinnedFiles) {
  assert(file.sizeBytes > 0 && isSha256(file.sha256), `invalid pinned file ${file.path}`);
}

assert(spec.claimState.sourceAudit === 'complete', 'source audit must be complete');
for (const field of ['environmentInstalled', 'upstreamTests', 'strictReproduction', 'harmonyAgentAdaptation']) {
  assert(spec.claimState[field] === 'notRun', `${field} must remain notRun at T48`);
}
assert(spec.method.runCount === 3, 'paper requires three runs');
assert(spec.method.historyEncoder === 'Qwen/Qwen3-Embedding-0.6B', 'history encoder drift');
assert(spec.method.historyEmbeddingDimensions === 1024, 'history embedding dimension drift');
assert(spec.method.historyMaxTokens === 8192, 'history token budget drift');
assert(spec.method.trainingEpochs === 100 && spec.method.earlyStoppingPatience === 3,
  'training schedule drift');
assert(spec.method.batchSize === 64 && spec.method.learningRate === 0.001,
  'training hyperparameter drift');
assert(spec.modelPool.length === 6, 'paper model pool must contain six models');
assert(new Set(spec.modelPool.map((model) => model.name)).size === 6, 'model names must be unique');
const expectedModels = [
  ['GPT-5', 400000, 1.25, 10.0],
  ['DeepSeek-V3.2', 164000, 0.27, 0.42],
  ['MiniMax-M2', 197000, 0.2, 1.0],
  ['Kimi-K2', 131000, 0.39, 1.9],
  ['Gemini-2.5-Flash-Lite', 1000000, 0.1, 0.4],
  ['GPT-OSS-120B', 131000, 0.09, 0.36]
];
for (let index = 0; index < expectedModels.length; index++) {
  const actual = spec.modelPool[index];
  const expected = expectedModels[index];
  assert(actual.name === expected[0] && actual.contextTokens === expected[1] &&
    actual.inputUsdPerMillion === expected[2] && actual.outputUsdPerMillion === expected[3],
  `model pool drift at index ${index}`);
}
assert(spec.benchmarks.length === 2, 'ScienceWorld and HLE must both be present');
assert(spec.benchmarks.flatMap((benchmark) => benchmark.targets).length === 4,
  'all four paper targets must be present');
const scienceWorld = spec.benchmarks.find((benchmark) => benchmark.id === 'scienceworld');
const hle = spec.benchmarks.find((benchmark) => benchmark.id === 'hle');
assert(scienceWorld !== undefined && scienceWorld.maximumHorizon === 50 &&
  scienceWorld.episodeBudgetUsd === 2.0 && scienceWorld.split.idTaskTypes === 13 &&
  scienceWorld.split.oodTaskTypes === 12 && scienceWorld.split.variationsPerTaskTypeMaximum === 30 &&
  JSON.stringify(scienceWorld.split.idTrainValidationTestPercent) === '[60,20,20]' &&
  scienceWorld.split.seed === 42, 'ScienceWorld protocol drift');
assert(JSON.stringify(scienceWorld.targets) === JSON.stringify([
  { split: 'test', performanceMetric: 'score', mean: 53.8, reportedStd: 3.2, totalCostUsd: 5.7 },
  { split: 'ood', performanceMetric: 'score', mean: 9.9, reportedStd: 3.9, totalCostUsd: 16.3 }
]), 'ScienceWorld targets drift');
assert(hle !== undefined && hle.maximumHorizon === 30 && hle.episodeBudgetUsd === 2.0 &&
  JSON.stringify(hle.tools) === '["search","browse","python","answer"]' &&
  hle.split.idCategories === 6 && hle.split.oodCategories === 2 &&
  hle.split.idQuestionCount === 359 && hle.split.oodQuestionCount === 369,
  'HLE protocol drift');
assert(JSON.stringify(hle.targets) === JSON.stringify([
  { split: 'test', performanceMetric: 'accuracyPercent', mean: 26.0, reportedStd: 2.3, totalCostUsd: 35.0 },
  { split: 'ood', performanceMetric: 'accuracyPercent', mean: 38.6, reportedStd: 3.0, totalCostUsd: 31.2 }
]), 'HLE targets drift');
assert(spec.acceptance.performanceMeanAbsoluteTolerance === 'reportedStd',
  'performance tolerance must be preregistered');
assert(spec.acceptance.totalCostRelativeToleranceBasisPoints === 500,
  'cost tolerance must be preregistered at five percent');
assert(spec.acceptance.environmentDriftResult === 'nonComparable', 'environment drift must be non-comparable');
assert(spec.acceptance.missingEvidenceResult === 'failClosed', 'missing evidence must fail closed');
assert(spec.execution.dependenciesInstalled === false && spec.execution.credentialsRead === false &&
  spec.execution.providerCallsExecuted === false && spec.execution.benchmarkRunsExecuted === 0 &&
  spec.execution.costIncurredUsd === 0, 'T48 must remain a zero-execution preflight');

const report = {
  reportSchemaVersion: '1',
  task: 'T48',
  milestone: 'M12-A',
  generatedAt: lock.capturedAt,
  status: 'source-frozen-reproduction-not-run',
  inputDigests: {
    upstreamLock: digest(lockPath),
    reproductionSpec: digest(specPath)
  },
  upstream: {
    commit: lock.repository.commit,
    tree: lock.repository.tree,
    license: lock.license.spdx,
    sourceArchiveSha256: lock.repository.archive.sha256,
    paper: `${lock.paper.arxivId}${lock.paper.version}`,
    paperPdfSha256: lock.paper.pdfSha256
  },
  preregistration: {
    runCount: spec.method.runCount,
    modelCount: spec.modelPool.length,
    benchmarkCount: spec.benchmarks.length,
    targetCount: spec.benchmarks.flatMap((benchmark) => benchmark.targets).length,
    performanceTolerance: spec.acceptance.performanceMeanAbsoluteTolerance,
    costToleranceBasisPoints: spec.acceptance.totalCostRelativeToleranceBasisPoints
  },
  execution: spec.execution,
  nextGate: 'isolated environment installation and upstream smoke tests require separate authorization'
};

const output = `${JSON.stringify(report, null, 2)}\n`;
if (process.argv.includes('--check')) {
  assert(readFileSync(reportPath, 'utf8') === output, 'preflight report is stale');
  process.stdout.write(`${digest(reportPath)}\n`);
} else if (process.argv.includes('--write')) {
  writeFileSync(reportPath, output, 'utf8');
  process.stdout.write(`${digest(reportPath)}\n`);
} else {
  process.stdout.write(output);
}
