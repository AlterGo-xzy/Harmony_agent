---
guide_id: core/numeric-semantics
family: core
tags: numeric-semantics, arithmetic, integer-division, migration
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, optimize-arkts, review-arkts
related_diagnostics: linter-fault:NumericSemantics
related_migration_patterns: any-or-unknown
status: active
---
# Treat Numeric Semantics As An ArkTS Design Choice

## Intent

Avoid writing arithmetic that assumes JavaScript or TypeScript numeric behavior when ArkTS selects a more specific numeric interpretation.

## Use When

- migrating arithmetic-heavy TypeScript code
- reviewing division, indexing, or range logic
- investigating surprising integer results

## Do

- make numeric intent explicit
- review division and conversion paths carefully
- treat integer-vs-floating behavior as part of the design

## Avoid

- assuming `number` always behaves like TypeScript `number`
- relying on implicit widening for correctness
- hiding numeric behavior behind loosely typed helper code

## Migration Notes

One of the easiest TypeScript-to-ArkTS regressions is arithmetic that accidentally shifts from floating-point expectations to integer behavior.

## Related Diagnostics

- `linter-fault:NumericSemantics`

## Status

Active. Important for migrations and product logic involving arithmetic or indexing.
