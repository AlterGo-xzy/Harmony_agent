---
name: arkts-skill
description: Apply the core ArkTS coding instincts and idioms when writing or reshaping ArkTS.
---

# ArkTS agentic entry

Copy patterns directly. Before editing any feature or API surface, route through this skilltree and open the matching specialist doc when a trigger matches.

## Loop
1. identify the feature/API surface you are about to touch
2. add `surface → route doc → planned check` to the route ledger
3. scan `## Routing` for matching triggers
4. **Hard gate: open and read the matching specialist document.** Stop here if you have only looked up its name. If multiple triggers match, read the most specific document first.
5. make one small edit
6. compile or run one narrow path
7. stop at the first blocker

## Rule
- **routing is a hard gate**: open the matching specialist document before editing ArkUI, OHOS, stdlib, interop, resources, startup, storage, networking, media, sensors, or concurrency code. Scanning the table and noting the name is not enough.
- write the preferred pattern in new code
- if touched code uses a non-preferred pattern, rewrite it locally
- keep the rewrite local unless the same blocker repeats
- **production quality, not fake behavior**: reject placeholder logic, hardcoded smoke values disguised as real data, and controls that only print or toast when real behavior was requested. If a bounded task cannot implement the full dependency, mark the limitation explicitly with `// STUB: not implemented` and report it.
- **app requirements interpretation**: when requirements or a user story are provided, treat them as acceptance criteria. Check every requirement against the code you write: is it actually implemented, or did you only produce a visibly similar surface? A scrollable list that only renders 3 hardcoded items when the requirement says "browse a catalog" is a finding. A search bar that only clears onEnter but does not filter results is a finding. A chart that displays fixed numbers and ignores user-edited input state is a finding. Do not silently degrade requirements into demos.

---

## `'use static'` imports — copy the exact import line

ArkTS `'use static'` code imports from two modules. Do not guess which module owns a symbol; use this table.

| Symbol(s) | Import from |
|---|---|
| `@Entry`, `@Component`, `struct`, `build()` | import structural shape, not a module |
| `Column`, `Row`, `Stack`, `Flex`, `Scroll`, `List`, `Text`, `Button`, `Image`, `Divider`, `Blank`, `Toggle`, `Slider`, `TextInput`, `ForEach`, `LazyForEach`, `ListItem`, `FlowItem` | `@ohos.arkui.component` |
| `FlexAlign`, `FlexWrap`, `HorizontalAlign`, `VerticalAlign` | `@ohos.arkui.component` |
| `ImageFit`, `ScrollDirection`, `BarState` | `@ohos.arkui.component` |
| `$r`, `$rawfile` | `@ohos.arkui.component` |
| `@State`, `@Link`, `@PropRef`, `@Provide`, `@Consume`, `@Watch`, `@StorageLink`, `@StorageProp` | `@ohos.arkui.stateManagement` |

```ts
// correct import pattern:
import { Button, Column, Component, Entry, FlexAlign, FlexWrap, ForEach, HorizontalAlign, Image, ImageFit, Row, Scroll, Text, VerticalAlign } from '@ohos.arkui.component'
import { State } from '@ohos.arkui.stateManagement'
```

---

## Narrowing fails → local copy
Language supports smart casts for locals/parameters, while excluding globals/class fields.
```ts
final class DraftState {
    author: string | undefined = undefined

    authorLabel(): string {
        let author = this.author          // one read
        if (author == undefined) { return "guest" }
        return author                     // same local after branch
    }
}
```

```ts
let nick = this.profile?.nick            // short nullable read
let name = maybeName!                    // non-null assertion, this site only
```

```ts
let active: object = "a"

function label(): string {
    let v = active
    if (v instanceof Greeter) { return v.sayHello() }  // instanceof narrows
    return "quiet"
}
```

```ts
final class User {
    name: string
    constructor(name: string) { this.name = name }
}

function firstUserName(items: (User | undefined)[]): string {
    for (let i: int = 0; i < items.length; i++) {
        let item = items[i]
        if (item == undefined) { continue }
        return item.name
    }
    return "guest"
}
```

---

## Class hierarchy → `interface` + `final class`

Prefer `final class` for app state. Classes are extensible by default — add `final` to prevent subclassing.

