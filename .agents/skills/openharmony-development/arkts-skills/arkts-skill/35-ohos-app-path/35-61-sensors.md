# Device sensors

Use this when the blocker is reading accelerometer, gyroscope, orientation, or other hardware sensor data.

## Load this doc when you see
- `sensor.onAccelerometerChange`, `sensor.onGyroscopeChange`, `onOrientationChange`
- `@ohos.sensor`, `AccelerometerResponse`, `GyroscopeResponse`

## Read accelerometer (tilt, shake detection)
```ts
import sensor from '@ohos.sensor'

@Component
struct TiltPage {
    @State ax: double = 0
    @State ay: double = 0
    @State az: double = 0
    private listening: boolean = false

    startListening(): void {
        if (this.listening) { return }
        this.listening = true
        sensor.onAccelerometerChange((data: sensor.AccelerometerResponse): void => {
            this.ax = data.x
            this.ay = data.y
            this.az = data.z
        }, { interval: 'game' as sensor.SensorFrequency } as sensor.Options)
    }

    stopListening(): void {
        sensor.offAccelerometerChange()
        this.listening = false
    }

    aboutToAppear(): void { this.startListening() }
    aboutToDisappear(): void { this.stopListening() }
}
```

## Read gyroscope (rotation rate)
```ts
import sensor from '@ohos.sensor'

sensor.onGyroscopeChange((data: sensor.GyroscopeResponse): void => {
    // data.x, data.y, data.z — angular velocity in rad/s
    this.gx = data.x
    this.gy = data.y
    this.gz = data.z
}, { interval: 200000000 as long } as sensor.Options)

// Stop:
sensor.offGyroscopeChange()
```

## Read device orientation (tilt relative to earth)
```ts
import sensor from '@ohos.sensor'

sensor.onOrientationChange((data: sensor.OrientationResponse): void => {
    // data.alpha — rotation around z-axis (0-360°, north=0)
    // data.beta  — rotation around x-axis (0 ± 180°, flat=0)
    // data.gamma — rotation around y-axis (0 ± 90°, flat=0)
    this.alpha = data.alpha
    this.beta = data.beta
    this.gamma = data.gamma
}, { interval: 'normal' as sensor.SensorFrequency } as sensor.Options)

sensor.offOrientationChange()
```

## One-shot sensor read — read once, then stop
```ts
// Read the current value once without subscribing:
sensor.onceAccelerometerChange((data: sensor.AccelerometerResponse): void => {
    // fires exactly once
    this.initialTilt = Math.sqrt(data.x * data.x + data.y * data.y + data.z * data.z)
})
```

## Sensor frequency presets
| `SensorFrequency` | Interval | Use case |
|---|---|---|
| `'game'` | 20ms (50 Hz) | Fast motion, games |
| `'ui'` | 60ms (~16 Hz) | UI animations that follow tilt |
| `'normal'` | 200ms (5 Hz) | General orientation, default |

## Always unsubscribe in `aboutToDisappear()`
```text
sensor keeps firing after navigating away — drains battery
```
```ts
@Component
struct SensorPage {
    aboutToDisappear(): void {
        sensor.offAccelerometerChange()
        sensor.offGyroscopeChange()
        sensor.offOrientationChange()
    }
}
```

## Permission required for some sensors
```json
// module.json5 — requestPermissions:
{
  "name": "ohos.permission.ACCELEROMETER",
  "reason": "$string:accel_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
}
```
Sensors requiring permission: `ACCELEROMETER`, `GYROSCOPE`, `ACTIVITY_MOTION` (pedometer), `READ_HEALTH_DATA` (heart rate). Others (orientation, ambient light, proximity, barometer) do not require user-facing permission in most configurations.

## Verify
- subscribe to accelerometer, tilt device, confirm x/y/z values change in real time
- call offAccelerometerChange, confirm no more callbacks fire
- read a one-shot value, confirm exactly one callback fires

## Return
- app lifecycle (aboutToAppear/aboutToDisappear) → `30-20-routing-lifecycle-and-app-flow.md`
- permission requests → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`
