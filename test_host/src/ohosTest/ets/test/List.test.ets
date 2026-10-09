import deviceSmokeTest from './McpDeviceSmoke.test';
import storageDeviceRecoveryTest from './StorageDeviceRecovery.test';
import memoryDeviceRecoveryTest from './MemoryDeviceRecovery.test';
import batteryStatusDeviceTest from './BatteryStatusDevice.test';

export default function testsuite(): void {
  deviceSmokeTest();
  storageDeviceRecoveryTest();
  memoryDeviceRecoveryTest();
  batteryStatusDeviceTest();
}

