# Scroll containers, pull-to-refresh, and scroll control

Use this when the blocker is making a scrollable area, controlling scroll position, or adding pull-to-refresh.

## Scrollable column -> `Scroll`
```ts
private scroller: Scroller = new Scroller()

Scroll(this.scroller) {
    Column() {
        ForEach(this.items, (item: string) => {
            Text(item).height(48).width('100%')
        }, (item: string) => item)
    }
}
.width('100%')
.scrollable(ScrollDirection.Vertical)
.scrollBar(BarState.Auto)
```

## Scroll to a specific position programmatically
```ts
this.scroller.scrollTo({ xOffset: 0, yOffset: 200 } as ScrollOptions)
// or scroll to the edge:
this.scroller.scrollEdge(Edge.Bottom)
```

## Scroll to a specific item by index
```ts
this.scroller.scrollToIndex(5, true, ScrollAlign.START)
```

## Detect when scroll reaches the edge — load more
```ts
Scroll(this.scroller) {
    // content
}
.onScrollEdge((side: Edge): void => {
    if (side == Edge.Bottom) {
        this.loadMore()   // pagination
    }
})
```

## Track scroll position
```ts
@State scrollY: double = 0

Scroll(this.scroller) {
    // content
}
.onDidScroll((xOffset: double, yOffset: double, scrollState: ScrollState): void => {
    this.scrollY = yOffset
})
```

## Nested scroll — inner list must delegate to outer scroll
```ts
Scroll() {
    Column() {
        Text('Header')
        List() { /* inner items */ }
            .nestedScroll({
                scrollForward: NestedScrollMode.SELF_FIRST,
                scrollBackward: NestedScrollMode.SELF_FIRST
            } as NestedScrollOptions)
    }
}
```

## Pull-to-refresh -> `Refresh`
```ts
@Component
struct FeedPage {
    @State isRefreshing: boolean = false
    private scroller: Scroller = new Scroller()

    build() {
        Refresh({ refreshing: $$this.isRefreshing } as RefreshOptions) {
            Scroll(this.scroller) {
                Column() {
                    ForEach(this.items, (item: string) => {
                        Text(item).height(64)
                    }, (item: string) => item)
                }
            }
        }
        .onRefreshing((): void => {
            this.loadData()   // fetch new data, then set isRefreshing = false
        })
        .onStateChange((state: RefreshStatus): void => {
            // state: Inactive → Drag → OverDrag → Refresh → Done
        })
    }

    loadData(): void {
        // simulate network:
        this.items = ['Fresh', 'Data']
        this.isRefreshing = false
    }
}
```

## Horizontal scroll — gallery or tab strip
```ts
Scroll() {
    Row() {
        ForEach(this.images, (img: ResourceStr) => {
            Image(img).width(160).height(120).margin(4)
        }, (img: ResourceStr, idx: int) => idx.toString())
    }
}
.scrollable(ScrollDirection.Horizontal)
.scrollBar(BarState.Off)
```

## Verify
- scroll a long list, confirm scroll bar appears and content moves
- call scrollToIndex, confirm the target item is visible
- pull down on a Refresh-wrapped scroll, confirm onRefreshing fires
- add onScrollEdge with loadMore, confirm pagination triggers at bottom

## Return
- list patterns with LazyForEach → `30-30-arkui-components-and-patterns.md`
- form controls that need scrolling → `30-35-form-controls.md`
- if the first direct fix fails → `30-40-arkui-failures.md`
