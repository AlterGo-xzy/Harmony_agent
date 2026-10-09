---
name: modernize-arkts
description: Update existing ArkTS toward current idioms, warnings guidance, and cleaner patterns.
---

# modernize-arkts

## Purpose
Bring existing ArkTS up to current idioms, warning guidance, and clearer maintainable patterns without changing intended behavior.

## Read First
- **`arkts-skills/arkts-skill/WORKFLOW.md` — for static ArkTS (arkts-static) modernization only. Follow this skilltree for all static ArkTS patterns, rewrite moves, and the TS-to-ArkTS table. Skip it when modernizing dynamic ArkTS code.**
- `docs/guide-usage.md`
- `docs/cards/`
- `docs/cards/migration/static-member-inheritance.md`
- `docs/cards/fixes/fix-numeric-semantics.md`
- `docs/cards/fixes/fix-primitive-as-conversions.md`
- `docs/cards/fixes/fix-enum-as-conversions.md`
- `docs/cards/core/`
- `docs/cards/fixes/`
- `docs/curated/`
- `docs/style/code-style.md`

## Inputs
- ArkTS file path, project path, or patch/diff input
- optional `target_rules` list of exact `guide_id` values from `docs/cards/`
- optional modernization goals or constraints

## Workflow
1. For static ArkTS (arkts-static) modernization, follow `arkts-skills/arkts-skill/WORKFLOW.md` for all coding patterns, rewrite moves, and routing. Return to the skilltree after any specialist doc resolves a blocker. For dynamic ArkTS, skip the skilltree.
2. Start from the skill contract and available build surface:
   - do not try to generate or consume a standalone modernization worklist before baseline verification
   - begin from the project-native compile/build command; use optional `arkts-check <path> --json` only when it is actually available and suitable for a standalone target
   - wrapper selection rules: see `arkts-skills/references/compiler-wrapper-interface.md`
2. Read cards whose frontmatter includes `modernize-arkts` in `related_skills`.
3. If `target_rules` is absent, use the full default `modernize-arkts` guide set.
4. If `target_rules` is present:
   - require exact guide ids only
   - validate every requested id against eligible card frontmatter
   - if validation passes, read and apply only those guide cards
   - if validation fails, stop and report the unknown or ineligible ids without falling back to the default modernization set
5. Choose the smallest truthful mode for the input:
   - `file`: modernize one or more target `.ets` files directly
   - `project`: recursively enumerate all eligible `.ets` files with `rg --files` in lexical order before editing anything, then use the compiler baseline to decide which files actually need edits
   - `patch`: inspect only newly added lines in changed or added `.ets` and `.yaml` files from the diff, ignore removed lines prefixed with `-`, and expand every changed `.ets` file before analysis
6. Prioritize the selected modernization rule packs first:
   - invalid static member inheritance should be rewritten only for direct class-qualified access such as `Derived.field` or `Derived.foo(...)`
   - static field access should target the actual declaring class, unless the derived class has an invalid same-name static field that must be renamed and retargeted
   - static method access should walk the superclass chain and retarget to the first base class with an exact callable static declaration for the existing argument list
   - numeric comparison rewrites should preserve the original operator token and only rewrite operands when the comparison is illegal under ArkTS numeric semantics
   - invalid `char`/numeric, `char`/`char`, and numeric/`bigint` relational comparisons should be modernized with explicit conversions when the operand types are compile-time obvious
   - `as` is not the conversion mechanism for ordinary primitive or regular enum values
   - primitive conversions should use `.toByte()`, `.toShort()`, `.toInt()`, `.toLong()`, `.toFloat()`, or `.toDouble()`
   - regular enum conversions should use implicit widening, `.valueOf()`, or `Enum.fromValue(...)`
7. For `project` mode, be exhaustive instead of stopping after the first small batch of fixes:
   - build the full `.ets` file inventory first and keep it in the run notes
   - run the baseline compiler or build before editing and extract the targeted warning set for the selected rule family
   - derive the initial edit set from the warning-bearing file paths and lines in that baseline output
   - edit only that bounded file set first instead of rewriting every discovered `.ets` file blindly
   - after each pass, rerun the same compiler or build, refresh the warning-bearing file set, and continue until the targeted warning family is gone
   - use deterministic scans only as a cross-check for missed live-code matches, not as permission to widen the edit set beyond the compiler evidence unless the follow-up compile points to new files
