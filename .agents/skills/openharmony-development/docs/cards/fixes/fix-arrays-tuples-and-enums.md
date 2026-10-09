---
guide_id: fixes/fix-arrays-tuples-and-enums
family: fixes
tags: fix, array, tuple, enum, iteratorresult, indexing, resizable-array
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:BuiltinIteratorResultValue, linter-fault:EnumMerging, linter-fault:LargeNumericLiteral, linter-fault:NoTuplesArrays, linter-fault:NosparseArray, linter-fault:RuntimeArrayCheck, linter-fault:UninitializedArrayElements, linter-fault:UnsupportPropNameFromValue, linter-fault:unfixedTuple
related_migration_patterns: any-or-unknown
source_refs: examples/migration-before-after/ts-enum-as-conversion-before.ts, examples/migration-before-after/arkts-enum-conversion-after.ets
status: active
---
# Fix Array, Tuple, and Enum Usage Errors

## Intent

Fix array, tuple, and enum usage errors by aligning with ArkTS restrictions on these types, which enforce stricter literal typing, member access, and iteration patterns.

## Use When

- code uses tuple types with operations that ArkTS restricts or rejects
- code uses array literals without a context type that ArkTS can infer from
- code accesses enum members by index or uses enum patterns that ArkTS forbids
- code uses `IteratorResult` without a concrete typed result value
- array indexes or loop counters use `long`, `float`, `double`, or `number`

## Do

- provide an explicit context type for array literals so ArkTS can infer element types
- replace untyped `IteratorResult` usage with a concrete typed result, e.g. `IteratorResult<T>`
- declare enum members with explicit types when ArkTS requires it
- use index-based access on arrays only with numeric literal or typed index expressions
- avoid destructuring tuples beyond their declared length
- treat `T[]` and `Array<T>` as the same resizable array type
- use `byte`, `short`, or `int` for array indexes; convert other numeric values explicitly

## Avoid

- using array literals in positions where ArkTS cannot infer a context type
- accessing enum members by computed or dynamic index
- relying on implicit `IteratorResult` typing without a concrete type parameter
- assuming tuple spread or rest patterns behave identically to TypeScript

## Migration Notes

ArkTS enforces stricter rules on array, tuple, and enum constructs to guarantee static type safety. Most fixes involve adding explicit type annotations or replacing dynamic access patterns with statically-resolvable alternatives.

Resizable arrays have equivalent `T[]` and `Array<T>` forms. Their length may
change at runtime, and valid indexes range from `0` through `length - 1`.

```typescript
let values: string[] = ["a", "b"]
let index: int = 1
console.log(values[index])

let longIndex: long = 0
console.log(values[longIndex.toInt()])
```

Array index expressions accept `byte`, `short`, or `int`. Convert `long`,
`float`, `double`, and `number` explicitly with `.toInt()`.


## Related Diagnostics

- `linter-fault:BuiltinIteratorResultValue`
- `linter-fault:EnumMerging`
- `linter-fault:LargeNumericLiteral`
- `linter-fault:NoTuplesArrays`
- `linter-fault:NosparseArray`
- `linter-fault:RuntimeArrayCheck`
- `linter-fault:UninitializedArrayElements`
- `linter-fault:UnsupportPropNameFromValue`
- `linter-fault:unfixedTuple`

## Status

Active. Use this card when fixing array, tuple, or enum diagnostic errors during ArkTS migration.
