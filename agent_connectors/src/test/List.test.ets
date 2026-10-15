import mcpAgentAdapterTest from './McpAgentAdapter.test';
import providerConnectorsTest from './ProviderConnectors.test';
import localAIGatewayTransportTest from './LocalAIGatewayTransport.test';
import providerSemanticPlannerTest from './ProviderSemanticPlanner.test';

export default function testsuite(): void {
  mcpAgentAdapterTest();
  providerConnectorsTest();
  localAIGatewayTransportTest();
  providerSemanticPlannerTest();
}
