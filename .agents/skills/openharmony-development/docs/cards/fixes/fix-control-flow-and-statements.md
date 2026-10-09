---
guide_id: fixes/fix-control-flow-and-statements
family: fixes
tags: fix, statement, for-in, with, throw, var, destructuring, flow
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:DebuggerStatement, linter-fault:DestructuringAssignment, linter-fault:DestructuringDeclaration, linter-fault:DestructuringParameter, linter-fault:EntryHasInvalidLocalStorageWithV2, linter-fault:EnumMemberNonConstInit, linter-fault:ForInStatement, linter-fault:InteropCallReflect, linter-fault:MissingSuperCall, linter-fault:ThrowStatement, linter-fault:VarDeclaration, linter-fault:WithStatement
related_migration_patterns: truthy-falsy-control-flow
status: active
---
# Fix Control Flow and Statement Errors

## Intent

Fix statement and control flow errors by replacing forbidden statement forms with ArkTS-compatible alternatives, since ArkTS prohibits several legacy JavaScript statement patterns.

## Use When

- code uses `for...in` to iterate over object keys
- code uses a `with` statement for scope manipulation
- code throws a non-Error value (string, number, or plain object)
- code declares variables with `var` instead of `let` or `const`
- application code needs an error carrying structured context

## Do

- replace `for...in` with `for...of` over `Object.keys()` or `Object.entries()`
- remove `with` statements entirely and qualify property access explicitly
- restrict `throw` to Error subtypes only; wrap raw values in `new Error()`
- replace `var` with `let` or `const`; replace destructuring with explicit individual assignments
- represent a new error category with a class that extends `Error`

## Avoid

- using `for...in` for any iteration purpose
- relying on `with` for implicit scope binding
- throwing strings, numbers, or untyped objects
- mixing `var` with block-scoped declarations in migrated code

## Migration Notes

ArkTS removes several legacy JavaScript statement forms to enforce predictable control flow. Most fixes are mechanical one-to-one replacements.

Custom application errors may directly extend `Error`:

```typescript
class ParseError extends Error {
  readonly line: int

  constructor(message: string, line: int) {
    super(message)
    this.line = line
  }
}
```

Throw the typed error and catch it as `Error`; use `instanceof ParseError` when
the structured fields are needed.


## Related Diagnostics

- `linter-fault:DebuggerStatement`
- `linter-fault:DestructuringAssignment`
- `linter-fault:DestructuringDeclaration`
- `linter-fault:DestructuringParameter`
- `linter-fault:EntryHasInvalidLocalStorageWithV2`
- `linter-fault:EnumMemberNonConstInit`
- `linter-fault:ForInStatement`
- `linter-fault:InteropCallReflect`
- `linter-fault:MissingSuperCall`
- `linter-fault:ThrowStatement`
- `linter-fault:VarDeclaration`
- `linter-fault:WithStatement`

## Status
Active. Use this card when fixing control flow and statement diagnostic errors during ArkTS migration.
