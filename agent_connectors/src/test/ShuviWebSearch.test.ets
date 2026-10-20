import { describe, expect, it } from '@ohos/hypium';
import { DataBoundary, RiskLevel } from '@harmony_agent/agent-contracts';
import {
  McpAggregateResult,
  McpCancellationSignal,
  McpCapabilityKind,
  McpCapabilityRef,
  McpClientError,
  McpErrorCode,
  McpProtocolMode,
  McpServerProfile,
  McpTool,
  McpToolResult
} from '@harmony_agent/mcp-client';
import { McpClientToolPort } from '../main/ets/mcp/McpConnectorTypes';
import {
  SHUVI_WEB_SEARCH_SERVER_ID,
  SHUVI_WEB_SEARCH_TOOL_NAME,
  ShuviWebSearchMcpClientToolPort,
  ShuviWebSearchMcpConfig,
  createShuviWebSearchPolicy,
  createShuviWebSearchProfile
} from '../main/ets/mcp/ShuviWebSearch';
import {
  McpCredentialAuthProvider,
  McpCredentialBinding
} from '../main/ets/mcp/McpCredentialAuthProvider';
import { ProviderCredential, ProviderCredentialPort } from '../main/ets/provider/ProviderContracts';

class FixtureClient implements McpClientToolPort {
  calls: number = 0;
  result: McpToolResult = new Object() as McpToolResult;

  listTools(): Promise<McpAggregateResult<McpTool>> {
    const value: McpAggregateResult<McpTool> = { items: [], errors: [] };
    return Promise.resolve(value);
  }

  callTool(_ref: McpCapabilityRef, _argumentsValue: Object,
    _cancellation?: McpCancellationSignal): Promise<McpToolResult> {
    this.calls++;
    return Promise.resolve(this.result);
  }
}

class FixtureCredentials implements ProviderCredentialPort {
  calls: number = 0;

  resolve(providerId: string, scope: string): Promise<ProviderCredential> {
    this.calls++;
    const value: ProviderCredential = new ProviderCredential();
    value.headers.Authorization = 'Bearer ' + providerId + ':' + scope;
    return Promise.resolve(value);
  }
}

function ref(): McpCapabilityRef {
  return {
    serverId: SHUVI_WEB_SEARCH_SERVER_ID,
    kind: McpCapabilityKind.TOOL,
    name: SHUVI_WEB_SEARCH_TOOL_NAME
  };
}

function result(structured: string, content?: string): McpToolResult {
  return {
    content: [{ type: 'text', text: content === undefined ? structured : content }],
    structuredContent: JSON.parse(structured) as Object,
    isError: false
  };
}

