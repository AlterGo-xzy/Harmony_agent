# ArkUI sizing, spacing, and visual styling

Use this when the blocker is how to size, space, color, or visually style a component tree.

## Load this doc when you see
- `.width()`, `.height()`, `.layoutWeight()`, `constraintSize`, sizing problems
- `.padding()`, `.margin()`, spacing problems
- `.backgroundColor()`, `.border()`, `.borderRadius()`, `.shadow()`, `.opacity()`
- text style issues: `.fontSize()`, `.fontColor()`, `.fontWeight()`, `.lineHeight()`
- `.alignItems(` string value rejected — use enum
- `.justifyContent(` string value rejected — use enum
- `FlexAlign`, `VerticalAlign`, `HorizontalAlign` import questions
- `Blank()` component to push siblings apart
- `.aspectRatio()` ratio calculation
- review flags misalignment, dead space, spacing inconsistency, low contrast

## Spacing scale — copy one consistent scale

Use multiples of 4. Preferred scale: 8, 12, 16, 24.

```ts
final class Gaps {
    static readonly INLINE: int = 8
    static readonly RELATED: int = 12
    static readonly CARD: int = 16
    static readonly SECTION: int = 24
}
```

Every section border ≥ 20px gap. Card/internal padding = 12-16px. Inline spacing = 8px.

## Remove dead space — fill columns with `layoutWeight`

A column's child that should fill remaining space:

```ts
Column() {
    Scroll() { /* content */ }
        .layoutWeight(1)   // fills remaining vertical space
    Row() { /* bottom CTA */ }
        .height(52)
}
.width('100%').height('100%')
```

## Contrast baseline

Body text on surface: use `#4A5A5A` or darker. Labels: use `#6B8080` min. Do not use light grey (`#C0C0C0`) on white — fails WCAG AA. Surfaces: use distinct lightness steps (e.g. `#FFFFFF` card on `#F0F4F4` background).

```ts
// preferred token contrast:
TEXT_PRIMARY: '#0F1A1A'       // headings
TEXT_SECONDARY: '#4A5A5A'     // body text on white
TEXT_TERTIARY: '#6B8080'      // captions, metadata
SURFACE_MUTED: '#F0F4F4'      // page background
SURFACE: '#FFFFFF'            // card background
```

## One row should fill available space -> `layoutWeight`
```text
one child in a row or column should take the remaining space
```
```ts
Row() {
    Text('Label')
    Text('Value')
        .layoutWeight(1)     // fills remaining horizontal space
        .textAlign(TextAlign.End)
}
```

```ts
Column() {
    Text('Header')
    List() { /* body */ }
        .layoutWeight(1)     // fills remaining vertical space
    Row() { /* bottom bar */ }
        .height(56)
}
```

## One item needs minimum or maximum dimensions -> `constraintSize`
```text
item should never shrink below or grow beyond certain bounds
```
```ts
Image($r('app.media.avatar'))
    .constraintSize({ minWidth: 48, maxWidth: 200, minHeight: 48, maxHeight: 200 } as ConstraintSizeOptions)
    .width('100%')
```

## Uniform padding or margin on all sides -> shorthand
```ts
.padding(16)                  // all four sides = 16vp
.margin({ top: 8, bottom: 8, left: 16, right: 16 } as Margin)
```

## Rounded corners
```ts
.borderRadius(12)             // all four corners
.borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 0 } as BorderRadiuses)
```

## Colored background
```ts
.backgroundColor('#FFFFFF')
.backgroundColor(Color.White)
.backgroundColor($r('app.color.page_bg'))
```

## Card-style shadow
```ts
.shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 } as ShadowOptions)
```

## Semi-transparent or hidden element
```ts
.opacity(0.5)                 // half-visible
// .visibility(Visibility.Hidden)  // invisible, still takes space
```

To make an element's background fully transparent (e.g. inactive button in a pill-track selector), prefer a theme token over a hardcoded hex:

```ts
final class Colors {
    static readonly TRANSPARENT: string = '#00000000'
}
```

Use `Colors.TRANSPARENT` wherever `'#00000000'` would appear — keeps the color system self-contained and makes later design-system changes a single-token edit.

## Text line clamping and overflow
```ts
Text(this.longText)
    .maxLines(2)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
```

