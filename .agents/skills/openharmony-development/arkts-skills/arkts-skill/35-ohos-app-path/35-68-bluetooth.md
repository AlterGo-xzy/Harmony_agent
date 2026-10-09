# Bluetooth

Use this when the blocker is scanning for BLE devices, connecting to a peripheral, or running a GATT server.

## BLE scan for nearby devices
```ts
import ble from '@ohos.bluetooth.ble'

@Component
struct BleScanner {
    @State devices: Array<ble.BLEDevice> = new Array<ble.BLEDevice>()

    startScan(): void {
        ble.on('BLEDeviceFind', (data: Array<ble.BLEDevice>): void => {
            for (let device of data) {
                if (!this.devices.some((d: ble.BLEDevice): boolean => d.deviceId == device.deviceId)) {
                    this.devices.push(device)
                }
            }
        })
        ble.startBLEScan(null, {
            interval: 0,
            dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER
        } as ble.ScanOptions)
    }

    stopScan(): void {
        ble.stopBLEScan()
        ble.off('BLEDeviceFind')
    }

    aboutToDisappear(): void { this.stopScan() }
}
```

## Create a GATT server — advertise a BLE peripheral service
```ts
import ble from '@ohos.bluetooth.ble'

// 1. Create the server
let gattServer = ble.createGattServer()

// 2. Add a service with a characteristic
let serviceUuid = '0000180D-0000-1000-8000-00805F9B34FB'  // Heart Rate Service
let charUuid = '00002A37-0000-1000-8000-00805F9B34FB'     // Heart Rate Measurement

let service: ble.BLEService = {
    serviceUuid: serviceUuid,
    isPrimary: true,
    characteristicUuids: [charUuid],
    characteristics: [{
        characteristicUuid: charUuid,
        characteristicValue: new Uint8Array([0x00]),
        properties: ble.CharacteristicProperty.READ | ble.CharacteristicProperty.NOTIFY,
        descriptors: []
    }],
    includeServices: []
} as ble.BLEService

gattServer.addService(service)

// 3. Listen for connections
gattServer.on('connectionStateChange', (data: ble.BLEConnectionChangeState): void => {
    if (data.state == ble.ProfileConnectionState.STATE_CONNECTED) {
        console.info('Device connected: ' + data.deviceId)
    }
})

// 4. Start advertising
let advData: ble.AdvertiseSetting = {
    interval: { minInterval: 0, maxInterval: 0 },
    txPower: 0,
    connectable: true
} as ble.AdvertiseSetting

let advManufactureData: ble.ManufactureData = {
    manufactureId: 0xFF,
    manufactureValue: new Uint8Array([0x01, 0x02, 0x03])
} as ble.ManufactureData

ble.startAdvertising(advData, advManufactureData)
```

## Connect to a remote BLE device (client)
```ts
import { connection } from '@ohos.bluetooth.connection'

function connectDevice(deviceId: string): void {
    connection.pairDevice(deviceId)

    connection.on('BLEConnectionStateChange', (data: connection.BLEConnectionState): void => {
        if (data.state == connection.ProfileConnectionState.STATE_CONNECTED) {
            this.deviceId = data.deviceId
        }
    })
}
```

## Verify
- start a BLE scan, confirm nearby advertising devices appear in the list
- add a GATT service, advertise, connect from another device, confirm connectionStateChange fires
- stop scanning, confirm no more device-find callbacks fire

## Return
- permissions: `ohos.permission.ACCESS_BLUETOOTH`, `ohos.permission.MANAGE_BLUETOOTH` (for advertising/connect), `ohos.permission.APPROXIMATELY_LOCATION` (for BLE scan)
- if the first direct fix fails → `35-40-ohos-app-failures.md`
