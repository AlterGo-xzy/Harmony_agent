# Window management

Use this when the blocker is window-level behavior: orientation lock, status bar appearance, or system-bar configuration.

## Lock orientation -> `setPreferredOrientation()`
```ts
import { window } from '@kit.ArkUI'
import common from '@ohos.app.ability.common'

async function lockPortrait(context: common.UIAbilityContext): Promise<void> {
    let win = await window.getLastWindow(context)
    await win.setPreferredOrientation(window.Orientation.PORTRAIT)
}

// Allow free rotation:
async function allowRotation(context: common.UIAbilityContext): Promise<void> {
    let win = await window.getLastWindow(context)
    await win.setPreferredOrientation(window.Orientation.AUTO_ROTATION)
}
```

## Light or dark status bar icons
```ts
async function setLightStatusBar(context: common.UIAbilityContext): Promise<void> {
    let win = await window.getLastWindow(context)
    await win.setWindowSystemBarProperties({
        statusBarColor: '#FFFFFF',
        isStatusBarLightIcon: true     // dark icons on light background
    } as window.SystemBarProperties)
}

async function setDarkStatusBar(context: common.UIAbilityContext): Promise<void> {
    let win = await window.getLastWindow(context)
    await win.setWindowSystemBarProperties({
        statusBarColor: '#1A1A1A',
        isStatusBarLightIcon: false    // light icons on dark background
    } as window.SystemBarProperties)
}
```

## Hide or show the navigation bar
```ts
async function showNavigationBar(context: common.UIAbilityContext, show: boolean): Promise<void> {
    let win = await window.getLastWindow(context)
    await win.setWindowSystemBarProperties({
        navigationBarColor: show ? '#FFFFFF' : '#00000000',
        isNavigationBarLightIcon: show ? true : false
    } as window.SystemBarProperties)
}
```

## Call from EntryAbility on startup
```ts
import UIAbility from '@ohos.app.ability.UIAbility'
import { window } from '@kit.ArkUI'

export default class EntryAbility extends UIAbility {
    onWindowStageCreate(windowStage: window.WindowStage): void {
        windowStage.loadContent('pages/Index', (err): void => {
            if (err != null) { return }

            let mainWindow = windowStage.getMainWindowSync()
            mainWindow.setPreferredOrientation(window.Orientation.PORTRAIT)
            mainWindow.setWindowSystemBarProperties({
                statusBarColor: '#FFFFFF',
                isStatusBarLightIcon: true
            } as window.SystemBarProperties)
        })
    }
}
```

## Get context from a page — call window APIs from any component
```ts
import common from '@ohos.app.ability.common

async function lockOrientationFromPage(pageCtx: object): Promise<void> {
    let ctx = pageCtx as common.UIAbilityContext
    if (ctx == null) { return }
    let win = await window.getLastWindow(ctx)
    await win.setPreferredOrientation(window.Orientation.LANDSCAPE)
}

// Usage from within a page:
aboutToAppear(): void {
    let ctx = this.getUIContext().getHostContext()
    lockOrientationFromPage(ctx)
}
```

## Orientation values
| `window.Orientation` | Meaning |
|---|---|
| `PORTRAIT` | Lock to normal portrait |
| `LANDSCAPE` | Lock to normal landscape |
| `PORTRAIT_INVERTED` | Lock to inverted portrait |
| `LANDSCAPE_INVERTED` | Lock to inverted landscape |
| `AUTO_ROTATION` | Free rotation, all four directions |
| `AUTO_ROTATION_PORTRAIT` | Free rotation, portrait only |
| `AUTO_ROTATION_LANDSCAPE` | Free rotation, landscape only |

## Verify
- lock to portrait in EntryAbility, rotate device, confirm no rotation
- change status bar color, verify it updates
- call from a page via getHostContext(), confirm orientation locks

## Return
- app startup wiring → `35-10-app-model-and-system-apis.md`
- page-level styling and layout → `30-15-styling-and-layout.md`
- safe area handling → `30-15-styling-and-layout.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`
