# ArkUI tabs, overlays, and gestures

Use this when the blocker is building tabbed pages, layered layouts, or gesture-driven controls.

## Custom tab bar outside `Tabs`
```text
default tab bar is not the wanted UI
```
Next move:
- keep one `@State selectedIndex`
- render `Tabs` content separately
- render the custom bar as normal `Row` or `Flex`
- update the same index from both the custom bar and the tab animation callback

```ts
@Component
struct TabShell {
    @State selectedIndex: int = 0

    build() {
        Column() {
            Tabs({ index: this.selectedIndex } as TabsOptions) {
                TabContent() {
                    Text('Home')
                }
                TabContent() {
                    Text('Video')
                }
            }
            .barHeight(1)
            .onAnimationStart((index: int, targetIndex: int) => {
                this.selectedIndex = targetIndex
            } as OnTabsAnimationStartCallback)

            Row() {
                Text('Home')
                    .onClick(() => {
                        this.selectedIndex = 0
                    })
                Text('Video')
                    .onClick(() => {
                        this.selectedIndex = 1
                    })
            }
        }
    }
}
```

## Horizontal tab strip that must scroll to the active tab
```text
many tab labels do not fit and the active label should stay visible
```
Next move:
- keep the labels in a horizontal `List`
- scroll to `targetIndex` in `onAnimationStart(...)`

## Overflow menu for many tabs
```text
the strip shows a few tabs, but all tabs still need one compact chooser
```
Next move:
- put the menu body in `@Builder`
- bind it to one button with `.bindMenu(...)`
- update the same tab index from each `MenuItem`

```ts
@Component
struct MenuTabs {
    @State selectedIndex: int = 0
    private controller: TabsController = new TabsController()
    private titles: string[] = ['All', 'Video', 'Photo']

    @Builder
    tabMenu() {
        Menu() {
            ForEach(this.titles, (title: string, index: int) => {
                MenuItem({ content: title } as MenuItemOptions)
                    .onClick(() => {
                        this.selectedIndex = index
                        this.controller.changeIndex(index)
                    })
            })
        }
    }

    build() {
        Row() {
            Image($r('app.media.ic_public_more'))
                .bindMenu(this.tabMenu)
        }
    }
}
```

## Video with custom overlay controls
```text
built-in controls are off and one overlay should start, pause, or seek the video
```
Next move:
- keep one `VideoController`
- update visible UI from `onPrepared`, `onUpdate`, and `onFinish`

```ts
private controller: VideoController = new VideoController()
@State isPlaying: boolean = false

Video({ src: $r('app.media.demo'), controller: this.controller })
    .controls(false)
    .onFinish(() => {
        this.isPlaying = false
    })

Button('Play')
    .onClick(() => {
        this.isPlaying = true
        this.controller.start()
    })
```

## Drag gesture updates a custom progress bar
```text
one dragged control should move with the finger and commit a final value at release
```
Next move:
- store the current visual offset in `@State`
- clamp it inside `onActionUpdate`
- commit the real target action in `onActionEnd`
- keep expensive work and logging out of the update callback

```ts
.gesture(
    PanGesture()
        .onActionUpdate((event: GestureEvent) => {
            this.offsetX = this.baseOffset + event.offsetX
            if (this.offsetX < 0) {
                this.offsetX = 0
            }
            if (this.offsetX > this.maxOffset) {
                this.offsetX = this.maxOffset
            }
        })
        .onActionEnd(() => {
            this.baseOffset = this.offsetX
        }) as GestureType
)
```

## Content should overflow over the custom bottom bar
```text
tab content should visually sit above the custom bar instead of stopping before it
```
Next move:
- reserve the bar height in content sizing
- put `Tabs` above the bar with `zIndex`

```ts
Tabs({ index: this.selectedIndex } as TabsOptions) {
    TabContent() {
        Text('Video')
    }
    .height('calc(100% - 60vp)')
}
.zIndex(2)

Row() {
    Text('Home')
    Text('Video')
}
.margin({ top: '-60vp' } as Margin)
```

## RelativeContainer is the first flattening move
```text
deep nested rows and columns exist only to position overlay elements
```
Next move:
- replace the overlay zone with one `RelativeContainer`

```ts
RelativeContainer() {
    Text()
        .width(this.trackWidth)
        .height(5)
    Text()
        .width(this.progressWidth)
        .height(5)
    Text()
        .width(20)
        .height(20)
        .translate({ x: this.progressWidth } as TranslateOptions)
}
```

