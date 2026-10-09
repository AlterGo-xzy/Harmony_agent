# ArkUI structure and state

Use this when the blocker is how to shape one page or component so ArkUI will render and update it.

## Default page shape
```ts
import { Button, Column, Component, Entry, Text } from '@ohos.arkui.component'
import { State } from '@ohos.arkui.stateManagement'

@Entry
@Component
struct HomePage {
    @State selectedIndex: int = 0

    build() {
        Column() {
            Text('Home')
            Button('Next')
                .onClick(() => {
                    this.selectedIndex = 1
                })
        }
    }
}
```

## If you are adding a page -> copy this first
```ts
import { Column, Component, Entry, Text } from '@ohos.arkui.component'
import { State } from '@ohos.arkui.stateManagement'

@Entry
@Component
struct HomePage {
    @State title: string = 'Home'

    build() {
        Column() {
            Text(this.title)
        }
    }
}
```

## Local UI state -> `@State`
```text
click or gesture should change the visible UI on this page
```
Next move:
- put the UI-owned field on the component with `@State`
- mutate that field in the event handler

```ts
@Component
struct CounterCard {
    @State count: int = 0

    build() {
        Column() {
            Text(this.count.toString())
            Button('Add')
                .onClick(() => {
                    this.count += 1
                })
        }
    }
}
```

## Plain field, not UI state
```text
field is only a helper object or datasource and the visible UI is driven by other state
```
Next move:
- keep it as a plain field
- do not add `@State` unless the UI should rerender when it changes

```ts
@Component
struct ArticlePage {
    @State selectedTitle: string = 'Home'
    private source: ArticleSource<Article> = new ArticleSource<Article>([])

    build() {
        Column() {
            Text(this.selectedTitle)
        }
    }
}
```

Plain class members accessed via nested property reads (`this.obj.field`) inside `build()` may trigger preview runtime verifier failures even when hvigorw compiles cleanly. TODO: root cause not confirmed — may be previewer-version-dependent. If a `@Component` with `private metric: SomeClass` and `this.metric.label` reads inside `build()` crashes the previewer with `Abstract interpretation failed`, inline the component's content at its call site. See `30-40` "Nested property access on plain class member".

## Child needs parent-owned state -> `@Link`
```text
child edit must update the parent-owned value immediately
```
Next move:
- keep the source of truth in the parent with `@State`
- pass it into the child with `@Link`

```ts
@Component
struct ParentPage {
    @State selectedIndex: int = 0

    build() {
        ChildTabs({ selectedIndex: this.selectedIndex })
    }
}

@Component
struct ChildTabs {
    @Link selectedIndex: int

    build() {
        Row() {
            Button('First')
                .onClick(() => {
                    this.selectedIndex = 0
                })
            Button('Second')
                .onClick(() => {
                    this.selectedIndex = 1
                })
        }
    }
}
```

## Parent passes one field into a child UI atom -> `@PropRef`
```text
parent has one row value and the child should render that value directly without becoming the owner
```
Next move:
- keep the list row value in the parent
- pass it into the child with `@PropRef`
- use the field directly inside the child
- **Static ArkTS note**: empty `@State` arrays must use `Array<T>` + `new Array<T>()` instead of `T[] = []` (compiler inference bug ESE0301)

```ts
@Component
struct CartPage {
    @State items: Array<string> = new Array<string>()

    aboutToAppear(): void {
        this.items.push('Apple')
        this.items.push('Orange')
    }

    build() {
        List() {
            ForEach(this.items, (item: string) => {
                ListItem() {
                    CartRow({ item: item })
                }
            }, (item: string) => item)
        }
    }
}

@Component
struct CartRow {
    @PropRef item: string = ''

    build() {
        Row() {
            Text(this.item)
        }
    }
}
```

## Child reads changing parent state -> `@PropRef`, not `@Prop`
```text
parent state changes and the child should redraw from the new value
```
Next move:
- use `@PropRef` for static ArkTS child input
- pass only **primitive** fields (string, int, number, boolean) — object props may stay stale
- use `@Link` only when the child writes back to the parent
- if `@PropRef` is missing in the target SDK or object staleness occurs, inline the child UI into the parent
- for dynamic lists: prefer `ForEach` with key function over parameterized `@Builder`

