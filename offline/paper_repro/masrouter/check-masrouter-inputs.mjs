import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptRoot = dirname(fileURLToPath(import.meta.url));
const root = process.env.MASROUTER_INPUT_ROOT === undefined ? scriptRoot : resolve(process.env.MASROUTER_INPUT_ROOT);

const paths = {
  upstreamLock: join(root, 'upstream-lock.json'),
  reproductionSpec: join(root, 'reproduction-spec.json'),
  environmentSchema: join(root, 'schemas', 'environment-lock.schema.json'),
  datasetSchema: join(root, 'schemas', 'dataset-lock.schema.json'),
  modelSchema: join(root, 'schemas', 'provider-model-lock.schema.json'),
  priceSchema: join(root, 'schemas', 'price-snapshot.schema.json'),
  environment: join(root, 'environment-candidates.json'),
  datasets: join(root, 'dataset-lock.json'),
  models: join(root, 'model-pools.json'),
  prices: join(root, 'price-snapshot-candidate.json'),
  issues: join(root, 'unresolved-issues.json'),
  meta: join(root, 'input-contract.json'),
  report: join(root, 'reports', 'input-contract-v1.json')
};

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

function isPositiveInteger(value) {
  return Number.isSafeInteger(value) && value > 0;
}

function hasEvidence(value, label) {
  assert(Array.isArray(value) && value.length > 0, `${label} requires source evidence`);
  for (const item of value) {
    assert(typeof item === 'string' && /^[A-Za-z0-9_./-]+:\d+(?:-\d+)?$/.test(item),
      `${label} has invalid source evidence: ${item}`);
  }
}

function exact(actual, expected, message) {
  assert(JSON.stringify(actual) === JSON.stringify(expected), message);
}

const ANNOTATION_KEYWORDS = new Set(['$schema', '$id', 'title', 'description', '$defs']);
const VALIDATION_KEYWORDS = new Set([
  'type', 'additionalProperties', 'required', 'properties', 'items', 'minItems', 'maxItems',
  'uniqueItems', 'minLength', 'minimum', 'maximum', 'pattern', 'const', 'enum', '$ref'
]);

function checkSchemaNode(schema, path, rootSchema) {
  assert(schema !== null && typeof schema === 'object' && !Array.isArray(schema), `invalid schema at ${path}`);
  for (const key of Object.keys(schema)) {
    assert(ANNOTATION_KEYWORDS.has(key) || VALIDATION_KEYWORDS.has(key),
      `unsupported schema keyword ${key} at ${path}`);
  }
  if (schema.$defs !== undefined) {
    assert(schema.$defs !== null && typeof schema.$defs === 'object' && !Array.isArray(schema.$defs),
      `invalid $defs at ${path}`);
    for (const name of Object.keys(schema.$defs)) {
      checkSchemaNode(schema.$defs[name], `${path}.$defs.${name}`, rootSchema);
    }
  }
  if (schema.properties !== undefined) {
    assert(schema.properties !== null && typeof schema.properties === 'object' && !Array.isArray(schema.properties),
      `invalid properties at ${path}`);
    for (const name of Object.keys(schema.properties)) {
      checkSchemaNode(schema.properties[name], `${path}.properties.${name}`, rootSchema);
    }
  }
  if (schema.items !== undefined) checkSchemaNode(schema.items, `${path}.items`, rootSchema);
  if (schema.additionalProperties !== undefined && typeof schema.additionalProperties === 'object') {
    checkSchemaNode(schema.additionalProperties, `${path}.additionalProperties`, rootSchema);
  }
  if (schema.$ref !== undefined) {
    assert(typeof schema.$ref === 'string' && schema.$ref.startsWith('#/$defs/'),
      `unsupported $ref at ${path}`);
  }
}

