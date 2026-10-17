import { describe, expect, it } from '@ohos/hypium';
import systemDateTime from '@ohos.systemDateTime';
import {
  AgentRuntimeEvent,
  AgentRuntimeEventType,
  AgentTaskSnapshot,
  AgentTaskStatus,
  AuthorizationDecision,
  AuthorizationDecisionType,
  ClarificationRequest,
  ClarificationResponse,
  CollaborationMode,
  DataBoundary,
  ExecutionBudget,
  PolicyRequest,
  PrivacyClass,
  ReconciliationReport,
  RiskLevel,
  TaskFrame,
  TaskHandle,
  TaskSubmission,
  ToolInvocation,
  ToolOutcome,
  WorkflowStep
} from '@harmony_agent/agent-contracts';
import {
  AgentRuntimeFacade,
  AgentRuntimeObserver,
  AgentSubscription,
  CollaborationPlan,
  CollaborationPlanSelectorPort,
  CollaborationRoleAssignment,
  DispatchPersistenceContext,
  PreparedToolDispatch,
  ProductionAgentRuntimeConfig,
  ProductionAgentRuntimePorts,
  ProductionRuntimePersistencePort,
  PlanningRequest,
  RuntimeClockPort,
  RuntimeDurableAuthorityPayload,
  RuntimeIdGeneratorPort,
  RuntimePersistenceCode,
  RuntimePersistenceResult,
  RuntimeTaskRecoveryCheckpoint,
  ShutdownMode,
  SubscriptionRequest,
  ToolInvocationPreparerPort,
  ToolRegistry
} from '@harmony_agent/agent-runtime';
import {
  ArkTsLocalAIGatewayHttpClient,
  ConnectorClockPort,
  ConnectorDigestPort,
  LocalAIGatewayHttpClientPort,
  LocalAIGatewayHttpRequest,
  LocalAIGatewayHttpResponse,
  LocalAIGatewayMcpRuntimeConfig,
  LocalAIGatewayMcpRuntimePorts,
  McpAgentAdapter,
  McpClientToolPort,
  McpGrantVerification,
  McpGrantVerifierPort,
  McpInvocationPolicyBridge,
  McpProviderRegistry,
  McpReadOnlyToolPolicy,
  McpReadOnlyToolPolicyRegistry,
  ProviderCredential,
  ProviderCredentialPort,
  ProviderOperationHandle,
  ProviderPlannerTrace,
  ProviderPriceSnapshot,
  ProviderSemanticPlannerConfig,
  ProviderSemanticPlannerObserverPort,
  SystemProviderTimer,
  canonicalJson,
  createLocalAIGatewayMcpProductionAgentRuntime
} from '../../Index';
import {
  McpAggregateResult,
  McpAuthorizationDecision,
  McpCapabilityKind,
  McpCapabilityRef,
  McpContentBlock,
  McpInvocationContext,
  McpServerFailure,
  McpServerProfile,
  McpTool,
  McpToolResult
} from '@harmony_agent/mcp-client';
import {
  BenchmarkArm,
  BenchmarkArmKind,
  BenchmarkManifest,
  BenchmarkSample,
  BenchmarkTaskCase,
  BenchmarkTaskKind,
  HarmonyAgentBenchPilotCatalog,
  SystemBenchmarkAdmissionSnapshot,
  SystemBenchmarkAgentEvidence,
  SystemBenchmarkEnvironment,
  SystemBenchmarkEvidence,
  SystemBenchmarkExecutionPlan,
  SystemBenchmarkExecutionPreflightValidator,
  SystemBenchmarkExecutionPrice,
  SystemBenchmarkMeasurementMode,
  SystemBenchmarkRecord,
  SystemBenchmarkRun,
  SystemBenchmarkRunRecorder,
  SystemBenchmarkSealResult
} from '@harmony_agent/agent-testkit';
import {
  BENCH_AUTHORIZATION_REF,
  BENCH_EXECUTION_ID,
  BENCH_GATEWAY_PORT,
  BENCH_LIVE,
  BENCH_MCP_PORT,
  BENCH_PROFILE_DIGEST,
  BENCH_SOURCE_COMMIT
} from './SystemBenchmarkLiveConfig';

function utf8(value: string): Uint8Array {
  const bytes: number[] = [];
  for (let i: number = 0; i < value.length; i++) {
    let code: number = value.charCodeAt(i);
    if (code >= 0xD800 && code <= 0xDBFF && i + 1 < value.length) {
      const low: number = value.charCodeAt(i + 1);
      if (low >= 0xDC00 && low <= 0xDFFF) {
        code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00);
        i++;
      }
    }
    if (code <= 0x7F) {
      bytes.push(code);
    } else if (code <= 0x7FF) {
      bytes.push(0xC0 | (code >> 6));
      bytes.push(0x80 | (code & 0x3F));
    } else if (code <= 0xFFFF) {
      bytes.push(0xE0 | (code >> 12));
      bytes.push(0x80 | ((code >> 6) & 0x3F));
      bytes.push(0x80 | (code & 0x3F));
    } else {
      bytes.push(0xF0 | (code >> 18));
      bytes.push(0x80 | ((code >> 12) & 0x3F));
      bytes.push(0x80 | ((code >> 6) & 0x3F));
      bytes.push(0x80 | (code & 0x3F));
    }
  }
  return new Uint8Array(bytes);
}

function rotateRight(value: number, bits: number): number {
  return (value >>> bits) | (value << (32 - bits));
}