```ts
interface Speaker { sayHello(): string }

final class Greeter implements Speaker {
    name: string
    constructor(name: string) { this.name = name }
    sayHello(): string { return 'Hello ' + this.name }
}

final class DefaultGreeter implements Speaker {
    sayHello(): string { return 'Hi' }
}
```

---

## Types are nominal

Same fields ≠ same type. Use explicit `extends` or `implements`.

`obj as Interface` does a runtime check — `ClassCastError` if the object does not implement the target interface; there is no structural duck-typing.

```ts
final class Cat { name: string = "" }
final class Dog { name: string = "" }
// Cat is NOT assignable to Dog even though shapes match

function describe(animal: Cat | Dog): string {
    if (animal instanceof Cat) { return "cat " + animal.name }
    return "dog " + animal.name
}
```

---

## Type system

ArkTS numeric types: `byte`, `short`, `int`, `long`, `float`, `double`. Prefer `int` for general integral work; use narrower types (`byte`, `short`) or wider (`long`) only when storage or range requires them.

`string`/`String` are equivalent (same for `object`/`Object`, `number`/`Number`, `int`/`Int`, `long`/`Long`, `float`/`Float`, `double`/`Double`, `boolean`/`Boolean`, `byte`/`Byte`, `short`/`Short`). Uppercase and lowercase spellings refer to the same type.

`object` is the supertype of `byte`–`double`, `bigint`, `boolean`, and `string`. `object` does NOT include `null`.

`Any` is the supertype of everything. It is type-safe — you cannot assign `Any` to a narrower type without a cast, and you cannot access its properties directly:

```ts
let v: Any = "hello"
// v.length     // error: no property on Any
let s: string = v as string    // explicit cast required
```

`as` is a type assertion — no value conversion. `d as int` is a compile-time error (types are incompatible). `v as string` checks at runtime that `v` actually is a string and throws if it isn't. `n as SomeEnum` is always a compile error — use explicit conversion or `int` constants instead. For value conversion, use explicit functions:

```ts
let n: int = d.toInt()                   // double → int (truncates)
let d: double = Int.toDouble(n)          // int → double
let s: string = n.toString()             // number → string
let n2: int = parseInt(s).toInt()        // string → int
```

Avoid mix numeric types in arithmetic — use only same-type operands:

```ts
let a: int = 5; let b: long = 10
let sum: long = a.toLong() + b
```

Use `as` only to narrow from a supertype (`Any`, `object`, or a union) to a concrete type that the runtime value already matches.

---

## Numbers: `int` for integrals, `double` for fractions

`int / int` is integer division (truncates). Convert before dividing.

```ts
function fraction(done: int, total: int): double {
    return Int.toDouble(done) / Int.toDouble(total)  // not done / total
}

function parseWeight(text: string): double { return parseFloat(text) }
function parseCount(text: string): int { return parseInt(text).toInt() }
function ratioText(done: int, total: int): string {
    let value = Int.toDouble(done) / Int.toDouble(total)
    return value.toString()
}
```

parseInt and Number.parseInt might be used interchangeably

```ts
let s = "1234"
let n = Number.parseInt(s)
n = parseInt(s)
```

## `null` / `undefined` preference

Prefer `undefined` over `null` for optional or absent values. Use `null` only when interop with external API contracts requires it.

Type optional values as `T | undefined`. Check with `value == undefined` (loose equality catches both `null` and `undefined`).

Normalize `null` to `undefined` once at boundaries when the rest of the codebase uses `undefined`.

```ts
function label(name: string | undefined): string {
    if (name == undefined) { return "unnamed" }
    return name
}

let data: string | undefined = maybeFetch()
```

---

## Collections: `T[]`, build locally, assign once

`T[]` and `Array<T>` are equivalent; prefer `T[]`. `for-of` works directly.

```ts
function hasName(names: string[], target: string): boolean {
    for (let name of names) { if (name == target) { return true } }
    return false
}
```

```ts
type Point2d = [int, int]
function moveTo(p: Point2d): Point2d { return [p[0] + 1, p[1] + 1] }
```
Tuple types are not subtypes of array — `[int, int]` is not assignable to `int[]`, and vice versa.

