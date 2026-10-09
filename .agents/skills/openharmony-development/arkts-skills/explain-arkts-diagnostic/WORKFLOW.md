---
name: explain-arkts-diagnostic
description: Explain ArkTS diagnostics, likely causes, and safe fixes without editing code.
---

# explain-arkts-diagnostic

## Purpose
Explain ArkTS diagnostics, likely root causes, and safe fix options without directly modifying code.

## Read First
- `docs/guide-usage.md`
- `docs/diagnostics/`
- `docs/cards/fixes/`
- `docs/curated/`
- `docs/diagnostics/`

## Inputs
- diagnostic id, message, or normalized diagnostics JSON
- optional file or project path for local context

## Workflow
1. Start from the diagnostic the user supplied or the narrowest project-native compiler/build output. If the optional `arkts-compile` wrapper is available for a standalone `.ets` file, its normalized fields may be used; do not require it for a project build.
2. Resolve the diagnostic family in `docs/diagnostics/`.
3. Select cards whose frontmatter includes `explain-arkts-diagnostic` in `related_skills`.
4. Explain what the diagnostic means in ArkTS terms, not just what the tool printed.
5. List likely causes, safe fixes, and unsafe fixes or anti-patterns.
6. If the user wants edits, hand the case off to `fix-arkts-errors`.

## Output
- meaning of the diagnostic
- likely causes
- safe fixes and risky fixes to avoid
- cited guides and diagnostic docs