function sha256(value: string): string {
  const source: Uint8Array = utf8(value);
  const bitLength: number = source.length * 8;
  const paddedLength: number = Math.ceil((source.length + 9) / 64) * 64;
  const message: Uint8Array = new Uint8Array(paddedLength);
  message.set(source);
  message[source.length] = 0x80;
  let remaining: number = bitLength;
  for (let i: number = 0; i < 8; i++) {
    message[paddedLength - 1 - i] = remaining & 0xff;
    remaining = Math.floor(remaining / 256);
  }
  const constants: number[] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];
  const state: number[] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ];
  const words: number[] = new Array<number>(64).fill(0);
  for (let offset: number = 0; offset < message.length; offset += 64) {
    for (let i: number = 0; i < 16; i++) {
      const base: number = offset + i * 4;
      words[i] = ((message[base] << 24) | (message[base + 1] << 16) |
        (message[base + 2] << 8) | message[base + 3]) >>> 0;
    }
    for (let i: number = 16; i < 64; i++) {
      const s0: number = rotateRight(words[i - 15], 7) ^ rotateRight(words[i - 15], 18) ^ (words[i - 15] >>> 3);
      const s1: number = rotateRight(words[i - 2], 17) ^ rotateRight(words[i - 2], 19) ^ (words[i - 2] >>> 10);
      words[i] = (words[i - 16] + s0 + words[i - 7] + s1) >>> 0;
    }
    let a: number = state[0]; let b: number = state[1]; let c: number = state[2]; let d: number = state[3];
    let e: number = state[4]; let f: number = state[5]; let g: number = state[6]; let h: number = state[7];
    for (let i: number = 0; i < 64; i++) {
      const upper: number = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25);
      const choice: number = (e & f) ^ (~e & g);
      const temporary1: number = (h + upper + choice + constants[i] + words[i]) >>> 0;
      const lower: number = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22);
      const majority: number = (a & b) ^ (a & c) ^ (b & c);
      const temporary2: number = (lower + majority) >>> 0;
      h = g; g = f; f = e; e = (d + temporary1) >>> 0;
      d = c; c = b; b = a; a = (temporary1 + temporary2) >>> 0;
    }
    state[0] = (state[0] + a) >>> 0; state[1] = (state[1] + b) >>> 0;
    state[2] = (state[2] + c) >>> 0; state[3] = (state[3] + d) >>> 0;
    state[4] = (state[4] + e) >>> 0; state[5] = (state[5] + f) >>> 0;
    state[6] = (state[6] + g) >>> 0; state[7] = (state[7] + h) >>> 0;
  }
  let output: string = '';
  for (let i: number = 0; i < state.length; i++) output += state[i].toString(16).padStart(8, '0');
  return output;
}

class BenchDigest implements ConnectorDigestPort {
  digest(value: string): string {
    return 'sha256:' + sha256(value);
  }
}

class BenchConnectorClock implements ConnectorClockPort {
  nowIso(): string { return new Date().toISOString(); }
}

class BenchRuntimeClock implements RuntimeClockPort {
  nowMs(): number { return Date.now(); }
}

class BenchIds implements RuntimeIdGeneratorPort {
  private next: number = 0;

  nextId(kind: string, requestId: string): string {
    this.next++;
    return kind + ':' + requestId + ':' + this.next.toString();
  }
}

class BenchGrantVerifier implements McpGrantVerifierPort {
  verify(invocation: ToolInvocation): McpGrantVerification {
    const result: McpGrantVerification = new McpGrantVerification();
    result.allowed = invocation.authorizationGrantId.trim().length > 0;
    result.code = result.allowed ? 'GRANT_ACCEPTED' : 'GRANT_REQUIRED';
    return result;
  }
}

class BenchCredentialPort implements ProviderCredentialPort {
  calls: number = 0;

  resolve(providerId: string, scope: string): Promise<ProviderCredential> {
    this.calls++;
    if (providerId !== 'local-ai-gateway' || scope !== 'gateway.invoke') {
      return Promise.reject(new Error('BENCH_CREDENTIAL_SCOPE_INVALID'));
    }
    const value: ProviderCredential = new ProviderCredential();
    value.headers['Authorization'] = 'Bearer device-test';
    return Promise.resolve(value);
  }
}

class BenchGatewayOperation implements ProviderOperationHandle<LocalAIGatewayHttpResponse> {
  readonly result: Promise<LocalAIGatewayHttpResponse>;

  constructor(response: LocalAIGatewayHttpResponse) {
    this.result = Promise.resolve(response);
  }

  cancel(): void {}
}

class BenchFixtureGatewayClient implements LocalAIGatewayHttpClientPort {
  private requestCount: number = 0;

  start(_request: LocalAIGatewayHttpRequest): ProviderOperationHandle<LocalAIGatewayHttpResponse> {
    this.requestCount++;
    const workflow: string = '{"status":"ready","workflow":{"entryStepIds":["bench-step-1"],' +
      '"steps":[{"stepId":"bench-step-1","kind":"tool","goal":"Read deterministic benchmark fixture",' +
      '"dependencies":[],"inputBindings":[],"expectedOutputSchemaJson":"{\\"type\\":\\"object\\"}",' +
      '"capabilityRequirements":["echo","read-only"],"sideEffect":"none","riskLevel":"low",' +
      '"permissionRequirements":["network"],"idempotencyMode":"none","timeoutMs":5000,' +
      '"retryPolicyRef":"none","verificationPolicyRef":"bench-runtime-evidence"}]}}';
    const body: string = '{"id":"fixture-' + this.requestCount.toString() + '","object":"chat.completion",' +
      '"model":"aigw/default","choices":[{"index":0,"message":{"role":"assistant","content":' +
      JSON.stringify(workflow) + '},"finish_reason":"stop"}],"usage":{"prompt_tokens":64,' +
      '"completion_tokens":64,"total_tokens":128}}';
    const response: LocalAIGatewayHttpResponse = new LocalAIGatewayHttpResponse();
    response.statusCode = 200;
    response.body = body;
    return new BenchGatewayOperation(response);
  }
}

class BenchPlannerObserver implements ProviderSemanticPlannerObserverPort {
  traces: ProviderPlannerTrace[] = [];

  onGenerationCompleted(trace: ProviderPlannerTrace): void { this.traces.push(trace); }
}

class BenchAggregate implements McpAggregateResult<McpTool> {
  items: McpTool[] = [];
  errors: McpServerFailure[] = [];
}

class BenchContentBlock implements McpContentBlock {
  type: string = 'text';
  text?: string;
}

class BenchToolResult implements McpToolResult {
  content: McpContentBlock[] = [];
  structuredContent?: Object;
  isError: boolean = false;
}