```ts
@Component
struct ParentPage {
    @State selectedCategory: int = 0

    build() {
        CategoryGrid({ selectedCategory: this.selectedCategory })
    }
}

@Component
struct CategoryGrid {
    @PropRef selectedCategory: int = 0

    build() {
        Text(this.selectedCategory.toString())
    }
}
```

## One state change must trigger one repair action -> `@Watch`
```text
one focused index or selected value changes, and another UI action must stay in sync
```
Next move: attach `@Watch('methodName')` to the `@State` field. Do the follow-up work in that method.

```ts
@State @Watch('syncFocus') currentIndex: int = 0
syncFocus(_: string): void {
    // scroll, update, or sync from this.currentIndex
}
```

## Page needs one app-stored value -> `@StorageLink`
```text
one page should show and update a shared stored value instead of owning a local copy
```
Next move: bind with `@StorageLink` and mutate the field directly.

```ts
@Component
struct TravelPage {
    @StorageLink('selectedDay') selectedDay: int = 12
    build() { Text(this.selectedDay.toString()) }
}
```

## Cross-component state without Provide/Consume -> `AppStorage`
Set from EntryAbility lifecycle:

```ts
// EntryAbility.ets
AppStorage.setOrCreate<string>('username', 'Guest')
```

Read via `@StorageLink` or `@StorageProp`:

```ts
@Component
struct Header {
    @StorageProp('username') name: string = 'Guest'
    // @StorageProp is read-only; use @StorageLink for two-way
    build() { Text('Hello ' + this.name) }
}
```

## Reusable UI shape callable from any file -> global `@Builder function`
```text
one UI shape must be used in multiple components and cannot be written as a component method
```
Next move: export a `@Builder function` with typed `$$` params. Call it from any file.

```ts
// common/Preview.ets
@Builder export function preview($$: { src: string; w: number; h: number }) {
    Image($$.src).width($$.w).height($$.h)
}
```

```ts
// pages/Page.ets
import { preview } from '../common/Preview'
preview({ src: '/path/to/img.png', w: 300, h: 200 })
```

## Repeated subtree with parameters -> `@Builder`
```text
page tree keeps repeating one local UI shape with a few changing values
```
Next move:
- keep page state on the component
- move only the repeated subtree into `@Builder`
- **Warning**: `@Builder` parameters may stay stale for content that changes at runtime. For dynamic lists or grids that must update on state change, prefer `ForEach` with key function.

```ts
@Component
struct MenuPage {
    @State selectedIndex: int = 0

    @Builder
    tabLabel(index: int, title: string) {
        Button(title)
            .onClick(() => {
                this.selectedIndex = index
            })
    }

    build() {
        Row() {
            this.tabLabel(0, 'Home')
            this.tabLabel(1, 'Video')
        }
    }
}
```

**Previewer limitation**: do not use a `while` or `for` loop inside a local
`@Builder` whose body creates event closures (`.onClick`, `.onChange`,
`.onTouch`) that capture `@State`. The Previewer runtime verifier cannot
complete abstract interpretation on these closures and will produce
`LinkerVerificationError` with `StateContext` in the lambda signature.

When you need a repeated control whose items vary per index, pre-compute
the item list into an `@State` array and render with `ForEach` in
`build()`. This is the standard ArkUI pattern used by every working demo
in `examples/`. See the full fix recipe in `30-40-arkui-failures.md`.

## List or waterflow should not render one eager giant array subtree -> use `LazyForEach`
```text
list-like UI is driven by a datasource and item updates should rerender one row
```
Next move:
- keep the datasource as a plain field
- render with `LazyForEach`
- notify the datasource when one row changes

```ts
@Component
struct ArticlePage {
    private source: ArticleSource<Article> = new ArticleSource<Article>([])

    build() {
        List() {
            LazyForEach(this.source, (article: Article, index: int) => {
                ListItem() {
                    Text(article.title)
                }
            }, (article: Article, index: int) => article.id)
        }
    }
}
```

