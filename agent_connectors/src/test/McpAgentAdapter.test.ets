import { describe, expect, it } from '@ohos/hypium';
import {
  AgentErrorClass,
  DataBoundary,
  RiskLevel,
  TaskEnvelope,
  ToolInvocation,
  ToolOutcome,
  ToolOutcomeStatus,
  WorkflowStep
} from '@harmony_agent/agent-contracts';
import {
  RegistryWriteCode,
  StepDispatchRequest,
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
}
