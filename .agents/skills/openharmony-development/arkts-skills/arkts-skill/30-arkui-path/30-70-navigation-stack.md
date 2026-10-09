# Navigation stack

Use this when the blocker is multi-page navigation with `Navigation`, `NavPathStack`, or `NavDestination`.

## Default nav shell shape
```ts
@Entry
@Component
struct AppNav {
    private pageStack: NavPathStack = new NavPathStack()
    @Builder
    pageMap(name: string, param: Object | null | undefined) {
        if (name == 'Home') {
            HomePage()
        } else if (name == 'Detail') {
            DetailPage({ itemId: (param as Record<string, Object>)?.['id'] as int ?? 0 })
        }
    }

    build() {
        Navigation(this.pageStack) {
            HomePage()
        }
        .mode(NavigationMode.Stack)
        .hideTitleBar(true)
        .navDestination(this.pageMap)
    }
}
```

## Navigate from one page to another -> push
```text
one page needs to open a sibling page with data
```
```ts
// from inside any page builder
let ctx = this.getUIContext().getRouter()
// router-based: ctx.pushUrl({ url: 'pages/Detail', params: { id: 42 } })
```
Or, if the page is inside a `Navigation` shell:
```ts
this.pageStack.pushPath(new NavPathInfo('Detail', { id: 42 } as Object))
this.pageStack.pushPathByName('Detail', { id: 42 } as Object, true)
```

## Go back one page -> pop
```text
back button should return to the previous page
```
```ts
this.pageStack.pop(true)
// or pass a result:
this.pageStack.pop({ selectedId: 5 } as Object, true)
```

## Replace the current page instead of pushing
```text
login/onboarding should not remain on the back stack
```
```ts
this.pageStack.replacePath(new NavPathInfo('Home', null))
this.pageStack.replacePathByName('Home', null, true)
```

## Pop to a specific earlier page in the stack
```text
several pages deep; one action should return to a named landing page
```
```ts
this.pageStack.popToName('Home', true)
this.pageStack.popToIndex(0, true)
```

## Clear the entire stack and show one page
```text
logout or reset should erase navigation history
```
```ts
this.pageStack.clear(true)
this.pageStack.pushPath(new NavPathInfo('Login', null))
```

## Intercept the back gesture on one page
```text
unsaved changes — confirm before leaving
```
```ts
NavDestination() {
    Column() {
        Text('Edit')
    }
}
.onBackPressed((): boolean => {
    if (this.hasUnsavedChanges) {
        this.showDiscardDialog = true
        return true   // consumed — stay on page
    }
    return false      // let the system pop
})
```

## Receive a result from a popped page
```text
picker page returns a selection; calling page needs the value
```
```ts
// Push with onPop callback
this.pageStack.pushPathByName('Picker', null, (popInfo: PopInfo): void => {
    let result = popInfo.result as Record<string, Object>
    if (result != undefined) {
        this.selectedId = result['id'] as int
    }
}, true)

// Or read via onResult on the pushed NavDestination:
NavDestination() {
    // page content
}
.onResult((result: Object | null | undefined): void => {
    if (result != undefined) {
        let data = result as Record<string, Object>
        this.selectedId = data['id'] as int
    }
})
```

## One page should show a custom title bar
```text
each page needs a different title or toolbar
```
```ts
NavDestination() {
    Column() {
        Text('Page Content')
    }
}
.title('Detail')
.hideBackButton(false)
```

```ts
// or custom builder title
@Builder
detailTitle() { Row() { Text('Detail').fontSize(18) } }

NavDestination() {
    Column() { Text('Content') }
}
.title(this.detailTitle)
```

## Page map builder is not receiving new param blocks
```text
pushing to the same page name with different params shows stale data
```
Next move:
- read the param inside the destination, not only from the builder:
```ts
@Entry
@Component
struct DetailPage {
    @State itemId: int = 0
    private paramObj: Object | null | undefined = undefined

    aboutToAppear(): void {
        let ctx = this.getUIContext().getRouter()
        let params = ctx.getParams() as Record<string, Object>
        if (params != undefined) {
            this.itemId = params['id'] as int ?? 0
        }
    }
}
```

## NavigationMode for split-pane on wide screens
```text
tablet layout should show list + detail side by side
```
```ts
Navigation(this.pageStack) {
    List() { /* left panel */ }
}
.mode(NavigationMode.Split)
.navBarWidth(320)
.minContentWidth(480)
```

## Verify
- push one page, pop back once
- push two pages, pop-to-index one
- intercept back press and confirm only changed pages show the dialog
- prove result data arrives at the calling page

## Return
- if the blocker is plain page routing without navigation shell → `30-20-routing-lifecycle-and-app-flow.md`
- title bar, tab bars, or toolbar wiring → `30-32-tabs-overlays-and-gestures.md`
- if the first direct fix fails → `30-40-arkui-failures.md`
