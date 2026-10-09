# ArkUI lists, grids, and datasource patterns

Use this when the blocker is structuring one lazy list, waterflow, linked scroller, tree, calendar grid, gallery grid, or search-backed list.

## Gallery grid: two columns with `Flex({ wrap: FlexWrap.Wrap })`
```text
need a 2-column grid of image tiles with square cards
```
```ts
import { Flex, FlexWrap, ForEach, Image, ImageFit, Text } from '@ohos.arkui.component'

Flex({ wrap: FlexWrap.Wrap }) {
    ForEach(this.names, (name: string, index: int): void => {
        Column() {
            Image($rawfile(this.paths[index]))
                .width('100%')
                .aspectRatio(1)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
            Text(name)
                .fontSize(12)
                .margin({ top: 8 })
                .maxLines(1)
        }
        .width('48%')
        .padding(10)
    }, (name: string, index: int): string => index.toString())
}
.width('100%')
```

## Image constructor — `$rawfile` path plus optional key
```ts
Image($rawfile('creature_images/clownfish.png'))
// optional second parameter — reuse key for rendering:
Image($rawfile(path), path)   // second param is a stability key, not alt text
```
The second parameter is an optional rendering key for component reuse, not alt text or URI. Use `$rawfile(path)` for single-arg Image.

## `FlexAlign` import
```ts
import { FlexAlign } from '@ohos.arkui.component'
```

## WaterFlow fed by a datasource
```text
grid-like page should lazily render cards from one datasource
```
Next move:
- keep the datasource on the page
- render `WaterFlow { LazyForEach(...) { FlowItem() { ... } } }`
- give one stable key extractor

```ts
WaterFlow() {
    LazyForEach(this.source, (item: SceneCard) => {
        FlowItem() {
            SceneCardView({ card: item })
        }
    }, (item: SceneCard, index: int) => item.id)
}
```

## Expand/collapse tree section
```text
click should open one nested section and rerender only that data path
```
Next move:
- flip `expand`
- call `updateData(index, node)`

```ts
ListItem() {
    Text(node.title)
}
.onClick(() => {
    node.expand = !node.expand
    this.source.updateData(index, node)
})
```

## Lazy item datasource pattern
```text
list or waterflow code wants a mutable array but rerender needs indexed notifications
```
Next move:
- implement `IDataSource<T>` with one listener list and one update helper

```ts
export class ArticleSource<T> implements IDataSource<T> {
    private items: T[] = []
    private listeners: DataChangeListener[] = []

    totalCount(): int {
        return this.items.length
    }

    getData(index: int): T {
        return this.items[index]
    }

    registerDataChangeListener(listener: DataChangeListener): void {
        this.listeners.push(listener)
    }

    unregisterDataChangeListener(listener: DataChangeListener): void {
        let index = this.listeners.indexOf(listener)
        if (index >= 0) {
            this.listeners.splice(index, 1)
        }
    }

    updateData(index: number, item: T): void {
        this.items.splice(index.toInt(), 1, item)
        this.listeners.forEach((listener: DataChangeListener) => {
            listener.onDataChange(index.toInt())
        })
    }
}
```

## Two lists must stay linked while either side scrolls
```text
left category list and right content list drift apart or fight each other during scroll
```
Next move:
- give each `List` its own `Scroller`
- keep one `@State currentIndex`
- set one guard flag before programmatic scroll
- in content `onScrollIndex(...)`, ignore sync work while the guard is active

```ts
@Component
struct LinkedListsPage {
    @State currentIndex: int = 0
    private menuScroller: Scroller = new Scroller()
    private contentScroller: Scroller = new Scroller()
    private groupStarts: int[] = [0, 8, 16]
    private isMenuClick: boolean = false

    build() {
        Row() {
            List({ scroller: this.menuScroller }) {
                ForEach(['Fruit', 'Drink', 'Snack'], (title: string, index: int) => {
                    ListItem() {
                        Text(title)
                            .onClick(() => {
                                this.isMenuClick = true
                                this.currentIndex = index
                                this.contentScroller.scrollToIndex(this.groupStarts[index], true)
                            })
                    }
                }, (title: string) => title)
            }

            List({ scroller: this.contentScroller }) {
                ForEach(this.items, (item: MenuRow, index: int) => {
                    ListItem() {
                        Text(item.title)
                    }
                }, (item: MenuRow) => item.id)
            }
            .onScrollIndex((start: int): void => {
                let nextIndex = this.findGroupIndex(start)
                if (!this.isMenuClick && nextIndex != this.currentIndex) {
                    this.currentIndex = nextIndex
                    this.menuScroller.scrollToIndex(nextIndex, true)
                }
            })
            .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) {
                    this.isMenuClick = false
                }
            })
        }
    }

    private items: MenuRow[] = [
        { id: 'fruit-0', title: 'Apple' } as MenuRow,
        { id: 'drink-0', title: 'Tea' } as MenuRow,
        { id: 'snack-0', title: 'Cake' } as MenuRow
    ]

    findGroupIndex(itemIndex: int): int {
        if (itemIndex < this.groupStarts[1]) {
            return 0
        }
        if (itemIndex < this.groupStarts[2]) {
            return 1
        }
        return 2
    }
}

type MenuRow = {
    id: string
    title: string
}
```