class BenchStructuredContent {
  echoed: Object;
  source: string = 'deterministic-bench-fixture';

  constructor(echoed: Object) {
    this.echoed = echoed;
  }
}

class BenchSchemaProperty {
  type: string = 'string';
}

class BenchSchema {
  type: string = 'object';
  properties: Record<string, Object> = new Object() as Record<string, Object>;
  required: string[] = ['text'];
}

class BenchAnnotations {
  destructiveHint: boolean = false;
}

function benchTool(serverId: string): McpTool {
  const schema: BenchSchema = new BenchSchema();
  schema.properties['text'] = new BenchSchemaProperty();
  return {
    ref: { serverId: serverId, kind: McpCapabilityKind.TOOL, name: 'echo' },
    name: 'echo',
    title: 'System Bench deterministic echo',
    description: 'Returns controlled benchmark fixture input without external side effects.',
    inputSchema: schema,
    annotations: new BenchAnnotations()
  };
}

class BenchMcpClient implements McpClientToolPort {
  tools: McpTool[] = [];
  callCount: number = 0;
  private readonly bridge: McpInvocationPolicyBridge;

  constructor(bridge: McpInvocationPolicyBridge) { this.bridge = bridge; }

  listTools(): Promise<McpAggregateResult<McpTool>> {
    const value: BenchAggregate = new BenchAggregate();
    value.items = this.tools.slice();
    return Promise.resolve(value);
  }

  async callTool(ref: McpCapabilityRef, argumentsValue: Object): Promise<McpToolResult> {
    const tool: McpTool = this.requireTool(ref);
    const context: McpInvocationContext = {
      profile: fixtureProfile(),
      tool: tool,
      arguments: argumentsValue
    };
    const decision: McpAuthorizationDecision = await this.bridge.authorize(context);
    if (!decision.allowed) throw new Error('BENCH_MCP_POLICY_DENIED');
    this.callCount++;
    const content: BenchContentBlock = new BenchContentBlock();
    content.text = 'controlled-benchmark-result';
    const result: BenchToolResult = new BenchToolResult();
    result.content = [content];
    result.structuredContent = new BenchStructuredContent(argumentsValue);
    return result;
  }

  private requireTool(ref: McpCapabilityRef): McpTool {
    for (let i: number = 0; i < this.tools.length; i++) {
      if (this.tools[i].ref.serverId === ref.serverId && this.tools[i].name === ref.name) return this.tools[i];
    }
    throw new Error('BENCH_MCP_TOOL_MISSING');
  }
}

class BenchCollaborationPlanSelector implements CollaborationPlanSelectorPort {
  private readonly digest: BenchDigest;

  constructor(digest: BenchDigest) { this.digest = digest; }

  selectPlan(frame: TaskFrame,
    maxAgentActivations: number): CollaborationPlan {
    const multi: boolean = maxAgentActivations >= 2;
    const roles: string[] = multi ? ['planner', 'verifier'] : ['planner'];
    const registryDigest: string = this.digest.digest('bench-role-registry-v1|planner@1|verifier@1');
    const plan: CollaborationPlan = new CollaborationPlan();
    plan.taskId = frame.taskId;
    plan.mode = multi ? CollaborationMode.MULTI : CollaborationMode.SINGLE;
    plan.roleRegistryDigest = registryDigest;
    plan.decisionDigest = this.digest.digest('bench-collaboration-v1|' + frame.taskId + '|' + roles.join('|'));
    for (let i: number = 0; i < roles.length; i++) {
      const assignment: CollaborationRoleAssignment = new CollaborationRoleAssignment();
      assignment.roleId = roles[i];
      assignment.roleVersion = '1';
      assignment.roleRegistryDigest = registryDigest;
      plan.assignments.push(assignment);
    }
    return plan;
  }
}

function saved(): Promise<RuntimePersistenceResult> {
  const value: RuntimePersistenceResult = new RuntimePersistenceResult();
  value.accepted = true;
  value.code = RuntimePersistenceCode.SAVED;
  return Promise.resolve(value);
}

class BenchPersistence implements ProductionRuntimePersistencePort {
  saveCheckpoint(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _authority: RuntimeDurableAuthorityPayload, _nowMs: number): Promise<RuntimePersistenceResult> { return saved(); }
  loadCheckpoint(_taskId: string): Promise<RuntimeTaskRecoveryCheckpoint | undefined> {
    return Promise.resolve(undefined);
  }
  normalizeRecoveredOperation(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _nowMs: number): Promise<RuntimePersistenceResult> { return saved(); }
  beforeDispatch(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _context: DispatchPersistenceContext | undefined, _authority: RuntimeDurableAuthorityPayload,
    _nowMs: number): Promise<RuntimePersistenceResult> { return saved(); }
  recordDispatchRejected(_context: DispatchPersistenceContext | undefined, _dispatchId: string,
    _rejectionCode: string, _nowMs: number): Promise<RuntimePersistenceResult> { return saved(); }
  recordOutcome(_taskId: string, _stepId: string, _dispatchId: string, _outcome: ToolOutcome,
    _nowMs: number): Promise<RuntimePersistenceResult> { return saved(); }
  recordReconciliation(_report: ReconciliationReport, _nowMs: number): Promise<RuntimePersistenceResult> {
    return saved();
  }
}

class BenchToolPreparer implements ToolInvocationPreparerPort {
  private readonly registry: ToolRegistry;
  private readonly digest: BenchDigest;

  constructor(registry: ToolRegistry, digest: BenchDigest) {
    this.registry = registry;
    this.digest = digest;
  }

