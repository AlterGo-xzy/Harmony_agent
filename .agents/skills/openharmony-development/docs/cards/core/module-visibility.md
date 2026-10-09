---
guide_id: core/module-visibility
family: core
tags: modules, imports, exports, visibility, build-system
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, fix-arkts-errors, modernize-arkts, review-arkts
related_diagnostics: linter-fault:ImportAfterStatement, linter-fault:DeclWithDuplicateName
related_migration_patterns: commonjs-exports, export-signature-consistency
source_refs: examples/migration-before-after/js-commonjs-before.js, examples/migration-before-after/arkts-module-after.ets
status: active
---
# Keep Imports, Exports, And Visibility Explicit

## Intent

Design module boundaries so names, export surfaces, and import placement are obvious and tool-friendly.

## Use When

- creating a new module API
- fixing visibility or import-order errors
- migrating CommonJS or TypeScript namespace patterns
- migrating exported APIs that mention local non-exported classes, interfaces, namespaces, or aliases

## Do

- keep imports at the top of the file
- export only explicit supported symbols
- make visibility part of the API design, not a side effect
- ensure exported signatures, public members, and namespace exports reference only exported local declarations or imported symbols

## Avoid

- relying on `require` or assignment-style export forms
- mixing unrelated declarations before imports
- leaking private or internal types through public signatures
- leaving exported generic constraints or class heritage clauses coupled to internal-only declarations

## Migration Notes

TypeScript module systems allow patterns that map poorly to ArkTS. Prefer a clean explicit module surface instead of preserving syntax. Export-consistency applies to exported functions, type aliases, classes, interfaces, namespace members, and public members of exported types.

## Related Diagnostics

- `linter-fault:ImportAfterStatement`
- `linter-fault:DeclWithDuplicateName`

## Status

Active. Important for library boundaries and multi-file migrations.
