# ArkUI failures

Use this only after the first direct fix fails. Each entry names one failure and one exact next move.

## Stack wrapper consumes all child clicks
```text
page builds and renders, but NO onClick handler fires anywhere —
tabs, buttons, post cards, search icons are all inert.
Previewer stdout shows {type: Click, tag: Stack, state: SUCCEED}
meaning the Stack absorbed the click and did not propagate it.
```
The root `Stack()` wrapper (added for an overlay or backdrop) intercepts every touch event. Even when the overlay child is conditionally hidden (`if (this.showOverlay)`), the Stack container still claims the click before children can receive it.

Move: remove the `Stack` wrapper. Replace with `if/else` conditional rendering at the page root:
```ts
// BEFORE — Stack eats every click
build(): void {
    Stack() {
        Column() { /* main content */ }
        if (this.showOverlay) { /* overlay */ }
    }
}

// AFTER — if/else, no Stack
build(): void {
    if (this.showOverlay) {
        Column() { /* overlay screen */ }
    } else {
        Column() { /* main content */ }
    }
}
```
If you need the overlay to appear above content without a full screen replace, put the overlay inside the main Column as a conditional child positioned at the bottom.

## Text().onClick() does not fire
```text
a Text element has .onClick() attached, compiles clean,
but tapping it in the previewer produces no state change.
Column().onClick() and Row().onClick() DO fire on the same page.
```
Bare `Text().onClick((): void => { ... })` may not fire in the ArkTS runtime with `@ohos.arkui.component` imports. The click event reaches the Text node but the gesture recognizer may not activate.

Move: wrap the Text in a `Column()` or `Row()`, then attach `.onClick()` to the wrapper:
```ts
// FAILS — Text.onClick does not fire
Text('🔍').fontSize(20)
    .onClick((): void => { this.showSearch = !this.showSearch })

// WORKS — wrapper Column carries the click
Column() {
    Text('🔍').fontSize(22)
}
.width(44).height(44).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
.onClick((): void => { this.showSearch = !this.showSearch })
```
Give the wrapper an explicit `.width()` and `.height()` of at least 44 to ensure a tappable hit area.

## Exported struct uses a type that is not exported (ESE1236581)
```text
hvigorw rejects with ESE1236581 "Type 'Foo' used in export declaration(s) is not exported"
```
When an `export struct` or `export function` uses a custom type in its parameter list or return type, that type must also be `export`ed. The compiler requires all referenced types in exported declarations to be visible to consumers.

Move: add `export` to the type declaration:
```ts
// FAILS — ChatBubbleData used in exported ChatBubble struct
final class ChatBubbleData { text: string = '' }

// WORKS
export final class ChatBubbleData { text: string = '' }
```

## `es2panda` passes, `hvigorw` rejects (ESE0046/ESE0127/ESE0143)
```text
build passed with es2panda compile, but hvigorw fails with
"Type 'undefined' is not compatible with type '((p1: ScrollAttribute) => undefined)'"
or "No matching call signature for Scroll(undefined, (() => undefined))"
or "Unresolved reference Blank/FlexAlign/..."
```
The two compilers have different strictness. hvigor rejects constructs es2panda accepts:
- `.alignItems('center')` → use `VerticalAlign.Center` or `HorizontalAlign.Start` enum
- `.justifyContent('center')` → use `FlexAlign.Center` enum  
- `Scroll()` without `Scroller` param → use `Scroll()` (trailing lambda only) or `Scroll(this.scroller)` with explicit constructor
- `Blank()` → import from `@ohos.arkui.component`
- `FontWeight.Bold` → use string `'bold'` in `'use static'` with `@ohos.arkui.component` imports
- `ForEach` with `int[]` using 2-param builder `(item, index)` → hvigor expects key extractor with matching signature; see `30-10` ForEach primitive arrays
- `border({ width: 0|1, ... })` with ternary on `width` → use constant `width: 1` and `color: Colors.TRANSPARENT` for invisible
- `for (let i = 0; i < N; i++) { ... }` as direct child of `Column`/`Row`/`Flex` builder → replace with unrolled `if (i < N)` blocks for each `i`, or extract the loop body into a `@Builder` method and call it N times
- `char` as parameter or variable name → rename to `ch` or another identifier; `char` is a keyword in ArkTS
- chaining `.margin()` / `.onClick()` / `.width()` directly on a custom `@Component struct` call → wrap in a native container first: `Column(undefined) { YourComponent({...}) }.margin(...)`. Custom component calls return `Object` which does not carry attribute methods.

Move: compare the first hvigor error against this list. Apply the exact replacement. Rebuild with `arkui-hvigor` to verify: `arkui-hvigor /path/to/arkui/project/ --json`

