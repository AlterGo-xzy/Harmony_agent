---
guide_id: fixes/fix-numeric-semantics
family: fixes
tags: fix, numeric, number, bigint, char, relational operators, primitive types, modernization
related_skills: arkts-skill, modernize-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:LongNumeric, linter-fault:NondecimalBigint, linter-fault:NumericBigintCompare, linter-fault:NumericSemantics, linter-fault:NumericUnsignedShiftBehaviorChange
related_migration_patterns: any-or-unknown
status: active
---
# Fix Numeric Literal, Conversion, and Relational Comparison Errors

## Intent

Fix numeric literal, conversion, and relational comparison errors by respecting ArkTS numeric type boundaries and explicit conversion rules.

## Use When

- code uses numeric literals that exceed the allowed range for their declared type
- code compares values across disallowed numeric boundaries in `<`, `<=`, `>`, or `>=`
- code compares `char` against a numeric type or another `char` with a relational operator
- code compares a numeric type against `bigint` directly

## Do

- ensure numeric literals fall within the allowed range for their target type
- treat the widening hierarchy as `byte < short < int < long < float < double`, with `number` following `double`
- keep already valid widening comparisons unchanged, such as `int` against `number`
- for disallowed mixed numeric comparisons, convert the narrower side to the wider operand type with `.toByte()`, `.toShort()`, `.toInt()`, `.toLong()`, `.toFloat()`, or `.toDouble()`
- for `char` against a numeric operand in a relational operator, convert the `char` operand to the comparison target type
- for `char` against `char` in a relational operator, convert both operands explicitly before comparing
- for numeric values against `bigint`, use `BigInt(nonBigintExpr)` on the non-`bigint` operand and preserve the original relational operator
- preserve the operator token and rewrite only the operands during modernization
- declare the intended numeric type explicitly when the compiler cannot infer it from context

## Avoid

- using numeric literals that exceed the representable range of their target type
- comparing `bigint` directly with any non-`bigint` operand
- using `char` directly in relational operators
- relying on implicit numeric coercion between different numeric types
- attempting to modernize equality operators with this rule; the scope here is relational operators only
- guessing union-typed or runtime-only comparison fixes that are not compile-time obvious

## Migration Notes

ArkTS widening for relational numeric operators follows the built-in hierarchy only: `byte < short < int < long < float < double`, with `number` treated as `double`. `bigint` does not belong to that hierarchy, and `char` is not a numeric type.

For modernization, keep valid widening comparisons as they are:

- `function foo(x: int, y: number) { return x > y }`

Use explicit operand rewrites for illegal relational comparisons:

- `x: char`, `y: number`:
  `x > y` -> `x.toDouble() > y`
- `left: char`, `right: char`:
  `left < right` -> `left.toDouble() < right.toDouble()`
- `small: short`, `wide: long` when the comparison is not already accepted in the source form:
  `small <= wide` -> `small.toLong() <= wide`
- `count: int`, `limit: bigint`:
  `count < limit` -> `BigInt(count) < limit`

`BigInt(nonBigintExpr)` is the canonical modernization shape for mixed `bigint` comparisons in this card. That rewrite can be precision-sensitive for floating-point expressions, so only compile-time-obvious and truth-preserving cases should be autofixed. Ambiguous or potentially lossy cases should be reported for manual review instead of guessed.

## Related Diagnostics

- `linter-fault:LongNumeric`
- `linter-fault:NondecimalBigint`
- `linter-fault:NumericBigintCompare`
- `linter-fault:NumericSemantics`
- `linter-fault:NumericUnsignedShiftBehaviorChange`

## Status

Active. Use this card for numeric literal, explicit conversion, and relational comparison repairs during modernization or diagnostic-driven fixes.
