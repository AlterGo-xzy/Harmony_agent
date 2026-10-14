import { describe, expect, it } from '@ohos/hypium';
import {
  AgentErrorClass,
  AgentRuntimeEvent,
  AgentTaskSnapshot,
  AgentTaskStatus,
  AuthorizationDecision,
  AuthorizationDecisionType,
  ClarificationRequest,
  ClarificationResponse,
  CollaborationMode,
  DataBoundary,
  ExecutionBudget,
  IdempotencyMode,
  PolicyRequest,
  ReconciliationReport,
  RiskLevel,
  SideEffect,
  TaskHandle,
  TaskSubmission,
  TaskEnvelope,
  ToolInvocation,
  ToolOutcome,
  ToolOutcomeStatus,
  WorkflowGraph,
  WorkflowStepKind,
  WorkflowStep
} from '@harmony_agent/agent-contracts';
import {
  AgentRuntimeFacade,
  AgentRuntimeObserver,
  AgentSubscription,
  DispatchPersistenceContext,
  PlanningRequest,
  PlanningResult,
  PlanningStatus,
  PreparedToolDispatch,
  ProductionAgentRuntimeConfig,
  ProductionAgentRuntimePorts,
  ProductionRuntimePersistencePort,
  ProductionRuntimeRecoverySourcePort,
  RegistryWriteCode,
  RuntimeClockPort,
  RuntimeDurableAuthorityPayload,
  RuntimeIdGeneratorPort,
  RuntimePersistenceCode,
  RuntimePersistenceResult,
  RuntimeRecoveryAuthority,
  RuntimeTaskRecoveryCheckpoint,
  SemanticPlannerPort,
  SubscriptionRequest,
  StepDispatchRequest,
  ToolInvocationPreparerPort,
  ToolRegistry
} from '@harmony_agent/agent-runtime';
import {
  McpAggregateResult,
  McpAuthorizationDecision,
  McpCapabilityKind,
  McpCapabilityRef,
  McpClientError,
  McpContentBlock,
  McpErrorCode,
  McpInvocationContext,
  McpServerFailure,
  McpServerProfile,
  McpTool,
  McpToolResult
} from '@harmony_agent/mcp-client';
import {
  ConnectorClockPort,
  ConnectorDigestPort,
  McpAgentAdapter,
  McpCatalogRefreshResult,
  McpClientToolPort,
  McpGrantVerification,
  McpGrantVerifierPort,
  McpInvocationPolicyBridge,
  McpProviderRegistry,
  McpReadOnlyToolPolicy,
  McpReadOnlyToolPolicyRegistry,
  McpStepDispatchAdapter,
  McpToolOutcomeSinkPort,
  McpRuntimeCompositionError,
  McpRuntimeCompositionErrorCode,
  createMcpProductionAgentRuntime,
  createRecoveredMcpProductionAgentRuntime,
  canonicalJson
} from '../../Index';

class FixtureAggregate implements McpAggregateResult<McpTool> {
  items: McpTool[] = [];
  errors: McpServerFailure[] = [];
}

class FixtureContentBlock implements McpContentBlock {
  type: string = 'text';
  text?: string;
}

class FixtureStructuredContent {
  station: string = 'CN-101';
  celsius: number = 21.4;
}

class FixtureToolResult implements McpToolResult {
  content: McpContentBlock[] = [];
  structuredContent?: Object;
  isError: boolean = false;
}

class FixtureSchemaProperty {
  type: string = '';

  constructor(type: string) {
    this.type = type;
  }
}

class FixtureSchema {
  type: string = 'object';
  properties: Record<string, Object> = new Object() as Record<string, Object>;
  required: string[] = ['station'];
}

class FixtureAnnotations {
  destructiveHint: boolean = true;
}

class FixtureDigest implements ConnectorDigestPort {
  failForArguments: boolean = false;

  digest(value: string): string {
    if (this.failForArguments && value.indexOf('CN-101') >= 0) throw new Error('digest unavailable');
    return 'digest:' + value;
  }
}

class FixtureClock implements ConnectorClockPort {
  private tick: number = 0;

