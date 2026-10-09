# ArkUI input controls, display, and web

Use this when the blocker is adding a search field, picker, progress bar, save button, web view, or touch/text display options.

## Toggleable inline search bar -> `TextInput` + `@State` query + cached results

`onChange` must write to a `@State` field — setting a `private` (non-`@State`) field
inside `onChange` may be rejected at runtime even if it compiles.
The `@State` query change triggers a rebuild, but the displayed list is a separate
cached `@State` array that only changes on explicit submit — so ForEach keys are stable.

```ts
@Component
struct FeedPage {
    @State showSearch: boolean = false
    @State searchQuery: string = ''        // @State — must be @State for onChange to work
    @State displayFeed: Array<Item> = new Array<Item>()  // cached, only changes on Go
    @State feedVersion: int = 0

    aboutToAppear(): void {
        this.displayFeed = this.copyItems(allItems)
    }

    build(): void {
        Column() {
            if (this.showSearch) {
                Row() {
                    TextInput({ placeholder: 'Search...' })
                        .height(40).layoutWeight(1).fontSize(14)
                        .backgroundColor('#F2F2F7').borderRadius(20)
                        .padding({ left: 16, right: 16 })
                        .onChange((value: string): void => {
                            this.searchQuery = value    // @State — rebuilds, but displayFeed is cached
                        })
                    Column() {
                        Text('Go').fontSize(14).fontWeight('600').fontColor('#FF2442')
                    }
                    .height(36).margin({ left: 8 })
                    .onClick((): void => {
                        this.displayFeed = this.copyItems(this.filterByQuery())
                        this.feedVersion = this.feedVersion + 1
                    })
                }
            }
            Scroll() {
                ForEach(this.displayFeed, (item: Item, idx: int): void => {
                    // render
                }, (item: Item, idx: int): string =>
                    'item-' + item.id.toString() + '-' + this.feedVersion.toString())
            }
        }
    }
    private filterByQuery(): Item[] { /* uses this.searchQuery */ }
    private copyItems(src: Item[]): Array<Item> {
        let arr: Array<Item> = new Array<Item>()
        for (let i: int = 0; i < src.length; i++) { arr.push(src[i]) }
        return arr
    }
}
```

**Why the old pattern crashed**: `let feed = this.filteredPosts()` inside `build()` created a
new array on every keystroke rebuild, ForEach got a different array reference each time,
keys collided → ESE0301 crash. The fix: cache filtered results in `@State displayFeed`,
only recompute on explicit submit. The `@State searchQuery` change still triggers rebuild
but `displayFeed` reference is stable → ForEach stays calm.

**Essential difference from chat**: chat `onChange` sets `@State inputText` which is
also safe because no ForEach depends on it — just a simple string read on Send.

## Search bar filtering a list -> `Search` + `SearchController`
```text
one text input should filter items as the user types
```
Next move:
- bind `SearchController` to the component
- read the current value from `@State changeValue`
- rebuild the visible list from the filter result

```ts
@Component
struct ContactListPage {
    @State changeValue: string = ''
    @State allItems: RowData[] = [
        { name: 'Alice' } as RowData,
        { name: 'Bob' } as RowData
    ]
    private controller: SearchController = new SearchController()

    get filteredItems(): RowData[] {
        if (this.changeValue.length == 0) {
            return this.allItems
        }
        return this.allItems.filter((item: RowData) =>
            item.name.includes(this.changeValue))
    }

    build() {
        Column() {
            Search({
                value: this.changeValue,
                placeholder: 'Search',
                controller: this.controller
            })
                .searchButton('Search')
                .onChange((value: string) => {
                    this.changeValue = value
                })

            List() {
                ForEach(this.filteredItems, (item: RowData) => {
                    ListItem() {
                        Text(item.name)
                    }
                }, (item: RowData) => item.name)
            }
        }
    }
}

type RowData = {
    name: string
}
```

## User must pick one value from a list -> `TextPickerDialog`
```text
one field needs a single choice from a list of options
```
Next move:
- keep the options list in plain array
- open `showTextPickerDialog` on click
- update the selected value in `onAccept`