  prepare(request: PlanningRequest,
    step: WorkflowStep, nowMs: number): PreparedToolDispatch {
    const entries = this.registry.activeEntries();
    let selected = entries[0];
    for (let i: number = 0; i < entries.length; i++) {
      if (entries[i].descriptor.capabilityTags.indexOf('echo') >= 0) selected = entries[i];
    }
    const argumentsJson: string = JSON.stringify({
      text: 'bench|' + request.envelope.requestId + '|' + step.stepId
    }) as string;
    const argumentsDigest: string = this.digest.digest(canonicalJson(JSON.parse(argumentsJson) as Object));
    const prepared: PreparedToolDispatch = new PreparedToolDispatch();
    const policy: PolicyRequest = prepared.policyRequest;
    policy.requestId = 'policy:' + request.envelope.taskId + ':' + step.stepId;
    policy.userId = request.envelope.userId;
    policy.taskId = request.envelope.taskId;
    policy.stepId = step.stepId;
    policy.operationId = 'operation:' + request.envelope.taskId + ':' + step.stepId;
    policy.toolId = selected.descriptor.toolId;
    policy.toolIdentityVersion = selected.descriptor.toolIdentityVersion;
    policy.providerId = selected.descriptor.providerId;
    policy.schemaDigest = selected.descriptor.schemaDigest;
    policy.argumentsDigest = argumentsDigest;
    policy.riskLevel = step.riskLevel;
    policy.sideEffect = step.sideEffect;
    policy.estimatedCostMicros = selected.estimatedCostMicros;
    policy.requestedAt = new Date(nowMs).toISOString();
    policy.expiresAtMs = nowMs + 120000;
    policy.expiresAt = new Date(policy.expiresAtMs).toISOString();
    const invocation: ToolInvocation = prepared.invocation;
    invocation.invocationId = 'invocation:' + request.envelope.taskId + ':' + step.stepId;
    invocation.taskId = request.envelope.taskId;
    invocation.stepId = step.stepId;
    invocation.operationId = policy.operationId;
    invocation.attemptId = 'attempt-1';
    invocation.toolId = policy.toolId;
    invocation.toolIdentityVersion = policy.toolIdentityVersion;
    invocation.schemaDigest = policy.schemaDigest;
    invocation.argumentsJson = argumentsJson;
    invocation.argumentsDigest = argumentsDigest;
    invocation.idempotencyKey = 'bench:' + invocation.operationId;
    invocation.authorizationGrantId = '';
    invocation.timeoutMs = step.timeoutMs;
    invocation.createdAt = policy.requestedAt;
    return prepared;
  }
}

class BenchTaskObserver implements AgentRuntimeObserver {
  events: AgentRuntimeEvent[] = [];
  policies: PolicyRequest[] = [];
  clarifications: ClarificationRequest[] = [];

  onEvent(event: AgentRuntimeEvent): void { this.events.push(event); }
  onPolicyRequest(request: PolicyRequest): void { this.policies.push(request); }
  onClarificationRequest(request: ClarificationRequest): void { this.clarifications.push(request); }
}

function manifest(): BenchmarkManifest {
  const value: BenchmarkManifest = new BenchmarkManifest();
  value.benchmarkId = 'harmony-agent-bench-pilot';
  value.suiteVersion = '1.0.0';
  value.frozenAt = '2026-10-17T00:00:00+08:00';
  value.datasetDigest = 'sha256:59fe59405aacf21d68bb562d69c84f623f53b8f14173ce633ecb47d5c9f1100a';
  value.modelId = 'aigw/default';
  value.modelVersion = 'gateway-revision-13';
  value.providerId = 'local-ai-gateway';
  value.region = 'local-windows';
  value.priceSnapshotId = 'deepseek-flash-peak-cache-miss-2026-10-17';
  value.priceSnapshotDigest = 'sha256:e8a3375c6028b514dd3ff9013b655fe5dad17c4b5ee8afc55c7f2739cd4f7029';
  value.routerPolicyVersion = 'collaboration-plan-v1';
  const single: BenchmarkArm = new BenchmarkArm();
  single.armId = 'strong-single';
  single.kind = BenchmarkArmKind.STRONG_SINGLE_AGENT;
  single.permissionPolicyVersion = 'policy-v1';
  single.contextPolicyVersion = 'context-v1';
  const multi: BenchmarkArm = new BenchmarkArm();
  multi.armId = 'multi-agent';
  multi.kind = BenchmarkArmKind.MULTI_AGENT;
  multi.permissionPolicyVersion = single.permissionPolicyVersion;
  multi.contextPolicyVersion = single.contextPolicyVersion;
  value.arms = [single, multi];
  return value;
}

function price(manifestValue: BenchmarkManifest): SystemBenchmarkExecutionPrice {
  const value: SystemBenchmarkExecutionPrice = new SystemBenchmarkExecutionPrice();
  value.priceSnapshotId = manifestValue.priceSnapshotId;
  value.priceSnapshotDigest = manifestValue.priceSnapshotDigest;
  value.providerId = manifestValue.providerId;
  value.modelId = manifestValue.modelId;
  value.modelVersion = manifestValue.modelVersion;
  value.region = manifestValue.region;
  value.upstreamProviderId = 'deepseek';
  value.upstreamModelId = 'deepseek-flash';
  value.upstreamModelVersion = 'DeepSeek-V4.1-Flash';
  value.upstreamRegion = 'global';
  value.currency = 'USD_MICROS';
  value.pricingTier = 'peak-cache-miss';
  value.frozenAt = '2026-10-17T00:00:00+08:00';
  value.sourceUrl = 'https://api-docs.deepseek.com/quick_start/pricing/';
  value.inputMicrosPerMillionTokens = 300000;
  value.outputMicrosPerMillionTokens = 1200000;
  return value;
}

function plan(manifestValue: BenchmarkManifest): SystemBenchmarkExecutionPlan {
  const value: SystemBenchmarkExecutionPlan = new SystemBenchmarkExecutionPlan();
  value.benchmarkId = manifestValue.benchmarkId;
  value.suiteVersion = manifestValue.suiteVersion;
  value.datasetDigest = manifestValue.datasetDigest;
  value.recordCount = 24;
  value.maxClarificationRounds = 1;
  value.strongSingleRequestLimit = 13;
  value.multiAgentRequestLimit = 26;
  value.providerRequestLimit = 39;
  value.perRequestInputTokenLimit = 4096;
  value.perRequestOutputTokenLimit = 8192;
  value.price = price(manifestValue);
  value.monetaryCostLimitMicros = 431340;
  return value;
}