export default function shuviWebSearchTest(): void {
  describe('ShuviWebSearch', () => {
    it('createsPinnedLegacyProfileAndExplicitReadOnlyPolicy', 0, () => {
      const config: ShuviWebSearchMcpConfig = new ShuviWebSearchMcpConfig();
      config.estimatedCostMicros = 19;
      const profile: McpServerProfile = createShuviWebSearchProfile(config);
      const policy = createShuviWebSearchPolicy(config);
      expect(profile.id).assertEqual(SHUVI_WEB_SEARCH_SERVER_ID);
      expect(profile.protocolMode).assertEqual(McpProtocolMode.LEGACY);
      expect(profile.retryToolCallOnExpiredSession).assertTrue();
      expect((profile.requestTimeoutMs === undefined ? 0 : profile.requestTimeoutMs) > 15000).assertTrue();
      expect(policy.toolName).assertEqual(SHUVI_WEB_SEARCH_TOOL_NAME);
      expect(policy.riskLevel).assertEqual(RiskLevel.LOW);
      expect(policy.dataBoundary).assertEqual(DataBoundary.REMOTE_ALLOWED);
      expect(policy.permissionRequirements[0]).assertEqual('network.search.public');
      expect(policy.estimatedCostMicros).assertEqual(19);
    });

    it('acceptsOnlyContractValidArgumentsAndEquivalentSuccessPayload', 0, async () => {
      const delegate: FixtureClient = new FixtureClient();
      const payload: string = '{"schemaVersion":"1.0",' +
        '"requestId":"00000000-0000-4000-8000-000000000001","provider":"tavily",' +
        '"query":"ArkUI","searchedAt":"2026-10-20T00:00:00.000Z","results":[' +
        '{"title":"ArkUI","url":"https://example.com/docs","snippet":"Official docs"}]}' ;
      delegate.result = result(payload);
      const client: ShuviWebSearchMcpClientToolPort = new ShuviWebSearchMcpClientToolPort(delegate);
      const accepted: McpToolResult = await client.callTool(ref(), JSON.parse('{"query":"ArkUI","maxResults":3}'));
      expect(accepted.isError).assertFalse();
      expect(delegate.calls).assertEqual(1);

      let inputCode: string = '';
      try {
        await client.callTool(ref(), JSON.parse('{"query":"ArkUI","maxResults":0}'));
      } catch (error) {
        inputCode = error instanceof McpClientError ? error.code : '';
      }
      expect(inputCode).assertEqual(McpErrorCode.INVALID_ARGUMENT);
      expect(delegate.calls).assertEqual(1);
    });

    it('failsClosedWhenSuccessShapeOrDuplicateTextDrifts', 0, async () => {
      const delegate: FixtureClient = new FixtureClient();
      const valid: string = '{"schemaVersion":"1.0",' +
        '"requestId":"00000000-0000-4000-8000-000000000001","provider":"tavily",' +
        '"query":"ArkUI","searchedAt":"2026-10-20T00:00:00.000Z","results":[]}' ;
      delegate.result = result(valid, '{"different":true}');
      const client: ShuviWebSearchMcpClientToolPort = new ShuviWebSearchMcpClientToolPort(delegate);
      let code: string = '';
      try {
        await client.callTool(ref(), JSON.parse('{"query":"ArkUI"}'));
      } catch (error) {
        code = error instanceof McpClientError ? error.code : '';
      }
      expect(code).assertEqual(McpErrorCode.SCHEMA_MISMATCH);
    });

    it('bindsSuccessToTheAuthorizedQueryAndRequestedResultLimit', 0, async () => {
      const delegate: FixtureClient = new FixtureClient();
      const wrongQuery: string = '{"schemaVersion":"1.0",' +
        '"requestId":"00000000-0000-4000-8000-000000000001","provider":"tavily",' +
        '"query":"different","searchedAt":"2026-10-20T00:00:00.000Z","results":[]}' ;
      delegate.result = result(wrongQuery);
      const client: ShuviWebSearchMcpClientToolPort = new ShuviWebSearchMcpClientToolPort(delegate);
      let queryCode: string = '';
      try {
        await client.callTool(ref(), JSON.parse('{"query":"ArkUI"}'));
      } catch (error) {
        queryCode = error instanceof McpClientError ? error.code : '';
      }
      expect(queryCode).assertEqual(McpErrorCode.SCHEMA_MISMATCH);

      const tooMany: string = '{"schemaVersion":"1.0",' +
        '"requestId":"00000000-0000-4000-8000-000000000001","provider":"tavily",' +
        '"query":"ArkUI","searchedAt":"2026-10-20T00:00:00.000Z","results":[' +
        '{"title":"A","url":"https://example.com/a","snippet":"A"},' +
        '{"title":"B","url":"https://example.com/b","snippet":"B"}]}' ;
      delegate.result = result(tooMany);
      let limitCode: string = '';
      try {
        await client.callTool(ref(), JSON.parse('{"query":"ArkUI","maxResults":1}'));
      } catch (error) {
        limitCode = error instanceof McpClientError ? error.code : '';
      }
      expect(limitCode).assertEqual(McpErrorCode.SCHEMA_MISMATCH);
    });

    it('resolvesBoundMcpBearerCredentialAtRequestTime', 0, async () => {
      const credentials: FixtureCredentials = new FixtureCredentials();
      const auth: McpCredentialAuthProvider = new McpCredentialAuthProvider(credentials);
      const binding: McpCredentialBinding = new McpCredentialBinding();
      binding.serverId = SHUVI_WEB_SEARCH_SERVER_ID;
      binding.credentialScope = 'mcp.search.invoke';
      expect(auth.register(binding)).assertTrue();
      const headers: Record<string, string> = await auth.getHeaders(
        createShuviWebSearchProfile(new ShuviWebSearchMcpConfig()), 'tools/call');
      expect(headers.Authorization).assertEqual('Bearer shuvi-web-search:mcp.search.invoke');
      expect(credentials.calls).assertEqual(1);
    });
  });
}
