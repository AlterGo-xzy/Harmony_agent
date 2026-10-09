# TypeScript To ArkTS

Grounding sources:

- `plugins/ets/doc/cookbook/TS_compatibility.rst`
- `plugins/ets/doc/cookbook/recipes.rst`
- `ets2panda/linter/src/lib/CookBookMsg.ts`

## Main Traps

- `any` and `unknown` usage
- overload signatures without separate bodies
- invalid field overrides or field/accessor clashes across class hierarchies
- structural typing assumptions
- unsupported decorators
- dynamic property access and `delete`
- `undefined` as a universal value

## Migration Workflow

1. Detect risky TypeScript constructs.
2. Map each construct to the matching migration card in `docs/cards/migration/`.
3. Rewrite into explicit ArkTS contracts.
4. Run `arkts-check`.
5. Run `arkts-lint --fix --json` only when the remaining follow-up is local and bounded.

## Use With The Kit

Use `arkts-migrate --from typescript <path> --json` to get a source-scanned migration plan with matched patterns, guide refs, and example refs when a local illustrative demo exists. Treat the grounding as the local migration rules, cards, diagnostics, and upstream references, not the demo files.

Not every migration guide is identified by the source-scan heuristics. `migration/static-member-inheritance` remains a valid guide and example-backed rule, but it is currently intended for LLM-guided or diagnostics-guided use rather than automatic source detection.

Read the migration cards in `docs/cards/migration/*` first and the source-heavy summaries in `docs/curated/*` second during active migration work. Treat this document as a higher-level reference.
