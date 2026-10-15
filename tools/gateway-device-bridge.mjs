import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

export const DEVICE_BRIDGE_AUTHORIZATION = 'Bearer device-test';

function normalizeGatewayBaseUrl(value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error('Gateway base URL is required.');
  }
  const parsed = new URL(value);
  if (parsed.protocol !== 'http:' || (parsed.hostname !== '127.0.0.1' && parsed.hostname !== 'localhost') ||
      parsed.username.length > 0 || parsed.password.length > 0 || parsed.search.length > 0 || parsed.hash.length > 0) {
    throw new Error('Gateway base URL must be an HTTP loopback URL.');
  }
  const pathname = parsed.pathname.replace(/\/+$/, '');
  if (pathname !== '' && pathname !== '/v1') {
    throw new Error('Gateway base URL path must be empty or /v1.');
  }
  const root = `${parsed.protocol}//${parsed.host}`;
  return { root, api: `${root}/v1` };
}

function safeWorkspacePath(filename, workspaceRoot) {
  const root = path.resolve(workspaceRoot);
  const resolved = path.resolve(filename);
  const relative = path.relative(root, resolved);
  if (relative.length === 0 || relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error('Bridge output path must stay inside the workspace.');
  }
  return resolved;
}

async function readLimitedBody(stream, limit) {
  const chunks = [];
  let received = 0;
  for await (const chunk of stream) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    received += buffer.length;
    if (received > limit) throw new Error('REQUEST_TOO_LARGE');
    chunks.push(buffer);
  }
  return Buffer.concat(chunks, received);
}

function requestBuffer(url, options, body, responseLimit) {
  return new Promise((resolve, reject) => {
    const request = http.request(url, options, async (response) => {
      try {
        const responseBody = await readLimitedBody(response, responseLimit);
        resolve({
          statusCode: response.statusCode ?? 502,
          contentType: typeof response.headers['content-type'] === 'string'
            ? response.headers['content-type'] : 'application/json',
          body: responseBody
        });
      } catch (error) {
        request.destroy();
        reject(error);
      }
    });
    request.on('error', reject);
    request.setTimeout(options.timeout, () => request.destroy(new Error('UPSTREAM_TIMEOUT')));
    if (body.length > 0) request.write(body);
    request.end();
  });
}

function nonNegativeInteger(value) {
  return Number.isSafeInteger(value) && value >= 0;
}

function objectValue(value) {
  return value !== null && !Array.isArray(value) && typeof value === 'object';
}

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function stringArrayShape(value) {
  return Array.isArray(value) && value.every(nonEmptyString);
}

function knownValue(value, allowed) {
  if (typeof value !== 'string') return 'missing';
  return allowed.includes(value) ? value : 'other';
}

function unexpectedKeyCount(value, allowed) {
  return objectValue(value) ? Object.keys(value).filter((key) => !allowed.includes(key)).length : 0;
}

function jsonObjectString(value) {
  if (typeof value !== 'string') return false;
  try {
    return objectValue(JSON.parse(value));
  } catch {
    return false;
  }
}

