import mcpAgentAdapterTest from './McpAgentAdapter.test';
import providerConnectorsTest from './ProviderConnectors.test';

export default function testsuite(): void {
  mcpAgentAdapterTest();
  providerConnectorsTest();
}
