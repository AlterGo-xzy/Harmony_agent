# Web component custom menus

Use this only when the blocker is customizing context menus, selection menus, or edit menus on a `Web` component.

## Shared setup (once per page)
```ts
import { webview } from '@kit.ArkWeb'
import { $rawfile, Web, Menu, MenuItem, WebContextMenuResult } from '@ohos.arkui.component'

@Component
struct W {
    private ctrl: webview.WebviewController = new webview.WebviewController(undefined)
    private menuRes: WebContextMenuResult | undefined = undefined
    @State show: boolean = false

    build() {
        Column() {
            Web({ src: $rawfile('page.html'), controller: this.ctrl })
                // attach one of the menu patterns below here
        }
    }
}
```

## Replace the long-press context menu
```text
long press opens the system menu; you need custom entries
```
Next move: listen to `onContextMenuShow`, build a custom `Menu()`, call result methods:

```ts
.onContextMenuShow((event) => {
    if (event) { this.menuRes = event.result }
    this.show = true; return true
})

@Builder
myMenu() {
    Menu() {
        MenuItem({ content: 'Copy Image' })
            .onClick(() => { this.menuRes?.copyImage(); this.show = false })
        MenuItem({ content: 'Copy' })
            .onClick(() => { this.menuRes?.copy(); this.show = false })
    }
}
```

## Attach one custom menu only for image long-press
```text
image long-press shows custom menu with preview; text selection keeps the system menu
```
Next move: use `.bindSelectionMenu(type, builder, WebResponseType.LONG_PRESS, options)`:

```ts
import { WebElementType, SelectionMenuOptionsExt, MenuType } from '@ohos.arkui.component'

@Builder
imgMenu() {
    Menu() {
        MenuItem({ content: 'Copy' })
            .onClick(() => { this.menuRes?.copyImage(); this.menuRes?.closeContextMenu() })
    }
}

Web({ src: $rawfile('gallery.html'), controller: this.ctrl })
    .bindSelectionMenu(WebElementType.IMAGE, this.imgMenu, WebResponseType.LONG_PRESS, {
        preview: this.preview,
        menuType: MenuType.PREVIEW_MENU
    } as SelectionMenuOptionsExt)
    .onContextMenuShow((event) => {
        if (event) { this.menuRes = event.result; return true }
        return false
    })
```

## Replace the text edit menu with custom entries
```text
Web text input shows default cut/copy/paste; you need custom items
```
Next move: define `EditMenuOptions` with `onCreateMenu` and `onMenuItemClick`:

```ts
import { EditMenuOptions, TextMenuItem, TextMenuItemId } from '@ohos.arkui.component'

onCreateMenu(items: TextMenuItem[]): TextMenuItem[] {
    let filtered = items.filter(i => i.id.equals(TextMenuItemId.COPY))
    filtered.push({ content: 'Translate', id: TextMenuItemId.of('tr') } as TextMenuItem)
    return filtered
}
onMenuItemClick(item: TextMenuItem): boolean {
    return item.id.equals(TextMenuItemId.COPY) ? false : true
}
@State opts: EditMenuOptions = { onCreateMenu: this.onCreateMenu, onMenuItemClick: this.onMenuItemClick } as EditMenuOptions

Web({ src: $rawfile('input.html'), controller: this.ctrl })
    .editMenuOptions(this.opts)
```

## Verify
- long-press an image → custom menu opens; tap each item → action fires once
- long-press plain text → system menu still works

## Return
- basic Web setup issues -> `30-34-input-display-and-web.md`
- if the first direct fix fails -> `30-40-arkui-failures.md`