## Previewer screenshots are black or show stale UI
```text
screenshot is fully black/white or shows previous build content, image_analyzer rejects as "void"
```
Causes and fixes:
- **Stale HAP**: previewer reloaded before build finished. Kill previewer, rebuild, restart.
- **PID confusion**: `start` says "already running" but the process may be from an older launch. Inspect the exact previewer processes and ownership first. Terminate only the verified project-related process when authorized; do not use broad name-based process killing.
- **Socket name collision**: multiple previewer instances share the default name `previewer`. One session's `screenshot` command connects to the wrong app instance. Always pass `--previewer-name <unique>` to `start`, `screenshot`, `mouse-click`, and `stop` commands when running more than one previewer on the same host. Use distinct names per concurrent session (e.g. `seafeed`, `learnchinese`).
- **CLI mode not reached**: previewer started with `--gui`, CLI screenshots ignored. Kill and restart in CLI mode only.
- **Timing**: screenshot taken before previewer fully initializes. Wait 6-8s after start before first screenshot.
- **Possible stale bytecode cache**: if unchanged classes fail non-deterministically, first reproduce with the project's native clean task. If manual cache removal is necessary, resolve and preview the exact absolute build directories under the project root, then follow the current authorization rules. Do not recursively delete unresolved relative paths or the workspace root.

Verify that the screenshot or runtime evidence timestamp is later than the built artifact using a platform-appropriate file metadata command.

## Tab / content out of sync
```text
tab label click changes state but visible content does not match, or swipe changes content but tab bar does not update
```
Move: mirror one `@State selectedIndex` in both `onAnimationStart((index, targetIndex) => ...)` and the bar click handlers. See `30-32`.

## Routing: page does not open / back does not work
```text
pushUrl or back() has no effect
```
Move: compare the route string against `main_pages.json`. Check the page file exists at that path. See `30-20`.

## State change doesn't re-render
```text
`@State` field changed but the visible UI stays the same
```
Move:
- basic: verify the mutation happens inside the component instance that owns the `@State`
- datasource: verify `notifyDataChange(index)` or `updateData(index, item)` fires after the data changes
- see `30-10` for decorator rules, `30-30` for datasource `IDataSource<T>`

## Primary button appears inert in preview
```text
button click exits successfully or handler compiles, but visible state does not change in HAP preview
```
Move: put the scenario-critical `Button(...).onClick(...)` in the page that owns the `@State`. Avoid routing the primary click through a child component callback prop until preview proves it works.

```ts
@Entry
@Component
struct HomePage {
    @State mode: int = 0

    build(): void {
        Button('Build')
            .onClick((): void => { this.mode = 1 })
    }
}
```

## Preview linker fails for a custom component
```text
HAP builds, but preview logs `LinkerVerificationError` for `components/Foo/Foo`
```
Move: inline that component's simple UI at the call site first. Rebuild the HAP and preview again before extracting another component.

Before inlining the entire component, try removing single-child wrapper containers (`Row`, `Column`) whose only child is a `Text`, `Image`, or other leaf element. A `Row(undefined) { Text(...) }` generates a verifier lambda that can fail at runtime without changing the visible layout. Remove the wrapper and place the child directly in the parent container.

```ts
// BEFORE — single-child Row may fail preview runtime verification
Component
struct Badge {
    build(): void {
        Row(undefined) {             // remove this Row
            Text(this.label)
                .fontSize(12)
        }
    }
}

// AFTER — inlined, no single-child wrapper
Component
struct Badge {
    build(): void {
        Text(this.label)
            .fontSize(12)
    }
}
```

If the single-child wrapper is needed for layout (padding, alignment, or border), try applying those attributes to the leaf element first. Only use the wrapper when the leaf's own attribute surface is insufficient.

## Verifier: abstract interpretation failed for @Builder with a loop closure
```text
HAP builds, but previewer shows a blank or unchanged screen after
pushUrl. The stderr log contains:

  Verifier error: Abstract interpretation failed for method
    EditorPage::lambda_invoke-N(EditorPage, ..., StateContext, ...)
  Class verification failed
  AceRouter: create page failed, name: LinkerVerificationError
```

**Why it happens**

A `@Builder` function contains a `while` or `for` loop whose body creates
`.onClick()` / `.onChange()` / `.onTouch()` closures that capture `@State`
fields. The Previewer runtime verifier cannot complete abstract interpretation
for these closures because the `StateContext` type is embedded inside a
loop-generated lambda.

This pattern does not fail the Hvigor build — it passes `arkui-hvigor` —
but fails at Previewer runtime.

No other example in `examples/` or the skill docs uses a `@Builder` with a
loop whose closures capture `@State`.  The `ohos_static_app` and every
working demo use `ForEach` inside `build()`, not loops inside `@Builder`.

**Fix**

Replace the `@Builder` + loop pattern with pre-computed `@State` arrays
rendered via `ForEach` directly in `build()` — the same pattern used by
every working demo in `examples/`.

1. Define a plain `final class` that holds the per-item display data
   (colours, stroke chars, indices).

2. Add `@State cellData: Array<CellInfo> = new Array<CellInfo>()`.

3. Pre-compute the array in `aboutToAppear()` and after every mutation.

4. Replace the `@Builder` call sites with `ForEach`:

