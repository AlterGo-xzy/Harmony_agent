# Using `modernize-arkts`

This guide explains how to make the `modernize-arkts` skill available through bootstrap, how to invoke it for a full modernization pass, and how to narrow it to specific rule packs.

## What `modernize-arkts` Does

`modernize-arkts` updates existing ArkTS toward current idioms, warning guidance, and cleaner maintainable patterns without changing intended behavior.

It is a product skill from `arkts-skills/`, so after bootstrap it is available from the runtime's managed skills directory.

The modernization workflow lives in the skill, while verification and diagnostics use the existing wrappers such as `arkts-check`, `arkts-compile`, and `arkts-lint`.

## Use It For A Full Modernization Pass

If you do not specify `target_rules`, `modernize-arkts` uses its full default guide set.

Typical prompts:

```text
Use modernize-arkts on src
```

```text
Use modernize-arkts on src/main/ets
```

```text
Use modernize-arkts on app.ets and summarize changed files, remaining warnings, and blocked verification
```

Use this default mode when you want the skill to choose all currently supported modernization rule packs automatically.

That default rule set now includes numeric comparison modernization for invalid relational comparisons involving mixed-width numeric operands, `char`, and `bigint`.
It also includes static-member inheritance modernization for invalid `Derived.field` and `Derived.foo(...)` access patterns that must be retargeted to the declaring class.

## Narrow It To Individual Rule Packs

If you want only specific modernization rules, pass exact guide ids with `target_rules`.

Single-rule example:

```text
Use modernize-arkts on src with target_rules: migration/static-member-inheritance
```

Multi-rule example:

```text
Use modernize-arkts on src with target_rules: migration/static-member-inheritance, fixes/fix-primitive-as-conversions
```

The ids must match `guide_id` values on cards whose `related_skills` includes `modernize-arkts`. If any id is unknown or ineligible, the skill should stop and report it instead of silently falling back to the default set.

Current examples of valid `target_rules` include:

- `migration/static-member-inheritance`
- `fixes/fix-numeric-semantics`
- `fixes/fix-primitive-as-conversions`
- `fixes/fix-enum-as-conversions`
- `fixes/fix-export-signature-consistency`
- `migration/override-fields`

Use `target_rules` when you already know the warning family or modernization theme you want to address.

`fixes/fix-numeric-semantics` is the rule pack for explicit operand rewrites in illegal relational comparisons such as `char` against numeric types, `char` against `char`, or numeric types against `bigint`.
`migration/static-member-inheritance` is the rule pack for retargeting forbidden inherited static member access such as `D1.field -> C.field`, `Derived.bar() -> Base.bar()`, and rename-and-retarget fixes for conflicting derived static fields.

## Choose The Right Scope

`modernize-arkts` supports three input shapes:

- `file`: modernize one or more specific `.ets` files directly
- `project`: enumerate eligible `.ets` files recursively, then use compiler or build output to decide which files need edits
- `patch`: inspect only newly added lines in changed or added `.ets` and `.yaml` files from a diff

Examples:

```text
Use modernize-arkts on src/feature/Login.ets
```

```text
Use modernize-arkts on ./entry/src/main/ets
```

```text
Use modernize-arkts on the current patch with target_rules: migration/static-member-inheritance
```

## How Verification Works

For file and project runs, `modernize-arkts` is expected to validate changes with the local wrappers:

- `arkts-check <path> --json` for a small file target
- the repo-native compile or build command for a project target

The baseline compiler output defines the bounded edit set for project-mode modernization. The skill should not claim success from search results alone.

## When To Use Other Skills Instead

Use these neighboring skills when modernization is not the best fit:

- `implement-arkts` for new ArkTS code
- `migrate-to-arkts` for TypeScript or JavaScript migration work
- `fix-arkts-errors` when compiler or linter diagnostics are already the main task
- `review-arkts` when you want findings instead of code changes
- `optimize-arkts` for performance or resource-behavior changes

Typical direct calls:

```text
Use fix-arkts-errors on src/main/ets
```

```text
Use review-arkts on src/main/ets
```

```text
Use migrate-to-arkts on src --from typescript
```

## Where To Look For Rule Details

- Skill contract: `arkts-skills/modernize-arkts/WORKFLOW.md`
- Allowed rule ids and rule catalog: `docs/cards/` frontmatter
- Rule cards: `docs/cards/core/`, `docs/cards/fixes/`, `docs/cards/migration/`

Use the skill contract for execution behavior and the cards for the concrete rewrite guidance behind each rule pack.
