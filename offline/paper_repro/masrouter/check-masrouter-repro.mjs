import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const root = process.env.MASROUTER_REPRO_ROOT === undefined ? scriptRoot : resolve(process.env.MASROUTER_REPRO_ROOT);
const lockPath = join(root, 'upstream-lock.json');
const specPath = join(root, 'reproduction-spec.json');
const reportPath = join(root, 'reports', 'preflight-v1.json');

function canonicalText(path) {
  return readFileSync(path, 'utf8').replace(/\r\n/g, '\n');
}

function json(path) {
  return JSON.parse(canonicalText(path));
}

function digest(path) {
  return `sha256:${createHash('sha256').update(canonicalText(path), 'utf8').digest('hex')}`;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function isSha256(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

function exact(actual, expected, message) {
  assert(JSON.stringify(actual) === JSON.stringify(expected), message);
}

const lock = json(lockPath);
const spec = json(specPath);

assert(lock.schemaVersion === '1' && spec.schemaVersion === '1', 'schema version must be 1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.commit), 'upstream commit must be a full Git SHA-1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.tree), 'upstream tree must be a full Git SHA-1');
assert(spec.upstreamCommit === lock.repository.commit, 'spec and lock commit must match');
assert(spec.paperArxivId === lock.paper.arxivId, 'spec and paper arXiv id must match');
assert(lock.repository.archive.url.includes(lock.repository.commit), 'archive URL must pin the commit');
assert(lock.repository.archive.sizeBytes === 2849986 && isSha256(lock.repository.archive.sha256),
  'source archive identity drift');
assert(lock.license.spdx === 'Apache-2.0' && lock.license.path === 'LICENSE' &&
  lock.license.sizeBytes === 11558 && isSha256(lock.license.sha256), 'license identity drift');
assert(lock.paper.version === 'v1' && lock.paper.submittedAt === '2025-02-16T14:00:59Z' &&
  lock.paper.pdfSizeBytes === 11904536 && isSha256(lock.paper.pdfSha256), 'paper identity drift');
assert(lock.repository.releaseTagsObserved === 0, 'unexpected upstream release tag count');
assert(lock.pinnedFiles.length === 15, 'all fifteen critical source files must be pinned');
assert(new Set(lock.pinnedFiles.map((file) => file.path)).size === 15, 'pinned file paths must be unique');
for (const file of lock.pinnedFiles) {
  assert(file.sizeBytes > 0 && isSha256(file.sha256), `invalid pinned file ${file.path}`);
}
assert(lock.sourceAudit.dependencyManifestPresent === false && lock.sourceAudit.checkpointPresent === false,
  'missing upstream environment artifacts must remain explicit');
assert(lock.sourceAudit.documentedEntrypointCaseMatchesRepository === false,
  'README entrypoint case mismatch must remain explicit');
assert(lock.sourceAudit.roleProfileFileCountExcludingFinalNode === 26,
  'source role profile count drift');
assert(lock.sourceAudit.priceMetadataConsistent === false &&
  lock.sourceAudit.priceMismatch.llmProfileInputUsdPerMillion === 1.0 &&
  lock.sourceAudit.priceMismatch.llmProfileOutputUsdPerMillion === 5.0 &&
  lock.sourceAudit.priceMismatch.priceModuleInputUsdPerMillion === 0.8 &&
  lock.sourceAudit.priceMismatch.priceModuleOutputUsdPerMillion === 4.0,
  'source price mismatch must remain explicit');

assert(spec.claimState.sourceAudit === 'complete', 'source audit must be complete');
for (const field of ['environmentResolved', 'dependenciesInstalled', 'upstreamTests', 'paperReproduction', 'harmonyAgentAdaptation']) {
  assert(spec.claimState[field] === 'notRun', `${field} must remain notRun at T50`);
}
const boundary = spec.architectureBoundary;
assert(boundary.targetPolicyPort === 'CollaborationPlanSelectorPort' &&
  boundary.onlyTaskControlEntry === 'AgentRuntimeFacade' && boundary.policyReplacementOnly === true &&
  boundary.roleRegistryOnly === true && boundary.singleAgentAlwaysValid === true &&
  boundary.reserveFullActivationBudgetBeforeMulti === true &&
  boundary.maximumCollaborationReevaluations === 1 &&
  boundary.boundedByExistingAgentActivationBudget === true,
  'harmony_agent collaboration boundary drift');
assert(boundary.lowConfidenceFallback === 'SINGLE' && boundary.timeoutFallback === 'SINGLE' &&
  boundary.checkpointIncompatibleFallback === 'SINGLE', 'single-agent fallback boundary drift');
assert(boundary.sourceVendoredIntoRuntime === false && boundary.trainingRuntimeBundled === false &&
  boundary.modelArtifactBundled === false && boundary.providerCredentialAccessAdded === false &&
  boundary.secondTaskControlEntryAdded === false, 'runtime/package boundary drift');

exact(spec.sourceMethod, {
  sentenceEncoder: 'sentence-transformers/all-MiniLM-L6-v2', embeddingDimensions: 384,
  hiddenDimensions: 64, maximumAgents: 6, taskAndRoleTemperature: 0.5,
  collaborationTemperature: 0.8, llmRouterTemperature: 1.0, randomSeed: 1234,
  optimizer: 'Adam', learningRate: 0.01, batchSize: 16, roundsPerQuery: 1,
  vaeLossWeight: 0.001, agentCountAdjustmentEnabled: false
}, 'source method drift');
exact(spec.paperProtocol.coreModelPool,
  ['gpt-4o-mini-0718', 'claude-3.5-haiku', 'gemini-1.5-flash', 'llama-3.1-70b'],
  'paper core model pool drift');
assert(spec.paperProtocol.inductiveValidationModel === 'deepseek-v3' &&
  spec.paperProtocol.temperature === 1.0 && spec.paperProtocol.learningRate === 0.01 &&
  spec.paperProtocol.maximumAgents === 6 && spec.paperProtocol.roleProfileCount === 26,
  'paper protocol drift');
exact(spec.paperProtocol.costPenaltyLambda, [5, 15, 25], 'paper cost penalty drift');
exact(spec.paperProtocol.optimizationIterations, [5, 10], 'paper iteration schedule drift');
exact(spec.sourceProfiles.models,
  ['gpt-4o-mini', 'claude-3-5-haiku-20241022', 'gemini-1.5-flash-latest',
    'llama-3.1-70b-instruct', 'deepseek-chat'], 'source model profile drift');
exact(spec.sourceProfiles.collaborationModes,
  ['IO', 'CoT', 'Chain', 'FullConnected', 'Debate', 'Reflection'], 'source collaboration profile drift');

const expectedBenchmarks = [
  ['mmlu', 10, 500.0, 84.25],
  ['gsm8k', 5, 200.0, 95.45],
  ['math', 5, 100.0, 75.42],
  ['humaneval', 10, 200.0, 90.62],
  ['mbpp', 10, 400.0, 84.0]
];
assert(spec.benchmarks.length === expectedBenchmarks.length, 'benchmark count drift');
for (let index = 0; index < expectedBenchmarks.length; index++) {
  const actual = spec.benchmarks[index];
  const expected = expectedBenchmarks[index];
  assert(actual.id === expected[0] && actual.epochs === expected[1] && actual.costRate === expected[2] &&
    actual.paperMasRouterScorePercent === expected[3] && typeof actual.datasetSplit === 'string' &&
    actual.datasetSplit.length > 0, `benchmark protocol drift at index ${index}`);
}
assert(spec.acceptance.resolvedDependencyLockRequiredBeforeExecution === true &&
  spec.acceptance.frozenDatasetDigestsRequiredBeforeBenchmark === true &&
  spec.acceptance.providerModelRevisionRequiredBeforeBenchmark === true &&
  spec.acceptance.priceSnapshotAndSourceMismatchResolutionRequiredForCostClaims === true &&
  spec.acceptance.paperAndSourceProtocolDifferencesMustRemainExplicit === true &&
  spec.acceptance.strictReproductionReady === false &&
  spec.acceptance.missingEvidenceResult === 'failClosed' &&
  spec.acceptance.environmentDriftResult === 'nonComparable', 'reproduction acceptance drift');
assert(spec.execution.sourceCopiedIntoRepository === false &&
  spec.execution.paperCopiedIntoRepository === false && spec.execution.dependenciesInstalled === false &&
  spec.execution.credentialsRead === false && spec.execution.providerCallsExecuted === false &&
  spec.execution.benchmarkRunsExecuted === 0 && spec.execution.trainingRunsExecuted === 0 &&
  spec.execution.costIncurredUsd === 0, 'T50 must remain a zero-execution preflight');

const report = {
  reportSchemaVersion: '1',
  task: 'T50',
  milestone: 'M13-A',
  generatedAt: lock.capturedAt,
  status: 'source-frozen-reproduction-blocked-on-environment-definition',
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
  sourceAudit: {
    pinnedFileCount: lock.pinnedFiles.length,
    roleProfileCount: lock.sourceAudit.roleProfileFileCountExcludingFinalNode,
    dependencyManifestPresent: lock.sourceAudit.dependencyManifestPresent,
    checkpointPresent: lock.sourceAudit.checkpointPresent,
    documentedEntrypointCaseMatchesRepository: lock.sourceAudit.documentedEntrypointCaseMatchesRepository,
    priceMetadataConsistent: lock.sourceAudit.priceMetadataConsistent
  },
  adaptationBoundary: {
    targetPolicyPort: boundary.targetPolicyPort,
    onlyTaskControlEntry: boundary.onlyTaskControlEntry,
    singleAgentAlwaysValid: boundary.singleAgentAlwaysValid,
    maximumAgents: spec.sourceMethod.maximumAgents,
    maximumCollaborationReevaluations: boundary.maximumCollaborationReevaluations
  },
  execution: spec.execution,
  nextGate: 'freeze an isolated dependency lock, dataset digests, provider revisions and price snapshot before requesting execution authorization'
};

const output = `${JSON.stringify(report, null, 2)}\n`;
if (process.argv.includes('--check')) {
  assert(canonicalText(reportPath) === output, 'preflight report is stale');
  process.stdout.write(`${digest(reportPath)}\n`);
} else if (process.argv.includes('--write')) {
  writeFileSync(reportPath, output, 'utf8');
  process.stdout.write(`${digest(reportPath)}\n`);
} else {
  process.stdout.write(output);
}