  nowIso(): string {
    this.tick++;
    return this.tick === 1 ? '2026-10-02T12:00:00.000Z' : '2026-10-02T12:00:00.001Z';
  }
}

class FixtureGrantVerifier implements McpGrantVerifierPort {
  allowed: boolean = true;
  fail: boolean = false;
  calls: number = 0;

  verify(_invocation: ToolInvocation): McpGrantVerification {
    this.calls++;
    if (this.fail) throw new Error('grant store unavailable');
    const result: McpGrantVerification = new McpGrantVerification();
    result.allowed = this.allowed;
    result.code = this.allowed ? 'IDEMPOTENT_REPLAY' : 'GRANT_REVOKED';
    return result;
  }
}

class FixtureClient implements McpClientToolPort {
  tools: McpTool[] = [];
  failures: McpServerFailure[] = [];
  callCount: number = 0;
  nextError?: McpClientError;
  private readonly bridge: McpInvocationPolicyBridge;

  constructor(bridge: McpInvocationPolicyBridge) {
    this.bridge = bridge;
  }

  listTools(): Promise<McpAggregateResult<McpTool>> {
    const result: FixtureAggregate = new FixtureAggregate();
    result.items = this.tools.slice();
    result.errors = this.failures.slice();
    return Promise.resolve(result);
  }

  async callTool(ref: McpCapabilityRef, argumentsValue: Object): Promise<McpToolResult> {
    this.callCount++;
    const context: McpInvocationContext = {
      profile: profile(ref.serverId, 'http://127.0.0.1:43127/mcp'),
      tool: this.requireTool(ref),
      arguments: argumentsValue
    };
    const decision: McpAuthorizationDecision = await this.bridge.authorize(context);
    if (!decision.allowed) {
      throw new McpClientError(McpErrorCode.POLICY_DENIED, 'bridge denied', ref.serverId);
    }
    const error: McpClientError | undefined = this.nextError;
    if (error !== undefined) throw error;
    const content: FixtureContentBlock = new FixtureContentBlock();
    content.text = '21.4 C';
    const result: FixtureToolResult = new FixtureToolResult();
    result.content = [content];
    result.structuredContent = new FixtureStructuredContent();
    return result;
  }

  private requireTool(ref: McpCapabilityRef): McpTool {
    for (let index: number = 0; index < this.tools.length; index++) {
      if (this.tools[index].ref.serverId === ref.serverId && this.tools[index].name === ref.name) {
        return this.tools[index];
      }
    }
    throw new Error('fixture tool missing');
  }
}

class FixtureSink implements McpToolOutcomeSinkPort {
  outcome?: ToolOutcome;
  taskId: string = '';
  stepId: string = '';
  dispatchId: string = '';
  private resolveWait?: () => void;
  readonly completed: Promise<void>;

  constructor() {
    this.completed = new Promise<void>((resolve: () => void): void => {
      this.resolveWait = resolve;
    });
  }

  complete(taskId: string, stepId: string, dispatchId: string, outcome: ToolOutcome): void {
    this.taskId = taskId;
    this.stepId = stepId;
    this.dispatchId = dispatchId;
    this.outcome = outcome;
    const resolve: (() => void) | undefined = this.resolveWait;
    if (resolve !== undefined) resolve();
  }
}

class FixtureAssembly {
  readonly digest: FixtureDigest = new FixtureDigest();
  readonly bridge: McpInvocationPolicyBridge = new McpInvocationPolicyBridge(this.digest);
  readonly client: FixtureClient = new FixtureClient(this.bridge);
  readonly providers: McpProviderRegistry = new McpProviderRegistry(this.digest);
  readonly policies: McpReadOnlyToolPolicyRegistry = new McpReadOnlyToolPolicyRegistry();
  readonly grants: FixtureGrantVerifier = new FixtureGrantVerifier();
  readonly adapter: McpAgentAdapter;

