# OpenHarmony app model and system APIs

Production OHOS apps have no `main()`. Entry is `module.json5` → `UIAbility` → `loadContent` → `@Entry @Component`.

Use this when the blocker is startup wiring or one small system API call in app shell code.

## Small Stage app startup shape
```ts
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'
import { BusinessError } from '@ohos.base'
import hilog from '@ohos.hilog'

export default class EntryAbility extends UIAbility {
    onWindowStageCreate(windowStage: window.WindowStage): void {
        windowStage.loadContent('pages/Index', (err: BusinessError<void> | null): void => {
            if (err != null && err.code != 0) {
                hilog.error(0x0000, 'app', 'loadContent failed')
                return
            }
            hilog.info(0x0000, 'app', 'loadContent ok')
        })
    }
}
```

## App starts on the wrong page -> compare `loadContent(...)` against `main_pages.json`
Compare the `loadContent('pages/...')` string with the page file under `entry/src/main/ets/pages/`. Fix the route string before changing page code.

## New page exists but home page should not change -> keep router navigation
Keep `EntryAbility` loading the existing home page. Use router navigation from that page instead of rewriting startup flow.

## Need one startup log or load failure branch
Branch on `err` — same callback pattern shown in the startup shape above (line 14).

## `UIAbility` owns startup, not page-local UI
```text
code mixes page rendering work into `EntryAbility`
```
Next move:
- keep `EntryAbility` for startup and window-stage loading only
- move visible page content back into ArkUI `@Component` pages

## `Want` and launch params appear in lifecycle signatures
```text
you are touching `onCreate(...)` or nearby lifecycle code and want to remove the parameters because they look unused
```
Next move:
- keep the typed lifecycle signature that the app already uses
- only simplify the body if the parameters are truly unused
- do not rewrite lifecycle method shapes into plain helper functions

## Need `UIAbilityContext` outside `EntryAbility`
```text
one helper file or non-page module needs ability context, but only `EntryAbility` owns it directly
```
Next move:
- store the context once in `onCreate(...)`
- expose it through one tiny holder file
- read it from other non-page code instead of passing `EntryAbility` around

```ts
// entryability/GlobalContext.ets
import common from '@ohos.app.ability.common'

export class GlobalContext {
    private abilityContext: common.UIAbilityContext | null = null

    setAbilityContext(context: common.UIAbilityContext): void {
        this.abilityContext = context
    }

    getAbilityContext(): common.UIAbilityContext {
        if (this.abilityContext == null) {
            throw new Error('AbilityContext missing')
        }
        return this.abilityContext
    }
}

export const globalContext = new GlobalContext()
```

```ts
// entryability/EntryAbility.ets
import UIAbility from '@ohos.app.ability.UIAbility'
import Want from '@ohos.app.ability.Want'
import AbilityConstant from '@ohos.app.ability.AbilityConstant'
import { globalContext } from './GlobalContext'

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        globalContext.setAbilityContext(this.context)
    }
}
```

## Context read fails because startup never stored it
```text
helper code calls `getAbilityContext()` and throws immediately
```
Next move:
- verify `EntryAbility.onCreate(...)` stores `this.context`
- verify the app reaches `onCreate(...)` before the helper path runs
- fix startup wiring before editing UI pages

## System API surface in this doc
Keep this doc on small in-app system API calls:
- `UIAbility`
- `windowStage.loadContent(...)`
- `BusinessError`
- `hilog`
- `abilityAccessCtrl` (permission request)
- `pasteboard` (clipboard copy)
- `resourceManager` (rawfile read)
- `fileIo` / `fs` (sandbox file read/write)
- `photoAccessHelper` (save image to gallery)
- `http` (network request)
- `systemDateTime` (timestamp)
- `this.getUIContext().getHostContext()` (get app context from a page)
- `UIContext.getCallingScopeUIContext()` (get UI context from a non-page scope)

## API call fails with "permission denied" -> request permission first
```text
a sensor, file, or health API throws permission-rejected error
```
Next move:
- request the permission before using the API
- put the actual API call inside the success branch of the permission request

```ts
import { abilityAccessCtrl } from '@kit.AbilityKit'
import common from '@ohos.app.ability.common'

function requestHealthPermission(context: common.UIAbilityContext): void {
    let atManager = abilityAccessCtrl.createAtManager()
    atManager.requestPermissionsFromUser(context, ['ohos.permission.READ_HEALTH_DATA'])
        .then((data: abilityAccessCtrl.PermissionRequestResult) => {
            if (data.authResults[0] == 0) {
                // permission granted; now call the API
            }
        })
}
```

## One text or link must be copied to the clipboard -> `pasteboard`
```text
copy action fires but nothing appears in the system clipboard
```
Next move:
- create pasteboard data with the right MIME type
- set it on the system pasteboard

```ts
import pasteboard from '@ohos.pasteboard'

function copyLink(url: string): void {
    let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, url)
    pasteboard.getSystemPasteboard().setData(pasteData)
}
```

## Need a rawfile path or binary content -> `resourceManager.getRawFdSync()`
```text
rawfile path as a string is not enough; the API needs a file descriptor
```
Next move:
- call `context.resourceManager.getRawFdSync('filepath')`
- read the `fd`, `offset`, and `length` from the returned descriptor

