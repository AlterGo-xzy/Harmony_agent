# JavaScript To ArkTS

Grounding sources:

- `plugins/ets/doc/cookbook/recipes.rst`
- `plugins/ets/doc/cookbook/TS_compatibility.rst`
- `plugins/ets/doc/spec/13_modules.rst`

## Main Traps

- CommonJS export and import patterns
- dynamic object shape mutation
- truthy and falsy control flow replacing explicit boolean or nullable checks
- implicit `undefined` flows
- untyped APIs crossing file boundaries

## Migration Workflow

1. Detect dynamic object, export, and control-flow patterns that rely on JavaScript flexibility.
2. Map each construct to the matching migration card in `docs/cards/migration/`.
3. Rewrite toward explicit ArkTS contracts and module boundaries.
4. Run `arkts-check`.
5. Use `arkts-lint --fix --json` only for bounded local follow-up.

## Use With The Kit

Use `arkts-migrate --from javascript <path> --json` to get a source-scanned migration plan with matched patterns, guide refs, and example refs when a local illustrative demo exists. Treat the grounding as the local migration rules, cards, diagnostics, and upstream references, not the demo files.

Read the migration cards in `docs/cards/migration/*` first and the source-heavy summaries in `docs/curated/*` second during active migration work. Treat this document as a higher-level reference.
