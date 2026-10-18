import policyGatewayTest from './PolicyGateway.test';
import fakeAgentRuntimeTest from './FakeAgentRuntime.test';
import runtimeCoordinatorTest from './RuntimeCoordinator.test';
import deterministicRoutersTest from './DeterministicRouters.test';
import productionAgentRuntimeTest from './ProductionAgentRuntime.test';
import artifactRegistryTest from './ArtifactRegistry.test';

export default function testsuite(): void {
  policyGatewayTest();
  fakeAgentRuntimeTest();
  runtimeCoordinatorTest();
  deterministicRoutersTest();
  productionAgentRuntimeTest();
  artifactRegistryTest();
}