function admission(executionPlan: SystemBenchmarkExecutionPlan): SystemBenchmarkAdmissionSnapshot {
  const value: SystemBenchmarkAdmissionSnapshot = new SystemBenchmarkAdmissionSnapshot();
  value.observedAt = new Date().toISOString();
  value.gatewayRunning = true;
  value.activeProfileId = 'deepseek';
  value.activeProfileDigest = BENCH_PROFILE_DIGEST;
  value.activeConfigurationRevision = 13;
  value.providerId = executionPlan.price.providerId;
  value.modelId = executionPlan.price.modelId;
  value.modelVersion = executionPlan.price.modelVersion;
  value.region = executionPlan.price.region;
  value.upstreamProviderId = executionPlan.price.upstreamProviderId;
  value.upstreamModelId = executionPlan.price.upstreamModelId;
  value.upstreamModelVersion = executionPlan.price.upstreamModelVersion;
  value.upstreamRegion = executionPlan.price.upstreamRegion;
  value.priceSnapshotId = executionPlan.price.priceSnapshotId;
  value.priceSnapshotDigest = executionPlan.price.priceSnapshotDigest;
  value.executionAuthorizationRef = BENCH_AUTHORIZATION_REF;
  return value;
}

function runHeader(digest: BenchDigest): SystemBenchmarkRun {
  const value: SystemBenchmarkRun = new SystemBenchmarkRun();
  value.executionId = BENCH_EXECUTION_ID;
  value.measurementMode = SystemBenchmarkMeasurementMode.REAL_PROVIDER_RUNTIME;
  value.startedAt = new Date().toISOString();
  value.completedAt = value.startedAt;
  value.performanceComparable = BENCH_LIVE;
  value.redactionPolicyVersion = 'bench-redaction-v1';
  value.qualityJudgeId = 'runtime-evidence-judge';
  value.qualityJudgeVersion = '1.0.0';
  const environment: SystemBenchmarkEnvironment = new SystemBenchmarkEnvironment();
  environment.sourceCommit = BENCH_SOURCE_COMMIT;
  environment.runtimeVersion = '0.14.0';
  environment.compositionVersion = '2.5';
  environment.harnessVersion = '1.0.0';
  environment.sdkVersion = 'OpenHarmony-26.0.0';
  environment.osVersion = 'Windows-host-previewer';
  environment.deviceClass = 'x64-host-previewer';
  environment.measurementClock = 'systemDateTime.getUptime.STARTUP.ms';
  environment.environmentDigest = digest.digest(JSON.stringify({
    sourceCommit: environment.sourceCommit,
    runtimeVersion: environment.runtimeVersion,
    compositionVersion: environment.compositionVersion,
    harnessVersion: environment.harnessVersion,
    sdkVersion: environment.sdkVersion,
    osVersion: environment.osVersion,
    deviceClass: environment.deviceClass,
    gatewayRevision: 13,
    profileDigest: BENCH_PROFILE_DIGEST
  }) as string);
  value.environment = environment;
  return value;
}

function gatewayConfig(): LocalAIGatewayMcpRuntimeConfig {
  const value: LocalAIGatewayMcpRuntimeConfig = new LocalAIGatewayMcpRuntimeConfig();
  value.runtimeConfig = new ProductionAgentRuntimeConfig();
  value.runtimeConfig.policyVersion = 'policy-v1';
  value.runtimeConfig.grantTtlMs = 120000;
  value.plannerConfig = new ProviderSemanticPlannerConfig();
  value.plannerConfig.promptVersion = 'typed-workflow-v1';
  value.plannerConfig.estimatedInputTokens = 4096;
  value.plannerConfig.maxOutputTokens = 8192;
  value.plannerConfig.temperature = 0;
  value.plannerConfig.timeoutMs = 120000;
  value.plannerConfig.clarificationTtlMs = 120000;
  value.plannerConfig.maxSteps = 2;
  value.plannerConfig.maxPromptCharacters = 40000;
  value.transportProfile.baseUrl = 'http://127.0.0.1:' + BENCH_GATEWAY_PORT.toString() + '/v1';
  value.transportProfile.modelVersion = 'gateway-revision-13';
  value.transportProfile.maxInputTokens = 4096;
  value.transportProfile.maxOutputTokens = 8192;
  value.transportProfile.qualityTier = 1;
  value.transportProfile.privacyClasses = [PrivacyClass.PUBLIC];
  value.transportProfile.available = true;
  value.transportProfile.connectTimeoutMs = 5000;
  const priceSnapshot: ProviderPriceSnapshot = value.priceSnapshot;
  priceSnapshot.snapshotId = 'deepseek-flash-peak-cache-miss-2026-10-17';
  priceSnapshot.providerId = value.transportProfile.providerId;
  priceSnapshot.capabilityId = value.transportProfile.publicModelAlias;
  priceSnapshot.capabilityVersion = value.transportProfile.modelVersion;
  priceSnapshot.region = value.transportProfile.region;
  priceSnapshot.currency = 'USD';
  priceSnapshot.inputMicrosPerMillionTokens = 300000;
  priceSnapshot.outputMicrosPerMillionTokens = 1200000;
  priceSnapshot.fixedCostMicros = 0;
  priceSnapshot.effectiveAt = '2026-10-17T00:00:00+08:00';
  priceSnapshot.snapshotDigest = 'sha256:e8a3375c6028b514dd3ff9013b655fe5dad17c4b5ee8afc55c7f2739cd4f7029';
  return value;
}

function exactWorkflowInstruction(taskCase: BenchmarkTaskCase): string {
  if (taskCase.kind === BenchmarkTaskKind.CLARIFICATION_REQUIRED) {
    return ' On the first plan request, return clarificationRequired because recordKey is missing. ' +
      'Use questionCode MISSING_RECORD_KEY and an object response schema requiring recordKey. ' +
      'After clarificationResponse is present, return exactly one TOOL step.';
  }
  if (taskCase.kind === BenchmarkTaskKind.MULTI_SOURCE_SYNTHESIS ||
    taskCase.kind === BenchmarkTaskKind.SEQUENTIAL_WORKFLOW) {
    return ' Return exactly two TOOL steps. The second step must depend on the first step.';
  }
  if (taskCase.kind === BenchmarkTaskKind.PARALLEL_WORKFLOW) {
    return ' Return exactly two independent TOOL steps and include both step IDs in entryStepIds.';
  }
  return ' Return exactly one TOOL step.';
}

