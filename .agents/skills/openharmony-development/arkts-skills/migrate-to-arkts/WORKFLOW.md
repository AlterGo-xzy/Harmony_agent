---
name: migrate-to-arkts
description: Migrate source code into ArkTS using curated source-language guidance.
---

# migrate-to-arkts

## Purpose
Migrate source code from TypeScript or related languages into idiomatic ArkTS with bounded rewrites and tool feedback.

## Read First
- **`arkts-skills/arkts-skill/WORKFLOW.md` — for static ArkTS (arkts-static) coding only. Follow this skilltree for all static ArkTS patterns, rewrite moves, and the TS-to-ArkTS table. Skip it when migrating to dynamic ArkTS paths.**
- `docs/guide-usage.md`
- `docs/cards/migration/`
- `docs/cards/core/`
- `docs/cards/fixes/`
- `docs/curated/`
- `docs/cards/migration/`

## Inputs
- source language
- source files
- migration target path
- semantic constraints to preserve

## Workflow
1. For static ArkTS (arkts-static) migration, follow `arkts-skills/arkts-skill/WORKFLOW.md` for all coding patterns, rewrite moves, and routing. Skip the skilltree when migrating to dynamic ArkTS.
2. Select relevant migration cards by their `related_migration_patterns` frontmatter.
3. Select the matching TypeScript or JavaScript migration references.
4. Identify source-language constructs that do not map directly to ArkTS.
5. Rewrite semantics first; do not preserve source-language syntax habits when they conflict with ArkTS.
6. When the optional `arkts-migrate` helper exists, use it for an additional migration inventory; otherwise perform the inventory from the selected cards and source evidence.
7. Validate the migrated result with the project-native compiler/build. For a standalone file, an available compiler or optional `arkts-check` wrapper is acceptable. See `arkts-skills/references/compiler-wrapper-interface.md`.
8. If compiler or lint diagnostics remain, repair them in the same run with the `fix-arkts-errors` workflow and linked diagnostics docs.
9. Rerun the same compiler or project-native build after each bounded fix pass until the touched migration output is compile-clean, or report the exact blocker.
10. Call out any unresolved source-language leakage explicitly.

## Output
- migrated ArkTS code
- migration notes and unresolved incompatibilities
- cited migration and repair guides
