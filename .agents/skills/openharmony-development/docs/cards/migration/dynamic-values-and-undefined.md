---
guide_id: migration/dynamic-values-and-undefined
family: migration
tags: undefined, dynamic-values, ts-migration, null-safety, any, unknown, enums
related_skills: arkts-skill, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:AnyType, linter-fault:UnknownType
related_migration_patterns: undefined-and-dynamic-values, any-or-unknown, enum-as-conversions
status: active
---
# Replace Dynamic Value Flows With Explicit ArkTS States

## Intent

Rewrite TypeScript code that leans on `undefined`, `any`, `unknown`, or cast-based
enum conversions into explicit ArkTS states and conversions.

## Use When

- arrays, lookups, or API responses may yield `undefined`
- migrated code relies on loose truthiness checks
- runtime safety depends on late value validation
- a value is typed as `any` or `unknown`
- a regular enum is converted with `as`

## Do

- introduce explicit nullable or result-bearing types
- narrow values before use
- make absent states part of the function contract
- replace `any` or `unknown` with a named type or a constrained generic parameter
- use implicit widening or `valueOf()` from a regular enum to its base type
- use `EnumType.fromValue(value)` from a primitive value to a regular enum

## Avoid

- treating `undefined` as a universal placeholder
- deferring all validation until after migration
- widening types just to let dynamic flows compile
- replacing `any` with `unknown` without defining how the value is validated
- preserving `enumValue as int` or `numberValue as EnumType`
- applying regular-enum methods to a `const enum`

## Migration Notes

Define allowed states first, then update callers:

```typescript
let name: string | null = findName()
if (name != null) {
  console.log(name)
}
```

Replace `any` or `unknown` with a contract or generic:

```typescript
interface NamedValue {
  name: string
}
function label(value: NamedValue): string {
  return value.name
}
```

For regular enums, choose conversion by direction:

```typescript
enum Status { Pending, Active, Complete }
let status: Status = Status.Active
let code: number = status
let exactCode = status.valueOf()
let restored: Status = Status.fromValue(1)
```

`Status.fromValue(99)` throws at runtime when no regular enum member has that
value. These methods do not exist on `const enum`.

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## References

Values are non-nullable unless absence is explicit. Regular enums support
implicit widening, `valueOf()`, and checked `fromValue()` conversion.

## Status

Active. Default migration card when TypeScript semantics depend on runtime value flexibility.