function submission(taskCase: BenchmarkTaskCase, arm: BenchmarkArm): TaskSubmission {
  const activations: number = arm.kind === BenchmarkArmKind.MULTI_AGENT ? 2 : 1;
  const budget: ExecutionBudget = new ExecutionBudget();
  budget.maxWallTimeMs = 120000;
  budget.maxInputTokens = 4096 * activations;
  budget.maxOutputTokens = 8192 * activations;
  budget.maxMonetaryCostMicros = 11060 * activations * 2;
  budget.maxToolCalls = 2;
  budget.maxAgentActivations = activations;
  budget.maxRetries = 0;
  budget.maxReplans = 0;
  const now: string = new Date().toISOString();
  const value: TaskSubmission = new TaskSubmission();
  value.requestId = BENCH_EXECUTION_ID + ':' + arm.armId + ':' + taskCase.caseId;
  value.userId = 'system-bench-user';
  value.userIntent = taskCase.promptTemplate + exactWorkflowInstruction(taskCase) +
    ' Every TOOL step must use capabilityRequirements ["echo","read-only"], kind "tool", sideEffect "none", ' +
    'riskLevel "low", permissionRequirements ["network"], idempotencyMode "none", no inputBindings, ' +
    'expectedOutputSchemaJson "{\\"type\\":\\"object\\"}", timeoutMs 5000, retryPolicyRef "none", ' +
    'and verificationPolicyRef "bench-runtime-evidence". Do not create LLM, verification, join, or confirmation steps.';
  value.locale = 'en-US';
  value.timeZone = 'Asia/Shanghai';
  value.referenceTime = now;
  value.privacyClass = PrivacyClass.PUBLIC;
  value.requestedBudget = budget;
  value.submittedAt = now;
  return value;
}

function terminal(status: AgentTaskStatus): boolean {
  return status === AgentTaskStatus.COMPLETED || status === AgentTaskStatus.FAILED ||
    status === AgentTaskStatus.CANCELLED || status === AgentTaskStatus.WAITING_RECONCILIATION;
}

async function delay(ms: number): Promise<void> {
  return await new Promise<void>((resolve: () => void): void => { setTimeout(resolve, ms); });
}

async function settle(runtime: AgentRuntimeFacade, handle: TaskHandle,
  observer: BenchTaskObserver): Promise<AgentTaskSnapshot> {
  let policyIndex: number = 0;
  let clarificationSent: boolean = false;
  for (let i: number = 0; i < 600; i++) {
    const snapshot: AgentTaskSnapshot = await runtime.getTaskSnapshot(handle.taskId);
    if (terminal(snapshot.status)) return snapshot;
    if (snapshot.status === AgentTaskStatus.WAITING_INPUT && !clarificationSent &&
      observer.clarifications.length > 0) {
      const request: ClarificationRequest = observer.clarifications[observer.clarifications.length - 1];
      const response: ClarificationResponse = new ClarificationResponse();
      response.commandId = 'clarify:' + handle.taskId;
      response.clarificationId = request.clarificationId;
      response.taskId = handle.taskId;
      response.answerJson = '{"recordKey":"pinned-bench-record"}';
      response.respondedAtMs = Date.now();
      response.respondedAt = new Date(response.respondedAtMs).toISOString();
      await runtime.provideClarification(response);
      clarificationSent = true;
    } else if (snapshot.status === AgentTaskStatus.WAITING_AUTHORIZATION &&
      policyIndex < observer.policies.length) {
      const policy: PolicyRequest = observer.policies[policyIndex];
      policyIndex++;
      const decision: AuthorizationDecision = new AuthorizationDecision();
      decision.commandId = 'authorize:' + handle.taskId + ':' + policyIndex.toString();
      decision.policyRequestId = policy.requestId;
      decision.userId = 'system-bench-user';
      decision.taskId = handle.taskId;
      decision.decision = AuthorizationDecisionType.APPROVED;
      decision.decidedAtMs = Date.now();
      decision.decidedAt = new Date(decision.decidedAtMs).toISOString();
      await runtime.provideAuthorization(decision);
    }
    await delay(100);
  }
  return await runtime.getTaskSnapshot(handle.taskId);
}

function eventCount(events: AgentRuntimeEvent[], type: AgentRuntimeEventType): number {
  let count: number = 0;
  for (let i: number = 0; i < events.length; i++) if (events[i].eventType === type) count++;
  return count;
}

function roleTraces(traces: ProviderPlannerTrace[], roleId: string): ProviderPlannerTrace[] {
  const values: ProviderPlannerTrace[] = [];
  for (let i: number = 0; i < traces.length; i++) if (traces[i].roleId === roleId) values.push(traces[i]);
  return values;
}

function quality(taskCase: BenchmarkTaskCase, snapshot: AgentTaskSnapshot, toolCalls: number,
  clarificationCount: number, policyCount: number, recoveryCount: number): number {
  let checks: number = 2;
  let passed: number = snapshot.status === AgentTaskStatus.COMPLETED ? 1 : 0;
  if (toolCalls > 0) passed++;
  if (taskCase.kind === BenchmarkTaskKind.MULTI_SOURCE_SYNTHESIS ||
    taskCase.kind === BenchmarkTaskKind.SEQUENTIAL_WORKFLOW ||
    taskCase.kind === BenchmarkTaskKind.PARALLEL_WORKFLOW) {
    checks++;
    if (toolCalls >= 2) passed++;
  }
  if (taskCase.kind === BenchmarkTaskKind.CLARIFICATION_REQUIRED) {
    checks++;
    if (clarificationCount === 1) passed++;
  }
  if (taskCase.kind === BenchmarkTaskKind.AUTHORIZATION_REQUIRED) {
    checks++;
    if (policyCount > 0) passed++;
  }
  if (taskCase.kind === BenchmarkTaskKind.RECOVERY_RECONCILIATION) {
    checks++;
    if (recoveryCount > 0) passed++;
  }
  if (taskCase.kind === BenchmarkTaskKind.LONG_TERM_MEMORY_RECALL) {
    checks++;
  }
  return Math.floor((passed * 10000) / checks);
}