  constructor() {
    this.providers.register(profile('weather-cn', 'http://127.0.0.1:43127/mcp'), 'profile-v1');
    const policy: McpReadOnlyToolPolicy = new McpReadOnlyToolPolicy();
    policy.serverId = 'weather-cn';
    policy.toolName = 'station.current';
    policy.capabilityTags = ['weather', 'read-only'];
    policy.permissionRequirements = ['network'];
    policy.riskLevel = RiskLevel.LOW;
    policy.dataBoundary = DataBoundary.REMOTE_ALLOWED;
    policy.estimatedCostMicros = 7;
    this.policies.register(policy);
    this.client.tools = [tool('weather-cn', 'station.current', 'temperature')];
    this.adapter = new McpAgentAdapter(this.client, this.providers, this.policies, this.digest,
      new FixtureClock(), this.grants, this.bridge);
  }
}

function profile(id: string, endpoint: string): McpServerProfile {
  return { id: id, endpoint: endpoint, allowInsecureHttp: true };
}

function tool(serverId: string, name: string, propertyName: string): McpTool {
  const schema: FixtureSchema = new FixtureSchema();
  schema.properties['station'] = new FixtureSchemaProperty('string');
  schema.properties[propertyName] = new FixtureSchemaProperty('boolean');
  return {
    ref: { serverId: serverId, kind: McpCapabilityKind.TOOL, name: name },
    name: name,
    title: 'Current station reading',
    description: 'Reads the latest station measurement',
    inputSchema: schema,
    annotations: new FixtureAnnotations()
  };
}

function invocation(refresh: McpCatalogRefreshResult, digest: ConnectorDigestPort): ToolInvocation {
  const descriptor = refresh.entries[0].descriptor;
  const value: ToolInvocation = new ToolInvocation();
  value.invocationId = 'invocation-weather-1';
  value.taskId = 'task-weather-1';
  value.stepId = 'read-current';
  value.operationId = 'operation-weather-1';
  value.attemptId = 'attempt-weather-1';
  value.toolId = descriptor.toolId;
  value.toolIdentityVersion = descriptor.toolIdentityVersion;
  value.schemaDigest = descriptor.schemaDigest;
  value.argumentsJson = '{"station":"CN-101"}';
  value.argumentsDigest = digest.digest(canonicalJson(JSON.parse(value.argumentsJson) as Object));
  value.authorizationGrantId = 'grant-weather-1';
  value.timeoutMs = 3000;
  value.createdAt = '2026-10-02T11:59:59.000Z';
  return value;
}

class CompositionClock implements RuntimeClockPort {
  nowMs(): number {
    return 1000;
  }
}

class CompositionIds implements RuntimeIdGeneratorPort {
  private next: number = 0;

  nextId(kind: string, requestId: string): string {
    this.next++;
    return kind + ':' + requestId + ':' + this.next.toString();
  }
}

class CompositionPlanner implements SemanticPlannerPort {
  private readonly registry: ToolRegistry;
  lastMode: CollaborationMode = CollaborationMode.MULTI;

  constructor(registry: ToolRegistry) {
    this.registry = registry;
  }

  plan(request: PlanningRequest): PlanningResult {
    this.lastMode = request.collaborationMode;
    return this.ready(request);
  }

  resume(request: PlanningRequest, _response: ClarificationResponse): PlanningResult {
    this.lastMode = request.collaborationMode;
    return this.ready(request);
  }

  replan(request: PlanningRequest): PlanningResult {
    this.lastMode = request.collaborationMode;
    return this.ready(request);
  }

  private ready(request: PlanningRequest): PlanningResult {
    const graph: WorkflowGraph = new WorkflowGraph();
    graph.workflowId = 'workflow:' + request.envelope.taskId;
    graph.taskId = request.envelope.taskId;
    graph.workflowVersion = '1';
    graph.createdAt = '2026-10-14T00:00:00.000Z';
    const step: WorkflowStep = new WorkflowStep();
    step.stepId = 'read-current';
    step.kind = WorkflowStepKind.TOOL;
    step.goal = 'Read the current station measurement';
    step.capabilityRequirements = ['weather', 'read-only'];
    step.expectedOutputSchemaJson = '{"type":"object"}';
    step.riskLevel = RiskLevel.LOW;
    step.sideEffect = SideEffect.NONE;
    step.idempotencyMode = IdempotencyMode.NONE;
    step.retryPolicyRef = 'no-tool-retry';
    step.verificationPolicyRef = 'mcp-result-contract';
    step.timeoutMs = 3000;
    graph.steps = [step];
    graph.entryStepIds = [step.stepId];
    const result: PlanningResult = new PlanningResult();
    result.status = this.registry.activeEntries().length === 1 ? PlanningStatus.READY : PlanningStatus.REJECTED;
    result.workflow = graph;
    result.rejectionCode = result.status === PlanningStatus.READY ? '' : 'MCP_CATALOG_NOT_BOUND';
    return result;
  }
}

