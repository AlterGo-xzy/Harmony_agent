# Camera capture

Use this when the blocker is capturing photos or recording video with the device camera.

## Permission and syscap

The full `@kit.CameraKit` / `@ohos.multimedia.camera` pipeline requires `systemapi` privileges and is marked deprecated. For third-party apps, prefer the simplified approach.

## Simplified: launch system camera via `startAbilityForResult`
```ts
import { common } from '@kit.AbilityKit'
import { Want } from '@kit.AbilityKit'

function launchCamera(context: common.UIAbilityContext): void {
    let want: Want = {
        action: 'ohos.want.action.imageCapture',
        parameters: { 'supportMultiMode': false }
    }
    context.startAbilityForResult(want, (err, result): void => {
        if (err != null) { return }
        if (result.resultCode == 0) {
            let uri = result.want?.parameters?.['resourceUri'] as string
            // uri points to the captured photo; display or save it
        }
    })
}
```

## Full camera pipeline (system-privileged apps only)

Only for apps with `systemapi` access. Requires `ohos.permission.CAMERA` and `ohos.permission.MICROPHONE`.

### Initialize
```ts
import { camera } from '@kit.CameraKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 1. Get camera manager
let cameraManager = camera.getCameraManager(context)

// 2. Pick a camera device
let cameras: camera.CameraDevice[] = cameraManager.getSupportedCameras()
let backCamera = cameras.find((c: camera.CameraDevice): boolean =>
    c.cameraPosition == camera.CameraPosition.CAMERA_POSITION_BACK
)
if (backCamera == undefined) { return }

// 3. Get output capability (what this camera supports)
let outputCapability = cameraManager.getSupportedOutputCapability(
    backCamera, camera.SceneMode.NORMAL_PHOTO
)

// 4. Pick preview and photo profiles
let previewProfile = outputCapability.previewProfiles[0]
let photoProfile = outputCapability.photoProfiles[0]

// 5. Create preview output (surfaceId from XComponent)
let previewOutput = cameraManager.createPreviewOutput(previewProfile, this.surfaceId)

// 6. Create photo output
let photoOutput = cameraManager.createPhotoOutput(photoProfile)
```

### Start session
```ts
// 7. Create camera input
let cameraInput = cameraManager.createCameraInput(backCamera)
await cameraInput.open()

// 8. Create and configure session
let session = cameraManager.createSession(
    camera.SceneMode.NORMAL_PHOTO
) as camera.PhotoSession

session.beginConfig()
session.addInput(cameraInput)
session.addOutput(previewOutput)
session.addOutput(photoOutput)
await session.commitConfig()
await session.start()
```

### Capture photo
```ts
let settings: camera.PhotoCaptureSetting = {
    quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
    rotation: camera.ImageRotation.ROTATION_0,
    mirror: false
} as camera.PhotoCaptureSetting

await photoOutput.capture(settings)
// or with callback:
photoOutput.capture(settings, (err: BusinessError): void => {
    if (err != null) { console.error('Capture failed: ' + err.message) }
})
```

### Listen for photo asset (to save the captured file)
```ts
photoOutput.on('photoAssetAvailable', (err: BusinessError, photoAsset: camera.PhotoAsset): void => {
    if (err != null) { return }
    // photoAsset.uri contains the saved photo URI
    // use fileIo to copy or process the file
})
```

### Record video (VideoSession)
```ts
let videoProfile = outputCapability.videoProfiles[0]
let videoOutput = cameraManager.createVideoOutput(videoProfile, videoSurfaceId)

let videoSession = cameraManager.createSession(
    camera.SceneMode.NORMAL_VIDEO
) as camera.VideoSession

videoSession.beginConfig()
videoSession.addInput(cameraInput)
videoSession.addOutput(previewOutput)
videoSession.addOutput(videoOutput)
await videoSession.commitConfig()
await videoSession.start()

// Start recording:
await videoOutput.start()
// Stop recording:
await videoOutput.stop()
```

### Tear down
```ts
await session.stop()
await photoOutput.release()
await previewOutput.release()
await session.release()
await cameraInput.close()
```

## Surface binding for preview -> `XComponent`
```ts
@State surfaceId: string = ''

build() {
    XComponent({ id: 'cameraPreview', type: XComponentType.SURFACE, controller: this.xController })
        .onLoad((): void => {
            this.surfaceId = this.xController.getXComponentSurfaceId()
            // now surfaceId can be passed to createPreviewOutput()
        })
        .width('100%')
        .height('100%')
}
```

## Photo capture on face detection (selfie camera)
```ts
// Use CAMERA_POSITION_FRONT for front camera:
let frontCamera = cameras.find((c: camera.CameraDevice): boolean =>
    c.cameraPosition == camera.CameraPosition.CAMERA_POSITION_FRONT
)
// Set mirror: true for front-facing captures
let settings: camera.PhotoCaptureSetting = {
    quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
    mirror: true   // mirror the front camera photo
} as camera.PhotoCaptureSetting
```

## Verify
- launch the system camera via startAbilityForResult, confirm the captured photo URI is returned
- for system apps: initialize camera pipeline, confirm preview renders on XComponent surface
- capture a photo, confirm photoAssetAvailable fires with the saved URI

## Return
- permission requests → `35-10-app-model-and-system-apis.md`
- XComponent surface binding → `30-34-input-display-and-web.md`
- file I/O for saving captured files → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`