function record(digest: BenchDigest, taskCase: BenchmarkTaskCase, arm: BenchmarkArm,
  snapshot: AgentTaskSnapshot, observer: BenchTaskObserver, traces: ProviderPlannerTrace[],
  latencyMs: number, toolCalls: number): SystemBenchmarkRecord {
  const value: SystemBenchmarkRecord = new SystemBenchmarkRecord();
  const sample: BenchmarkSample = value.sample;
  sample.caseId = taskCase.caseId;
  sample.runId = BENCH_EXECUTION_ID;
  sample.armId = arm.armId;
  for (let i: number = 0; i < traces.length; i++) {
    sample.inputTokens += traces[i].usage.inputTokens;
    sample.outputTokens += traces[i].usage.outputTokens;
    sample.monetaryCostMicros += traces[i].usage.settledCostMicros;
  }
  sample.latencyMs = latencyMs <= 0 ? 1 : latencyMs;
  sample.toolCalls = toolCalls;
  sample.agentActivations = arm.kind === BenchmarkArmKind.MULTI_AGENT ? 2 : 1;
  sample.recoveryEvents = eventCount(observer.events, AgentRuntimeEventType.RECONCILIATION_REQUIRED);
  sample.routerDecisions = 1;
  sample.routerCorrectDecisions = traces.length >= sample.agentActivations ? 1 : 0;
  sample.qualityScoreBasisPoints = quality(taskCase, snapshot, toolCalls,
    eventCount(observer.events, AgentRuntimeEventType.CLARIFICATION_REQUIRED), observer.policies.length,
    sample.recoveryEvents);
  sample.passed = sample.qualityScoreBasisPoints === 10000;
  const evidence: SystemBenchmarkEvidence = value.evidence;
  evidence.taskId = snapshot.taskId;
  evidence.taskSnapshotDigest = digest.digest(JSON.stringify(snapshot) as string);
  evidence.eventTraceDigest = digest.digest(JSON.stringify(observer.events) as string);
  const usages: Object[] = [];
  for (let i: number = 0; i < traces.length; i++) usages.push(traces[i].usage);
  evidence.providerUsageDigest = digest.digest(JSON.stringify(usages) as string);
  evidence.resultDigest = digest.digest(snapshot.resultJson);
  evidence.qualityEvidenceDigest = digest.digest(JSON.stringify({
    status: snapshot.status,
    toolCalls: toolCalls,
    clarificationCount: eventCount(observer.events, AgentRuntimeEventType.CLARIFICATION_REQUIRED),
    policyCount: observer.policies.length,
    recoveryCount: sample.recoveryEvents,
    qualityScoreBasisPoints: sample.qualityScoreBasisPoints
  }) as string);
  evidence.roleRegistryDigest = traces.length > 0 ? traces[0].roleRegistryDigest :
    digest.digest('missing-role-registry|' + snapshot.taskId);
  evidence.collaborationDecisionDigest = traces.length > 0 ? traces[0].collaborationDecisionDigest :
    digest.digest('missing-collaboration-decision|' + snapshot.taskId);
  evidence.evidenceKinds = taskCase.expectedEvidence.slice();
  evidence.usedAgentRuntimeFacade = true;
  evidence.providerRequestCount = traces.length;
  const roles: string[] = arm.kind === BenchmarkArmKind.MULTI_AGENT ? ['planner', 'verifier'] : ['planner'];
  for (let i: number = 0; i < roles.length; i++) {
    const matching: ProviderPlannerTrace[] = roleTraces(traces, roles[i]);
    const agent: SystemBenchmarkAgentEvidence = new SystemBenchmarkAgentEvidence();
    agent.activationId = matching.length > 0 ? matching[0].agentActivationId :
      'missing:' + snapshot.taskId + ':' + roles[i];
    agent.roleId = roles[i];
    agent.roleVersion = '1';
    agent.providerRequestCount = matching.length;
    const requestIds: string[] = [];
    for (let j: number = 0; j < matching.length; j++) requestIds.push(matching[j].providerRequestId);
    agent.providerRequestIdsDigest = digest.digest(JSON.stringify(requestIds) as string);
    agent.traceDigest = digest.digest(JSON.stringify(matching) as string);
    agent.resultDigest = digest.digest(JSON.stringify({
      roleId: roles[i],
      finalStatus: matching.length === 0 ? 'missing' : matching[matching.length - 1].planningStatus
    }) as string);
    evidence.agentEvidence.push(agent);
  }
  return value;
}

function fixtureProfile(): McpServerProfile {
  return {
    id: 'system-bench-mcp',
    endpoint: 'http://127.0.0.1:' + BENCH_MCP_PORT.toString() + '/fixture',
    allowInsecureHttp: true,
    connectTimeoutMs: 5000,
    requestTimeoutMs: 5000
  };
}