class CompositionToolPreparer implements ToolInvocationPreparerPort {
  private readonly registry: ToolRegistry;
  private readonly digest: ConnectorDigestPort;

  constructor(registry: ToolRegistry, digest: ConnectorDigestPort) {
    this.registry = registry;
    this.digest = digest;
  }

  prepare(request: PlanningRequest, step: WorkflowStep, nowMs: number): PreparedToolDispatch {
    const entry = this.registry.activeEntries()[0];
    const argumentsJson: string = '{"station":"CN-101"}';
    const argumentsDigest: string = this.digest.digest(canonicalJson(JSON.parse(argumentsJson) as Object));
    const prepared: PreparedToolDispatch = new PreparedToolDispatch();
    const policy: PolicyRequest = prepared.policyRequest;
    policy.requestId = 'policy:' + request.envelope.taskId + ':' + step.stepId;
    policy.userId = request.envelope.userId;
    policy.taskId = request.envelope.taskId;
    policy.stepId = step.stepId;
    policy.operationId = 'operation:' + request.envelope.taskId + ':' + step.stepId;
    policy.toolId = entry.descriptor.toolId;
    policy.toolIdentityVersion = entry.descriptor.toolIdentityVersion;
    policy.providerId = entry.descriptor.providerId;
    policy.schemaDigest = entry.descriptor.schemaDigest;
    policy.argumentsDigest = argumentsDigest;
    policy.riskLevel = step.riskLevel;
    policy.sideEffect = step.sideEffect;
    policy.estimatedCostMicros = entry.estimatedCostMicros;
    policy.requestedAt = new Date(nowMs).toISOString();
    policy.expiresAtMs = nowMs + 60000;
    policy.expiresAt = new Date(policy.expiresAtMs).toISOString();
    const current: ToolInvocation = prepared.invocation;
    current.invocationId = 'invocation:' + request.envelope.taskId;
    current.taskId = request.envelope.taskId;
    current.stepId = step.stepId;
    current.operationId = policy.operationId;
    current.attemptId = 'attempt-1';
    current.toolId = policy.toolId;
    current.toolIdentityVersion = policy.toolIdentityVersion;
    current.schemaDigest = policy.schemaDigest;
    current.argumentsJson = argumentsJson;
    current.argumentsDigest = argumentsDigest;
    current.idempotencyKey = 'read:' + current.operationId;
    current.authorizationGrantId = '';
    current.timeoutMs = step.timeoutMs;
    current.createdAt = policy.requestedAt;
    return prepared;
  }
}

function compositionPersistenceResult(): RuntimePersistenceResult {
  const result: RuntimePersistenceResult = new RuntimePersistenceResult();
  result.accepted = true;
  result.code = RuntimePersistenceCode.SAVED;
  return result;
}

