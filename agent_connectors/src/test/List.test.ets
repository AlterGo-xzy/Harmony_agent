import mcpAgentAdapterTest from './McpAgentAdapter.test';
import providerConnectorsTest from './ProviderConnectors.test';
import localAIGatewayTransportTest from './LocalAIGatewayTransport.test';

export default function testsuite(): void {
  mcpAgentAdapterTest();
  providerConnectorsTest();
  localAIGatewayTransportTest();
}