function summarizePlannerContent(content) {
  const planner = {
    status: knownValue(content.status, ['ready', 'clarificationRequired', 'rejected']),
    topLevelUnexpectedKeyCount: unexpectedKeyCount(content,
      ['status', 'workflow', 'clarification', 'rejectionCode']),
    workflowObject: objectValue(content.workflow),
    clarificationPresent: content.clarification !== undefined,
    rejectionCodePresent: content.rejectionCode !== undefined,
    workflowUnexpectedKeyCount: 0,
    entryStepIdsArray: false,
    entryStepIdsValidStrings: false,
    entryStepIdCount: 0,
    stepsArray: false,
    stepCount: 0,
    firstStepObject: false,
    firstStepUnexpectedKeyCount: 0,
    firstStepIdValid: false,
    firstStepKind: 'missing',
    firstStepGoalValid: false,
    firstStepDependenciesValid: false,
    firstStepDependencyCount: 0,
    firstStepInputBindingsArray: false,
    firstStepInputBindingCount: 0,
    firstStepExpectedOutputSchemaJsonObject: false,
    firstStepCapabilitiesValid: false,
    firstStepCapabilityCount: 0,
    firstStepSideEffect: 'missing',
    firstStepRiskLevel: 'missing',
    firstStepPermissionsValid: false,
    firstStepPermissionCount: 0,
    firstStepIdempotencyMode: 'missing',
    firstStepTimeoutInteger: false,
    firstStepTimeoutPositive: false,
    firstStepRetryPolicyRefValid: false,
    firstStepVerificationPolicyRefValid: false,
    entryContainsFirstStep: false
  };
  const workflow = content.workflow;
  if (!objectValue(workflow)) return planner;
  planner.workflowUnexpectedKeyCount = unexpectedKeyCount(workflow, ['entryStepIds', 'steps']);
  planner.entryStepIdsArray = Array.isArray(workflow.entryStepIds);
  planner.entryStepIdsValidStrings = stringArrayShape(workflow.entryStepIds);
  planner.entryStepIdCount = planner.entryStepIdsArray ? workflow.entryStepIds.length : 0;
  planner.stepsArray = Array.isArray(workflow.steps);
  planner.stepCount = planner.stepsArray ? workflow.steps.length : 0;
  if (!planner.stepsArray || workflow.steps.length === 0 || !objectValue(workflow.steps[0])) return planner;
  const step = workflow.steps[0];
  planner.firstStepObject = true;
  planner.firstStepUnexpectedKeyCount = unexpectedKeyCount(step, [
    'stepId', 'kind', 'goal', 'dependencies', 'inputBindings', 'expectedOutputSchemaJson',
    'capabilityRequirements', 'sideEffect', 'riskLevel', 'permissionRequirements',
    'idempotencyMode', 'timeoutMs', 'retryPolicyRef', 'verificationPolicyRef'
  ]);
  planner.firstStepIdValid = nonEmptyString(step.stepId);
  planner.firstStepKind = knownValue(step.kind, ['llm', 'tool', 'verify', 'join', 'userConfirmation']);
  planner.firstStepGoalValid = nonEmptyString(step.goal);
  planner.firstStepDependenciesValid = stringArrayShape(step.dependencies);
  planner.firstStepDependencyCount = Array.isArray(step.dependencies) ? step.dependencies.length : 0;
  planner.firstStepInputBindingsArray = Array.isArray(step.inputBindings);
  planner.firstStepInputBindingCount = planner.firstStepInputBindingsArray ? step.inputBindings.length : 0;
  planner.firstStepExpectedOutputSchemaJsonObject = jsonObjectString(step.expectedOutputSchemaJson);
  planner.firstStepCapabilitiesValid = stringArrayShape(step.capabilityRequirements);
  planner.firstStepCapabilityCount = Array.isArray(step.capabilityRequirements)
    ? step.capabilityRequirements.length : 0;
  planner.firstStepSideEffect = knownValue(step.sideEffect, ['none', 'reversible', 'irreversible']);
  planner.firstStepRiskLevel = knownValue(step.riskLevel, ['low', 'medium', 'high', 'critical']);
  planner.firstStepPermissionsValid = stringArrayShape(step.permissionRequirements);
  planner.firstStepPermissionCount = Array.isArray(step.permissionRequirements)
    ? step.permissionRequirements.length : 0;
  planner.firstStepIdempotencyMode = knownValue(step.idempotencyMode, ['none', 'providerKey', 'reconcile']);
  planner.firstStepTimeoutInteger = Number.isSafeInteger(step.timeoutMs);
  planner.firstStepTimeoutPositive = planner.firstStepTimeoutInteger && step.timeoutMs > 0;
  planner.firstStepRetryPolicyRefValid = nonEmptyString(step.retryPolicyRef);
  planner.firstStepVerificationPolicyRefValid = nonEmptyString(step.verificationPolicyRef);
  planner.entryContainsFirstStep = planner.firstStepIdValid && planner.entryStepIdsArray &&
    workflow.entryStepIds.includes(step.stepId);
  return planner;
}

