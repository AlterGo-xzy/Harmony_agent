# Image display and media processing

Use this when the blocker is scaling images, handling image load events, or encoding/decoding image data.

## Image fit modes — control how the image fills its container
```ts
// Fill: stretches to fill, ignores aspect ratio
Image($r('app.media.photo')).objectFit(ImageFit.Fill).width(200).height(200)

// Contain: fit entirely within bounds, keep aspect ratio, letterbox if needed
Image($r('app.media.photo')).objectFit(ImageFit.Contain).width(200).height(200)

// Cover: fill bounds, keep aspect ratio, crop if needed (default)
Image($r('app.media.photo')).objectFit(ImageFit.Cover).width(200).height(200)

// None: display at original size, centered
Image($r('app.media.photo')).objectFit(ImageFit.None).width(200).height(200)
```

## Detect when an image finishes loading -> `onComplete`
```ts
@State imageLoaded: boolean = false
@State imageWidth: int = 0

Image(this.url)
    .width('100%')
    .onComplete((event?: ImageCompleteEvent): void => {
        if (event != undefined) {
            this.imageWidth = event.width
            this.imageLoaded = true
        }
    })
    .onError((err: ImageError): void => {
        console.error('Image load failed: ' + err.message)
    })
```

## Repeat a small texture across a region -> `objectRepeat`
```ts
Image($r('app.media.pattern'))
    .width('100%')
    .height(200)
    .objectRepeat(ImageRepeat.XY)   // tile both directions
```

## Render mode — use image as a tinted template
```ts
Image($r('app.media.icon'))
    .width(24)
    .height(24)
    .fillColor(Color.Red)        // tint the template image
    .renderMode(ImageRenderMode.Template)
```

## Create a PixelMap from an image file -> `ImageSource`
```ts
import image from '@ohos.multimedia.image'

async function loadPixelMap(rawfilePath: string): Promise<image.PixelMap | undefined> {
    let source = image.createImageSource($rawfile(rawfilePath))
    if (source == undefined) { return undefined }
    let decodeOpts: image.DecodingOptions = {
        desiredSize: { width: 200, height: 200 },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    } as image.DecodingOptions
    let pixelMap = await source.createPixelMap(decodeOpts)
    source.release()
    return pixelMap
}
```

## Display a PixelMap in an Image component
```ts
@State avatar: image.PixelMap | undefined = undefined

aboutToAppear(): void {
    loadPixelMap('avatar.jpg').then((pm: image.PixelMap | undefined): void => {
        if (pm != undefined) { this.avatar = pm }
    })
}

build() {
    if (this.avatar != undefined) {
        Image(this.avatar)
            .width(100).height(100)
            .objectFit(ImageFit.Cover)
    }
}
```

## Encode a PixelMap to JPEG/PNG -> `ImagePacker`
```ts
import image from '@ohos.multimedia.image'
import { fileIo as fs } from '@kit.CoreFileKit'

async function savePixelMapAsJpeg(pixelMap: image.PixelMap, filePath: string): Promise<void> {
    let packer = image.createImagePacker()
    let packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 90
    } as image.PackingOption
    let data = await packer.packToData(pixelMap, packOpts)
    let file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
    fs.writeSync(file.fd, data)
    fs.closeSync(file.fd)
    packer.release()
}
```

## Verify
- load an image with onComplete, confirm event fires with correct dimensions
- switch objectFit between Cover and Contain, visually confirm the difference
- load a PixelMap from rawfile, display it in an Image component
- encode a PixelMap to JPEG, verify the file is written

## Return
- image styling (borders, shadows, corners) → `30-15-styling-and-layout.md`
- network image loading → `35-57-network-and-http.md`
- file I/O → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `30-40-arkui-failures.md`