## ForEach with primitive arrays — matching builder and key signatures
```text
hvigor rejects ForEach with int[] using 2-param builder
```
In hvigor strict mode, `ForEach` over primitive arrays (`int[]`, `double[]`) requires the builder, key extractor, and callback all match. When the key extractor takes `(item, index)`, the builder must also take `(item, index)`.

```ts
// correct — builder and key extractor both take (item, index):
ForEach([0, 1, 2], (mode: int, index: int): void => {
    Text(modeLabel(mode))
}, (mode: int, index: int): string => mode.toString())
```
```ts
// WRONG — key extractor has different signature than builder:
ForEach([0, 1, 2], (mode: int, index: int): void => {
    Text(modeLabel(mode))
}, (mode: int): string => mode.toString())   // ESE0124
```

## ForEach with class arrays — delegate to `@Builder` method
```text
hvigorw rejects ForEach over class arrays with ESE0127 "No matching call signature"
even when builder and key extractor signatures match
```
In `'use static'` ArkTS, `ItemGeneratorFunc<T>` carries the `@Builder` annotation. Inline arrow functions lack this annotation, so hvigorw rejects them. The fix: extract the item body into a `@Builder` method, then delegate to it from the inline ForEach callback.

```ts
@Builder
wordRow(w: VocabWord, _idx: int): void {
    Column(undefined) {
        WordCard({ word: w.word, pinyin: w.pinyin, definition: w.definition })
    }
    .margin({ bottom: 8 })
    .onClick((): void => { this.openDetail(w.id) })
}

// correct — inline closure delegates to @Builder method:
ForEach(this.words, (w: VocabWord, index: int): void => {
    this.wordRow(w, index)
}, (w: VocabWord, index: int): string => w.id.toString())
```

The @Builder method must take two parameters `(item: T, index: int)` to match `ItemGeneratorFunc<T>`. The `this.wordRow(w, index)` delegation inside the inline closure compiles to a builder call and satisfies hvigorw.

Without this delegation, hvigorw reports ESE0127 even for 2-param `(item, index)` inline callbacks.

## Shared page-wide value needed by many descendants -> `@Provide` and `@Consume`
```text
many nested children need the same current value and one direct `@Link` is no longer enough
```
Next move:
- provide it once at the owner
- consume it in the deep child

```ts
@Component
struct ParentPage {
    @Provide selectedIndex: int = 0

    build() {
        Column() {
            DeepChild()
        }
    }
}

@Component
struct DeepChild {
    @Consume selectedIndex: int

    build() {
        Text(this.selectedIndex.toString())
    }
}
```

## One item view is reused by lazy containers -> `@Reusable`
```text
lazy list or waterflow item needs reuse-specific update input
```
Next move: put `@Reusable` on the item component, update its fields in `aboutToReuse(...)`:
```ts
@Reusable @Component struct Card {
    @State item: T = /* default */
    aboutToReuse(params: Record<string, T>): void { this.item = params['item'] }
    build() { Text(this.item.title) }
}
```

## Slot-based component with custom content -> `@BuilderParam`
```text
one component should accept caller-defined UI blocks as named slots
```
Next move: declare `@BuilderParam` fields, pass them from the caller:
```ts
@Component struct Card {
    @BuilderParam header: () => void = this.defaultHeader
    @Builder defaultHeader() { Text('Default') }
    build() { Column() { this.header() } }
}
// caller:
Card({ header: this.myHeader })
// or trailing-closure syntax for the last builder param:
Card({ header: this.myHeader }) { this.myFooter() }
```

## Two-way binding into @Builder -> `UIUtils.makeBinding()`
```text
one @Builder needs to read and write the same state value
```
Next move:
```ts
import { UIUtils } from '@kit.ArkUI'

@State label: string = 'Hello'
UIUtils.makeBinding<string>(this, { get: () => this.label, set: (v) => { this.label = v } })
```

