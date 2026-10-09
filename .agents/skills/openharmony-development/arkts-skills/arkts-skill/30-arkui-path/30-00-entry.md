# ArkUI path entry

Load this path only when the blocker is inside declarative UI code.

## Load this path when you see
- `@Entry`, `@Component`, `struct`, `build()`
- `@State`, `@Link`, `@PropRef`, `@Provide`, `@Consume`, `@StorageLink`, `@StorageProp`, `@Watch`, `@Builder`, `@Builder function`, `@Reusable`
- `@ObservedV2`, `@Trace`, `PersistenceV2`, `AppStorageV2`
- `Tabs`, `TabContent`, `List`, `LazyForEach`, `ForEach`, `Scroller`, `Menu`, `Video`, `Web`, `$rawfile`, gestures, layout modifiers
- `Search`, `SearchController`, `Divider`, `TextPickerDialog`, `Progress`, `SaveButton`, `ImageSpan`, `backgroundBlurStyle`
- `animateTo`, `keyframeAnimateTo`, `transition`, `sharedTransition`, `Swiper`, `SwiperController`, `@BuilderParam`, `UIUtils.makeBinding`, `Binding`
- `webview.WebviewController`, `onContextMenuShow`, `bindSelectionMenu`, `editMenuOptions`, `WebContextMenuResult`
- `HitTestMode`, `CopyOptions`, `.px2vp()`
- `.width()`, `.height()`, `.padding()`, `.margin()`, `.layoutWeight()`, `.constraintSize()`, `.border()`, `.borderRadius()`, `.shadow()`, `.opacity()`
- `.aspectRatio()`, `.alignItems(` string rejected, `.justifyContent(` string rejected, `FlexAlign`, `VerticalAlign`, `HorizontalAlign`, `Blank()`
- `.fontWeight()` with `'bold'`/`'medium'` strings vs `FontWeight.Bold` enum
- `$r(`, `$rawfile(`, `resourceManager`, resource qualifier issues
- JSON-backed UI data from rawfile or resources
- `TextInput`, `Toggle`, `Checkbox`, `Radio`, `Slider`, `Select`, `DatePicker`, `InputType`, `ToggleType`
- `Navigation`, `NavPathStack`, `NavDestination`, `pushPath`, `pop`, `replacePath`
- `CustomDialogController`, `AlertDialog`, `ActionSheet`, `@CustomDialog`
- `.gesture()`, `TapGesture`, `LongPressGesture`, `PinchGesture`, `RotationGesture`, `SwipeGesture`, `GestureGroup`
- `onPageShow`, `onPageHide`, `onBackPress`
- `.accessibilityText`, `.accessibilityLevel`, `.accessibilityGroup`, `.accessibilityDescription`

## Stay on the main ArkTS playbooks when
- the blocker is plain data shape, nullability, array ownership, or local typing
- the code is not in ArkUI UI trees

## Before importing an ArkUI symbol
```text
component, enum, attribute type, or helper is not already imported in this file
```
Next move:
1. Search `interface_sdk-js/api/arkui/component/*.static.d.ets` for the exact `export declare function`, `export declare enum`, `export declare interface`, or `export type`.
2. Import the symbol from `@ohos.arkui.component` only after the static declaration exists.
3. If the symbol is not in static SDK declarations, pick a declared alternative from this path instead of importing from dynamic docs.
4. For system APIs outside ArkUI components, read the exact available `.static.d.ets` declaration.

```ts
import { Button, Column, Image, Resource, Text, TextAlign, $r } from '@ohos.arkui.component'
```

## Load order inside this path
1. `30-10-ui-structure-and-state.md` for decorator-backed UI state and page/component shape (includes PersistenceV2 and AppStorageV2 patterns)
2. `30-15-styling-and-layout.md` for sizing, spacing, borders, color, and visual styling
3. `30-16-resources-and-assets.md` for $r(), $rawfile(), resourceManager, and resource qualifiers
4. `30-17-accessibility.md` for screen-reader labels, grouping, and accessibility levels
5. `30-20-routing-lifecycle-and-app-flow.md` for page routing, lifecycle hooks, and app flow blockers
5. `30-30-arkui-components-and-patterns.md` for list, grid, waterflow, linked scroller, tree, calendar grid, and datasource patterns
6. `30-32-tabs-overlays-and-gestures.md` for tab bars, overflow menus, video overlays, drag gestures, RelativeContainer flattening, animations, and multi-gesture patterns
7. `30-34-input-display-and-web.md` for search, pickers, progress bars, save buttons, web views, and touch/copy display options
8. `30-35-form-controls.md` for TextInput, TextArea, Toggle, Checkbox, Radio, Slider, Select, DatePicker, and form patterns
9. `30-36-scroll-containers.md` for Scroll, Scroller, Refresh/pull-to-refresh, nested scroll
9. `30-55-web-menus.md` for Web component context-menu, selection-menu, or edit-menu customization
10. `30-70-navigation-stack.md` for NavPathStack-based navigation (push, pop, replace, clear, back-press interception, split-pane)
11. `30-80-dialogs.md` for CustomDialogController, AlertDialog, ActionSheet, bottom sheets, and dismiss detection
12. `30-90-attribute-modifiers.md` — placeholder; do not load
13. `30-40-arkui-failures.md` only after the first direct UI fix fails

## Return rule
- if the blocker becomes app config, `UIAbility`, `module.json5`, `main_pages.json`, resources, or startup wiring, switch to `../35-ohos-app-path/35-00-entry.md`
- if the blocker becomes plain stored data shape, return to `../10-playbooks/11-data-and-state.md`