## Verify
- click one custom tab
- open one overflow menu item if present
- drag one progress control if present
- prove only the intended UI surface changes

## Return
- if the pattern works but layout or state is wrong -> `30-10-ui-structure-and-state.md`
- if the first direct fix fails -> `30-40-arkui-failures.md`

## Imperative animation -> `this.getUIContext()?.animateTo(...)`
```text
one view must slide, fade, or resize in response to a state change
```
Next move:
- call `this.getUIContext()?.animateTo(...)`
- mutate the animated `@State` inside the closure
- if only `animateToImmediately(...)` resolves, treat it as an immediate fallback

```ts
this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut } as AnimateParam, () => {
    this.indicatorX = targetX
})
```

```ts
animateToImmediately({ duration: 0 } as AnimateParam, () => {
    this.indicatorX = targetX
})
```

## Page-level swipe content → `Swiper`
```text
multiple tab-like pages should swipe horizontally
```
Next move:
```ts
Swiper() {
    ForEach(this.tabs, (t: string) => {
        Text(t)
    })
}
.index(this.currentIndex)
.onChange((i: int) => { this.currentIndex = i })
```

## Keyframe animation -> `keyframeAnimateTo()`
```text
one view must animate through several named steps, not one linear tween
```
```ts
this.getUIContext()?.keyframeAnimateTo({
    duration: 600,
    iterations: 1,
    keyframes: [
        { curve: Curve.Linear, duration: 200, event: (): void => { this.scale = 1.2 } },
        { curve: Curve.EaseOut, duration: 200, event: (): void => { this.scale = 1.0 } },
        { curve: Curve.EaseIn, duration: 200, event: (): void => { this.offsetY = 0 } }
    ]
} as KeyframeAnimateParam, () => {
    this.offsetY = -20  // starting state
})
```

## One element slides in or out -> `.transition()`
```text
a panel or notification appears and disappears with animation
```
```ts
@State showDetail: boolean = false

Column() {
    if (this.showDetail) {
        Text('Detail Panel')
            .transition(TransitionEffect.OPACITY
                .animation({ duration: 300, curve: Curve.EaseOut }))
    }
}
// toggle:
this.showDetail = !this.showDetail
```

```ts
// slide from right:
.transition(TransitionEffect.translate({ x: 300, y: 0 })
    .combine(TransitionEffect.OPACITY))
```

## Shared element transition between pages -> `sharedTransition()`
```text
one image or card on list page should animate smoothly to the same element on the detail page
```
```ts
// Source page:
Image($r('app.media.photo'))
    .sharedTransition('photo-' + this.item.id, { duration: 300 })

// Destination page:
Image($r('app.media.photo'))
    .sharedTransition('photo-' + this.item.id, { duration: 300 })
```

## Tap gesture — single or double
```ts
.gesture(
    TapGesture({ count: 1 })
        .onAction((event: GestureEvent) => {
            this.selectedIndex = this.targetIndex
        })
)
```

## Long-press gesture
```ts
.gesture(
    LongPressGesture({ repeat: false, duration: 500 })
        .onAction((event: GestureEvent) => {
            this.showContextMenu = true
        })
        .onActionEnd(() => {
            this.showContextMenu = false
        })
)
```

## Pinch-to-zoom
```ts
@State scaleValue: double = 1.0
@State lastScale: double = 1.0

.gesture(
    PinchGesture()
        .onActionUpdate((event: GestureEvent) => {
            this.scaleValue = this.lastScale * event.scale
        })
        .onActionEnd(() => {
            this.lastScale = this.scaleValue
        })
)
```

## Swipe to delete
```ts
.gesture(
    SwipeGesture({ direction: SwipeDirection.Horizontal })
        .onAction((event: GestureEvent) => {
            if (event.angle <= 90) {
                this.onDelete()
            }
        })
)
```

## Combine two gestures on one element
```ts
.gesture(
    GestureGroup(GestureMode.Parallel,
        TapGesture({ count: 1 }).onAction(() => { /* tap */ }),
        LongPressGesture({ duration: 500 }).onAction(() => { /* long press */ })
    )
)
```

## Verify
- click one custom tab
- open one overflow menu item if present
- drag one progress control if present
- double-tap fires distinct from single tap
- pinch-zoom resets correctly on release
- prove keyframe animation runs each segment
- prove transition effect fires on state toggle
