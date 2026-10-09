---
guide_id: fixes/fix-export-signature-consistency
family: fixes
tags: fix, exports, visibility, signatures, public-api, modernization
related_skills: migrate-to-arkts, modernize-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics:
related_migration_patterns: export-signature-consistency
status: active
---
# Export Local Types That Appear In Exported Signatures

## Intent

Repair exported ArkTS APIs so every local declaration referenced from the public signature is itself exported.

## Use When

- an exported function, method, class, interface, namespace member, or type alias references a local non-exported declaration
- an exported class heritage clause uses a local non-exported class or interface
- an exported generic bound references a local non-exported declaration
- modernizing legacy ArkTS that compiled before this exported-signature check became strict
- a non-exported API uses a local declaration and you need to confirm whether that is still valid

## Do

- add `export` to local classes, interfaces, namespaces, and type aliases that appear in exported signatures
- keep imported symbols unchanged; if a symbol is imported into the file, treat it as already exported from its defining module
- preserve internal-only declarations in non-exported functions, methods, and helper types
- update namespace-local declarations when an exported namespace member returns or accepts them
- export local declarations used in `extends`, `implements`, return types, parameter types, property types, and generic constraints when those clauses are part of an exported API
- redesign the API instead of exporting more symbols when the declaration must remain internal

## Avoid

- leaking file-local declarations through exported signatures and assuming the compiler will keep accepting it
- adding redundant exports to imported symbols
- exporting extra declarations mechanically when the better fix is to narrow the public API
- treating non-exported functions or methods as if they had the same export-consistency restriction

## Migration Notes

The strict rule is local: exported signatures may only reference other exported local declarations or imported symbols. Non-exported APIs can still use internal declarations freely.

The default modernization fix is:

- export the local declaration when it is intentionally part of the public API
- otherwise rewrite the exported API so the internal declaration no longer appears in the signature

Typical repair sites include:

- `export function foo(): X` where local `X` is not exported
- `export type B = A` where local `A` is not exported
- `export class B extends A implements I` where local `A` or `I` is not exported
- `export function foo<T extends A>(x: T)` where local `A` is not exported
- exported namespace members that mention local namespace declarations without `export`

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. Use for migration, repair, and modernization when exported signatures leak local non-exported declarations.