class CompositionPersistence implements ProductionRuntimePersistencePort, ProductionRuntimeRecoverySourcePort {
  saveCheckpoint(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _authority: RuntimeDurableAuthorityPayload, _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  loadCheckpoint(_taskId: string): Promise<RuntimeTaskRecoveryCheckpoint | undefined> {
    return Promise.resolve(undefined);
  }

  normalizeRecoveredOperation(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  beforeDispatch(_checkpoint: RuntimeTaskRecoveryCheckpoint, _expectedPreviousVersion: number,
    _context: DispatchPersistenceContext | undefined, _authority: RuntimeDurableAuthorityPayload,
    _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  recordDispatchRejected(_context: DispatchPersistenceContext | undefined, _dispatchId: string,
    _rejectionCode: string,
    _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  recordOutcome(_taskId: string, _stepId: string, _dispatchId: string, _outcome: ToolOutcome,
    _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  recordReconciliation(_report: ReconciliationReport, _nowMs: number): Promise<RuntimePersistenceResult> {
    return Promise.resolve(compositionPersistenceResult());
  }

  listRecoveryTaskIds(): Promise<string[]> {
    return Promise.resolve([]);
  }

  loadRecoveryAuthority(_taskId: string): Promise<RuntimeRecoveryAuthority | undefined> {
    return Promise.resolve(undefined);
  }
}

class CompositionObserver implements AgentRuntimeObserver {
  policies: PolicyRequest[] = [];

  onEvent(_event: AgentRuntimeEvent): void {
  }

  onPolicyRequest(request: PolicyRequest): void {
    this.policies.push(request);
  }

  onClarificationRequest(_request: ClarificationRequest): void {
  }
}

function compositionPorts(registry: ToolRegistry, digest: ConnectorDigestPort,
  planner: CompositionPlanner, recovery: boolean = false): ProductionAgentRuntimePorts {
  const ports: ProductionAgentRuntimePorts = new ProductionAgentRuntimePorts();
  ports.clock = new CompositionClock();
  ports.ids = new CompositionIds();
  ports.planner = planner;
  ports.toolPreparer = new CompositionToolPreparer(registry, digest);
  const persistence: CompositionPersistence = new CompositionPersistence();
  ports.persistence = persistence;
  if (recovery) ports.recovery = persistence;
  return ports;
}

function compositionConfig(): ProductionAgentRuntimeConfig {
  const config: ProductionAgentRuntimeConfig = new ProductionAgentRuntimeConfig();
  config.policyVersion = 'policy-v1';
  config.grantTtlMs = 30000;
  return config;
}

function compositionSubmission(): TaskSubmission {
  const budget: ExecutionBudget = new ExecutionBudget();
  budget.maxWallTimeMs = 60000;
  budget.maxInputTokens = 1000;
  budget.maxOutputTokens = 1000;
  budget.maxMonetaryCostMicros = 1000;
  budget.maxToolCalls = 2;
  budget.maxAgentActivations = 1;
  budget.maxRetries = 0;
  budget.maxReplans = 0;
  const value: TaskSubmission = new TaskSubmission();
  value.requestId = 'request-mcp-composition';
  value.userId = 'user-1';
  value.userIntent = 'Read the current station measurement';
  value.locale = 'zh-CN';
  value.timeZone = 'Asia/Shanghai';
  value.referenceTime = '2026-10-14T00:00:00.000Z';
  value.requestedBudget = budget;
  value.submittedAt = value.referenceTime;
  return value;
}

export default function mcpAgentAdapterTest(): void {
  describe('McpAgentAdapter', () => {
    it('normalizesAllowlistedToolAndPreservesMcpIdentity', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();

      expect(refresh.entries.length).assertEqual(1);
      expect(refresh.entries[0].descriptor.toolId).assertEqual('mcp://weather-cn/tool/station.current');
      expect(refresh.entries[0].descriptor.providerId).assertEqual('weather-cn');
      expect(refresh.entries[0].descriptor.capabilityName).assertEqual('station.current');
      expect(refresh.entries[0].descriptor.sideEffect).assertEqual('none');
      expect(refresh.entries[0].requiresNetwork).assertTrue();
      expect(refresh.entries[0].estimatedCostMicros).assertEqual(7);
    });

    it('excludesRemoteToolWithoutControlledReadOnlyPolicy', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      fixture.client.tools.push(tool('weather-cn', 'station.delete', 'force'));

      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();

      expect(refresh.entries.length).assertEqual(1);
    });

    it('invalidatesOldIdentityWhenProviderProfileChanges', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const first: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const oldInvocation: ToolInvocation = invocation(first, fixture.digest);
      const registry: ToolRegistry = new ToolRegistry();
      expect(registry.register(first.entries[0]).code).assertEqual(RegistryWriteCode.CREATED);
      const oldSnapshot: string = registry.snapshot().snapshotDigest;
      fixture.providers.register(profile('weather-cn', 'https://weather.internal.example/mcp'), 'profile-v2');

      const second: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      expect(registry.register(second.entries[0]).code).assertEqual(RegistryWriteCode.UPDATED);
      const outcome: ToolOutcome = await fixture.adapter.invoke(oldInvocation);

      expect(second.invalidatedToolIds.length).assertEqual(1);
      expect(registry.snapshot().snapshotDigest === oldSnapshot).assertFalse();
      expect(second.entries[0].descriptor.toolIdentityVersion === oldInvocation.toolIdentityVersion).assertFalse();
      expect(outcome.errorCode).assertEqual('MCP_TOOL_IDENTITY_STALE');
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('invalidatesOldIdentityWhenSchemaChanges', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const first: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      fixture.client.tools = [tool('weather-cn', 'station.current', 'includeHumidity')];

      const second: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();

      expect(second.invalidatedToolIds.length).assertEqual(1);
      expect(second.entries[0].descriptor.schemaDigest === first.entries[0].descriptor.schemaDigest).assertFalse();
    });

    it('invalidatesOldIdentityWhenControlledProfileVersionChanges', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const first: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      fixture.providers.register(profile('weather-cn', 'http://127.0.0.1:43127/mcp'), 'profile-v2');

      const second: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();

      expect(second.invalidatedToolIds.length).assertEqual(1);
      expect(second.entries[0].descriptor.toolIdentityVersion ===
        first.entries[0].descriptor.toolIdentityVersion).assertFalse();
    });

    it('failsClosedForRejectedGrantBeforeClientCall', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      fixture.grants.allowed = false;

      const outcome: ToolOutcome = await fixture.adapter.invoke(invocation(refresh, fixture.digest));

      expect(outcome.status).assertEqual(ToolOutcomeStatus.DENIED);
      expect(outcome.errorCode).assertEqual('GRANT_REVOKED');
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('failsClosedWhenGrantVerifierThrows', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      fixture.grants.fail = true;

      const outcome: ToolOutcome = await fixture.adapter.invoke(invocation(refresh, fixture.digest));

      expect(outcome.status).assertEqual(ToolOutcomeStatus.DENIED);
      expect(outcome.errorCode).assertEqual('MCP_GRANT_VERIFIER_FAILED');
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('rejectsChangedArgumentsBeforeGrantOrClientCall', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const changed: ToolInvocation = invocation(refresh, fixture.digest);
      changed.argumentsJson = '{"station":"CN-999"}';

      const outcome: ToolOutcome = await fixture.adapter.invoke(changed);

      expect(outcome.errorCode).assertEqual('MCP_ARGUMENTS_DIGEST_MISMATCH');
      expect(fixture.grants.calls).assertEqual(0);
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('reportsDigestPortFailureWithoutCallingClient', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const current: ToolInvocation = invocation(refresh, fixture.digest);
      fixture.digest.failForArguments = true;

      const outcome: ToolOutcome = await fixture.adapter.invoke(current);

      expect(outcome.status).assertEqual(ToolOutcomeStatus.FAILED);
      expect(outcome.errorCode).assertEqual('MCP_ADAPTER_PORT_FAILURE');
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('callsToolExactlyOnceAndMapsStructuredSuccess', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();

      const outcome: ToolOutcome = await fixture.adapter.invoke(invocation(refresh, fixture.digest));

      expect(outcome.status).assertEqual(ToolOutcomeStatus.SUCCEEDED);
      expect(outcome.resultJson).assertEqual('{"celsius":21.4,"station":"CN-101"}');
      expect(fixture.client.callCount).assertEqual(1);
      expect(fixture.grants.calls).assertEqual(1);
    });

    it('doesNotRetryNetworkFailureAndMapsTaxonomy', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      fixture.client.nextError = new McpClientError(McpErrorCode.NETWORK, 'connection closed', 'weather-cn');

      const outcome: ToolOutcome = await fixture.adapter.invoke(invocation(refresh, fixture.digest));

      expect(outcome.status).assertEqual(ToolOutcomeStatus.FAILED);
      expect(outcome.errorClass).assertEqual(AgentErrorClass.NETWORK);
      expect(fixture.client.callCount).assertEqual(1);
    });

    it('policyBridgeDeniesUnarmedAndConsumesMatchingTicket', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const current: ToolInvocation = invocation(refresh, fixture.digest);
      const argumentsValue: Object = JSON.parse(current.argumentsJson) as Object;
      const context: McpInvocationContext = {
        profile: profile('weather-cn', 'http://127.0.0.1:43127/mcp'),
        tool: fixture.client.tools[0],
        arguments: argumentsValue
      };

      const before: McpAuthorizationDecision = await fixture.bridge.authorize(context);
      const armed: boolean = fixture.bridge.arm(current, fixture.client.tools[0].ref, argumentsValue);
      const first: McpAuthorizationDecision = await fixture.bridge.authorize(context);
      const replay: McpAuthorizationDecision = await fixture.bridge.authorize(context);

      expect(before.allowed).assertFalse();
      expect(armed).assertTrue();
      expect(first.allowed).assertTrue();
      expect(replay.allowed).assertFalse();
    });

    it('adaptsRuntimeDispatchPortWithoutExposingTaskControl', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const refresh: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const sink: FixtureSink = new FixtureSink();
      const dispatcher: McpStepDispatchAdapter = new McpStepDispatchAdapter(fixture.adapter, sink);
      const request: StepDispatchRequest = new StepDispatchRequest();
      request.task = new TaskEnvelope();
      request.task.taskId = 'task-weather-1';
      request.step = new WorkflowStep();
      request.step.stepId = 'read-current';
      request.dispatchId = 'dispatch-weather-1';
      request.toolInvocation = invocation(refresh, fixture.digest);

      const receipt = dispatcher.dispatch(request);
      await sink.completed;

      expect(receipt.accepted).assertTrue();
      expect(sink.taskId).assertEqual('task-weather-1');
      expect(sink.stepId).assertEqual('read-current');
      expect(sink.dispatchId).assertEqual('dispatch-weather-1');
      expect(sink.outcome?.status).assertEqual(ToolOutcomeStatus.SUCCEEDED);
    });
  });

  describe('McpProductionRuntime', () => {
    it('composesSingleAgentFacadeAndCompletesAuthorizedReadOnlyMcpTask', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const registry: ToolRegistry = new ToolRegistry();
      const planner: CompositionPlanner = new CompositionPlanner(registry);
      const runtime: AgentRuntimeFacade = await createMcpProductionAgentRuntime(
        compositionConfig(), compositionPorts(registry, fixture.digest, planner), fixture.adapter, registry);

      expect(registry.activeEntries().length).assertEqual(1);
      const handle: TaskHandle = await runtime.submitTask(compositionSubmission());
      expect(planner.lastMode).assertEqual(CollaborationMode.SINGLE);
      expect((await runtime.getTaskSnapshot(handle.taskId)).status)
        .assertEqual(AgentTaskStatus.WAITING_AUTHORIZATION);
      const observer: CompositionObserver = new CompositionObserver();
      const subscriptionRequest: SubscriptionRequest = new SubscriptionRequest();
      subscriptionRequest.subscriptionId = 'subscription:mcp-composition';
      subscriptionRequest.taskId = handle.taskId;
      const subscription: AgentSubscription = await runtime.subscribe(subscriptionRequest, observer);
      expect(observer.policies.length).assertEqual(1);
      const decision: AuthorizationDecision = new AuthorizationDecision();
      decision.commandId = 'authorize:mcp-composition';
      decision.policyRequestId = observer.policies[0].requestId;
      decision.userId = 'user-1';
      decision.taskId = handle.taskId;
      decision.decision = AuthorizationDecisionType.APPROVED;
      decision.decidedAt = '1970-01-01T00:00:01.000Z';
      decision.decidedAtMs = 1000;
      await runtime.provideAuthorization(decision);
      let snapshot: AgentTaskSnapshot = await runtime.getTaskSnapshot(handle.taskId);
      for (let i: number = 0; i < 20 && snapshot.status !== AgentTaskStatus.COMPLETED; i++) {
        await Promise.resolve();
        snapshot = await runtime.getTaskSnapshot(handle.taskId);
      }

      expect(snapshot.status).assertEqual(AgentTaskStatus.COMPLETED);
      expect(fixture.client.callCount).assertEqual(1);
      subscription.close();
    });

    it('failsClosedBeforeFacadeWhenControlledMcpCatalogIsEmpty', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      fixture.client.tools = [];
      const registry: ToolRegistry = new ToolRegistry();
      const planner: CompositionPlanner = new CompositionPlanner(registry);
      let code: McpRuntimeCompositionErrorCode | undefined = undefined;
      try {
        await createMcpProductionAgentRuntime(
          compositionConfig(), compositionPorts(registry, fixture.digest, planner), fixture.adapter, registry);
      } catch (error) {
        if (error instanceof McpRuntimeCompositionError) {
          code = (error as McpRuntimeCompositionError).code;
        }
      }

      expect(code).assertEqual(McpRuntimeCompositionErrorCode.CATALOG_EMPTY);
      expect(registry.snapshot().snapshotVersion).assertEqual(0);
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('failsClosedWithoutPublishingPartialCatalogWhenDiscoveryHasServerFailure', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      fixture.client.failures = [{
        serverId: 'offline-server',
        code: McpErrorCode.NETWORK,
        message: 'fixture network failure'
      }];
      const registry: ToolRegistry = new ToolRegistry();
      const planner: CompositionPlanner = new CompositionPlanner(registry);
      let code: McpRuntimeCompositionErrorCode | undefined = undefined;
      try {
        await createMcpProductionAgentRuntime(
          compositionConfig(), compositionPorts(registry, fixture.digest, planner), fixture.adapter, registry);
      } catch (error) {
        if (error instanceof McpRuntimeCompositionError) {
          code = (error as McpRuntimeCompositionError).code;
        }
      }

      expect(code).assertEqual(McpRuntimeCompositionErrorCode.CATALOG_PARTIAL_FAILURE);
      expect(registry.snapshot().snapshotVersion).assertEqual(0);
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('bindsCatalogBeforeExposingRecoveredFacade', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const registry: ToolRegistry = new ToolRegistry();
      const planner: CompositionPlanner = new CompositionPlanner(registry);
      const runtime: AgentRuntimeFacade = await createRecoveredMcpProductionAgentRuntime(
        compositionConfig(), compositionPorts(registry, fixture.digest, planner, true), fixture.adapter, registry);

      expect(registry.activeEntries().length).assertEqual(1);
      const handle: TaskHandle = await runtime.submitTask(compositionSubmission());
      expect(handle.taskId.length > 0).assertTrue();
      expect((await runtime.getTaskSnapshot(handle.taskId)).status)
        .assertEqual(AgentTaskStatus.WAITING_AUTHORIZATION);
      expect(fixture.client.callCount).assertEqual(0);
    });

    it('refusesPrepopulatedRegistryBeforeCatalogDiscovery', 0, async () => {
      const fixture: FixtureAssembly = new FixtureAssembly();
      const first: McpCatalogRefreshResult = await fixture.adapter.refreshCatalog();
      const registry: ToolRegistry = new ToolRegistry();
      registry.register(first.entries[0]);
      const planner: CompositionPlanner = new CompositionPlanner(registry);
      let code: McpRuntimeCompositionErrorCode | undefined = undefined;
      try {
        await createMcpProductionAgentRuntime(
          compositionConfig(), compositionPorts(registry, fixture.digest, planner), fixture.adapter, registry);
      } catch (error) {
        if (error instanceof McpRuntimeCompositionError) {
          code = (error as McpRuntimeCompositionError).code;
        }
      }

      expect(code).assertEqual(McpRuntimeCompositionErrorCode.REGISTRY_NOT_EMPTY);
      expect(registry.activeEntries().length).assertEqual(1);
      expect(fixture.client.callCount).assertEqual(0);
    });
  });
}