function resolveRef(ref, rootSchema) {
  assert(ref.startsWith('#/$defs/'), `unsupported $ref: ${ref}`);
  const name = ref.slice('#/$defs/'.length);
  const definition = rootSchema.$defs === undefined ? undefined : rootSchema.$defs[name];
  assert(definition !== undefined, `unresolved $ref: ${ref}`);
  return definition;
}

function jsonTypeName(value) {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  if (typeof value === 'number') return Number.isInteger(value) ? 'integer' : 'number';
  return typeof value;
}

function matchesType(value, type) {
  if (type === 'null') return value === null;
  if (type === 'object') return value !== null && typeof value === 'object' && !Array.isArray(value);
  if (type === 'array') return Array.isArray(value);
  if (type === 'integer') return typeof value === 'number' && Number.isInteger(value);
  if (type === 'number') return typeof value === 'number' && Number.isFinite(value);
  if (type === 'boolean') return typeof value === 'boolean';
  if (type === 'string') return typeof value === 'string';
  throw new Error(`unsupported schema type: ${type}`);
}

function expectedTypeName(type) {
  return Array.isArray(type) ? type.join(' or ') : type;
}

function validateValue(value, schema, rootSchema, path) {
  if (schema.$ref !== undefined) {
    validateValue(value, resolveRef(schema.$ref, rootSchema), rootSchema, path);
    return;
  }
  if (schema.type !== undefined) {
    const types = Array.isArray(schema.type) ? schema.type : [schema.type];
    assert(types.some((type) => matchesType(value, type)),
      `schema validation failed at ${path}: expected ${expectedTypeName(schema.type)}, got ${jsonTypeName(value)}`);
  }
  if (schema.const !== undefined) {
    assert(JSON.stringify(value) === JSON.stringify(schema.const),
      `schema validation failed at ${path}: const mismatch`);
  }
  if (schema.enum !== undefined) {
    assert(schema.enum.some((entry) => JSON.stringify(entry) === JSON.stringify(value)),
      `schema validation failed at ${path}: value is not in enum`);
  }
  if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
    if (schema.required !== undefined) {
      for (const name of schema.required) {
        assert(Object.prototype.hasOwnProperty.call(value, name),
          `schema validation failed at ${path}: missing required property "${name}"`);
      }
    }
    if (schema.properties !== undefined) {
      for (const name of Object.keys(schema.properties)) {
        if (Object.prototype.hasOwnProperty.call(value, name)) {
          validateValue(value[name], schema.properties[name], rootSchema,
            path === '$' ? `$.${name}` : `${path}.${name}`);
        }
      }
    }
    if (schema.additionalProperties === false) {
      for (const name of Object.keys(value)) {
        assert(schema.properties !== undefined &&
          Object.prototype.hasOwnProperty.call(schema.properties, name),
          `schema validation failed at ${path}.${name}: additional property is not allowed`);
      }
    } else if (schema.additionalProperties !== undefined && typeof schema.additionalProperties === 'object') {
      for (const name of Object.keys(value)) {
        if (schema.properties === undefined ||
          !Object.prototype.hasOwnProperty.call(schema.properties, name)) {
          validateValue(value[name], schema.additionalProperties, rootSchema, `${path}.${name}`);
        }
      }
    }
  }
  if (Array.isArray(value)) {
    if (schema.minItems !== undefined) {
      assert(value.length >= schema.minItems, `schema validation failed at ${path}: fewer than ${schema.minItems} items`);
    }
    if (schema.maxItems !== undefined) {
      assert(value.length <= schema.maxItems, `schema validation failed at ${path}: more than ${schema.maxItems} items`);
    }
    if (schema.uniqueItems === true) {
      const seen = new Set();
      for (const entry of value) {
        const key = JSON.stringify(entry);
        assert(!seen.has(key), `schema validation failed at ${path}: duplicate item`);
        seen.add(key);
      }
    }
    if (schema.items !== undefined) {
      for (let index = 0; index < value.length; index++) {
        validateValue(value[index], schema.items, rootSchema, `${path}[${index}]`);
      }
    }
  }
  if (typeof value === 'string') {
    if (schema.minLength !== undefined) {
      assert(value.length >= schema.minLength, `schema validation failed at ${path}: shorter than ${schema.minLength}`);
    }
    if (schema.pattern !== undefined) {
      assert(new RegExp(schema.pattern).test(value), `schema validation failed at ${path}: pattern mismatch`);
    }
  }
  if (typeof value === 'number') {
    if (schema.minimum !== undefined) {
      assert(value >= schema.minimum, `schema validation failed at ${path}: below minimum`);
    }
    if (schema.maximum !== undefined) {
      assert(value <= schema.maximum, `schema validation failed at ${path}: above maximum`);
    }
  }
}

