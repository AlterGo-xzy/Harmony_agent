import http from 'node:http';
import { writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    port: { type: 'string', default: '0' },
    'ready-file': { type: 'string' }
  }
});

const requestedPort = Number.parseInt(values.port, 10);
let requestCount = 0;

async function readJson(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function taskId(prompt) {
  const match = /"taskId":"([^"]+)"/.exec(prompt);
  return match?.[1] ?? 'fixture-task';
}

function clarification(prompt) {
  return prompt.includes('pilot-08-clarification-required') && !prompt.includes('clarificationResponse=');
}

function workflow(prompt) {
  const id = taskId(prompt);
  const two = prompt.includes('exactly two TOOL steps') || prompt.includes('two independent TOOL steps');
  const parallel = prompt.includes('two independent TOOL steps');
  const first = {
    stepId: 'bench-step-1',
    kind: 'tool',
    goal: 'Read deterministic benchmark fixture one',
    dependencies: [],
    inputBindings: [],
    expectedOutputSchemaJson: '{"type":"object"}',
    capabilityRequirements: ['echo', 'read-only'],
    sideEffect: 'none',
    riskLevel: 'low',
    permissionRequirements: ['network'],
    idempotencyMode: 'none',
    timeoutMs: 5000,
    retryPolicyRef: 'none',
    verificationPolicyRef: 'bench-runtime-evidence'
  };
  const steps = [first];
  if (two) {
    steps.push({
      ...first,
      stepId: 'bench-step-2',
      goal: 'Read deterministic benchmark fixture two',
      dependencies: parallel ? [] : ['bench-step-1']
    });
  }
  return {
    status: 'ready',
    workflow: {
      entryStepIds: parallel ? ['bench-step-1', 'bench-step-2'] : ['bench-step-1'],
      steps
    }
  };
}

const server = http.createServer(async (request, response) => {
  if (request.method === 'GET' && request.url === '/ready') {
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end('{"ready":true}');
    return;
  }
  if (request.method !== 'POST' || request.url !== '/v1/chat/completions') {
    response.writeHead(404, { 'content-type': 'application/json' });
    response.end('{"error":{"code":"not_found"}}');
    return;
  }
  try {
    const body = await readJson(request);
    const prompt = String(body.messages?.[1]?.content ?? '');
    const content = clarification(prompt) ? {
      status: 'clarificationRequired',
      clarification: {
        questionCode: 'MISSING_RECORD_KEY',
        prompt: 'Provide recordKey.',
        responseSchemaJson: '{"type":"object","properties":{"recordKey":{"type":"string"}},"required":["recordKey"]}'
      }
    } : workflow(prompt);
    requestCount++;
    const payload = {
      id: `fixture-${requestCount}`,
      object: 'chat.completion',
      model: 'aigw/default',
      choices: [{ index: 0, message: { role: 'assistant', content: JSON.stringify(content) }, finish_reason: 'stop' }],
      usage: { prompt_tokens: 64, completion_tokens: 64, total_tokens: 128 }
    };
    response.writeHead(200, { 'content-type': 'application/json' });
    response.end(JSON.stringify(payload));
  } catch {
    response.writeHead(400, { 'content-type': 'application/json' });
    response.end('{"error":{"code":"invalid_request"}}');
  }
});

server.listen(requestedPort, '127.0.0.1', async () => {
  const address = server.address();
  if (!address || typeof address === 'string') throw new Error('fixture gateway did not bind');
  const ready = { pid: process.pid, host: '127.0.0.1', port: address.port };
  if (values['ready-file']) await writeFile(values['ready-file'], `${JSON.stringify(ready, null, 2)}\n`, 'utf8');
  process.stdout.write(`${JSON.stringify(ready)}\n`);
});

function shutdown() {
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 3000).unref();
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
