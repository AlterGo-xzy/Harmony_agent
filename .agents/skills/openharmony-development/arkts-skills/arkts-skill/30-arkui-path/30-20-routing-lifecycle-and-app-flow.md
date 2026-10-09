# ArkUI routing, lifecycle, and app flow

Use this when the blocker is page flow inside ArkUI code.

## Navigate between pages
```ts
// push
this.getUIContext().getRouter().pushUrl({ url: 'pages/Detail' })

// back
this.getUIContext().getRouter().back()
```
Make sure the page path is also listed in `main_pages.json`.

## Pass data to a new page
Two approaches:
1. Static class fields (write before push, read in `aboutToAppear`)
2. `params` on the RouterOptions object + `getParams()` on the target page

```ts
// Calling page - static class
RouteParams.filePath = path
this.getUIContext().getRouter().pushUrl({ url: 'pages/EditorPage' })
```

```ts
// Calling page - params
class Payload { item: string = '' }
this.getUIContext().getRouter().pushUrl({ url: 'pages/Edit', params: new Payload() as Object })
```

```ts
// Target page - getParams()
aboutToAppear(): void {
    const p = this.getUIContext().getRouter().getParams() as Payload
    if (p != undefined) { /* use p */ }
}
```

## Router params are undefined on a return visit
```text
getParams() returns undefined when a page is re-entered from back navigation
```
Next move: wrap the read in `setTimeout`:
```ts
aboutToAppear(): void {
    setTimeout(() => {
        const p = this.getUIContext().getRouter().getParams() as Payload
        // use p
    }, 1)
}
```

## Page lifecycle: run work when page becomes visible
```text
data fetch or refresh should happen each time the page is shown, not just once at creation
```
```ts
@Entry
@Component
struct FeedPage {
    @State items: Array<string> = new Array<string>()

    aboutToAppear(): void {
        this.loadData()      // runs once on creation
    }

    onPageShow(): void {
        this.loadData()      // runs each time page is navigated to
    }

    onPageHide(): void {
        // stop audio, pause animations, cancel timers, unsubscribe
    }

    loadData(): void {
        // fetch or compute items
    }
}
```

**Common gap**: existing examples put cleanup (audio `stop()`, timer cancel) only in explicit navigation handlers like back-button `onClick`. If the page is popped via system back gesture, `onBackPress`, or `router.back()` from outside the handler, those callbacks never fire and resources leak. Always duplicate cleanup in `onPageHide()` or `aboutToDisappear()` — the lifecycle hooks fire regardless of how the page is exited. The sensors (`35-61`), bluetooth (`35-68`), and location (`35-62`) skill docs all require `aboutToDisappear()` cleanup for this reason.

## Lifecycle starts async work
```text
startup or page-show work needs await, Promise, or launch
```
Move: keep the lifecycle hook `void`; call a private async method.
```ts
import { launch } from 'std/concurrency'

function computeStartupScore(): int { return 42 }

@Entry
@Component
struct HomePage {
    @State score: int = 0

    aboutToAppear(): void {
        this.loadStartupScore()
    }

    private async loadStartupScore(): Promise<void> {
        this.score = await launch<int>(computeStartupScore)
    }
}
```

## Back press should show confirmation instead of exiting
```text
user presses back on a form with unsaved changes
```
```ts
onBackPress(): boolean | void {
    if (this.hasUnsavedChanges) {
        this.showConfirmDialog = true
        return true    // consumed — stay on page
    }
    // return nothing to let system pop
}
```

## Replace router back stack after login
```text
after login, the login page should not be in the back stack
```
```ts
// push and clear history:
this.getUIContext().getRouter().pushUrl({
    url: 'pages/Home'
}, router.RouterMode.Single)
// or replace the current page:
this.getUIContext().getRouter().replaceUrl({ url: 'pages/Home' })
```

## Callback from an external page or system — reload data
```text
setting page changes a preference, home page is now stale
```
Next move:
- override `onPageShow()` on the home page
- reload data there instead of relying on `aboutToAppear()` alone

## Tab sync
See "Custom tab bar outside Tabs" and "One page owns tabs" in `30-32-tabs-overlays-and-gestures.md`.

## Navigation stack (NavPathStack) for multi-page flows
For `Navigation`-based multi-page navigation with push/pop/replace/clear stack operations → `30-70-navigation-stack.md`.

## Return rule
- component tree shape or decorator state → `30-10-ui-structure-and-state.md`
- tab bars, menus, lists, waterflow, video, gestures → `30-32-tabs-overlays-and-gestures.md`
- list/grid/datasource patterns → `30-30-arkui-components-and-patterns.md`

## Verify
- push one page, back out once
- push with params, read them on the target page
- navigate away and back — confirm onPageShow fires
- press back on unsaved form — confirm dialog appears