function summarizeChatResponse(body) {
  const summary = {
    jsonObject: false,
    choiceCount: 0,
    messageObject: false,
    contentType: 'missing',
    contentLength: 0,
    contentJsonObject: false,
    plannerTopLevelShape: false,
    planner: null,
    finishReason: 'missing',
    usageObject: false,
    usageValid: false
  };
  try {
    const root = JSON.parse(body.toString('utf8'));
    if (root === null || Array.isArray(root) || typeof root !== 'object') return summary;
    summary.jsonObject = true;
    const choices = root.choices;
    summary.choiceCount = Array.isArray(choices) ? choices.length : 0;
    if (!Array.isArray(choices) || choices.length !== 1 || choices[0] === null ||
        Array.isArray(choices[0]) || typeof choices[0] !== 'object') return summary;
    const choice = choices[0];
    summary.finishReason = ['stop', 'length', 'content_filter'].includes(choice.finish_reason)
      ? choice.finish_reason : (typeof choice.finish_reason === 'string' ? 'other' : 'missing');
    const message = choice.message;
    summary.messageObject = message !== null && !Array.isArray(message) && typeof message === 'object';
    if (summary.messageObject) {
      summary.contentType = Array.isArray(message.content) ? 'array' : typeof message.content;
      if (typeof message.content === 'string') {
        summary.contentLength = Buffer.byteLength(message.content, 'utf8');
        try {
          const content = JSON.parse(message.content);
          summary.contentJsonObject = content !== null && !Array.isArray(content) && typeof content === 'object';
          if (summary.contentJsonObject) {
            summary.planner = summarizePlannerContent(content);
            summary.plannerTopLevelShape = summary.planner.topLevelUnexpectedKeyCount === 0 &&
              summary.planner.status !== 'missing' && summary.planner.status !== 'other';
          }
        } catch {
          // The shape summary deliberately records no response text.
        }
      }
    }
    const usage = root.usage;
    summary.usageObject = usage !== null && !Array.isArray(usage) && typeof usage === 'object';
    if (summary.usageObject) {
      summary.usageValid = nonNegativeInteger(usage.prompt_tokens) &&
        nonNegativeInteger(usage.completion_tokens) && nonNegativeInteger(usage.total_tokens) &&
        usage.total_tokens === usage.prompt_tokens + usage.completion_tokens;
    }
  } catch {
    // Invalid JSON is represented only by jsonObject=false.
  }
  return summary;
}

