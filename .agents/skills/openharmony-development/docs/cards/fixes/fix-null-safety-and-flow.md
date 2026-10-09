---
guide_id: fixes/fix-null-safety-and-flow
family: fixes
tags: fix, null, undefined, optional, truthy, falsy, nullable, catch
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:CatchWithUnsupportedType, linter-fault:MethodReassignment, linter-fault:OptionalMethod, linter-fault:OptionalMethodFromSdk, linter-fault:OptionalTupleType, linter-fault:PromiseVoidNeedResolveArg, linter-fault:TsLikeCatchType
related_migration_patterns: undefined-and-dynamic-values
status: active
---
# Fix Null Safety and Flow Errors

## Intent

Fix null-safety and control-flow errors by making nullable states explicit and narrowing types before use, since ArkTS enforces strict nullability checking.

## Use When

- code uses truthy/falsy checks to guard nullable values
- code catches exceptions without typing the catch variable
- code passes a nullable value to a parameter that requires a non-nullable type
- code omits null checks before dereferencing optional properties

## Do

- use explicit `!= null` or `!= undefined` checks instead of truthy/falsy coercion
- annotate catch clause variables with `Error` or a specific Error subtype
- use optional chaining (`?.`) and nullish coalescing (`??`) where the language supports them
- narrow nullable types with an explicit guard before passing to non-nullable parameters
- declare optional fields and parameters with `T | null` or `T | undefined` rather than leaving nullability implicit

## Avoid

- relying on falsy coercion (`if (x)`) to check for null or undefined
- leaving catch variables untyped or typed as `unknown` without narrowing
- suppressing null warnings with non-null assertions (`!`) unless the value is provably non-null
- passing nullable values through without narrowing in the hope that downstream code handles it

## Migration Notes

ArkTS strict null checking surfaces issues that TypeScript's `strictNullChecks` flag would also catch. The companion card `core/null-safety.md` covers foundational null-safety patterns; this card adds coverage for truthy-guard and catch-clause diagnostics.


## Related Diagnostics

- `linter-fault:CatchWithUnsupportedType`
- `linter-fault:MethodReassignment`
- `linter-fault:OptionalMethod`
- `linter-fault:OptionalMethodFromSdk`
- `linter-fault:OptionalTupleType`
- `linter-fault:PromiseVoidNeedResolveArg`
- `linter-fault:TsLikeCatchType`

## Status
Active. Companion to core/null-safety.md; adds catch-clause and truthy-guard diagnostic coverage.
