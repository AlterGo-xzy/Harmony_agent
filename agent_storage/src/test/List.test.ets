import executionRecoveryStoreTest from './ExecutionRecoveryStore.test';
import deterministicMemoryStoreTest from './DeterministicMemoryStore.test';
import durableMemoryStoreTest from './DurableMemoryStore.test';
import runtimeExecutionRecoveryBridgeTest from './RuntimeExecutionRecoveryBridge.test';

export default function testsuite(): void {
  executionRecoveryStoreTest();
  deterministicMemoryStoreTest();
  durableMemoryStoreTest();
  runtimeExecutionRecoveryBridgeTest();
}
