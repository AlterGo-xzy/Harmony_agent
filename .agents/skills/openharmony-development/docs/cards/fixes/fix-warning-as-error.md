---
guide_id: fixes/fix-warning-as-error
family: fixes
tags: fix, warnings, werror, quality-gates
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, modernize-arkts, optimize-arkts, review-arkts
related_diagnostics:
related_migration_patterns: any-or-unknown
status: active
---
# Fix Warning-As-Error Failures By Applying The Suggested Rewrite

## Intent

Resolve `werror`-style failures by understanding the warning category and applying the underlying ArkTS rewrite, not by disabling enforcement first.

## Use When

- compiler warnings are promoted to errors via `ets-werror`
- a compile passes without `werror` but fails with it enabled
- modernization is blocked by warning debt

## Do

- inspect the warning category
- apply the suggested ArkTS rewrite
- suppress only after deciding the rewrite is not appropriate for the codebase

## Avoid

- immediately turning `werror` off
- treating all warnings as style-only
- suppressing categories without documenting the tradeoff

## Migration Notes

Warnings often point directly at where the code still follows TypeScript habits instead of ArkTS-native patterns.

## Related Diagnostics

No stable diagnostic ID is recorded for this card; route by skill, tag, or migration pattern.

## Status

Active. Repair card for quality-gated builds.