## `onScrollIndex(...)` should own only visible-index sync
```text
scroll callback grows into logging, formatting, data rebuilds, and starts causing jank
```
Next move:
- keep `onScrollIndex(...)` limited to index math and one state sync
- move anything else out of the scroll callback

```ts
.onScrollIndex((start: int): void => {
    let nextIndex = this.findGroupIndex(start)
    if (nextIndex != this.currentIndex) {
        this.currentIndex = nextIndex
    }
})
```

## Cross-file reusable UI atom
```text
same bottom bar or image-text row repeats across pages with the same structure
```
Next move:
- move the repeated UI shape into its own file
- give it a small parameter surface
- reuse it from page files instead of copying the subtree

```ts
// common/BottomBar.ets
@Component
export struct BottomBar {
    @PropRef buttonName: string = 'Checkout'

    build() {
        Row() {
            Button(this.buttonName)
        }
        .height(60)
        .width('100%')
    }
}

// pages/CartPage.ets
@Component
struct CartPage {
    build() {
        Column() {
            BottomBar({ buttonName: 'Checkout' })
        }
    }
}
```

## Fixed calendar or day grid -> `Flex({ wrap: FlexWrap.Wrap })`
```text
calendar-like cells should wrap into rows of seven without building nested rows by hand
```
Next move: render one `Flex` with weekday header + day cells. Hide placeholders with `opacity(0)`. Add selected/disabled states inline.

```ts
@Component
struct MonthGrid {
    private titles: string[] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    @State days: int[] = [0, 0, 1, 2, 3, 4, 5]
    @State selected: int = 12
    private today: int = 12

    build() {
        Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.titles, (t: string) => {
                Text(t).width(48).textAlign(TextAlign.Center)
            }, (t: string) => t)

            ForEach(this.days, (day: int, idx: int) => {
                Text(day == 0 ? '' : day.toString())
                    .width(48).height(48)
                    .opacity(day == 0 ? 0 : 1)
                    .fontColor(day < this.today ? Color.Grey : Color.Black)
                    .backgroundColor(day == this.selected ? Color.Blue : Color.Transparent)
                    .onClick(() => {
                        if (day < this.today) return
                        this.selected = day
                    })
            }, (day: int, idx: int) => idx.toString())
        }
    }
}
```

## High-load month list -> `LazyForEach` + `@Reusable`
```text
many repeated month grids drop frames when each row rebuilds from scratch during fast scroll
```
Next move:
- keep the outer month list lazy
- move one month grid into `@Reusable`
- refresh only its input data in `aboutToReuse(...)`

```ts
@Reusable
@Component
struct MonthCard {
    @State month: MonthData = {
        title: '',
        days: []
    } as MonthData

    aboutToReuse(params: Record<string, MonthData>): void {
        let nextMonth = params['month']
        if (nextMonth != undefined) {
            this.month = nextMonth
        }
    }

    build() {
        Flex({ wrap: FlexWrap.Wrap }) {
            Text(this.month.title)
                .width('100%')
            ForEach(this.month.days, (day: int, index: int) => {
                Text(day == 0 ? '' : day.toString())
                    .width(48)
                    .height(48)
                    .opacity(day == 0 ? 0 : 1)
            }, (day: int, index: int) => index.toString())
        }
    }
}

type MonthData = {
    title: string
    days: int[]
}
```

## List items need one visible separator -> `Divider`
```text
adjacent list rows merge together with no clear boundary
```
Next move:
- insert `Divider()` between ListItems
- set the stroke width, height, and color

```ts
List() {
    ForEach(this.items, (item: string) => {
        ListItem() {
            Text(item)
        }
        Divider()
            .strokeWidth('100%')
            .height(1)
            .color('#e0e0e0')
    }, (item: string) => item)
}
```

## Verify
- scroll one linked list pair and prove the left and right sides stay in sync
- click one category label in the left list and prove the right list jumps to the correct group
- expand one tree row if present
- prove the calendar grid wraps correctly
- prove one month card reuses during fast scroll

## Return
- if the pattern works but the page flow is wrong -> `30-20-routing-lifecycle-and-app-flow.md`
- if the first direct fix fails -> `30-40-arkui-failures.md`
