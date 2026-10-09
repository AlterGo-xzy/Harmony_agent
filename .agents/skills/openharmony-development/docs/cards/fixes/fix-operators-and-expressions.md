---
guide_id: fixes/fix-operators-and-expressions
family: fixes
tags: fix, operator, expression, typeof, is, in, unary, binary, instanceof, comma
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:BinaryOperations, linter-fault:CaseExpression, linter-fault:CommaOperator, linter-fault:InOperator, linter-fault:InstanceofUnsupported, linter-fault:InteropEqualityJudgment, linter-fault:InteropJsInstanceof, linter-fault:IsOperator, linter-fault:PrefixUnaryInfinity, linter-fault:RegularExpressionLiteral, linter-fault:SpreadOperator, linter-fault:SwitchExpression, linter-fault:TypeQuery, linter-fault:UnaryArithmNotNumber, linter-fault:UnsupportOperator, linter-fault:VoidOperator
related_migration_patterns: any-or-unknown
status: active
---
# Fix Operator and Expression Errors

## Intent

Fix operator and expression errors by replacing TS-specific operators with ArkTS-compatible alternatives.

## Use When

- code uses `typeof` in a type position as a type query
- code uses `in` to test property existence on an object
- code uses the comma operator or applies unary arithmetic to non-number values

## Do

- replace `typeof` type queries with explicit type annotations or interface references
- replace `in` checks with `instanceof` or an explicit property-check method
- remove comma operator usage by splitting into separate statements
- cast operands to `number` before applying unary arithmetic; replace `Infinity` with `Number.POSITIVE_INFINITY`

## Avoid

- using `typeof x` in type positions; it is only valid as a runtime expression guard
- relying on `in` for structural property testing
- chaining expressions with the comma operator for side effects
- assuming unary `+` or `-` will coerce non-number values automatically

## Migration Notes

ArkTS restricts operators to enforce static type safety. Most fixes involve replacing a single-expression idiom with a multi-statement equivalent or an explicit type annotation.


## Related Diagnostics

- `linter-fault:BinaryOperations`
- `linter-fault:CaseExpression`
- `linter-fault:CommaOperator`
- `linter-fault:InOperator`
- `linter-fault:InstanceofUnsupported`
- `linter-fault:InteropEqualityJudgment`
- `linter-fault:InteropJsInstanceof`
- `linter-fault:IsOperator`
- `linter-fault:PrefixUnaryInfinity`
- `linter-fault:RegularExpressionLiteral`
- `linter-fault:SpreadOperator`
- `linter-fault:SwitchExpression`
- `linter-fault:TypeQuery`
- `linter-fault:UnaryArithmNotNumber`
- `linter-fault:UnsupportOperator`
- `linter-fault:VoidOperator`

## Status
Active. Use this card when fixing operator and expression diagnostic errors during ArkTS migration.
