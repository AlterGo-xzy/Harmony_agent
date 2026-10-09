# File picker — selecting documents, photos, and files

Use this when the blocker is letting the user pick a file, photo, or document from the device.

## Pick a document or folder -> `DocumentViewPicker`
```ts
import { picker } from '@kit.CoreFileKit'
import common from '@ohos.app.ability.common'

async function pickDocument(context: common.UIAbilityContext): Promise<string[]> {
    let documentPicker = new picker.DocumentViewPicker(context)
    try {
        let uris = await documentPicker.select()
        return uris   // ['file://docs/storage/.../file.pdf']
    } catch (err) {
        console.error('Picker failed: ' + (err as Error).message)
        return []
    }
}
```

## Save a file with system picker
```ts
async function saveDocument(context: common.UIAbilityContext): Promise<string[]> {
    let documentPicker = new picker.DocumentViewPicker(context)
    let saveOpts: picker.DocumentSaveOptions = {
        newFileNames: ['report.pdf']
    } as picker.DocumentSaveOptions
    try {
        let uris = await documentPicker.save(saveOpts)
        // uris now contains the save destination; write your file there
        return uris
    } catch (err) {
        return []
    }
}
```

## Select a photo from gallery -> `photoAccessHelper.PhotoViewPicker`
```ts
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import common from '@ohos.app.ability.common'

async function pickPhoto(context: common.UIAbilityContext): Promise<string[]> {
    let photoPicker = new photoAccessHelper.PhotoViewPicker()
    let result = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
    })
    return result.photoUris
}
```
Note: `PhotoViewPicker` in `@ohos.file.picker` is **deprecated** and dynamic-only. Use `@kit.MediaLibraryKit` / `photoAccessHelper.PhotoViewPicker` instead.

## Open the picked file for reading
```ts
import { picker } from '@kit.CoreFileKit'
import { fileIo as fs } from '@kit.CoreFileKit'

async function openPickedFile(context: common.UIAbilityContext): Promise<void> {
    let documentPicker = new picker.DocumentViewPicker(context)
    let uris = await documentPicker.select()
    if (uris.length == 0) { return }
    let file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY)
    // read from file.fd
    fs.closeSync(file.fd)
}
```

## Pick an audio file
```ts
import { picker } from '@kit.CoreFileKit'

async function pickAudio(context: common.UIAbilityContext): Promise<string[]> {
    let audioPicker = new picker.AudioViewPicker(context)
    let uris = await audioPicker.select()
    return uris
}
```

## Verify
- call DocumentViewPicker.select(), confirm the system file picker opens
- pick a file, confirm the returned URI can be opened with fileIo
- call PhotoViewPicker.select() with maxSelectNumber, confirm only that many can be selected

## Return
- file I/O for reading picked files → `35-10-app-model-and-system-apis.md`
- permissions (document picker needs no permission; photo picker needs no permission; file read may need ohos.permission.READ_MEDIA or WRITE_MEDIA)
- if the first direct fix fails → `35-40-ohos-app-failures.md`
