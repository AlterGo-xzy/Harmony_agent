---
guide_id: fixes/fix-enum-as-conversions
family: fixes
tags: fix, enums, as-casts, valueof, fromvalue, modernization
related_skills: migrate-to-arkts, modernize-arkts, fix-arkts-errors, review-arkts, explain-arkts-diagnostic
related_diagnostics:
related_migration_patterns: enum-as-conversions
source_refs: examples/migration-before-after/ts-enum-as-conversion-before.ts, examples/migration-before-after/arkts-enum-conversion-after.ets
status: active
---
# Replace Enum `as` Conversions With Enum Conversion APIs

## Intent

Repair regular enum conversion code by using ArkTS enum conversion behavior instead of `as` casts between regular enums and primitive values.

## Use When

- code converts a regular enum to a numeric or string value with `as`
- code converts a primitive value to a regular enum with `as`
- code relies on legacy enum `as` casts that now produce compile-time errors or runtime failures
- migration or modernization needs to preserve valid enum literals while removing cast-based enum conversion

## Do

- prefer implicit enum-to-base-type assignment when the target type already accepts the enum base type
- otherwise rewrite explicit enum-to-primitive conversion to `e.valueOf()`
- rewrite primitive-to-regular-enum conversion to `E.fromValue(value)`
- preserve valid literal-context enum assignments when the value is accepted by the target enum
- keep direct enum-literal assignments such as `e = 1` only when the literal is accepted by the enum value set
- call out that `E.fromValue(value)` can fail at runtime when the value does not match a regular enum member
- call out that `e as int` and `i as E` are no longer valid conversion syntax for regular enums

## Avoid

- rewriting `e as int` or `value as E` as if they were ordinary primitive casts
- assuming enum `as` conversions are merely deprecated style when they now often lead to `CTE` or `RTE`
- inventing `fromValue()` or `valueOf()` calls on constant enums
- hiding out-of-range enum values behind a cast
- removing valid implicit widening from regular enums to their base numeric or string types

## Migration Notes

Regular enums already participate in ArkTS conversion rules: they widen to compatible base types, expose `valueOf()` on enum instances, and expose `fromValue()` on the enum type. Enum `as` casts should be treated as invalid modernization targets, not as legal conversions to preserve.

Use this direction table when modernizing:

- enum to primitive: prefer implicit widening such as `i = e`; otherwise use `e.valueOf()`
- primitive to enum: use `E.fromValue(value)` for non-literal values
- primitive literal to enum: preserve direct assignment only when the literal is accepted by the enum, such as `e = 1`; reject or rewrite out-of-range cases such as `e = 10`

`E.fromValue(value)` can throw at runtime when `value` does not correspond to an enum member. Constant enums are erased to their base type, so do not blindly apply regular-enum method rewrites there or treat constant-enum casts as evidence for this migration rule.

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. Use this repair card for regular enum `as` conversions during migration, modernization, and diff-based review.
