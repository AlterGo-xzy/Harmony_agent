# Specialized OHOS system APIs

Brief canonical references for OHOS APIs that are grounded in static samples but too specialized for the main system-API doc. Use this when the blocker specifically mentions one of these APIs.

## File compression -> `@ohos.zlib`
See `../35-ohos-app-path/35-50-rdb-and-storage.md` ("Compress or decompress one sandbox file").

## Modern file system -> `@ohos.file.fs`
Newer module alternative to the `fileIo`/`@kit.CoreFileKit` pattern shown in `35-10-app-model-and-system-apis.md`. Signature-compatible for common operations:
```ts
import fs from '@ohos.file.fs'

let file: fs.File = fs.openSync('/path/to/file', fs.OpenMode.READ_WRITE)
let buf = new ArrayBuffer(4096)
fs.readSync(file.fd, buf, { offset: 0 as long, length: 4096 as long } as fs.ReadOptions)
fs.writeSync(file.fd, buf, { offset: 0 as long, length: 4096 as long } as fs.WriteOptions)
fs.closeSync(file.fd)
fs.accessSync('/path/to/file')          // check existence
fs.mkdirSync('/path/to/dir')            // create directory
fs.listFileSync('/path/to/dir')         // list files
```

## Haptic vibration -> `@kit.SensorServiceKit` / `vibrator`
```ts
import { vibrator } from '@kit.SensorServiceKit'

vibrator.startVibration({
    type: 'time',
    duration: 1000
}, { usage: 'alarm' })

vibrator.stopVibration(vibrator.VibratorStopMode.VIBRATOR_STOP_MODE_TIME)

// File-based haptic from rawfile:
let fd = context.resourceManager.getRawFdSync('haptic.json')
vibrator.startVibration({
    type: 'file',
    hapticFd: { fd: fd.fd, offset: fd.offset, length: fd.length }
}, { usage: 'alarm' })
context.resourceManager.closeRawFdSync('haptic.json')
```

## Haptic info queries
```ts
let info: vibrator.VibratorInfo = vibrator.getVibratorInfoSync()
vibrator.isSupportEffect('haptic.light')
vibrator.isHdHapticSupported()
vibrator.getEffectInfoSync('haptic.light')
vibrator.onVibratorStateChange((state: string) => { /* started/stopped */ })
```

## Distributed peer-to-peer collaboration -> `@kit.DistributedKit`

Status: placeholder. `abilityConnectionManager` and `distributedDeviceManager` are grounded by StaticCollabSample but the complete P2P collaboration surface (create session, connect, send message/data, lifecycle) requires a full sample to be guided safely. The import shapes are:
```ts
import { abilityConnectionManager } from '@kit.DistributedKit'
import { distributedDeviceManager } from '@kit.DistributedKit'
```
Core surface: `createAbilityConnectionSession()`, `connect()`, `disconnect()`, `sendMessage()`, `sendData()`, `onConnect()`, `onDisconnect()`, `onReceiveMessage()`, `onReceiveData()`, plus device discovery via `getAvailableDeviceListSync()` and collaboration lifecycle hooks in `UIAbility.onCollaborate()`.

## Verify
- confirm the API resolves from the import path shown
- confirm the call pattern matches the static sample that grounds it

## Return
- API found here -> return to `35-10-app-model-and-system-apis.md` or `../30-arkui-path/30-00-entry.md`
- file or DB storage issues -> `35-50-rdb-and-storage.md`
