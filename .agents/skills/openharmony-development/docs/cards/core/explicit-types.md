---
guide_id: core/explicit-types
family: core
tags: explicit-types, typing, any, unknown, product-code
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, fix-arkts-errors, modernize-arkts, review-arkts
related_diagnostics: linter-fault:AnyType, linter-fault:UnknownType
related_migration_patterns: any-or-unknown
source_refs: examples/migration-before-after/ts-any-before.ts, examples/migration-before-after/arkts-explicit-type-after.ets
status: active
---
# Prefer Explicit Types Over `any` And `unknown`

## Intent

Keep generated ArkTS product code explicit and type-safe instead of relying on TypeScript escape hatches.

## Use When

- a migration introduces `any` or `unknown`
- generated code leaves placeholder types behind
- a fix is tempted to silence the checker with a broad type

## Do

- model data with a class or interface
- introduce a constrained generic when the shape is reusable
- keep type annotations explicit when inference is not obvious

## Avoid

- replacing `any` with `unknown` without a narrowing plan
- forcing casts that only make the error disappear
- leaving partially typed product APIs

## Migration Notes

TypeScript code often uses `any` to move quickly. In ArkTS, that usually means the code model is incomplete and should be rewritten toward an explicit contract.

## Related Diagnostics

- `linter-fault:AnyType`
- `linter-fault:UnknownType`

## Status

Active. This is a first-read card for product-code generation and TypeScript migration.
