---
guide_id: core/null-safety
family: core
tags: null-safety, undefined, strict-typing, runtime-safety
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, fix-arkts-errors, modernize-arkts, review-arkts
related_diagnostics:
related_migration_patterns: undefined-and-dynamic-values
status: active
---
# Treat Null Safety As A Compile-Time Requirement

## Intent

Write ArkTS so nullable and undefined-like flows are explicit and checked early.

## Use When

- porting code that relies on `undefined`
- handling optional results or partially initialized data
- fixing checker complaints around nullable access

## Do

- make nullable shapes explicit in the type
- narrow before use
- structure code so invalid states are hard to represent

## Avoid

- assuming `undefined` is a universal fallback value
- deferring null checks until runtime
- weakening types to avoid a null-safety error

## Migration Notes

TypeScript often tolerates value flows that ArkTS rejects or treats as potential runtime faults. Rewrite the data model first, then fix the use sites.

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. This is part of the default quality bar for generated product code.
