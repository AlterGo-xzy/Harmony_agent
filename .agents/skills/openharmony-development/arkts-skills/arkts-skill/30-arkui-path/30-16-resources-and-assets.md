# Resources and assets

Use this when the blocker is referencing images, strings, colors, raw files, or resource qualifiers.

## Load an image from app resources -> `$r()`
```ts
Image($r('app.media.logo'))
    .width(100)
    .height(100)

// app.media refers to entry/src/main/resources/base/media/
// Supported formats: png, jpg, svg, gif, webp
```

## Data chooses an image -> choose by asset scale
```text
image comes from app data and a giant `$r(...)` lookup would grow with content
```
Next move:
- for a small fixed icon set, store `Resource` directly in typed ArkTS data
- for production content catalogs, store a rawfile path or file path and load bytes with `resourceManager` or file APIs
- decode bytes to `image.PixelMap` and pass the `PixelMap` to `Image(...)`
- do not build large generated `$r` switch tables for production data

Small fixed icon set imports from static ArkUI component declarations:
```ts
import { Image, Resource, $r } from '@ohos.arkui.component'

final class NavItem {
    title: string
    icon: Resource
    constructor(title: string, icon: Resource) {
        this.title = title
        this.icon = icon
    }
}

let item = new NavItem('Home', $r('app.media.home'))
Image(item.icon)
```

Production rawfile catalog:
```text
Put files under:
entry/src/main/resources/rawfile/covers/reef.png
entry/src/main/resources/rawfile/covers/river.png

Store paths relative to `rawfile/` only:
covers/reef.png
covers/river.png

Do not store:
entry/src/main/resources/rawfile/covers/reef.png
resources/rawfile/covers/reef.png
/rawfile/covers/reef.png
$r('app.media.reef')
```

```ts
import { Image } from '@ohos.arkui.component'
import common from '@ohos.app.ability.common'
import image from '@ohos.multimedia.image'

final class CatalogItem {
    title: string = ''
    rawImagePath: string = 'covers/reef.png'
}

function normalizeRawfilePath(path: string): string {
    if (path.startsWith('/')) { return path.substring(1) }
    return path
}

async function loadRawImage(context: common.UIAbilityContext, rawImagePath: string): Promise<image.PixelMap | undefined> {
    let path = normalizeRawfilePath(rawImagePath)
    let bytes = context.resourceManager.getRawFileContentSync(path)
    let buffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)
    let source = image.createImageSource(buffer)
    let pixelMap = await source.createPixelMap()
    source.release()
    return pixelMap
}

Image(this.coverPixelMap)
```

## Reference a color from resources
```ts
Text('Title')
    .fontColor($r('app.color.primary'))

// Defined in entry/src/main/resources/base/element/color.json:
// { "color": [ { "name": "primary", "value": "#1A73E8" } ] }
```

## Reference a string from resources
```ts
Text($r('app.string.welcome'))
// Defined in entry/src/main/resources/base/element/string.json
```

## Load a bundled raw file -> `$rawfile()`
```ts
// Files in entry/src/main/resources/rawfile/ are accessed by name:
Image($rawfile('logo.png'))

// Web component loading a bundled HTML page:
Web({ src: $rawfile('index.html'), controller: this.webCtrl })

// Video from bundled file:
Video({ src: $rawfile('intro.mp4'), controller: this.videoCtrl })
```

## Read bundled JSON rawfile -> `resourceManager` + JSON route
```text
entry/src/main/resources/rawfile/config.json
```
Next move:
- place JSON under `resources/rawfile/`
- read bytes by rawfile-relative path such as `config.json`
- decode UTF-8 text
- return to `../40-stdlib-path/40-15-json-data-surfaces.md` for parse choice

```ts
import common from '@ohos.app.ability.common'
import util from '@ohos.util'

function readRawJson(context: common.UIAbilityContext, filename: string): string {
    let bytes = context.resourceManager.getRawFileContentSync(filename)
    return util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(bytes)
}
```

## Read a binary rawfile at runtime -> `resourceManager`
```ts
import common from '@ohos.app.ability.common'

function readRawfile(context: common.UIAbilityContext, filename: string): ArrayBuffer | null {
    try {
        let descriptor = context.resourceManager.getRawFdSync(filename)
        let buf = new ArrayBuffer(descriptor.length)
        // read from descriptor.fd at descriptor.offset
        context.resourceManager.closeRawFdSync(filename)
        return buf
    } catch (e) {
        return null
    }
}
```

## String resource with format argument
```ts
// resource: "Hello, %s"
Text($r('app.string.greeting', 'Alice'))
```

## Plural string resource
```ts
// resource: { "one": "%d item", "other": "%d items" }
Text($r('app.plural.item_count', 3))
```

## Resource qualifier directories — density, orientation, dark mode
```text
entry/src/main/resources/
  base/          — default (fallback for all configurations)
  dark/          — dark mode override
  en_US/         — language override
  ldpi/          — low-density device images
  mdpi/          — medium-density
  hdpi/          — high-density
  xhdpi/         — extra-high-density
```
Place images in the density-appropriate directory. The system picks the best match at runtime. No code changes needed — use the same `$r('app.media.xxx')` reference everywhere.

## Media directory vs rawfile directory
| Directory | Access | Best for |
|---|---|---|
| `resources/base/media/` | `$r('app.media.name')` | Images, SVGs, start icons that benefit from qualifier selection |
| `resources/rawfile/` | `$rawfile('name.ext')` | Arbitrary files: HTML, JSON, fonts, videos |
| String/color/float resources | `$r('app.string.name')`, `$r('app.color.name')`, `$r('app.float.name')` | Localizable text, theme colors, design tokens |

## String or color reference resolved at runtime
```ts
// Get the resolved string from a resource reference:
let resolvedStr = this.getUIContext().getHostContext()?.resourceManager
    .getStringSync($r('app.string.welcome'))
```

## Verify
- drop an image into media/, reference with $r(), confirm it displays
- drop an HTML file into rawfile/, load it in a Web component
- create a dark-mode color override, toggle dark mode, confirm color changes

## Return
- styling colors and fonts → `30-15-styling-and-layout.md`
- parse JSON text → `../40-stdlib-path/40-15-json-data-surfaces.md`
- file I/O for non-bundled files → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `30-40-arkui-failures.md`
