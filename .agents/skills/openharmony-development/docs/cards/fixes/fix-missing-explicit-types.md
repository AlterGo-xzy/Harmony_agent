---
guide_id: fixes/fix-missing-explicit-types
family: fixes
tags: fix, explicit-types, any, unknown, modeling
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, modernize-arkts
related_diagnostics: linter-fault:AnyType, linter-fault:UnknownType
related_migration_patterns: any-or-unknown
source_refs: examples/migration-before-after/ts-any-before.ts, examples/migration-before-after/arkts-explicit-type-after.ets
status: active
---
# Fix Missing Explicit Types By Introducing A Real Contract

## Intent

Repair loosely typed code by naming the contract the code actually depends on.

## Use When

- a variable, parameter, or return value is typed as `any` or `unknown`
- a quick migration left placeholder types behind
- a fix recipe suggests explicit modeling

## Do

- add a class, interface, or constrained generic
- update the call sites to match that contract
- keep the type local and obvious if the scope is narrow

## Avoid

- substituting one vague type for another
- casting away the problem
- allowing placeholders to remain in product-facing APIs

## Migration Notes

This fix is frequently the first cleanup step after TypeScript migration.

## Related Diagnostics

- `linter-fault:AnyType`
- `linter-fault:UnknownType`

## Status

Active. Preferred repair card for loose typing findings.
