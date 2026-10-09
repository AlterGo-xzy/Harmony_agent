---
guide_id: fixes/fix-interop-and-js
family: fixes
tags: fix, interop, javascript, js, esobject, esvalue, property restrictions
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:InstantiatedJsOjbect, linter-fault:InteropCallObjectMethods, linter-fault:InteropIncrementDecrement, linter-fault:InteropJsObjectConditionJudgment, linter-fault:InteropJsObjectTraverseJsInstance, linter-fault:JsxElement, linter-fault:NoAwaitJsPromise
related_migration_patterns: implicit-dynamic-shapes
status: active
---
# Fix Interop and JavaScript Boundary Violations

## Intent

Fix interop boundary violations where ArkTS code incorrectly accesses or operates on JavaScript values by introducing proper ESObject wrappers and explicit conversions.

## Use When

- code accesses properties on a JavaScript object directly from ArkTS
- code applies ArkTS operators to interop values without conversion
- code passes or returns JavaScript values across the interop boundary without wrapping

## Do

- use `ESObject` to type JavaScript values received at the interop boundary
- convert interop values explicitly to ArkTS types before further use on the ArkTS side
- access JavaScript object properties only through the approved interop API, not via direct dot or bracket access
- respect the restricted operation set on interop values and convert before storing or passing

## Avoid

- treating JavaScript objects as if they were ArkTS class instances
- applying arithmetic, comparison, or logical operators directly to interop values
- assuming JavaScript property access semantics carry over to ArkTS
- ignoring the ESObject boundary when mixing ArkTS and JS modules

## Migration Notes

Interop errors arise when migrated code still assumes TypeScript-style dynamic access to JavaScript objects. Introducing an explicit ESObject boundary layer is usually the cleanest fix.


## Related Diagnostics

- `linter-fault:InstantiatedJsOjbect`
- `linter-fault:InteropCallObjectMethods`
- `linter-fault:InteropIncrementDecrement`
- `linter-fault:InteropJsObjectConditionJudgment`
- `linter-fault:InteropJsObjectTraverseJsInstance`
- `linter-fault:JsxElement`
- `linter-fault:NoAwaitJsPromise`

## Status
Active. Use this card when fixing JavaScript interop boundary diagnostic errors during ArkTS migration.
