# OHOS app failures

Use this only after the first direct wiring fix failed. Re-verify the canonical diagnostics first.

## App launches but shows the wrong page
Re-verify `loadContent('pages/...')` → `main_pages.json` → page file path. See `35-10-app-model-and-system-apis.md` and `35-30-project-layout-and-build-surfaces.md`.

## New page exists but router or startup cannot reach it
Re-verify all three: page file under `entry/`, route in `main_pages.json`, and `module.json5` still points at `$profile:main_pages`. See `35-30-project-layout-and-build-surfaces.md`.

## App identity or build config edit had no effect
Separate the fix: app identity is in `AppScope/app.json5`; module-level wiring is in `module.json5`. Keep them as separate fix passes.

## Module wiring and page wiring were edited together
Separate the fix passes. Fix the module-level change (in `module.json5`) and the page-level change (in `main_pages.json`) independently. Only then test the full app flow.

## Load callback reports failure
Treat this as startup wiring, not page-local UI. Verify the route string in `loadContent(...)` matches `main_pages.json`. Do not touch page trees yet.

## HAP build prints SDK declaration warnings
```text
build succeeds but output contains `Warning W0440`, `Warning W685267`, or ambient-context warnings in SDK `.d.ets` files
```
Move: do not rewrite app code for SDK declaration warnings when Hvigor reports `BUILD SUCCESSFUL`. Only fix diagnostics that point to project files or make the build fail.

## HAP preview fails after successful build
```text
Hvigor build succeeds, but preview logs `LinkerVerificationError`, internal `NullPointerError`, or screenshots do not update
```
Move:
- `LinkerVerificationError` naming a component → inline that component at the call site and rebuild
- `LinkerVerificationError` with `Abstract interpretation failed` and `StateContext` in a `lambda_invoke-N` signature → a `@Builder` contains a loop whose closures capture `@State`. Replace with pre-computed `@State` arrays + `ForEach` in `build()`. See `30-40-arkui-failures.md` for the full fix recipe.
- internal `ArkTS Application.updateState` `NullPointerError` with first frame still produced → treat as previewer evidence; continue only if app renders
- screenshots unchanged after clicks → put scenario-critical handlers in the page owning `@State`, then rebuild and preview the HAP again

## Previewer cannot read rawfile data
```text
device path can read rawfile, but CLI preview shows empty app data
```
Move:
- initialize small typed fallback data at module load
- attempt rawfile loading only when `resourceManager` returns content
- replace fallback data only after parsed data is non-empty

```ts
final class ItemList {
    items: string[] = []
}

let DATA: ItemList = new ItemList()

function fillDefaultData(): void {
    if (DATA.items.length > 0) { return }
    DATA.items.push('Demo')
}

fillDefaultData()

function initFromJson(json: string): void {
    let parsed = JSON.parseUpdate<ItemList>(json, new ItemList())
    if (parsed.items.length > 0) { DATA = parsed }
}
```

## Verify
- re-run the narrowest config or startup check first
- prove the targeted change alone restores the correct behavior

## Return
- wiring fixed → return to `../SKILL.md`
- bug moved into page trees → `../../30-arkui-path/30-40-arkui-failures.md`
