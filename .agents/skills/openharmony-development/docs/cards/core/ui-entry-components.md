---
guide_id: core/ui-entry-components
family: core
tags: ui, arkui, entry, component, state, product-code
related_skills: implement-arkts, review-arkts, modernize-arkts
related_diagnostics: linter-fault:EntryAnnotation, linter-fault:DecoratorsNotSupported
related_migration_patterns: decorators-not-supported
source_refs: examples/minimal/hello_ui.ets, examples/minimal/hello_app.ets
status: active
---
# Build UI Pages As Explicit `@Entry` And `@Component` Structs

## Intent

Use the supported ArkUI page shape for simple product UI instead of inventing framework syntax.

## Use When

- starting a new ArkTS UI page
- creating a minimal app entry screen
- reviewing migrated UI code that mixes TS decorators with ArkUI annotations

## Do

- define the page as a `struct` with `@Entry` and `@Component`
- keep mutable view state explicit with `@State`
- place UI nodes inside `build()` using ArkUI builder calls such as `Column()`, `Text()`, and `Button()`

## Avoid

- inventing React-, Vue-, or JSX-style UI syntax
- adding dynamic parameters to `@Entry`
- mixing unsupported TypeScript decorators into ArkUI component code

## Migration Notes

UI migration should preserve the screen behavior, not the original framework syntax. Rewrite the page into ArkUI annotations and builder-style component calls first, then handle state flow.

## Related Diagnostics

- `linter-fault:EntryAnnotation`
- `linter-fault:DecoratorsNotSupported`

## Status

Active. Use this as the first-read card for simple ArkTS UI page generation.