```ts
@Component
struct SensorPage {
    @State selectedSensor: string = ''
    private sensorNames: string[] = ['Accelerometer', 'Gyroscope', 'Light']

    build() {
        Column() {
            TextInput({ placeholder: 'Select sensor', text: this.selectedSensor })
                .onClick(() => {
                    this.getUIContext().showTextPickerDialog({
                        range: this.sensorNames,
                        selected: 0,
                        onAccept: (result: TextPickerResult): void => {
                            this.selectedSensor = result.value.toString()
                        }
                    } as TextPickerDialogOptions)
                })
        }
    }
}
```

## One async operation needs visible progress -> `Progress`
```text
page download or load shows no feedback to the user while work runs
```
Next move:
- keep one `@State progressValue`
- bind it to a linear `Progress` component
- update the value from the work callback

```ts
@Component
struct DownloadPage {
    @State progressValue: number = 0
    @State isFinished: boolean = false

    build() {
        Column() {
            Progress({
                value: this.progressValue,
                total: 100,
                type: ProgressType.Linear
            } as ProgressOptions)
                .style({
                    strokeWidth: 3,
                    enableSmoothEffect: true
                } as LinearStyleOptions)

            Text(this.isFinished ? 'Done' : 'Loading...')
        }
    }
}
```

## User should save or download one image -> `SaveButton`
```text
one image needs a system-standard save button whose result fires one callback
```
Next move:
- define `SaveButtonOptions` with icon and description
- call the actual save work in the success branch of `onClick`

```ts
@Component
struct ImagePage {
    private saveOptions: SaveButtonOptions = {
        icon: SaveIconStyle.FULL_FILLED,
        text: SaveDescription.SAVE_IMAGE,
        buttonType: ButtonType.Capsule
    } as SaveButtonOptions

    build() {
        Row() {
            SaveButton(this.saveOptions)
                .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                    if (result == SaveButtonOnClickResult.SUCCESS) {
                        // save the image here
                    }
                })
        }
    }
}
```

## Page needs embedded web content -> `Web` + `$rawfile`
```text
one page shows an HTML page bundled as a rawfile
```
Next move:
- create one `webview.WebviewController`
- load the source from `$rawfile('index.html')`

```ts
import { webview } from '@kit.ArkWeb'
import { $rawfile, Web } from '@ohos.arkui.component'

@Component
struct WebPage {
    private controller: webview.WebviewController = new webview.WebviewController(undefined)

    build() {
        Column() {
            Web({
                src: $rawfile('index.html'),
                controller: this.controller
            } as WebOptions)
        }
    }
}
```

## One overlay preview should not intercept touch -> `HitTestMode.None`
```text
one overlay renders a preview that blocks the content behind it
```
Next move:
- set `hitTestBehavior(HitTestMode.None)` on the preview surface

```ts
Web({ src: this.linkUrl, controller: this.previewController })
    .hitTestBehavior(HitTestMode.None)
```

## Text field should support local copy -> `CopyOptions.LocalDevice`
```text
displayed text cannot be selected or copied
```
Next move:
- set `copyOption(CopyOptions.LocalDevice)` on the text node

```ts
Text(this.urlText)
    .copyOption(CopyOptions.LocalDevice)
    .maxLines(1)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
```

## Convert callback pixel values to layout units -> `.px2vp()`
```text
one callback gives pixel values (getPreviewWidth returns px), but layout needs vp
```
Next move:
- call `this.getUIContext().px2vp(pxValue)`

```ts
.onContextMenuShow((event) => {
    let previewWidth = this.getUIContext().px2vp(event.param.getPreviewWidth())
    let previewHeight = this.getUIContext().px2vp(event.param.getPreviewHeight())
})
```

## Verify
- open one text picker and select a value
- prove one progress bar updates during loading
- prove the web page loads in the component

## Return
- Web context menus or selection customisation -> `30-55-web-menus.md`
- if the first direct fix fails -> `30-40-arkui-failures.md`

## Inline image inside text -> `ImageSpan`
```text
one text line needs an icon or image embedded among words
```
Next move:
```ts
Text() {
    Span('hello ')
    ImageSpan($r('app.media.icon'))
        .verticalAlign(ImageSpanAlignment.CENTER)
    Span(' world')
}
```

## Translucent blur background -> `.backgroundBlurStyle()`
```text
one overlay bar should show blurred content behind it
```
Next move:
```ts
Row() { /* bar content */ }
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundBrightness({ rate: 0.5 } as BackgroundBrightnessOptions)
```
