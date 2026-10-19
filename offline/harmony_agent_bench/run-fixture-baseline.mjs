import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const manifestPath = join(root, 'manifest-v1.json');
const datasetPath = join(root, 'dataset-v1.json');
const pricePath = join(root, 'price-snapshot-v1.json');
const reportPath = join(root, 'reports', 'fixture-baseline-v1.json');

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

function percentile(values, percent) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.ceil((percent * sorted.length) / 100) - 1];
}

function summarize(samples) {
  const latencies = samples.map((sample) => sample.latencyMs);
  return {
    sampleCount: samples.length,
    passedCount: samples.filter((sample) => sample.passed).length,
    failedCount: samples.filter((sample) => !sample.passed).length,
    averageQualityBasisPoints: samples.length === 0 ? 0 :
      Math.floor(samples.reduce((total, sample) => total + sample.qualityScoreBasisPoints, 0) / samples.length),
    inputTokens: samples.reduce((total, sample) => total + sample.inputTokens, 0),
    outputTokens: samples.reduce((total, sample) => total + sample.outputTokens, 0),
    monetaryCostMicros: samples.reduce((total, sample) => total + sample.monetaryCostMicros, 0),
    latencyP50Ms: percentile(latencies, 50),
    latencyP95Ms: percentile(latencies, 95),
    toolCalls: samples.reduce((total, sample) => total + sample.toolCalls, 0),
    agentActivations: samples.reduce((total, sample) => total + sample.agentActivations, 0),
    recoveryEvents: samples.reduce((total, sample) => total + sample.recoveryEvents, 0),
    routerDecisions: samples.reduce((total, sample) => total + sample.routerDecisions, 0),
    routerCorrectDecisions: samples.reduce((total, sample) => total + sample.routerCorrectDecisions, 0)
  };
}

function expectedToolCalls(kind) {
  if (kind === 'clarificationRequired' || kind === 'authorizationRequired') return 0;
  if (kind === 'multiSourceSynthesis' || kind === 'sequentialWorkflow' || kind === 'parallelWorkflow') return 2;
  return 1;
}

const expectedKinds = [
  'readOnlyRetrieval', 'multiSourceSynthesis', 'structuredExtraction', 'schemaTransformation',
  'toolSelection', 'sequentialWorkflow', 'parallelWorkflow', 'clarificationRequired',
  'authorizationRequired', 'budgetConstrained', 'recoveryReconciliation', 'longTermMemoryRecall'
];

const manifest = json(manifestPath);
const dataset = json(datasetPath);
const price = json(pricePath);

assert(manifest.datasetDigest === digest(datasetPath), 'dataset digest mismatch');
assert(manifest.priceSnapshotDigest === digest(pricePath), 'price snapshot digest mismatch');
assert(manifest.priceSnapshotId === price.priceSnapshotId, 'price snapshot id mismatch');
assert(manifest.contractSchemaVersion === '1', 'contract schema must be pinned to version 1');
assert(manifest.performanceComparable === false, 'fixture report must remain non-comparable');
assert(manifest.latencyClock === 'deterministic-virtual-zero', 'fixture clock must be explicit');
assert(dataset.cases.length === 12, 'dataset must contain exactly twelve cases');
assert(new Set(dataset.cases.map((item) => item.caseId)).size === 12, 'case ids must be unique');
assert(new Set(dataset.cases.map((item) => item.kind)).size === 12, 'task kinds must be unique');
for (const kind of expectedKinds) assert(dataset.cases.some((item) => item.kind === kind), `missing task kind ${kind}`);
for (const item of dataset.cases) {
  assert(typeof item.promptTemplate === 'string' && item.promptTemplate.trim().length > 0,
    `missing prompt template for ${item.caseId}`);
  assert(Array.isArray(item.requiredCapabilities) && item.requiredCapabilities.length > 0,
    `missing capabilities for ${item.caseId}`);
  assert(Array.isArray(item.expectedEvidence) && item.expectedEvidence.length > 0,
    `missing evidence contract for ${item.caseId}`);
}
assert(manifest.arms.length === 2, 'fixture baseline requires exactly two arms');
assert(new Set(manifest.arms.map((arm) => arm.armId)).size === 2, 'arm ids must be unique');
assert(new Set(manifest.arms.map((arm) => arm.permissionPolicyVersion)).size === 1,
  'arms must share one permission policy');
assert(new Set(manifest.arms.map((arm) => arm.contextPolicyVersion)).size === 1,
  'arms must share one context policy');

const samples = [];
for (const item of dataset.cases) {
  for (const arm of manifest.arms) {
    samples.push({
      caseId: item.caseId,
      runId: 'fixture-run-1',
      armId: arm.armId,
      passed: true,
      qualityScoreBasisPoints: 10000,
      inputTokens: 0,
      outputTokens: 0,
      monetaryCostMicros: 0,
      latencyMs: 0,
      toolCalls: expectedToolCalls(item.kind),
      agentActivations: arm.kind === 'multiAgent' ? 2 : 1,
      recoveryEvents: item.includesFailureRecovery ? 1 : 0,
      routerDecisions: item.kind === 'toolSelection' ? 1 : 0,
      routerCorrectDecisions: item.kind === 'toolSelection' ? 1 : 0
    });
  }
}

const toolScale = [32, 128, 512].map((registrySize) => ({
  caseId: `tool-scale-${registrySize}`,
  registrySize,
  targetToolId: 'fixture.weather.current',
  selectedToolId: 'fixture.weather.current',
  passed: true,
  candidateEvaluations: registrySize,
  wrongToolSelections: 0,
  latencyMs: 0,
  latencyClock: manifest.latencyClock
}));

const report = {
  reportSchemaVersion: '1',
  generatorVersion: 'fixture-baseline-1',
  generatedAt: manifest.frozenAt,
  measurementMode: 'deterministic-fixture-contract',
  performanceComparable: false,
  limitations: [
    'No real model or provider was invoked.',
    'Latency uses a deterministic virtual zero clock and is not a performance measurement.',
    'Tool-scale results prove fixture correctness at 32/128/512 entries, not production latency or memory.'
  ],
  inputDigests: {
    manifest: digest(manifestPath),
    dataset: digest(datasetPath),
    priceSnapshot: digest(pricePath)
  },
  manifest,
  datasetSummary: {
    caseCount: dataset.cases.length,
    taskKinds: dataset.cases.map((item) => item.kind)
  },
  summary: summarize(samples),
  armSummaries: manifest.arms.map((arm) => ({
    armId: arm.armId,
    summary: summarize(samples.filter((sample) => sample.armId === arm.armId))
  })),
  samples,
  toolScale
};

const output = `${JSON.stringify(report, null, 2)}\n`;
if (process.argv.includes('--check')) {
  assert(readFileSync(reportPath, 'utf8') === output, 'fixture baseline report is stale');
  process.stdout.write(`${digest(reportPath)}\n`);
} else if (process.argv.includes('--write')) {
  writeFileSync(reportPath, output, 'utf8');
  process.stdout.write(`${digest(reportPath)}\n`);
} else {
  process.stdout.write(output);
}