export async function startGatewayDeviceBridge(options) {
  const gateway = normalizeGatewayBaseUrl(options.gatewayBaseUrl);
  if (typeof options.gatewayToken !== 'string' || options.gatewayToken.trim().length === 0) {
    throw new Error('Gateway token is required.');
  }
  const requestLimit = options.maxRequestBytes ?? 1048576;
  const responseLimit = options.maxResponseBytes ?? 8388608;
  const timeoutMs = options.timeoutMs ?? 60000;
  const summary = {
    schemaVersion: '1.0',
    listeningHost: '127.0.0.1',
    listeningPort: 0,
    requestCount: 0,
    readyCount: 0,
    chatCount: 0,
    rejectedCount: 0,
    upstreamStatusCounts: {},
    chatResponseShape: null,
    gatewayCredentialRecorded: false,
    requestBodyRecorded: false,
    responseBodyRecorded: false
  };

  const persistSummary = () => {
    if (options.summaryPath === undefined) return;
    fs.mkdirSync(path.dirname(options.summaryPath), { recursive: true });
    fs.writeFileSync(options.summaryPath, `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
  };

  const server = http.createServer(async (request, response) => {
    summary.requestCount++;
    try {
      const incomingUrl = new URL(request.url ?? '/', 'http://127.0.0.1');
      const exactPath = incomingUrl.search.length === 0;
      const ready = exactPath && request.method === 'GET' && incomingUrl.pathname === '/ready';
      const chat = exactPath && request.method === 'POST' && incomingUrl.pathname === '/v1/chat/completions';
      if (!ready && !chat) {
        summary.rejectedCount++;
        response.writeHead(404, { 'content-type': 'application/json' });
        response.end('{"error":{"code":"bridge_not_found"}}');
        return;
      }
      if (chat && request.headers.authorization !== DEVICE_BRIDGE_AUTHORIZATION) {
        summary.rejectedCount++;
        response.writeHead(401, { 'content-type': 'application/json' });
        response.end('{"error":{"code":"bridge_authentication"}}');
        return;
      }
      const body = chat ? await readLimitedBody(request, requestLimit) : Buffer.alloc(0);
      const upstreamUrl = ready ? `${gateway.root}/ready` : `${gateway.api}/chat/completions`;
      const headers = chat ? {
        'authorization': `Bearer ${options.gatewayToken}`,
        'content-type': 'application/json',
        'accept': 'application/json',
        'content-length': String(body.length)
      } : { 'accept': 'application/json' };
      const upstream = await requestBuffer(upstreamUrl, {
        method: ready ? 'GET' : 'POST',
        headers,
        timeout: timeoutMs
      }, body, responseLimit);
      if (ready) summary.readyCount++;
      if (chat) {
        summary.chatCount++;
        summary.chatResponseShape = summarizeChatResponse(upstream.body);
      }
      const statusKey = String(upstream.statusCode);
      summary.upstreamStatusCounts[statusKey] = (summary.upstreamStatusCounts[statusKey] ?? 0) + 1;
      response.writeHead(upstream.statusCode, { 'content-type': upstream.contentType });
      response.end(upstream.body);
    } catch (error) {
      const requestTooLarge = error instanceof Error && error.message === 'REQUEST_TOO_LARGE';
      summary.rejectedCount++;
      response.writeHead(requestTooLarge ? 413 : 502, { 'content-type': 'application/json' });
      response.end(requestTooLarge
        ? '{"error":{"code":"bridge_request_too_large"}}'
        : '{"error":{"code":"bridge_upstream_failure"}}');
    } finally {
      persistSummary();
    }
  });

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(options.port ?? 0, '127.0.0.1', resolve);
  });
  const address = server.address();
  if (address === null || typeof address === 'string') throw new Error('Bridge TCP address was not assigned.');
  summary.listeningPort = address.port;
  persistSummary();
  return {
    port: address.port,
    summary,
    close: () => new Promise((resolve, reject) => {
      server.close((error) => error === undefined ? resolve() : reject(error));
    })
  };
}

function argumentValue(name) {
  const index = process.argv.indexOf(name);
  return index < 0 || index + 1 >= process.argv.length ? undefined : process.argv[index + 1];
}

if (process.argv[1] !== undefined && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const workspace = process.cwd();
  const readyArgument = argumentValue('--ready-file');
  const summaryArgument = argumentValue('--summary-file');
  if (readyArgument === undefined || summaryArgument === undefined) {
    throw new Error('--ready-file and --summary-file are required.');
  }
  const readyPath = safeWorkspacePath(readyArgument, workspace);
  const summaryPath = safeWorkspacePath(summaryArgument, workspace);
  const gatewayBaseUrl = process.env.HARMONY_AGENT_GATEWAY_BASE_URL;
  const gatewayToken = process.env.HARMONY_AGENT_GATEWAY_TOKEN;
  const bridge = await startGatewayDeviceBridge({ gatewayBaseUrl, gatewayToken, summaryPath });
  fs.mkdirSync(path.dirname(readyPath), { recursive: true });
  fs.writeFileSync(readyPath, `${JSON.stringify({
    schemaVersion: '1.0',
    host: '127.0.0.1',
    port: bridge.port,
    deviceAuthorization: DEVICE_BRIDGE_AUTHORIZATION,
    gatewayCredentialRecorded: false
  }, null, 2)}\n`, 'utf8');
  const shutdown = async () => {
    await bridge.close();
    process.exit(0);
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
}