Array indices and loop counters must be `int`, not `number`/`double`:

```ts
function sum(values: int[]): int {
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) { total += values[i] }
    return total
}
```

---

## Control: `instanceof`, `enum`, `int` constants

`instanceof` is limited by type erasure — tuples, function and most generic types cannot appear as RHS.

```ts
final class User {
    name: string
    constructor(name: string) { this.name = name }
}
final class Guest { name: string = "" }

function label(value: User | Guest): string {
    if (value instanceof User) { return value.name }
    return "unknown"
}
```

```ts
type Flag = number | boolean
function resolve(v: Flag): number {
    if (v instanceof number) { return v }
    return 0
}
```

```ts
enum Mode { Idle = 0, Running = 1, Done = 2 }
function modeCode(mode: Mode): int {
    switch (mode) {
        case Mode.Idle: return 0
        case Mode.Running: return 1
        case Mode.Done: return 2
        default: return -1
    }
}
```

When enum cast friction appears:
```ts
const MODE_IDLE: int = 0
const MODE_RUNNING: int = 1
const MODE_DONE: int = 2
```

When two domains both use `int` constants, map them explicitly:
```ts
const MODE_BUILD: int = 1
const CATEGORY_RIVER: int = 1

function modeToCategory(mode: int): int {
    if (mode == MODE_BUILD) { return CATEGORY_RIVER }
    return CATEGORY_OCEAN
}
```

---

## Generics, callbacks, helpers

```ts
function firstOrUndefined<T>(items: T[]): T | undefined {
    if (items.length == 0) { return undefined }
    return items[0]
}
let first = firstOrUndefined<string>(names)  // explicit <T>
```

```ts
type Action = () => void
type Visit = (name: string, onDone?: () => void) => void  // optional callback
function runAction(action: Action): void { action() }
function padLeft(text: string, width: int = 0): string { return text }
```

```ts
export final class MoveStep {
    dx: int; dy: int
    constructor(dx: int, dy: int) { this.dx = dx; this.dy = dy }
}
function moveBy(step: MoveStep): void {}
```

```ts
final class SaveData { level: int = 0; name: string = "" }
let raw = JSON.stringify(new SaveData())
```

---

## TS patterns → ArkTS replacement

| TS (compile error) | ArkTS |
|---|---|
| `obj["field"]` | `obj.field` (use `Map` for dynamic keys) |
| `let {a,b} = obj` | `let a2 = obj.a; let b2 = obj.b` |
| `let [x,y] = pair` | `let x2 = pair[0]; let y2 = pair[1]` |
| `f({a,b}: T)` | `f(val: T) { let a2 = val.a; ... }` |
| `{...base, extra: 1}` | `let m = new Merged(); m.a = base.a; m.extra = 1` |
| `{ name, price }` | `{ name: name, price: price }` |
| `constructor(public x: T)` | declare `x: T` + `this.x = x` in body |
| `(data: any)` | `(data: string \| int)`; `Any` is type-safe — cast before use |
| `typeof x` | `x instanceof number` |
| `catch (e: unknown)` | `catch (e)` — catch variable is `Error`, `.message` works directly |

---

## Async / concurrency

ArkTS has `async` / `await` / `Promise<T>` — transfer directly from TS.
```ts
async function loadName(id: int): Promise<string> { return await fetchName(id) }
```

For `launch`, use `std/concurrency` and pass a top-level non-capturing function. ArkUI lifecycle hooks stay `void`; call a private async method from the hook.
```ts
import { launch } from 'std/concurrency'

function computeScore(): int { return 42 }

@Entry
@Component
struct HomePage {
    @State score: int = 0

    aboutToAppear(): void { this.loadScore() }

    private async loadScore(): Promise<void> {
        this.score = await launch<int>(computeScore)
    }
}
```

| Symptom | Choose | Why |
|---|---|---|
| UI freezes on heavy computation | `launch` | Always preferred — one call, one result |
| Need a pinned dedicated thread | `EAWorker` + `attachThread` | Long-lived pinned worker |
| `launch` is genuinely unavailable | `taskpool` | Legacy API — last resort |
| Task C starts only after A and B finish | `AsyncLock` | Shared/exclusive lock modes |
| Callback order or suspension is wrong | scheduler | Execution-order debug |