## Persist one data object across app restarts -> `PersistenceV2`
```text
one settings or user profile object should survive app restarts without manual JSON serialization
```
```ts
import { PersistenceV2 } from '@kit.ArkUI'

@ObservedV2
class UserSettings {
    @Trace theme: string = 'light'
    @Trace notifications: boolean = true
}

@Component
struct SettingsPage {
    private settings: UserSettings = PersistenceV2.connect(
        UserSettings,
        'userSettings',
        (): UserSettings => { return new UserSettings() }
    ) as UserSettings

    build() {
        Column() {
            Text(this.settings.theme)
            Button('Toggle')
                .onClick(() => {
                    this.settings.theme = this.settings.theme == 'light' ? 'dark' : 'light'
                    PersistenceV2.save(UserSettings)
                })
        }
    }
}
```

## Share one object across pages in memory -> `AppStorageV2`
```text
one object instance should be shared between pages without passing it through nav params
```
```ts
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
class SessionState {
    @Trace username: string = 'Guest'
    @Trace loginCount: int = 0
}

// Connect once in EntryAbility.onCreate():
let session = AppStorageV2.connect(SessionState, 'session', (): SessionState => {
    return new SessionState()
}) as SessionState
session.username = 'Alice'

// Read from any page or component — same instance:
@Component
struct HeaderBar {
    private session: SessionState = AppStorageV2.connect(
        SessionState, 'session'
    ) as SessionState

    build() {
        Text('Hello ' + this.session.username)
    }
}
```

## Verify
- click one control that mutates one field
- prove the visible subtree changes once
- if the field changes but the UI does not, move to `30-40-arkui-failures.md`

## Grid layout with dynamic columns -> `Flex({ wrap: FlexWrap.Wrap })`
```text
items should flow into multiple columns without hardcoding rows
```
Next move:
- use `Flex({ wrap: FlexWrap.Wrap })` instead of `Grid`/`GridItem` (Grid may produce blank cells in this path)
- set each tile to `width('30%')` with `margin`
- use `ForEach` with a key function that includes changing state for fresh identity

```ts
Flex({ wrap: FlexWrap.Wrap }) {
    ForEach(this.cellNames, (name: string, index: int): void => {
        Column(undefined) {
            Image($rawfile(this.cellPaths[index]))
                .width('100%').height(86)
            Text(name)
        }
        .width('30%')
        .margin({ right: 8, bottom: 8 })
    }, (name: string, index: int): string =>
        this.selectedCategory.toString() + '-' + index.toString())
}
.width('100%')
```

## @State array initialization bug (ESE0301)
```text
@State T[] = [] fails with "Can't resolve array type" at compile time
```
Fix: use explicit `Array<T>` type annotation and `new Array<T>()` constructor:
```ts
// FAILS
@State names: string[] = []

// WORKS
@State names: Array<string> = new Array<string>()
```
Applies to all element types (string, int, number, custom classes). Non-empty literals like `['a', 'b']` are unaffected.

## Mutable array that must trigger re-render -> version counter
```text
A plain (non-@State) array is mutated with .push() or .pop(), but the UI does not
update because ArkTS does not track mutations on plain fields. @State on the array
itself fails with ESE0301 for custom element types, and even Array<T> + new Array<T>()
may not re-render on push.
```
Move: keep the array as a plain field (`private items: T[] = []`), add one `@State version: int = 0`, and bump the version after every mutation. Use the version in the ForEach key function:
```ts
@Component
struct ChatView {
    @State chatVersion: int = 0
    private messages: ChatBubbleData[] = []

    build(): void {
        ForEach(this.messages, (msg: ChatBubbleData, idx: int): void => {
            // render msg
        }, (msg: ChatBubbleData, idx: int): string =>
            idx.toString() + '-' + this.chatVersion.toString())
    }

    private addMessage(text: string): void {
        this.messages.push(/* new msg */)
        this.chatVersion = this.chatVersion + 1
    }
}
```
The version counter forces ArkTS to re-evaluate ForEach because the key function changes. This avoids ESE0301 on custom element types and works when `@State` on the array type is rejected.
