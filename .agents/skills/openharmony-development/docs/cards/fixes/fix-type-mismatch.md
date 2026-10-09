---
guide_id: fixes/fix-type-mismatch
family: fixes
tags: fix, type-mismatch, assignability, overrides
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic
related_diagnostics: linter-fault:FieldTypeMismatch, linter-fault:MethodInheritRule, ESE0087, ESE0091
related_migration_patterns: overload-signatures-with-single-body, structural-typing-assumptions
status: active
---
# Fix Type Mismatches By Tightening The Model

## Intent

Resolve type mismatch failures by aligning the data model or signature contract, not by weakening the checker.

## Use When

- an assignment or return is rejected
- an override violates the inherited contract
- a migrated function no longer matches its declared type

## Do

- inspect both sides of the contract
- fix the model, signature, or generic arguments explicitly
- verify whether a TypeScript assumption leaked into the code

## Avoid

- broad casts that hide the mismatch
- introducing `any` to unblock a compile
- changing public contracts casually during a local fix

## Migration Notes

Type mismatches are often symptoms of a larger migration issue, especially around overrides, structural typing, or nullable flows.

## Related Diagnostics

- `linter-fault:FieldTypeMismatch`
- `linter-fault:MethodInheritRule`

## Status

Active. First repair card for assignability and compatibility failures.
