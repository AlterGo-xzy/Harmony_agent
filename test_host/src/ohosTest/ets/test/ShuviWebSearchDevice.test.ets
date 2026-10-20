import { describe, expect, it } from '@ohos/hypium';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import {
  ConnectorDigestPort,
  McpProviderRegistry,
  McpReadOnlyToolPolicyRegistry,
  ShuviWebSearchMcpConfig,
  connectShuviWebSearchMcp
} from '@harmony_agent/agent-connectors';
import {
  McpAuthorizationDecision,
  McpCapabilityKind,
  McpClientManager,
  McpInvocationContext,
  McpInvocationPolicy,
  McpToolResult
} from '@harmony_agent/mcp-client';

function searchUrl(): string {
  const parameters: Record<string, string> = abilityDelegatorRegistry.getArguments().parameters;
  const directValue: string | undefined = parameters['searchUrl'];
  if (directValue !== undefined) return directValue;
  const literalValue: string | undefined = parameters['-s searchUrl'];
  return literalValue === undefined ? '' : literalValue;
}

class DeviceDigest implements ConnectorDigestPort {
  digest(value: string): string {
    return 'device-shuvi-search:' + value;
  }
}

/** Test-only policy; production uses McpInvocationPolicyBridge and a Runtime grant. */
class DeviceAllowSearchPolicy implements McpInvocationPolicy {
  authorize(context: McpInvocationContext): Promise<McpAuthorizationDecision> {
    const decision: McpAuthorizationDecision = {
      allowed: context.profile.id === 'shuvi-web-search' && context.tool.name === 'web_search'
    };
    return Promise.resolve(decision);
  }
}

export default function shuviWebSearchDeviceTest(): void {
  describe('ShuviWebSearchDevice', () => {
    it('discoversSearchAndReturnsStructuredConfigurationFailureWithoutUpstreamCall', 0, async () => {
      const endpoint: string = searchUrl();
      expect(endpoint.length > 0).assertTrue();
      const manager: McpClientManager = new McpClientManager({
        clientName: 'harmony_agent Shuvi Search Device Test',
        clientVersion: '0.2.0',
        debugBuild: true,
        invocationPolicy: new DeviceAllowSearchPolicy()
      });
      const digest: DeviceDigest = new DeviceDigest();
      const providers: McpProviderRegistry = new McpProviderRegistry(digest);
      const policies: McpReadOnlyToolPolicyRegistry = new McpReadOnlyToolPolicyRegistry();
      const config: ShuviWebSearchMcpConfig = new ShuviWebSearchMcpConfig();
      config.endpoint = endpoint;
      try {
        await connectShuviWebSearchMcp(manager, providers, policies, config);
        const catalog = await manager.listTools();
        expect(catalog.errors.length).assertEqual(0);
        expect(catalog.items.length).assertEqual(1);
        expect(catalog.items[0].name).assertEqual('web_search');
        const result: McpToolResult = await manager.callTool({
          serverId: 'shuvi-web-search',
          kind: McpCapabilityKind.TOOL,
          name: 'web_search'
        }, JSON.parse('{"query":"HarmonyOS ArkUI 官方开发文档","maxResults":1}'));
        expect(result.isError).assertTrue();
        const envelope: Record<string, Object> = result.structuredContent as Record<string, Object>;
        const error: Record<string, Object> = envelope['error'] as Record<string, Object>;
        expect(envelope['schemaVersion']).assertEqual('1.0');
        expect(error['code']).assertEqual('CONFIGURATION');
      } finally {
        await manager.disconnectAll();
      }
    });
  });
}