function loadSchema(path, name, expectedId) {
  const schema = json(path);
  assert(schema.$schema === 'https://json-schema.org/draft/2020-12/schema', `${name} schema draft drift`);
  assert(schema.$id === expectedId, `${name} schema id drift`);
  assert(schema.type === 'object', `${name} schema must describe an object`);
  assert(Array.isArray(schema.required) && schema.required.length > 0, `${name} schema must declare required fields`);
  checkSchemaNode(schema, '$', schema);
  return schema;
}

const lock = json(paths.upstreamLock);
const spec = json(paths.reproductionSpec);
const environment = json(paths.environment);
const datasets = json(paths.datasets);
const models = json(paths.models);
const prices = json(paths.prices);
const issues = json(paths.issues);
const meta = json(paths.meta);

const environmentSchema = loadSchema(paths.environmentSchema, 'environment',
  'https://harmony-agent.local/schemas/masrouter-environment-lock-v1.json');
const datasetSchema = loadSchema(paths.datasetSchema, 'dataset',
  'https://harmony-agent.local/schemas/masrouter-dataset-lock-v1.json');
const modelSchema = loadSchema(paths.modelSchema, 'provider-model',
  'https://harmony-agent.local/schemas/masrouter-provider-model-lock-v1.json');
const priceSchema = loadSchema(paths.priceSchema, 'price',
  'https://harmony-agent.local/schemas/masrouter-price-snapshot-v1.json');

validateValue(environment, environmentSchema, environmentSchema, '$');
validateValue(datasets, datasetSchema, datasetSchema, '$');
validateValue(models, modelSchema, modelSchema, '$');
validateValue(prices, priceSchema, priceSchema, '$');