- `launch` / `EAWorker` → `20-references/22-launch-and-eaworker.md`
- `taskpool` / `AsyncLock` → `20-references/28-taskpool-and-synchronization.md`
- execution-order → `20-references/26-scheduler-and-promise-runtime.md`
---

## Rewrite moves (TS habit → ArkTS)

- structural-type assumption → nominal; add `extends`/`implements`
- `int / int` → convert before dividing
- `typeof` → `instanceof`
- `obj["k"]` → `obj.k`; dynamic keys → `Map`
- destructuring → explicit field access
- spread → explicit field copy
- shorthand `{a}` → `{a: a}`
- constructor `public x: T` → declare + assign in body
- `any`/`unknown` → concrete `string | int`
- nullable member → local copy once
- numeric `as` → explicit `Int.toDouble()` / `.toInt()` (no conversion happens with `as`)
- ambiguous generic → explicit `<T>`
- `Record<K,V>` → `final class` or `Map<K,V>`
- structural helper → `final class MoveStep` shape
- no need for `FixedArray`/`ValueArray` → plain `T[]`

---

## Routing

Before editing a feature, scan this table against imports, decorators, components, lifecycle names, resource calls, app config, and APIs in touched files. Record `surface → route doc → planned check`. If multiple rows match, open the most specific row first, then parent path entry if the doc sends you there.