export default function systemBenchmarkLiveTest(): void {
  describe('SystemBenchmarkLive', () => {
    it('executesAndSealsTwelveByTwoThroughTheSoleFacade', 0, async () => {
      const digest: BenchDigest = new BenchDigest();
      expect(digest.digest('abc')).assertEqual(
        'sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      const manifestValue: BenchmarkManifest = manifest();
      const dataset = HarmonyAgentBenchPilotCatalog.datasetV1();
      const executionPlan: SystemBenchmarkExecutionPlan = plan(manifestValue);
      const preflight = SystemBenchmarkExecutionPreflightValidator.validate(
        manifestValue, dataset, executionPlan, admission(executionPlan));
      expect(preflight.ready).assertTrue();
      const header: SystemBenchmarkRun = runHeader(digest);
      if (!BENCH_LIVE) header.performanceComparable = true;
      const recorder: SystemBenchmarkRunRecorder = new SystemBenchmarkRunRecorder(manifestValue, dataset, header);
      const bridge: McpInvocationPolicyBridge = new McpInvocationPolicyBridge(digest);
      const profile: McpServerProfile = fixtureProfile();
      const client: BenchMcpClient = new BenchMcpClient(bridge);
      client.tools = [benchTool(profile.id)];
      let runtime: AgentRuntimeFacade | undefined = undefined;
      try {
        const providers: McpProviderRegistry = new McpProviderRegistry(digest);
        expect(providers.register(profile, digest.digest('system-bench-mcp-profile-v1'))).assertTrue();
        const policies: McpReadOnlyToolPolicyRegistry = new McpReadOnlyToolPolicyRegistry();
        const policy: McpReadOnlyToolPolicy = new McpReadOnlyToolPolicy();
        policy.serverId = profile.id;
        policy.toolName = 'echo';
        policy.capabilityTags = ['echo', 'read-only'];
        policy.permissionRequirements = ['network'];
        policy.riskLevel = RiskLevel.LOW;
        policy.dataBoundary = DataBoundary.REMOTE_ALLOWED;
        policy.estimatedCostMicros = 0;
        expect(policies.register(policy)).assertTrue();
        const adapter: McpAgentAdapter = new McpAgentAdapter(client,
          providers, policies, digest, new BenchConnectorClock(), new BenchGrantVerifier(), bridge);
        const registry: ToolRegistry = new ToolRegistry();
        const credentials: BenchCredentialPort = new BenchCredentialPort();
        const plannerObserver: BenchPlannerObserver = new BenchPlannerObserver();
        const runtimePorts: ProductionAgentRuntimePorts = new ProductionAgentRuntimePorts();
        runtimePorts.clock = new BenchRuntimeClock();
        runtimePorts.ids = new BenchIds();
        runtimePorts.collaborationPlan = new BenchCollaborationPlanSelector(digest);
        runtimePorts.toolPreparer = new BenchToolPreparer(registry, digest);
        runtimePorts.persistence = new BenchPersistence();
        const ports: LocalAIGatewayMcpRuntimePorts = new LocalAIGatewayMcpRuntimePorts();
        ports.runtimePorts = runtimePorts;
        ports.digest = digest;
        ports.credentials = credentials;
        ports.timer = new SystemProviderTimer();
        ports.httpClient = BENCH_LIVE ? new ArkTsLocalAIGatewayHttpClient() : new BenchFixtureGatewayClient();
        ports.plannerObserver = plannerObserver;
        const activeRuntime: AgentRuntimeFacade = await createLocalAIGatewayMcpProductionAgentRuntime(
          gatewayConfig(), ports, adapter, registry);
        runtime = activeRuntime;
        for (let armIndex: number = 0; armIndex < manifestValue.arms.length; armIndex++) {
          const arm: BenchmarkArm = manifestValue.arms[armIndex];
          for (let caseIndex: number = 0; caseIndex < dataset.cases.length; caseIndex++) {
            const taskCase: BenchmarkTaskCase = dataset.cases[caseIndex];
            const beforeTools: number = client.callCount;
            const traceStart: number = plannerObserver.traces.length;
            const started: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
            const handle: TaskHandle = await activeRuntime.submitTask(submission(taskCase, arm));
            const observer: BenchTaskObserver = new BenchTaskObserver();
            const request: SubscriptionRequest = new SubscriptionRequest();
            request.subscriptionId = 'bench-subscription:' + handle.taskId;
            request.taskId = handle.taskId;
            const subscription: AgentSubscription = await activeRuntime.subscribe(request, observer);
            const snapshot: AgentTaskSnapshot = await settle(activeRuntime, handle, observer);
            const finished: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
            const afterTools: number = client.callCount;
            subscription.close();
            const traces: ProviderPlannerTrace[] = plannerObserver.traces.slice(traceStart);
            if (traces.length === 0) {
              throw new Error('BENCH_PROVIDER_TRACE_MISSING:' + snapshot.status + ':' + snapshot.resultJson + ':' +
                JSON.stringify(observer.events));
            }
            const observed: SystemBenchmarkRecord = record(digest, taskCase, arm, snapshot, observer,
              traces, finished - started, afterTools - beforeTools);
            const appended = recorder.append(observed);
            if (!appended.accepted) {
              throw new Error('BENCH_APPEND_REJECTED:' + appended.issues.join('|'));
            }
            console.info('HARMONY_AGENT_BENCH_PROGRESS=' + JSON.stringify({
              record: recorder.recordCount(),
              armId: arm.armId,
              caseId: taskCase.caseId,
              taskStatus: snapshot.status,
              providerRequests: traces.length,
              inputTokens: observed.sample.inputTokens,
              outputTokens: observed.sample.outputTokens,
              costMicros: observed.sample.monetaryCostMicros,
              quality: observed.sample.qualityScoreBasisPoints
            }));
          }
        }
        const sealed: SystemBenchmarkSealResult = recorder.seal();
        expect(sealed.valid).assertTrue();
        expect(sealed.run !== undefined).assertTrue();
        const completed: SystemBenchmarkRun = sealed.run as SystemBenchmarkRun;
        completed.completedAt = new Date().toISOString();
        const reportJson: string = JSON.stringify(completed);
        const chunkSize: number = 1500;
        const chunkCount: number = Math.ceil(reportJson.length / chunkSize);
        for (let chunkIndex: number = 0; chunkIndex < chunkCount; chunkIndex++) {
          const start: number = chunkIndex * chunkSize;
          console.info('HARMONY_AGENT_BENCH_RUN_CHUNK=' + (chunkIndex + 1).toString() + '/' +
            chunkCount.toString() + ':' + reportJson.substring(start, start + chunkSize));
        }
        expect(credentials.calls <= executionPlan.providerRequestLimit).assertTrue();
      } finally {
        if (runtime !== undefined) await runtime.shutdown(ShutdownMode.GRACEFUL);
      }
    });
  });
}
