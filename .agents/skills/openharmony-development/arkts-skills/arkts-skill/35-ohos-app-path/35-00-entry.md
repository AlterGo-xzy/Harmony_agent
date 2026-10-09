# OpenHarmony app path entry

Load this path only when the blocker is in OpenHarmony app wiring, not ordinary ArkUI tree code.

## Load this path when you see
- `UIAbility`, `Want`, `windowStage.loadContent(...)`
- `common.UIAbilityContext`, global context holder files, ability-owned startup context handoff
- `module.json5`, `app.json5`, `build-profile.json5`, `oh-package.json5`, `hvigorfile.ts`
- `main_pages.json`, `AppScope/`, `entry/`
- `@ohos.hilog`, `@ohos.base`, `@ohos.window` in startup or ability code
- `abilityAccessCtrl`, `pasteboard`, `resourceManager`, `fileIo` / `fs`, `getHostContext()` in non-UI code
- `relationalStore`, `RdbStore`, `ResultSet`, `ValuesBucket`, data/DB storage work
- `preferences`, `getPreferences`, `putSync`, `getSync`, `flushSync`, `@ohos.data.preferences`
- `window.getLastWindow`, `setPreferredOrientation`, `setWindowSystemBarProperties`, `Orientation`
- `http.createHttp`, `http.HttpRequest`, `http.HttpResponse`, `connection.getDefaultNet`
- `notificationManager`, `publish`, `NotificationRequest`, `@kit.NotificationKit`
- `taskpool`, `AsyncLock`, `backgroundTaskManager`, `launch`, `ServiceExtensionAbility`
- `FormExtensionAbility`, `formProvider`, `formBindingData`, `@kit.FormKit`
- `PixelMap`, `ImageSource`, `ImagePacker`, `objectFit`, `ImageFit`, image encoding/decoding
- `media.createAVPlayer`, `AVPlayer`, audio playback
- `sensor.onAccelerometerChange`, `sensor.onGyroscopeChange`, `sensor.onOrientationChange`
- `geoLocationManager`, `getCurrentLocation`, `onLocationChange`, `getLastLocation`
- `zlib`, `request.agent`, `startAbilityForResult`, `Want`, `AsyncLock`, `vibrator`, `distributedDeviceManager`, `abilityConnectionManager`

## Load order inside this path
1. `35-30-project-layout-and-build-surfaces.md` for root/layout/config blockers
2. `35-10-app-model-and-system-apis.md` for `UIAbility` startup and small system-API usage
3. `35-12-window-management.md` for orientation lock, status bar, and system-bar configuration
4. `35-22-background-tasks-and-workers.md` for taskpool, launch, AsyncLock, and background work
5. `35-25-form-widgets.md` for FormExtensionAbility, widget updates, and widget configuration
6. `35-50-rdb-and-storage.md` for relational database open, query, insert, update, or delete work
7. `35-55-preferences-and-light-store.md` for key-value storage with `@ohos.data.preferences`
8. `35-56-notifications.md` for local notification publishing with `@kit.NotificationKit`
9. `35-57-network-and-http.md` for HTTP requests and network connectivity checks
10. `35-58-image-and-media.md` for image loading, PixelMap, image encoding, and ImageFit modes
11. `35-59-audio-playback.md` for AVPlayer audio playback (file, stream, rawfile)
12. `35-60-specialized-ohos-apis.md` for vibrator, distributed collaboration, or modern file-system variants not covered above
13. `35-61-sensors.md` for accelerometer, gyroscope, and orientation sensors
14. `35-62-location.md` for device location, GPS, and continuous tracking
15. `35-63-file-picker.md` for DocumentViewPicker, PhotoViewPicker, and file save dialogs
16. `35-64-camera.md` for camera capture (photo, video, preview)
17. `35-65-biometric-auth.md` for fingerprint and face authentication
18. `35-66-calendar.md` for calendar event add/read/delete
19. `35-67-contacts.md` for contacts — placeholder
20. `35-68-bluetooth.md` for BLE scan, GATT server, and connection
21. `35-69-telephony.md` for SIM info, network state, and telephony observers
22. `35-40-ohos-app-failures.md` after the first direct app-wiring fix fails

## Keep `35-20-abilities-workers-and-background-work.md` separate
`35-22-background-tasks-and-workers.md` replaces this as the active content. Keep the old placeholder for backward reference only.

## Return rule
- if the blocker moves into `@Component`, tabs, lists, gestures, or page-local state, switch to `../30-arkui-path/30-00-entry.md`
- if the blocker is plain ArkTS data shape or typing, return to `../SKILL.md`