| Trigger | Open |
|---|---|
| You see `@Component`, `@Entry`, `build()`, `@State`, `List`, `LazyForEach`, `this.getUIContext()` | `30-arkui-path/30-00-entry.md` |
| You see `UIAbility`, `module.json5`, `@ohos.hilog`, `getHostContext()`, system permissions, `loadContent` | `35-ohos-app-path/35-00-entry.md` |
| You see `Navigation`, `NavPathStack`, `NavDestination`, `pushPath`, `pop`, `replacePath`, `pageStack` | `30-arkui-path/30-70-navigation-stack.md` |
| You see `CustomDialogController`, `AlertDialog`, `ActionSheet`, `@CustomDialog`, `DialogAlignment` | `30-arkui-path/30-80-dialogs.md` |
| You see `.width()`, `.height()`, `.padding()`, `.margin()`, `.borderRadius()`, `.border()`, `.layoutWeight()`, `.constraintSize()`, `.shadow()`, `.opacity()`, `.aspectRatio()`, `Blank()`, spacing problems, contrast problems | `30-arkui-path/30-15-styling-and-layout.md` |
| You see `FlexAlign`, `FlexWrap`, `VerticalAlign`, `HorizontalAlign` import questions, `.alignItems()`, `.justifyContent()` enum vs string | `30-arkui-path/30-15-styling-and-layout.md` |
| You see `$r(`, `$rawfile(`, `resourceManager`, or resource qualifier issues | `30-arkui-path/30-16-resources-and-assets.md` |
| You see `Image()` constructor, gallery grid, `Flex({ wrap: FlexWrap.Wrap })` | `30-arkui-path/30-30-arkui-components-and-patterns.md` |
| You see `ForEach` with `int[]` or primitive array — builder and key signature must match | `30-arkui-path/30-10-ui-structure-and-state.md` |
| You see `JSON.parse`, `JSON.parseUpdate`, `JSON.parseJsonElement`, `JSON.stringify`, `@JSONRename`, `@JSONParseIgnore`, parsed JSON object data, or raw JSON mapped into classes | `40-stdlib-path/40-15-json-data-surfaces.md` |
| You see `TextInput`, `Toggle`, `Checkbox`, `Radio`, `Slider`, `Select`, `DatePicker`, `InputType`, `ToggleType` | `30-arkui-path/30-35-form-controls.md` |
| You see `keyframeAnimateTo`, `.transition()`, `sharedTransition`, `TapGesture`, `LongPressGesture`, `PinchGesture`, `SwipeGesture`, `GestureGroup` | `30-arkui-path/30-32-tabs-overlays-and-gestures.md` |
| You see `onPageShow`, `onPageHide`, `onBackPress`, `router.replaceUrl` | `30-arkui-path/30-20-routing-lifecycle-and-app-flow.md` |
| You see `PersistenceV2`, `AppStorageV2`, `@ObservedV2`, `@Trace` | `30-arkui-path/30-10-ui-structure-and-state.md` |
| You see `preferences`, `getPreferences`, `putSync`, `getSync`, `flushSync`, `@ohos.data.preferences` | `35-ohos-app-path/35-55-preferences-and-light-store.md` |
| You see `window.getLastWindow`, `setPreferredOrientation`, `setWindowSystemBarProperties`, `Orientation` | `35-ohos-app-path/35-12-window-management.md` |
| You see `http.createHttp`, `HttpRequest`, `HttpResponse`, `connection`, `getDefaultNet`, `NetCapabilities` | `35-ohos-app-path/35-57-network-and-http.md` |
| You see `notificationManager`, `publish`, `NotificationRequest`, `@kit.NotificationKit` | `35-ohos-app-path/35-56-notifications.md` |
| You see `taskpool`, `AsyncLock`, `backgroundTaskManager`, `launch`, `ServiceExtensionAbility` | `35-ohos-app-path/35-22-background-tasks-and-workers.md` |
| You see `FormExtensionAbility`, `formProvider`, `formBindingData`, `@kit.FormKit` | `35-ohos-app-path/35-25-form-widgets.md` |
| You see `.accessibilityText`, `.accessibilityLevel`, `.accessibilityGroup`, `.accessibilityDescription` | `30-arkui-path/30-17-accessibility.md` |
| You see `objectFit`, `ImageFit`, `PixelMap`, `ImageSource`, `ImagePacker`, `onComplete` on Image | `35-ohos-app-path/35-58-image-and-media.md` |
| You see `media.createAVPlayer`, `AVPlayer`, `play()`, `pause()`, `prepare()`, `onStateChange` | `35-ohos-app-path/35-59-audio-playback.md` |
| You see `sensor.onAccelerometerChange`, `sensor.onGyroscopeChange`, `sensor.onOrientationChange`, `AccelerometerResponse` | `35-ohos-app-path/35-61-sensors.md` |
| You see `geoLocationManager`, `getCurrentLocation`, `onLocationChange`, `LocationRequest`, lat/lng | `35-ohos-app-path/35-62-location.md` |
| You see `Scroll(`, `Scroller`, `Refresh(`, `onScrollEdge`, `pullToRefresh` | `30-arkui-path/30-36-scroll-containers.md` |
| You see `TextArea`, `TextAreaOptions`, multi-line input | `30-arkui-path/30-35-form-controls.md` |
| You see `picker.DocumentViewPicker`, `photoAccessHelper.PhotoViewPicker`, file/document picker | `35-ohos-app-path/35-63-file-picker.md` |
| You see `camera.getCameraManager`, `CameraInput`, `PhotoSession`, camera capture | `35-ohos-app-path/35-64-camera.md` |
| You see `userAuth.getUserAuthInstance`, `UserAuthType.FINGERPRINT`, biometric auth | `35-ohos-app-path/35-65-biometric-auth.md` |
| You see `calendarManager`, `CalendarKit`, `addEvent`, `CalendarType` | `35-ohos-app-path/35-66-calendar.md` |
| You see `Contact`, `ContactsKit`, `contactManager`, `addContact`, `queryContacts` | `35-ohos-app-path/35-67-contacts.md` |
| You see `ble.startBLEScan`, `ble.createGattServer`, `@ohos.bluetooth`, `BLEDeviceFind` | `35-ohos-app-path/35-68-bluetooth.md` |
| You see `sim.getSimInfo`, `radio.getNetworkState`, `observer.on('simStateChange')`, `@kit.TelephonyKit` | `35-ohos-app-path/35-69-telephony.md` |
| Need `String`, `Array`, `ArrayList`, `HashMap` beyond TS basics | `40-stdlib-path/40-10-collections-and-data-surfaces.md` |
| Need runtime `Class` reflection or annotations | `40-stdlib-path/40-30-interop-and-boundary-surfaces.md` |
| A class-owned array keeps mutating from many methods | `10-playbooks/11-data-and-state.md` |
| The build fails with missing config or wrong root path | `10-playbooks/15-toolchain-and-startup.md` |
| You see `hvigorw`, `hvigor`, `ohpm`, `assembleHap`, `assembleHar`, or need to build an OHOS artifact | `10-playbooks/15-toolchain-and-startup.md` — select the verified project-native or installed DevEco toolchain |
| You need to launch the OHOS previewer or capture UI evidence | `10-playbooks/15-toolchain-and-startup.md` — use an available authorized previewer/device surface |
| The first direct fix failed | `10-playbooks/16-failed-fix-recovery.md` |
| Wrong startup function or entry order | `20-references/24-entrypoints-and-startup.md` |
| Need `Map`, `Set`, deduplication, or key-value lookup | `20-references/27-map-set-and-weak-collections.md` |
| Large arrays/loops cause visible scroll lag | `20-references/25-performance-habits.md` |
| A `native` declaration or C++ binding | `20-references/23-10-native-code.md` |
| Mixes ArkTS with `EsValue`, dynamic types, JS interop | `50-interop-path/50-00-entry.md` |
| Runtime failure with no named failure family | `20-references/29-runtime-debugging-and-exceptions.md` |
| TS migration: `@Sendable`, `'use shared'`, `ESObject`, `keyof`, decorator errors | `10-playbooks/17-migration-mistakes.md` |
| Compiler error on TS pattern from the table above | stay here |
| `es2panda` passes clean but `hvigorw` rejects with ESE0046/ESE0127/ESE0143 | `30-arkui-path/30-40-arkui-failures.md` (hvigor strict-mode divergence) |
| `ForEach` with `int[]` or primitive array — builder signature mismatch | `30-arkui-path/30-10-ui-structure-and-state.md` |
| `.fontWeight()` wants `FontWeight.Bold` but `FontWeight` is not importable | `30-arkui-path/30-15-styling-and-layout.md` (use string values in `'use static'`) |
| `.alignItems('center')`, `.justifyContent('center')` — string rejected | `30-arkui-path/30-15-styling-and-layout.md` (use enum: `VerticalAlign.Center`, `FlexAlign.Center`) |
| `Blank()` unresolved | `30-arkui-path/30-15-styling-and-layout.md` — import from `@ohos.arkui.component` |
| `.border({...})` compile error on shape | `30-arkui-path/30-15-styling-and-layout.md` |
| `Image()` constructor — second parameter semantics | `30-arkui-path/30-30-arkui-components-and-patterns.md` |
| Review flags misalignment, dead space, low contrast, spacing inconsistency | `30-arkui-path/30-15-styling-and-layout.md` (spacing scale, contrast baseline) |
| Previewer screenshots black, stale, or wrong PID | `30-arkui-path/30-40-arkui-failures.md` (previewer failures) |
| `.aspectRatio()` integer division gives wrong ratio | `30-arkui-path/30-15-styling-and-layout.md` |
| You need to discover which module provides a feature (unknown import), and no routing trigger above matched the feature domain | `references/sdk-modules.md` (hard gate — open only after the routing table above is exhausted) |

## Fallback: OHOS API not in the routing table

When an import (e.g. `@ohos.xxx` or `@kit.XxxKit`) does not match any routing trigger above:

**Hard gate — discovery only**: If you do not know which module provides a feature, and the routing table above did not match, open `references/sdk-modules.md` as a last-resort discovery tool. Scan the domain sections for the feature area, find candidate modules, then return here and continue with step 1 for each candidate. Do not open this file unless the skilltree routing has been exhausted.

1. Locate the actual declaration file in the available SDK or standard library.
2. Check system-only, deprecated, permission, and capability constraints in that declaration and its metadata.
3. For ArkUI components, inspect the static component declarations and local curated UI docs.
4. Use only the explicitly verified API surface. Do not invent method names, parameter shapes, or return types. If no accessible declaration or supported alternative exists, report the API as blocked.

## Verify
- compile after one change
- rerun the smallest path that touches the changed code
- for OHOS apps, use the verified project-native build and the available authorized previewer or device surface. Do not treat a single `.ets` preview as equivalent to a HAP build or real-device evidence.
- if Hvigor succeeds but prints warnings from SDK `.d.ets` files, keep focus on project-file diagnostics

## Return
- return here after any specialist doc resolves its blocker
