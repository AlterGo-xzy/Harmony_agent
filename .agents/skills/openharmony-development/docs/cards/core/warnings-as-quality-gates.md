---
guide_id: core/warnings-as-quality-gates
family: core
tags: warnings, werror, quality-gates
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, modernize-arkts, optimize-arkts, review-arkts
related_diagnostics:
related_migration_patterns: any-or-unknown
status: active
---
# Treat Compiler Warnings As Design Feedback

## Intent

Use compiler warnings to improve code shape and performance instead of treating them as optional noise.

## Use When

- reviewing code quality
- deciding whether to enable `ets-werror`
- planning modernization after a successful compile

## Do

- inspect warning categories before suppressing them
- use warning output to drive targeted rewrites
- escalate to `werror` when a codebase is ready to enforce the rule

## Avoid

- blanket suppression before understanding the warning
- treating warning-clean and error-clean as the same thing
- rewriting code mechanically without checking the semantic intent

## Migration Notes

Warnings often expose where migrated code still behaves like TypeScript rather than idiomatic ArkTS.

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. Default review and modernization card.