8. Keep valid literal-context typing and same-type casts intact instead of rewriting `as` mechanically.
9. Prefer explicit types, cleaner module surfaces, null-safe modeling, and warning-driven rewrites after the selected rule pass.
10. For `fixes/fix-primitive-as-conversions`, use a deterministic scan only to cross-check the compiler-driven file set and to find remaining live-code matches inside files that the compiler points to:
   - scan only `.ets` files
   - ignore comment-only matches
   - preserve literal-context cases such as typed literal initializers and numeric literal context casts like `1 as byte`
   - preserve intentional same-type casts such as `a as int` when `a` is already `int`
   - treat non-literal value conversions such as `file.fd as int`, `foo() as int`, and `(a + b) as short` as modernization findings
   - normalize `as number` to `.toDouble()` because `number` is an alias for `double` and there is no separate `.toNumber()` helper
   - use the scan to verify cleanup and to catch missed sites in the already-implicated files, not as a substitute for the compiler baseline
11. For `fixes/fix-numeric-semantics`, use a deterministic scan only to cross-check the compiler-driven file set and to find remaining live-code matches inside files that the compiler points to:
   - scan only relational operators: `<`, `<=`, `>`, `>=`
   - preserve already-valid widening comparisons such as `int` against `number`
   - treat `char` as non-numeric for relational operators and rewrite only the operand side that needs explicit conversion
   - rewrite `char`/`char` relational comparisons by converting both operands explicitly before comparison
   - rewrite numeric/`bigint` relational comparisons to `BigInt(nonBigintExpr) <op> bigintExpr` only when the non-`bigint` operand is compile-time obvious and the conversion is not a guess
   - preserve the original relational operator and rewrite operands only
   - report union-driven, runtime-only, or precision-sensitive cases as blocked/manual instead of guessing a rewrite
12. For `migration/static-member-inheritance`, use a deterministic scan only to cross-check the compiler-driven file set and to find remaining live-code matches inside files that the compiler points to:
   - scan only direct class-qualified static access forms such as `Derived.field` and `Derived.foo(...)`
   - rewrite `Derived.field` to the nearest base class that actually declares `field` when the derived class does not declare the field itself
   - rename invalid same-name derived static fields and retarget subclass-specific direct accesses to the renamed field
   - rewrite `Derived.foo(args)` only when the derived class does not already declare an exact callable static method for the current argument list and a base class does
   - preserve valid derived static declarations and direct calls that already match them
   - report method references, aliased class references, computed member access, or any ambiguous match as blocked/manual instead of guessing
13. Run compiler validation before editing so the modernization pass is driven by real warning output:
    - for a small file target, run the available compiler/linter or optional `arkts-check <path> --json` before the first edit pass
    - for a project target, locate and run the repo-native ArkTS compile or build command from the nearest `AGENTS.md`, build docs, or checked-in wrappers before the first edit pass
    - wrapper selection rules: see `arkts-skills/references/compiler-wrapper-interface.md`
    - compiler or build output is the task source for project-mode modernization
   - record the warning family and affected files that match the selected modernization rules from this baseline compiler output
   - for `migration/static-member-inheritance`, collect static-member diagnostics such as `ESE225047`, `ESE0087`, and `ESE0172`
   - for `fixes/fix-numeric-semantics`, collect numeric-comparison diagnostics such as `linter-fault:NumericBigintCompare`, `linter-fault:NumericSemantics`, and compiler semantic errors like `Bad operand type...` for invalid relational operands
   - for `fixes/fix-primitive-as-conversions`, collect numeric-cast deprecation warnings such as `Warning W0029: 'As' expression for cast is deprecated for numeric types. Use explicit conversion function ... instead.`
   - treat these warning lines as the baseline target set for the rule, together with the affected files and lines
    - do not start a project-wide rewrite-only pass before this baseline exists
    - if the compile or build command is unavailable from the current checkout, stop and report verification as blocked instead of widening into a heuristic whole-tree rewrite unless the user explicitly asks for that fallback
    - fallback rules: see `arkts-skills/references/compiler-wrapper-interface.md`
14. Verify the modernization result with the compiler again after each rewrite pass:
   - rerun the same compiler, optional wrapper, or repo-native build command after edits
   - compare against the baseline warning set for the selected rule family
   - for `migration/static-member-inheritance`, do not declare success while the targeted static-member inheritance diagnostics still appear after the rewrite pass
   - for `fixes/fix-numeric-semantics`, do not declare success while the targeted invalid relational comparison diagnostics still appear after the rewrite pass
   - for `fixes/fix-primitive-as-conversions`, do not declare success while `W0029` lines for numeric `as` casts still appear after the rewrite pass
   - use the new compiler output to shrink or refresh the bounded file set for the next pass
   - do not declare success while modernization has introduced new compile or lint failures elsewhere in the touched code
15. If compiler or build diagnostics remain after the rewrite pass:
    - classify the diagnostics using `arkts-skills/references/diagnostic-classification.md`
   - continue resolving them in the same run, using `fix-arkts-errors` when needed
   - rerun the compiler or repo-native build after each bounded fix pass
   - only stop when the targeted warnings observed in the baseline compile are gone and the touched code is compile-clean, or when you can state exactly why verification is blocked
