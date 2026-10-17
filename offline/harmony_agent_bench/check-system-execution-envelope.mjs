import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const datasetPath = join(root, 'dataset-v1.json');
const pricePath = join(root, 'price-snapshot-deepseek-flash-2026-10-17.json');
const envelopePath = join(root, 'execution-envelope-candidate-v1.json');

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function digest(path) {
  return `sha256:${createHash('sha256').update(readFileSync(path)).digest('hex')}`;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const dataset = readJson(datasetPath);
const price = readJson(pricePath);
const envelope = readJson(envelopePath);
const clarificationCount = dataset.cases.filter(value => value.kind === 'clarificationRequired').length;
const strongRequests = dataset.cases.length * envelope.strongSingleRoleCount + clarificationCount;
const multiRequests = dataset.cases.length * envelope.multiAgentRoleCount +
  clarificationCount * envelope.multiAgentRoleCount;
const requestLimit = strongRequests + multiRequests;
const perRequestCost = Math.ceil((
  envelope.perRequestInputTokenLimit * price.inputMicrosPerMillionTokens +
  envelope.perRequestOutputTokenLimit * price.outputMicrosPerMillionTokens
) / 1_000_000) + price.fixedCostMicros;
const monetaryLimit = perRequestCost * requestLimit;

assert(process.argv.length === 3 && process.argv[2] === '--check', 'Use --check; this script never starts execution.');
assert(envelope.schemaVersion === '1', 'Unsupported envelope schema.');
assert(dataset.cases.length === 12, 'Dataset must contain twelve cases.');
assert(clarificationCount === 1, 'Dataset must contain one clarification case.');
assert(envelope.recordCount === dataset.cases.length * 2, 'Record count must cover 12 x 2.');
assert(envelope.maxClarificationRounds === 1, 'Exactly one clarification round must be allowed.');
assert(envelope.datasetDigest === digest(datasetPath), 'Dataset digest drifted.');
assert(envelope.priceSnapshotDigest === digest(pricePath), 'Price snapshot digest drifted.');
assert(envelope.priceSnapshotId === price.priceSnapshotId, 'Price snapshot identity drifted.');
assert(envelope.gatewayProviderId === price.gatewayProviderId, 'Gateway provider identity drifted.');
assert(envelope.gatewayModelId === price.gatewayModelId, 'Gateway model identity drifted.');
assert(envelope.upstreamProviderId === price.upstreamProviderId, 'Upstream provider identity drifted.');
assert(envelope.upstreamModelId === price.upstreamModelId, 'Upstream model identity drifted.');
assert(envelope.upstreamModelVersion === price.upstreamModelVersion, 'Upstream model version drifted.');
assert(envelope.upstreamRegion === price.upstreamRegion, 'Upstream region drifted.');
assert(envelope.strongSingleRequestLimit === strongRequests, 'Strong Single request limit drifted.');
assert(envelope.multiAgentRequestLimit === multiRequests, 'Multi Agent request limit drifted.');
assert(envelope.providerRequestLimit === requestLimit, 'Provider request limit drifted.');
assert(envelope.monetaryCostLimitMicros === monetaryLimit, 'Monetary cost limit drifted.');
assert(price.sourceUrl.startsWith('https://'), 'Price source must use HTTPS.');
assert(envelope.requiresActiveGatewayProfile === true, 'Active gateway profile gate is required.');
assert(envelope.requiresExplicitExecutionAuthorization === true, 'Explicit execution authorization gate is required.');

console.log(JSON.stringify({
  envelopeValid: true,
  executionStarted: false,
  runtimeAdmissionRequired: true,
  recordCount: envelope.recordCount,
  strongSingleRequestLimit: strongRequests,
  multiAgentRequestLimit: multiRequests,
  providerRequestLimit: requestLimit,
  perRequestCostLimitMicros: perRequestCost,
  monetaryCostLimitMicros: monetaryLimit
}, null, 2));