## Text alignment and weight
```ts
.fontWeight('bold')            // 'bold', 'medium', 'semibold', 'regular' — use strings in 'use static'
.textAlign(TextAlign.Center)  // or TextAlign.Start, TextAlign.End
.fontColor('#333333')
.fontSize(16)
.lineHeight(24)
```
When importing from `@ohos.arkui.component` in `'use static'`, `FontWeight.Bold` and `FontWeight.Medium` are not importable. Use string values: `'bold'`, `'medium'`, `'semibold'`, `'regular'`.

## Align and justify — use enum values, not strings
```ts
Row().alignItems(VerticalAlign.Center)          // not 'center'
Column().alignItems(HorizontalAlign.Start)       // not 'start'
Row().justifyContent(FlexAlign.Center)            // not 'center'
```
Import `VerticalAlign`, `HorizontalAlign`, `FlexAlign` from `@ohos.arkui.component`.

## Push siblings apart -> `Blank()`
```ts
import { Blank, Row, Text } from '@ohos.arkui.component'

Row() {
    Text('Left')
    Blank()           // pushes remaining space between siblings
    Text('Right')
}
.width('100%')
```

## One visible border
```ts
.border({ width: 1, color: '#E0E0E0' })
// or individual sides:
.border({ width: { bottom: 1 }, color: '#E0E0E0' })
```
In `'use static'`, the short form works without `as BorderOptions` cast. Only use the cast when the compiler requires it.

## Force square or cinema aspect ratio -> `aspectRatio()`
```ts
Image($rawfile(path))
    .width('100%')
    .aspectRatio(1)              // square
    .objectFit(ImageFit.Cover)

Image($rawfile(path))
    .width('100%')
    .aspectRatio(16 / 9)         // cinema — both operands are literals, produces double
    .objectFit(ImageFit.Cover)
```
When both arguments are numeric literals, `16 / 9` produces `double` not `int` division. If one operand is a variable of type `int`, convert first: `Int.toDouble(w) / Int.toDouble(h)`.

## Clip child content to bounds
```ts
Image($r('app.media.photo'))
    .borderRadius(16)
    .clip(true)               // children respect the rounded shape
```

## Center one child inside its parent
```ts
Stack() {
    Text('Centered')
}
.width('100%')
.height(200)
.alignContent(Alignment.Center)
```

If `Stack` or `TextAlign` is unresolved in the target SDK import surface, use container alignment first:

```ts
Column() {
    Text('Centered')
}
.width('100%')
.height(200)
.justifyContent(FlexAlign.Center)
.alignItems(HorizontalAlign.Center)
```

## Stack items: place one in a corner
```ts
Stack() {
    Image($r('app.media.banner'))
        .width('100%')
        .height(200)
    Text('Badge')
        .position({ x: 8, y: 8 } as Position)
        .zIndex(1)
}
```

If `Stack` is unresolved, use `RelativeContainer` before deep `Column`/`Row` nesting.

## Safe area — content should avoid system bars
```ts
Column()
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .padding({ top: '0vp' as Length })
```

## One section should fill rows that wrap -> `Flex({ wrap: FlexWrap.Wrap })`
```ts
Flex({ wrap: FlexWrap.Wrap }) {
    ForEach(this.tags, (tag: string) => {
        Text(tag)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 } as Padding)
            .backgroundColor('#F0F0F0')
            .borderRadius(4)
            .margin(4)
    }, (tag: string) => tag)
}
.width('100%')
```

## Element overlaps stack children without extra nesting -> `offset`
```ts
// move an element visually without affecting layout space:
Text('Overlay')
    .offset({ x: -8, y: -4 } as Position)
```

## Verify
- change one `.width()` / `.height()` value and confirm the layout responds
- replace `margin` with `padding` on the right element and prove spacing moves correctly
- add `.layoutWeight(1)` to one child and confirm it stretches
- test `.borderRadius()` on an `Image` and enable `.clip(true)`
- add `Blank()` between two siblings and confirm gap

## Return
- component composition and tree shape → `30-10-ui-structure-and-state.md`
- list/grid-specific layout → `30-30-arkui-components-and-patterns.md`
- tabs or overlay patterns → `30-32-tabs-overlays-and-gestures.md`
- if the first direct fix fails → `30-40-arkui-failures.md`
- image constructor or gallery patterns → `30-30-arkui-components-and-patterns.md`