```ts
// BEFORE – builds but fails Previewer runtime verification
@Builder laneRow(liVal: int): void {
    while (sj < strokesCount) {
        let sjClosure: int = sj
        Button(stroke)
            .onClick((): void => { this.laneIndex = liVal; this.stepIndex = sjClosure })
    }
}
build(): void {
    Scroll() { Column() { this.laneRow(0); this.laneRow(1); ... } }
}

// AFTER – passes both Hvigor build and Previewer verification
final class CellInfo {
    stroke: string = ''
    bgColor: string = '#FFFFFF'
    fgColor: string = '#000000'
    laneIdx: int = 0
    stepIdx: int = 0
}
@State cellData: Array<CellInfo> = new Array<CellInfo>()

build(): void {
    Scroll() {
        Column() {
            ForEach(this.cellData, (cell: CellInfo): void => {
                Button(cell.stroke)
                    .backgroundColor(cell.bgColor)
                    .fontColor(cell.fgColor)
                    .onClick((): void => { this.laneIndex = cell.laneIdx; this.stepIndex = cell.stepIdx })
            }, (cell: CellInfo, idx: int): string => idx.toString())
        }
    }
}
```

## Ternary in attribute produces wrong tuple type (ESE0319)
```text
hvigorw rejects with ESE0319 "Type 'Array<Array<String|Double>>' is not compatible with type 'Array<[Color|Int|String|Resource, Double]>'" on an attribute like `.linearGradient({colors: this.flag ? [[...]] : [[...]]})`
```
The ternary produces a union-of-arrays type that the compiler cannot unify with the expected tuple-array shape. The same failure can appear on any attribute expecting `Array<[string, number]>` tuples — `linearGradient`, `keyframeAnimateTo`, `sharedTransition`, etc.

Move: avoid the ternary. Compute the array with a private method or local variable before the builder expression, or use separate `if/else` branches with distinct component trees. Do not add `as` casts on the array — the compiler rejects those here.

```ts
// BEFORE — ternary on gradient colors fails ESE0319
.linearGradient({ angle: 180,
    colors: this.dark ? [['#111' as string, 0.0]] : [['#EEE' as string, 0.0]] })

// AFTER — separate component trees per branch
if (this.dark) {
    Column() { /* content */ }
        .linearGradient({ angle: 180, colors: [['#111', 0.0]] })
} else {
    Column() { /* content */ }
        .linearGradient({ angle: 180, colors: [['#EEE', 0.0]] })
}
```
Note: the `as string` cast on hex literals does not fix the tuple inference; the root cause is the ternary producing a union type. Remove the ternary, not the literal type.

## Nested property access on plain class member may fail preview verification
```text
hvigorw builds, but preview runtime verifier fails with
"Abstract interpretation failed" and "Method verification failed"
on a @Component that accesses `this.obj.nestedField` where `obj` is a plain (non-@State) class member
```
Observed: `@Component` struct with `metric: StarterMetric` reading `this.metric.label`, `this.metric.value` inside `build()` compiled and built clean with hvigorw but caused the same runtime verifier crash as `LinkerVerificationError`. Replacing the component with direct `Text()` children at the call site fixed it.

TODO: the root cause is not confirmed. May be previewer-version-dependent, may be specific to class instances passed as component constructor arguments, may be related to how the verifier traces field reads through non-primitive member paths. Until root cause is known, the safe move is:

Move: if a `@Component` has a plain class member (`private item: SomeClass`) and accesses nested properties on it in `build()`, and preview verification fails with `Abstract interpretation failed`, inline the content of that component at its call site and remove the component.

```ts
// BEFORE — component with nested property access may fail preview verification
@Component
struct MetricTile {
    metric: StarterMetric = new StarterMetric('', '', '')

    build(): void {
        Column(undefined) {
            Text(this.metric.label)     // nested property read
            Text(this.metric.value)     // nested property read
            Text(this.metric.detail)    // nested property read
        }
    }
}

// AFTER — inlined at call site
// In parent build():
Column(undefined) {
    Text(METRIC_STRUCTURE.label)
    Text(METRIC_STRUCTURE.value)
    Text(METRIC_STRUCTURE.detail)
}
```

## Content hidden behind system area or bar
```text
part of the page is clipped by the status bar, navigation bar, or safe area
```
Move: add `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])`, or use `.height('calc(100% - 60vp)')` with a known bar height.

## Drag or gesture does not reach the target
```text
drag fires on the wrong layer or gesture does not respond
```
Move: if a deeper surface blocks touch, set `.hitTestBehavior(HitTestMode.None)` on the blocking layer. If the gesture is on the correct component but still silent, verify `.gesture()` or `.priorityGesture()` is attached to the correct node.

## Dragged control jumps on first touch
```text
offsetX resets or snaps at the start of each drag
```
Move: store the committed base offset in `onActionEnd` and reuse it as the starting point in the next `onActionUpdate`. See `30-32` drag gesture snippet.