16. For `patch` mode, report:
   - inspect only newly added lines in changed or added `.ets` and `.yaml` files
   - ignore removed lines prefixed with `-`
   - expand every changed `.ets` file in the diff before analysis so no collapsed file is skipped
   - every analyzed `.ets` file path, even when no violations were found
   - each primitive-cast violation with rule number, short description, full file path, line number, the wrong code line, and a minimal replacement diff
   - for `fixes/fix-primitive-as-conversions`, use these rule numbers in patch output:
     - `1` `expr as byte` -> `expr.toByte()`
     - `2` `expr as short` -> `expr.toShort()`
     - `3` `expr as int` -> `expr.toInt()`
     - `4` `expr as long` -> `expr.toLong()`
     - `5` `expr as float` -> `expr.toFloat()`
     - `6` `expr as double` -> `expr.toDouble()`
     - `7` `expr as number` -> `expr.toDouble()`
     - `8` `return file.fd as int`-style return conversions -> `return file.fd.toInt()`
   - `9` `foo() as int`-style call-result conversions -> `foo().toInt()`
   - `10` `(a + b) as short`-style parenthesized conversions -> `(a + b).toShort()`
   - treat `let domain: int = 0x0000` as a valid non-finding example of context-driven typing
17. Summarize exhaustively:
   - enumerated `.ets` file count
   - warning-bearing file count from the baseline compile/build
   - analyzed file count
   - changed file count
   - unchanged file count
   - any skipped or blocked files with reasons
   - which rule packs were applied
   - which targeted compiler warnings were present before the pass
   - which targeted compiler warnings were removed after the final recheck

## Exhaustiveness Rules
- `project` mode means recursive whole-directory coverage for eligible `.ets` files, not a sample pass
- do not stop after 5-10 files if the directory still contains unscanned candidates
- do not treat “some files changed successfully” as completion if the selected rules have not been checked against the full baseline warning set from the compiler or build
- when `target_rules` is provided, enumerate the full file inventory but limit edits to files implicated by the selected warning family unless follow-up compiler output expands that set
- keep an explicit in-run checklist of analyzed, changed, clean, and blocked files while the pass is in progress
- only finish when the latest compiler or build no longer reports the targeted warning family and deterministic rescans of the implicated files are clean
- do not start claiming success from scan results alone; baseline compiler output must exist unless verification is explicitly blocked
- do not treat a clean search-and-replace scan as completion if compiler validation has not been run yet
- for project runs, only finish after a baseline compile/build, a post-fix compile/build, the targeted warning family no longer appears, no new compile failures remain in the touched code, or after explicitly listing why verification is blocked

## Compiler Evidence
- plain `.ets` compile can emit the primitive-cast warning as `Warning W0029`
- invalid static member inheritance can surface as `ESE225047` for conflicting derived static fields, `ESE0087` for missing inherited static members on the subclass type, and `ESE0172` for invalid static method calls on the subclass
- invalid numeric comparisons can surface as linter findings such as `NumericBigintCompare` and `NumericSemantics`, or as compiler semantic errors like `Bad operand type, the types of the operands must be numeric type.`
- confirmed examples:
  - `a as number` -> `Warning W0029 ... Use explicit conversion function Int.toDouble(...) instead.`
  - `b as int` -> `Warning W0029 ... Use explicit conversion function Byte.toInt(...) instead.`
  - `(a + b) as short` -> `Warning W0029 ... Use explicit conversion function Int.toShort(...) instead.`
- valid literal-context casts such as `1 as byte` may compile without `W0029` and should not be treated as rewrite targets

## Discoverability
- allowed `target_rules` ids come from `guide_id` fields on cards related to `modernize-arkts`
- inspect matching card titles and paths directly under `docs/cards/`

## Examples
- single-rule run:
  - `Use modernize-arkts on src with target_rules: fixes/fix-primitive-as-conversions`
- single-rule static-member run:
  - `Use modernize-arkts on src with target_rules: migration/static-member-inheritance`
- single-rule numeric-comparison run:
  - `Use modernize-arkts on src with target_rules: fixes/fix-numeric-semantics`
- multi-rule run:
  - `Use modernize-arkts on src with target_rules: migration/static-member-inheritance, fixes/fix-primitive-as-conversions`
- invalid rule request:
  - `Use modernize-arkts on src with target_rules: fixes/not-a-rule, migration/dynamic-object-shapes`
  - expected behavior: stop and report both ids as invalid for `modernize-arkts`

## Non-Goals
- do not depend on generated modernization worklists or `pending_task_count`
- for project mode, the compiler or repo-native build defines the bounded file set for the next edit pass

## Output
- modernized ArkTS code or a bounded modernization report
- for patch mode, the analyzed `.ets` file list plus per-finding fix diffs
- before/after rationale
- cited guides used during modernization