assert(lock.schemaVersion === '1' && spec.schemaVersion === '1', 'T50 inputs must use schema version 1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.commit), 'upstream commit must be a full Git SHA-1');
assert(/^[0-9a-f]{40}$/.test(lock.repository.tree), 'upstream tree must be a full Git SHA-1');
assert(spec.upstreamCommit === lock.repository.commit, 'T51 and T50 commit identities must match');
assert(meta.paperArxivId === lock.paper.arxivId, 'T51 and T50 paper identities must match');
for (const document of [environment, datasets, models, prices, issues, meta]) {
  assert(document.schemaVersion === '1', 'T51 documents must use schema version 1');
  assert(document.upstreamCommit === lock.repository.commit, 'T51 document commit drift');
}
assert(meta.task === 'T51' && meta.milestone === 'M13-B', 'input contract must identify T51/M13-B');
assert(meta.contractRevision === '2', 'input contract revision must be 2 after strict schema validation');

assert(environment.contractId === 'harmony-agent-masrouter-environment-candidates-v1',
  'environment candidate identity drift');
assert(['candidate-unresolved', 'partially-resolved', 'locked'].includes(environment.lockStatus),
  'environment lock status drift');
assert(environment.python.implementation === 'CPython', 'Python implementation drift');
assert(environment.python.minimumVersion === '3.10', 'Python syntax-derived minimum version drift');
assert(environment.python.version === null && environment.python.status === 'unresolved',
  'Python version must remain unresolved at T51');
assert(environment.torch.name === 'torch' && environment.torch.version === null &&
  environment.torch.build === null && environment.torch.status === 'unresolved',
  'torch version and build must remain unresolved at T51');
assert(environment.accelerator.selectedMode === null && environment.accelerator.status === 'unresolved' &&
  environment.accelerator.cudaVersion === null && environment.accelerator.cudnnVersion === null,
  'accelerator selection must remain unresolved at T51');
exact(environment.accelerator.supportedModes, ['cpu', 'cuda'], 'accelerator modes must be cpu and cuda');
assert(Array.isArray(environment.dependencies) && environment.dependencies.length >= 25,
  'environment candidate list is unexpectedly incomplete');

const dependencyNames = environment.dependencies.map((entry) => entry.name);
assert(new Set(dependencyNames).size === dependencyNames.length, 'dependency candidate names must be unique');
const requiredDependencies = [
  'torch', 'sentence-transformers', 'numpy', 'pandas', 'tiktoken', 'openai', 'groq', 'tenacity',
  'aiohttp', 'requests', 'python-dotenv', 'PyYAML', 'loguru', 'shortuuid', 'class-registry',
  'matplotlib', 'seaborn', 'beautifulsoup4', 'charset-normalizer', 'python-docx', 'openpyxl',
  'python-pptx', 'markdown', 'PyPDF2', 'pylatexenc', 'astunparse', 'langchain-community'
];
for (const name of requiredDependencies) {
  assert(dependencyNames.includes(name), `required dependency candidate missing: ${name}`);
}
let unresolvedDependencies = 0;
for (const entry of environment.dependencies) {
  assert(Array.isArray(entry.importNames) && entry.importNames.length > 0,
    `dependency ${entry.name} must declare import names`);
  assert(entry.scope === 'benchmark-entrypoint-transitive' ||
    entry.scope === 'tool-only-not-imported-by-benchmark-entrypoints',
    `dependency ${entry.name} has an unknown scope`);
  assert(entry.status === 'unresolved' || entry.status === 'resolved',
    `dependency ${entry.name} has an unknown status`);
  hasEvidence(entry.evidence, `dependency ${entry.name}`);
  if (entry.status === 'resolved') {
    assert(typeof entry.version === 'string' && entry.version.length > 0 && isSha256(entry.sha256),
      `resolved dependency ${entry.name} requires a version and sha256`);
  } else {
    assert(entry.version === null && entry.sha256 === null,
      `unresolved dependency ${entry.name} must not claim a version or digest`);
    unresolvedDependencies++;
  }
}
if (environment.lockStatus === 'locked') {
  assert(unresolvedDependencies === 0, 'unresolved dependency cannot be marked locked');
}
assert(environment.lockStatus === 'candidate-unresolved',
  'environment must remain an unresolved candidate at T51');
assert(environment.implicitRuntimeDependencies.length > 0, 'implicit runtime dependencies must remain explicit');
for (const entry of environment.implicitRuntimeDependencies) {
  assert(entry.status === 'unresolved' && entry.version === null,
    `implicit dependency ${entry.name} must remain unresolved at T51`);
  hasEvidence(entry.evidence, `implicit dependency ${entry.name}`);
}

assert(datasets.contractId === 'harmony-agent-masrouter-dataset-lock-v1', 'dataset lock identity drift');
assert(datasets.lockStatus === 'candidate-unresolved', 'dataset lock must remain unresolved at T51');
assert(datasets.executionReady === false, 'dataset executionReady must remain false at T51');
exact(datasets.datasets.map((entry) => entry.id), ['gsm8k', 'humaneval', 'math', 'mbpp', 'mmlu'],
  'dataset lock must cover all five benchmarks in the fixed order');
let unresolvedDatasets = 0;
for (const entry of datasets.datasets) {
  assert(entry.status === 'unresolved' || entry.status === 'locked', `dataset ${entry.id} has an unknown status`);
  hasEvidence(entry.evidence, `dataset ${entry.id}`);
  if (entry.status === 'locked') {
    assert(isPositiveInteger(entry.sizeBytes) && isPositiveInteger(entry.recordCount) && isSha256(entry.sha256),
      'locked dataset requires positive sizeBytes, recordCount, and sha256');
  } else {
    assert(entry.sizeBytes === null && entry.sha256 === null && entry.recordCount === null,
      `unresolved dataset ${entry.id} must not claim a digest or record count`);
    unresolvedDatasets++;
  }
}
if (datasets.lockStatus === 'locked') {
  assert(unresolvedDatasets === 0, 'unresolved dataset cannot be marked locked');
}
const datasetById = new Map(datasets.datasets.map((entry) => [entry.id, entry]));
for (const id of ['gsm8k', 'humaneval']) {
  const entry = datasetById.get(id);
  assert(entry.split.trainPercent === 20 && entry.split.testPercent === 80,
    `${id} split must remain 20 percent train and 80 percent test`);
  assert(entry.split.determinism === 'not-reproducible',
    `${id} split determinism must remain explicitly non-reproducible`);
  assert(entry.blockingIssues.includes('gsm8k-humaneval-split-unseeded'),
    `${id} must reference the unseeded split issue`);
}
const math = datasetById.get('math');
assert(math.blockingIssues.includes('math-paper-subset-not-reproducible'),
  'MATH must reference the paper subset issue');
const mathSubset = datasets.paperSubsets.find((entry) => entry.benchmark === 'math');
assert(mathSubset !== undefined && mathSubset.expectedCount === 519 && mathSubset.manifestPresent === false &&
  mathSubset.status === 'unresolved', 'MATH paper subset must remain an unresolved 519-problem reconstruction');
assert(datasetById.get('mbpp').sourceRevision === null &&
  datasetById.get('mbpp').blockingIssues.includes('mbpp-remote-dataset-unpinned'),
  'MBPP remote dataset revision must remain unresolved');
const mmlu = datasetById.get('mmlu');
assert(mmlu.blockingIssues.includes('mmlu-download-module-missing') &&
  mmlu.blockingIssues.includes('dataset-path-case'), 'MMLU blocking issues must remain explicit');

assert(models.contractId === 'harmony-agent-masrouter-model-pools-v1', 'model pool identity drift');
assert(models.lockStatus === 'candidate-unresolved', 'model pool lock must remain unresolved at T51');
assert(models.poolsSeparate === true, 'paper and source model pools must remain separate');
const paperIds = new Set([...models.paperCoreModelPool.map((entry) => entry.modelId),
  models.paperInductiveValidationModel.modelId]);
for (const entry of models.sourceModelPool) {
  assert(!paperIds.has(entry.modelId), 'paper and source model pools must remain separate');
}
exact(models.paperCoreModelPool.map((entry) => entry.modelId),
  ['gpt-4o-mini-0718', 'claude-3.5-haiku', 'gemini-1.5-flash', 'llama-3.1-70b'],
  'paper core model pool drift');
assert(models.paperInductiveValidationModel.modelId === 'deepseek-v3',
  'paper inductive validation model drift');
exact(models.sourceModelPool.map((entry) => entry.modelId),
  ['gpt-4o-mini', 'claude-3-5-haiku-20241022', 'gemini-1.5-flash-latest', 'llama-3.1-70b-instruct', 'deepseek-chat'],
  'source model pool drift');
const allModelEntries = [...models.paperCoreModelPool, models.paperInductiveValidationModel, ...models.sourceModelPool];
for (const entry of allModelEntries) {
  hasEvidence(entry.evidence, `model ${entry.modelId}`);
  assert(entry.status === 'unresolved', `model revision must remain unresolved at T51: ${entry.modelId}`);
  assert(entry.revision === null && entry.region === null,
    `model revision must remain unresolved at T51: ${entry.modelId}`);
}
if (models.lockStatus === 'locked') {
  assert(allModelEntries.every((entry) => entry.status === 'resolved'),
    'unresolved model revision cannot be marked locked');
}
const encoder = models.modelArtifacts.find((entry) => entry.kind === 'sentence-encoder');
assert(encoder !== undefined && encoder.artifactId === 'sentence-transformers/all-MiniLM-L6-v2' &&
  encoder.revision === null && encoder.sha256 === null && encoder.status === 'unresolved' &&
  encoder.packaging === 'forbidden-in-har-hap',
  'sentence encoder identity must remain unresolved and forbidden in HAR/HAP');
const checkpoint = models.modelArtifacts.find((entry) => entry.kind === 'router-checkpoint');
assert(checkpoint !== undefined && checkpoint.revision === null && checkpoint.status === 'unresolved',
  'router checkpoint must remain unresolved at T51');

assert(prices.contractId === 'harmony-agent-masrouter-price-snapshot-v1', 'price snapshot identity drift');
assert(prices.snapshotStatus !== 'verified', 'price snapshot must not be verified at T51');
assert(prices.costClaimsAllowed === false, 'cost claims must remain disabled at T51');
const conflict = prices.conflicts.find((entry) => entry.modelId === 'claude-3-5-haiku-20241022');
assert(conflict !== undefined && conflict.values.length >= 2, 'Claude price conflict must remain explicit');
const conflictSources = conflict.values.map((entry) => `${entry.sourceFile}:${entry.inputUsdPerMillion}/${entry.outputUsdPerMillion}`);
assert(conflictSources.includes('MAR/LLM/llm_profile.py:1/5') &&
  conflictSources.includes('MAR/LLM/price.py:0.8/4'), 'Claude price conflict values drift');
assert(conflict.resolution === 'unresolved', 'price conflict must remain explicit and unresolved');
assert(conflict.resolutionEvidence === null, 'price conflict must remain explicit and unresolved');
for (const entry of prices.models) {
  assert(entry.status === 'source-metadata-only' && entry.officialSourceUrl === null &&
    entry.officialSourceSha256 === null, `price entry ${entry.modelId} must remain source metadata only`);
}

assert(meta.claimState.environmentInputContract === 'complete', 'environment input contract must be complete');
for (const field of ['environmentResolved', 'dependenciesInstalled', 'datasetsDownloaded',
  'providerCredentialsRead', 'providerCalls']) {
  assert(meta.claimState[field] === 'notRun', `${field} must remain notRun at T51`);
}
assert(meta.claimState.benchmarkRuns === 0 && meta.claimState.trainingRuns === 0,
  'T51 must remain a zero-execution input contract');
for (const field of ['environmentReady', 'datasetReady', 'providerModelReady', 'priceReady', 'executionReady']) {
  assert(meta.readiness[field] === false, `${field} must remain false at T51`);
}
assert(meta.execution.dependenciesInstalled === false && meta.execution.datasetsDownloaded === false &&
  meta.execution.credentialsRead === false && meta.execution.providerCallsExecuted === false &&
  meta.execution.benchmarkRunsExecuted === 0 && meta.execution.trainingRunsExecuted === 0 &&
  meta.execution.costIncurredUsd === 0, 'T51 must remain a zero-execution input contract');

const requiredIssues = [
  'dependency-manifest-missing', 'checkpoint-manifest-missing', 'readme-entrypoint-case',
  'mmlu-download-module-missing', 'dataset-path-case', 'claude-price-conflict',
  'gsm8k-humaneval-split-unseeded', 'mbpp-remote-dataset-unpinned',
  'math-paper-subset-not-reproducible', 'mmlu-test-slice-implied',
  'provider-env-contract-drift', 'deepseek-client-selection-case',
  'model-revisions-regions-unresolved', 'minimum-python-version-undeclared',
  'dataset-digests-missing'
];
const issueIds = issues.issues.map((entry) => entry.id);
assert(new Set(issueIds).size === issueIds.length, 'unresolved issue ids must be unique');
for (const id of requiredIssues) {
  assert(issueIds.includes(id), `required unresolved issue missing: ${id}`);
}
for (const entry of issues.issues) {
  hasEvidence(entry.evidence, `issue ${entry.id}`);
  assert(entry.status === 'open', `unresolved issue ${entry.id} must remain open`);
}
assert(issues.issueCount === issues.issues.length, 'unresolved issue count drift');

const report = {
  reportSchemaVersion: '1',
  task: 'T51',
  milestone: 'M13-B',
  reportDate: meta.contractDate,
  contractRevision: meta.contractRevision,
  checkerRevision: '2',
  validationMode: 'strict-json-schema',
  status: 'environment-input-contract-complete-reproduction-blocked',
  inputDigests: {
    upstreamLock: digest(paths.upstreamLock),
    reproductionSpec: digest(paths.reproductionSpec),
    environmentSchema: digest(paths.environmentSchema),
    datasetSchema: digest(paths.datasetSchema),
    providerModelSchema: digest(paths.modelSchema),
    priceSchema: digest(paths.priceSchema),
    environmentCandidates: digest(paths.environment),
    datasetLock: digest(paths.datasets),
    modelPools: digest(paths.models),
    priceSnapshot: digest(paths.prices),
    unresolvedIssues: digest(paths.issues),
    inputContract: digest(paths.meta)
  },
  upstream: {
    commit: lock.repository.commit,
    tree: lock.repository.tree,
    license: lock.license.spdx,
    paper: `${lock.paper.arxivId}${lock.paper.version}`
  },
  environment: {
    lockStatus: environment.lockStatus,
    pythonMinimum: environment.python.minimumVersion,
    pythonVersion: environment.python.version,
    torchVersion: environment.torch.version,
    acceleratorModes: environment.accelerator.supportedModes,
    dependencyCandidateCount: environment.dependencies.length,
    unresolvedDependencyCount: unresolvedDependencies,
    implicitDependencyCount: environment.implicitRuntimeDependencies.length,
    environmentReady: false
  },
  datasets: {
    lockStatus: datasets.lockStatus,
    executionReady: datasets.executionReady,
    datasetCount: datasets.datasets.length,
    statuses: datasets.datasets.map((entry) => ({ id: entry.id, status: entry.status })),
    digestCount: datasets.datasets.filter((entry) => entry.sha256 !== null).length,
    mathPaperSubsetCount: mathSubset.expectedCount,
    mathPaperSubsetManifestPresent: mathSubset.manifestPresent
  },
  modelPools: {
    poolsSeparate: models.poolsSeparate,
    paperCoreCount: models.paperCoreModelPool.length,
    paperInductiveCount: 1,
    sourceCount: models.sourceModelPool.length,
    unresolvedModelCount: allModelEntries.filter((entry) => entry.status === 'unresolved').length,
    encoderStatus: encoder.status,
    encoderPackaging: encoder.packaging,
    checkpointStatus: checkpoint.status
  },
  price: {
    snapshotStatus: prices.snapshotStatus,
    conflictCount: prices.conflicts.length,
    conflictModel: conflict.modelId,
    conflictResolution: conflict.resolution,
    costClaimsAllowed: prices.costClaimsAllowed
  },
  issues: {
    issueCount: issues.issues.length,
    blockingCount: issues.issues.filter((entry) => entry.severity === 'blocking').length,
    requiredOpenCount: issues.issues.filter((entry) => entry.requiredBeforeExecution).length
  },
  execution: meta.execution,
  nextGate: meta.nextGate
};

const output = `${JSON.stringify(report, null, 2)}\n`;
if (process.argv.includes('--check')) {
  assert(canonicalText(paths.report) === output, 'input contract report is stale');
  process.stdout.write(`${digest(paths.report)}\n`);
} else if (process.argv.includes('--write')) {
  writeFileSync(paths.report, output, 'utf8');
  process.stdout.write(`${digest(paths.report)}\n`);
} else {
  process.stdout.write(output);
}