```ts
import common from '@ohos.app.ability.common'

function copyRawfileToCache(context: common.UIAbilityContext): void {
    let srcFileDes = context.resourceManager.getRawFdSync('assets/image.png')
    let dstPath = context.cacheDir + '/image.png'
    // read from srcFileDes.fd at srcFileDes.offset, write to dstPath
}
```

## Read or write one file in the app sandbox -> `fileIo`
```text
one file must be read from or written to cache or data dirs
```
Next move:
- open the file with `fs.openSync(...)`
- read or write with `fs.readSync(...)` / `fs.writeSync(...)`
- close when done

```ts
import common from '@ohos.app.ability.common'
import { fileIo as fs, ReadOptions, WriteOptions } from '@kit.CoreFileKit'

function copyToCacheDir(context: common.UIAbilityContext, srcFd: int, srcOffset: number, srcLength: number): void {
    let dstPath = context.cacheDir + '/output.png'
    let dest = fs.openSync(dstPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
    let buf = new ArrayBuffer(4096)
    let off: int = 0

    while (true) {
        let readOpt: ReadOptions = {
            offset: (srcOffset + off) as long,
            length: 4096 as long
        } as ReadOptions
        let len: int = fs.readSync(srcFd, buf, readOpt) as int
        if (len <= 0) {
            break
        }
        let writeOpt: WriteOptions = {
            offset: off as long,
            length: len as long
        } as WriteOptions
        fs.writeSync(dest.fd, buf, writeOpt)
        off = (off + len) as int
        if ((srcLength - off) < 4096) {
            break
        }
    }
    fs.close(dest.fd)
}
```

## Need the app ability context from a page -> `getHostContext()`
```text
page code needs UIAbilityContext but only has UIContext
```
Next move:
- call `this.getUIContext().getHostContext()` and cast to `common.UIAbilityContext`
- use the returned context to access system APIs

```ts
import common from '@ohos.app.ability.common'

let context = this.getUIContext().getHostContext() as common.UIAbilityContext
```

## Need the UI context from outside a page -> `getCallingScopeUIContext()`
```text
non-page code needs to show a dialog or open a picker but `this.getUIContext()` is not available
```
Next move:
- call `UIContext.getCallingScopeUIContext()` as a static method
- check for null before using it

```ts
import { UIContext } from '@ohos.arkui.UIContext'

let uiContext = UIContext.getCallingScopeUIContext()
if (uiContext != null) {
    uiContext.showTextPickerDialog({ range: ['Option A', 'Option B'], selected: 0 })
}
```

## Download a file from a URL -> `http.request()`
```text
one remote image or data blob must be fetched into app storage
```
Next move:
- create an http request
- await the response
- write the response body to cacheDir

```ts
import { http } from '@kit.NetworkKit'
import common from '@ohos.app.ability.common'

async function downloadAndSave(url: string, context: common.UIAbilityContext): Promise<void> {
    let request = http.createHttp()
    let response: http.HttpResponse = await request.request(url)
    if (response.responseCode == http.ResponseCode.OK) {
        let path = context.cacheDir + '/downloaded.png'
        let dest = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
        fs.writeSync(dest.fd, response.result as ArrayBuffer)
        fs.close(dest.fd)
    }
}
```

## Save one image or file to the device gallery -> `photoAccessHelper`
```text
one image path exists on disk but does not appear in the device media gallery
```
Next move:
- open a photo access helper
- create a media asset change request from the file URI
- apply the change

```ts
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import common from '@ohos.app.ability.common'

async function saveToGallery(fileUri: string, context: common.UIAbilityContext): Promise<void> {
    let helper = photoAccessHelper.getPhotoAccessHelper(context)
    let request = photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(context, fileUri)
    if (request != null) {
        await helper.applyChanges(request)
    }
}
```

## Get one timestamp -> `systemDateTime.getTime()`
```text
one value needs a current millisecond timestamp
```
```ts
import systemDateTime from '@ohos.systemDateTime'

let ts = systemDateTime.getTime()
let fileName = 'img_' + ts.toString() + '.png'
```

## Download with progress -> `request.agent`
```ts
import { request } from '@kit.BasicServicesKit'

let config: request.agent.Config = {
    action: request.agent.Action.DOWNLOAD,
    url: 'https://example.com/file.zip',
    filePath: context.cacheDir + '/file.zip'
}
let task = await request.agent.create(context, config)
task.onProgress((p: request.agent.Progress) => {
    this.progress = p.processed / p.total * 100
})
task.onCompleted(() => { /* done */ })
await task.start()
```

## Launch the camera or another ability and get the result -> `startAbilityForResult`
```ts
let want: Want = {
    action: 'ohos.want.action.imageCapture',
    parameters: { 'supportMultiMode': false }
}
context.startAbilityForResult(want, (err, result) => {
    if (result.resultCode == 0) {
        let uri = result.want?.parameters?.['resourceUri'] as string
    }
})
```

## Verify
- start the app once
- prove `loadContent(...)` points at the intended home page
- if startup succeeds and a later page path fails, switch to `../30-arkui-path/30-20-routing-lifecycle-and-app-flow.md`

## Return
Return to `../../SKILL.md` after the system API call resolves the blocker.
