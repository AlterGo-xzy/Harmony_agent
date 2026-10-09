---
name: fix-arkts-errors
description: Repair ArkTS code from compiler and linter diagnostics.
---

# fix-arkts-errors

## Purpose
Repair ArkTS code using normalized diagnostics, bounded fixes, and citation-backed repair cards. This is also a subworkflow of `implement-arkts` and `migrate-to-arkts`.

## Read First
- **`arkts-skills/arkts-skill/WORKFLOW.md` — for static ArkTS (arkts-static) fixes only. Follow this skilltree for all static ArkTS patterns and rewrite moves. Skip it when fixing dynamic ArkTS errors.**
- `docs/guide-usage.md`
- `docs/cards/fixes/`
- selected `docs/cards/migration/` when the failure came from migrated code
- `docs/curated/`
- `docs/diagnostics/`
- `arkts-skills/references/diagnostic-classification.md` — shared classification contract

## Inputs
- target file or project path
- compiler, linter, or checker diagnostics

## Workflow
1. For static ArkTS (arkts-static) fixes, follow `arkts-skills/arkts-skill/WORKFLOW.md` for all coding patterns, rewrite moves, and routing. Return to the skilltree after any specialist doc resolves a blocker. For dynamic ArkTS errors, skip the skilltree.
2. Start with the smallest truthful signal: the supplied diagnostic, the project-native compile/build/test command, or an optional wrapper that is actually available and appropriate. Use the full project graph for multi-module or local-HAR code. See `arkts-skills/references/compiler-wrapper-interface.md`.
3. Classify diagnostics before editing:
   - `failed`: diagnose root causes from the diagnostic family
   - `blocked`: explain the missing capability and avoid claiming a clean repair
   - `migration-leakage`: source-language pattern detected in migration context; load migration cards first
   See `arkts-skills/references/diagnostic-classification.md` for the full classification contract and 14 diagnostic clusters.
4. When a tool provides normalized diagnostics, use its primary diagnostic, source location, summary, and suggested references before raw output. Otherwise work directly from the native compiler output.
5. Group diagnostics by likely root cause before editing, and separate migration leakage from ordinary ArkTS mistakes.
6. Read the linked fix cards and diagnostics docs for the highest-value failures first.
7. Prefer safe local fixes, explicit types, null-safe rewrites, and smaller module/API surfaces over broad refactors.
8. Cite the guide or diagnostics family behind each non-obvious repair recommendation.
9. Re-run compile, lint, or combined checks after each bounded repair pass.
10. Stop when the code is clean, when the remaining issue is purely blocked by the environment, or when architectural decisions are required.

## Static Frontend Triage

- use this path for non-UI ArkTS files that fail in raw frontend compilation
- prefer a known-good file or module from the same project when you need a compile baseline
- compare the failing target against that local baseline before making broad edits
- if compilation succeeds but lint fails, treat the issue as style, migration, or policy repair rather than frontend breakage
- See `arkts-skills/references/diagnostic-classification.md` for the full static frontend triage procedure

## Output
- patched ArkTS code or a blocked report
- normalized diagnostics before and after
- cited fix guides used during repair
