---
guide_id: fixes/fix-primitive-as-conversions
family: fixes
tags: fix, as-casts, numeric-conversion, primitives, modernization
related_skills: arkts-skill, modernize-arkts, fix-arkts-errors, review-arkts, explain-arkts-diagnostic
related_diagnostics:
related_migration_patterns: any-or-unknown
status: active
---
# Replace Primitive `as` Conversions With Explicit Conversion Methods

## Intent

Repair primitive `as` conversions by switching to the ArkTS conversion method that makes the new value explicit.

## Use When

- code casts a non-literal expression with `as byte`, `as short`, `as int`, `as long`, `as float`, `as double`, or `as number`
- a return statement uses `as` to force a primitive result type
- field access, call results, or arithmetic expressions are being cast to a primitive type
- patch review needs to inspect newly added `.ets` or `.yaml` lines for deprecated primitive `as` conversions
- legacy ArkTS relied on `as` both for reinterpretation and for primitive conversion, and only the conversion usage now needs rewriting
- text input must be converted to an ArkTS integer or floating-point value

## Do

- rewrite `expr as byte` to `expr.toByte()`
- rewrite `expr as short` to `expr.toShort()`
- rewrite `expr as int` to `expr.toInt()`
- rewrite `expr as long` to `expr.toLong()`
- rewrite `expr as float` to `expr.toFloat()`
- rewrite `expr as double` to `expr.toDouble()`
- rewrite `expr as number` to `expr.toDouble()`
- rewrite return expressions such as `return file.fd as int` to `return file.fd.toInt()`
- rewrite call results such as `foo() as int` to `foo().toInt()`
- rewrite parenthesized arithmetic such as `(a + b) as short` to `(a + b).toShort()`
- keep valid literal-context typing such as `1 as byte` and direct typed declarations such as `let domain: int = 0x0000`
- keep same-type cases such as `a as int` when `a` is already `int`
- preserve non-conversion uses of `as`, such as object-literal context and checked reinterpretation between reference types
- use `parseInt(text).toInt()` for integer text and `parseFloat(text)` for decimal text

## Avoid

- replacing valid same-type casts such as `a as int` when `a` is already `int`
- introducing a non-existent `.toNumber()` helper
- dropping parentheses when rewriting `(a + b) as short` to `(a + b).toShort()`
- treating literal-context casts and ordinary value conversions as the same operation
- rewriting removed lines from a patch or scanning unchanged files as if they were part of a diff-only review

## Migration Notes

Numeric conversion is now modeled as an explicit method call. This keeps conversion behavior local and predictable, while literal-context casts remain available when a numeric literal needs a target type.

`number` follows the `double` conversion path in the current skill contract. Developer examples may still mention `.toNumber()`, but the canonical modernization rewrite remains `.toDouble()` because `number` is treated as a `double` alias in the current ArkTS guidance.

Historically, ArkTS used `as` for three different jobs:

- reinterpret a value as another reference type
- provide target-type context for literals, array literals, object literals, or lambdas
- convert one primitive numeric value to another

Modernization for this rule removes only the third job. The guiding invariant is that `x as T` should keep referring to the same object or literal-context value, while primitive conversion must use explicit conversion methods.

Use this rewrite table for primitive-conversion findings:

- `1` `expr as byte` -> `expr.toByte()`
- `2` `expr as short` -> `expr.toShort()`
- `3` `expr as int` -> `expr.toInt()`
- `4` `expr as long` -> `expr.toLong()`
- `5` `expr as float` -> `expr.toFloat()`
- `6` `expr as double` -> `expr.toDouble()`
- `7` `expr as number` -> `expr.toDouble()`
- `8` `return file.fd as int` -> `return file.fd.toInt()`
- `9` `foo() as int` -> `foo().toInt()`
- `10` `(a + b) as short` -> `(a + b).toShort()`

Patch-review and diff-report expectations for this rule are:

- inspect only newly added lines in changed or added `.ets` and `.yaml` files
- ignore removed lines prefixed with `-`
- expand every changed `.ets` file before analysis so collapsed hunks do not hide findings
- report every analyzed `.ets` file path, even when no findings were present
- for each violation, include the full file path, line number, wrong line, rule number, short description, and minimal replacement diff

Treat these as non-findings for this rule:

- `let domain: int = 0x0000`
- `let b = 1 as byte`
- `a as int` when `a` is already `int`

For string input, parsing and narrowing are separate steps:

```typescript
let count: int = parseInt(text).toInt()
let ratio: double = parseFloat(text)
```

Validate untrusted input before using the result when malformed text is possible.

Literal caveats matter:

- literal-context `as` remains valid for numeric literals because `as` can still supply target-type context
- `let nn = 1` gives `nn` a fixed type, so `nn as byte` is no longer a literal-context case and should become `nn.toByte()`
- floating-point literals need the `f` suffix to be `float`; otherwise they are `double`

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. Use this repair card for primitive `as` conversions in modernization and patch review.
