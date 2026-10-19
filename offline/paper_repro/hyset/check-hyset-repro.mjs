import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const root = process.env.HYSET_REPRO_ROOT === undefined ? scriptRoot : resolve(process.env.HYSET_REPRO_ROOT);
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

function valueDigest(value) {
  return createHash('sha256').update(JSON.stringify(value), 'utf8').digest('hex');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function exact(actual, expected, message) {
  assert(JSON.stringify(actual) === JSON.stringify(expected), message);
}

function exactKeys(value, expected, message) {
  exact(Object.keys(value), expected, message);
}

function isSha256(value) {
  return typeof value === 'string' && /^[0-9a-f]{64}$/.test(value);
}

const lock = json(lockPath);
const spec = json(specPath);

exactKeys(lock,
  ['schemaVersion', 'capturedAt', 'repository', 'license', 'externalSources', 'pinnedFiles', 'paper', 'sourceAudit'],
  'upstream lock fields drift');
exactKeys(spec,
  ['schemaVersion', 'specId', 'upstreamCommit', 'paperArxivId', 'claimState', 'architectureBoundary',
    'sourceMethod', 'paperProtocol', 'evaluation', 'reproductionBlockers', 'acceptance', 'execution'],
  'reproduction spec fields drift');
assert(lock.schemaVersion === '1' && spec.schemaVersion === '1', 'schema version must be 1');
assert(spec.specId === 'harmony-agent-hyset-source-preflight-v1', 'spec identity drift');

exactKeys(lock.repository,
  ['url', 'defaultBranch', 'commit', 'tree', 'commitDate', 'commitSubject', 'releaseTagsObserved', 'archive'],
  'repository fields drift');
assert(lock.repository.url === 'https://github.com/stormwther18/HYSET' &&
  lock.repository.defaultBranch === 'main', 'official repository identity drift');
assert(lock.repository.commit === 'd0885766a9b60f778c35e161ad91e3a0d8af6dd7' &&
  lock.repository.tree === 'e3b0bf2a3428640ece71ec5994571544100ec5a4', 'upstream source identity drift');
assert(spec.upstreamCommit === lock.repository.commit, 'spec and lock commit must match');
assert(lock.repository.archive.url.endsWith(lock.repository.commit) &&
  lock.repository.archive.sizeBytes === 14318571 &&
  lock.repository.archive.sha256 === '745be2af629e11e641db1b6fd490942031c2167eed50f1424e293ab7724b2a80',
  'source archive identity drift');
assert(lock.repository.releaseTagsObserved === 0, 'unexpected upstream release tag count');

assert(lock.license.spdx === 'MIT' && lock.license.path === 'LICENSE' && lock.license.sizeBytes === 1106 &&
  lock.license.sha256 === '3240c54331c9c0568cea30d43cbc140c38422e1b8bc464b6d38d6389b4399c41',
  'root license identity drift');
assert(valueDigest(lock.externalSources) === '787df63e4707ec3d55e6d02958f7c67672124662e7635a7893a7ff8c2d6c1e19',
  'external source identity drift');
assert(lock.externalSources.length === 2 && lock.externalSources.every((source) =>
  source.actualGitMode === '040000' && source.gitlinkCommit === null && source.licenseSpdx === 'Apache-2.0' &&
  isSha256(source.licenseSha256)), 'external source boundary drift');

assert(lock.pinnedFiles.length === 26, 'all twenty-six critical source and data files must be pinned');
assert(new Set(lock.pinnedFiles.map((file) => file.path)).size === 26, 'pinned file paths must be unique');
assert(lock.pinnedFiles.every((file) => file.sizeBytes > 0 && isSha256(file.sha256)),
  'pinned file identity must include size and SHA-256');
assert(valueDigest(lock.pinnedFiles) === '19af1090367963b17b2387410584ba36ebc1d0a38b74a95860161013b3be91de',
  'pinned source file identities drift');

exactKeys(lock.paper,
  ['title', 'arxivId', 'version', 'submittedAt', 'revisedAt', 'pdfUrl', 'pdfSizeBytes', 'pdfSha256'],
  'paper fields drift');
assert(spec.paperArxivId === lock.paper.arxivId, 'spec and paper arXiv id must match');
assert(lock.paper.arxivId === '2607.25718' && lock.paper.version === 'v2' &&
  lock.paper.submittedAt === '2026-07-28T13:45:08Z' && lock.paper.revisedAt === '2026-07-29T16:33:21Z' &&
  lock.paper.pdfSizeBytes === 1385792 &&
  lock.paper.pdfSha256 === 'f0b25a3a79294ea5503d43a7026f167a1346b3888d9a2a294c6718393c3852cd',
  'paper identity drift');

const audit = lock.sourceAudit;
exact(audit.dependencies,
  ['torch==2.2.0', 'transformers==4.45.2', 'numpy==1.26.4', 'safetensors==0.4.5',
    'sentencepiece==0.2.0', 'openai==1.30.5'], 'dependency declaration drift');
assert(audit.dependencyManifestPresent === true && audit.pythonDeclaration === '>=3.10',
  'environment declaration drift');
assert(audit.checkpoint.presentInRepository === false && audit.checkpoint.repositoryId === null &&
  audit.checkpoint.revision === null && audit.checkpoint.sha256 === null && audit.checkpoint.status === 'unresolved',
  'checkpoint identity must remain unresolved');
assert(audit.encoders.length === 2 && audit.encoders.every((encoder) =>
  encoder.authoritativelyBoundByUpstream === false && encoder.revision === null && encoder.sha256 === null &&
  encoder.status === 'unresolved'), 'encoder identities must remain unresolved');
assert(audit.encoders[1].observedCandidateRepository ===
  'reasonwang/ToolGen-Qwen2.5-1.5B-Tool-Retriever', 'Qwen encoder candidate observation drift');
assert(audit.data.corpusPresent === true && audit.data.corpusToolCount === 13860 &&
  audit.data.testSplitCount === 6 && audit.data.queriesPerSplit === 100 &&
  audit.data.rawToolBenchInstructionsPresent === false && audit.data.ultraToolPresent === false &&
  audit.data.rewardCachePresent === false &&
  audit.data.frozenAgentTrajectoriesPresent === false, 'source data audit drift');
assert(audit.externalDeclarationMatchesGitStorage === false && audit.externalGitlinkCount === 0 &&
  audit.externalTrackedTreeCount === 2, 'external storage mismatch must remain explicit');
assert(audit.credentialShapedPath.path === 'external/stabletoolbench/openai_key.json' &&
  audit.credentialShapedPath.contentInspected === false &&
  audit.credentialShapedPath.approvedCredentialSource === false,
  'credential-shaped upstream path boundary drift');

exactKeys(spec.claimState,
  ['sourceAudit', 'environmentResolved', 'checkpointResolved', 'encoderResolved', 'upstreamTests',
    'paperReproduction', 'harmonyAgentAdaptation'], 'claim state fields drift');
assert(spec.claimState.sourceAudit === 'complete', 'source audit must be complete');
for (const field of ['environmentResolved', 'checkpointResolved', 'encoderResolved', 'upstreamTests',
  'paperReproduction', 'harmonyAgentAdaptation']) {
  assert(spec.claimState[field] === 'notRun', `${field} must remain notRun at T56`);
}

const boundary = spec.architectureBoundary;
exactKeys(boundary,
  ['targetPolicyPort', 'integrationOwner', 'onlyTaskControlEntry', 'learnedScorerReplacementOnly',
    'hardEligibilityRemainsAuthoritative', 'policyGatewayRemainsAuthoritative',
    'selectedToolsMustBeEligibleSubset', 'riskPermissionSideEffectAndDataBoundaryNotScoreable',
    'newToolFallback', 'unknownSchemaFallback', 'unknownRelationFallback', 'emptyArtifactFallback',
    'timeoutFallback', 'exceptionFallback', 'sourceVendoredIntoRuntime', 'pythonRuntimeBundled',
    'checkpointBundled', 'encoderBundled', 'providerCredentialAccessAdded', 'secondTaskControlEntryAdded'],
  'architecture boundary fields drift');
assert(boundary.targetPolicyPort === 'LearnedRouterPort' && boundary.integrationOwner === 'DeterministicToolRouter' &&
  boundary.onlyTaskControlEntry === 'AgentRuntimeFacade' && boundary.learnedScorerReplacementOnly === true &&
  boundary.hardEligibilityRemainsAuthoritative === true && boundary.policyGatewayRemainsAuthoritative === true &&
  boundary.selectedToolsMustBeEligibleSubset === true &&
  boundary.riskPermissionSideEffectAndDataBoundaryNotScoreable === true,
  'harmony_agent tool-set architecture boundary drift');
for (const field of ['newToolFallback', 'unknownSchemaFallback', 'unknownRelationFallback',
  'emptyArtifactFallback', 'timeoutFallback', 'exceptionFallback']) {
  assert(boundary[field] === 'DETERMINISTIC_TOP_K', 'deterministic top-k fallback boundary drift');
}
for (const field of ['sourceVendoredIntoRuntime', 'pythonRuntimeBundled', 'checkpointBundled', 'encoderBundled',
  'providerCredentialAccessAdded', 'secondTaskControlEntryAdded']) {
  assert(boundary[field] === false, 'runtime package boundary drift');
}

exact(spec.sourceMethod, {
  maximumSetCardinality: 5,
  negativePoolSize: 64,
  singletonShortlistSize: 15,
  rerankingPoolSize: 20,
  selfTrainingWeight: 0.3,
  interactionRegularization: 0.01,
  learningRate: 0.0001,
  warmupRatio: 0.06,
  batchSize: 32,
  epochs: 10,
  earlyStoppingPatience: 3,
  earlyStoppingMetric: 'Recall@5',
  randomSeeds: [13, 42, 87],
  queryEncoderFrozen: true,
  negativeSamplingPercent: { uniformSizeMatched: 50, inBatch: 30, hardNearestNeighborReplacement: 20 }
}, 'source method drift');
exact(spec.paperProtocol, {
  toolBenchCallableTools: 13860,
  toolBenchInstructions: 200311,
  heldOutTestSplits: 6,
  heldOutTestQueries: 600,
  maximumSetCardinality: 5,
  singletonShortlistSize: 15,
  rerankingPoolSize: 20,
  negativePoolSize: 64,
  candidateSetsScoredPerQuery: 21699,
  executionRewardSubsetQueries: 5000,
  rewardRefreshSteps: 20000,
  maximumRollouts: 20000,
  maximumJudgeCalls: 20000,
  frozenBackbones: ['ToolBench BERT-base retriever', 'tuned ToolGen Qwen2.5-1.5B retriever'],
  frozenAgent: 'ToolLLaMA-2-7B-v2',
  agentProtocol: 'DFSDT',
  runCount: 3,
  earlyStoppingMetric: 'Recall@5'
}, 'paper protocol drift');
assert(spec.evaluation.toolCount === 13860 && spec.evaluation.queryCount === 600,
  'evaluation corpus size drift');
exact(spec.evaluation.splits,
  ['I1-Inst', 'I1-Tool', 'I1-Cate', 'I2-Inst', 'I2-Cate', 'I3-Inst'], 'evaluation splits drift');
assert(spec.evaluation.paperTargets.length === 2, 'paper target count drift');
exact(spec.evaluation.paperTargets[0], {
  configuration: 'HYSET (BERT)', supervision: 'A+R', recallAt5Mean: 84.75, recallAt5Std: 0.09,
  ndcgAt5Mean: 88.99, ndcgAt5Std: 0.16, compAt5Mean: 77.55, compAt5Std: 0.12,
  gpt4PassRateMean: 69.69, gpt4PassRateStd: 0.61, humanPassRateMean: 66.17, humanPassRateStd: 1.93
}, 'BERT paper targets drift');
exact(spec.evaluation.paperTargets[1], {
  configuration: 'HYSET (Qwen2.5)', supervision: 'A+R', recallAt5Mean: 88.61, recallAt5Std: 0.12,
  ndcgAt5Mean: 91.07, ndcgAt5Std: 0.18, compAt5Mean: 78.13, compAt5Std: 0.16,
  gpt4PassRateMean: 71.11, gpt4PassRateStd: 0.58, humanPassRateMean: 69.92, humanPassRateStd: 1.87
}, 'Qwen paper targets drift');

assert(spec.reproductionBlockers.length === 10, 'all ten reproduction blockers must remain explicit');
assert(spec.acceptance.strictReproductionReady === false &&
  spec.acceptance.sameUpstreamCommitRequired === true && spec.acceptance.samePaperVersionRequired === true &&
  spec.acceptance.samePinnedCorpusAndSplitDigestsRequired === true &&
  spec.acceptance.exactCheckpointRepositoryRevisionAndDigestRequired === true &&
  spec.acceptance.exactEncoderRepositoryRevisionAndDigestRequired === true &&
  spec.acceptance.rawInstructionDigestsRequired === true &&
  spec.acceptance.rewardCacheAndTrajectoryDigestsRequired === true &&
  spec.acceptance.judgeProviderAndModelRevisionRequired === true &&
  spec.acceptance.frozenAgentAndProtocolRevisionRequired === true &&
  spec.acceptance.ultraToolDatasetDigestsRequired === true &&
  spec.acceptance.externalLicenseBoundaryMustRemainExplicit === true &&
  spec.acceptance.paperReproductionAndHarmonyAdaptationReportedSeparately === true &&
  spec.acceptance.missingEvidenceResult === 'failClosed' &&
  spec.acceptance.environmentDriftResult === 'nonComparable', 'reproduction acceptance drift');

exact(spec.execution, {
  sourceVendoredIntoRepository: false,
  paperVendoredIntoRepository: false,
  dependenciesInstalled: false,
  checkpointDownloaded: false,
  encoderDownloaded: false,
  rawDatasetDownloaded: false,
  credentialsRead: false,
  providerCallsExecuted: false,
  upstreamTestsExecuted: false,
  inferenceRunsExecuted: 0,
  trainingRunsExecuted: 0,
  benchmarkRunsExecuted: 0,
  costIncurredUsd: 0
}, 'T56 must remain a zero-execution source preflight');

const report = {
  reportSchemaVersion: '1',
  task: 'T56',
  milestone: 'M14-A',
  generatedAt: lock.capturedAt,
  status: 'source-frozen-reproduction-blocked-on-artifact-and-data-identities',
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
    externalTrackedTreeCount: audit.externalTrackedTreeCount,
    externalGitlinkCount: audit.externalGitlinkCount,
    corpusToolCount: audit.data.corpusToolCount,
    testSplitCount: audit.data.testSplitCount,
    totalTestQueries: audit.data.testSplitCount * audit.data.queriesPerSplit,
    checkpointStatus: audit.checkpoint.status,
    encoderStatuses: audit.encoders.map((encoder) => encoder.status),
    reproductionBlockerCount: spec.reproductionBlockers.length
  },
  adaptationBoundary: {
    targetPolicyPort: boundary.targetPolicyPort,
    integrationOwner: boundary.integrationOwner,
    onlyTaskControlEntry: boundary.onlyTaskControlEntry,
    fallback: boundary.timeoutFallback,
    strictReproductionReady: spec.acceptance.strictReproductionReady
  },
  execution: spec.execution,
  nextGate: 'T57 may define the research-only tool-set handoff and scale harness; T58 remains blocked until checkpoint, encoder, raw data and reward identities are frozen under separate authorization'
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
