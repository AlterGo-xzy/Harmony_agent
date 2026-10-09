---
name: optimize-arkts
description: Improve ArkTS performance or resource behavior without intended semantic changes.
---

# optimize-arkts

## Purpose
Improve ArkTS performance or resource behavior without intentionally changing observable semantics.

## Read First
- **`arkts-skills/arkts-skill/WORKFLOW.md`** — load before touching any ArkTS code; use its routing table for all API surfaces encountered
- `docs/guide-usage.md`
- `docs/cards/`
- `docs/cards/core/numeric-semantics.md`
- `docs/cards/core/warnings-as-quality-gates.md`
- `arkts-skills/arkts-skill/20-references/25-performance-habits.md` — canonical ArkTS performance patterns
- `docs/curated/`
- `docs/style/code-style.md`

## Inputs
- ArkTS files or project path
- optional performance goal, hotspot, or constraint

## Workflow
1. Read cards whose frontmatter includes `optimize-arkts` in `related_skills`.
2. Focus on concrete hotspots or warning-driven opportunities instead of generic "cleanup".
3. Preserve intended behavior while tightening numeric intent, control flow, allocations, or warning-heavy code paths.
4. Run the narrowest project-native compile, build, test, or benchmark that can detect semantic regressions. Use optional `arkts-check` only when it is available and suitable for the target.
5. Use `review-arkts` when optimization touches public APIs or subtle semantics. Do not claim a performance improvement without measurement evidence.
6. Report the optimization tradeoff and any remaining risks explicitly.

## Output
- optimized ArkTS code or a no-op report when no safe optimization is justified
- stated performance rationale and semantic risks
- cited guides used during optimization
