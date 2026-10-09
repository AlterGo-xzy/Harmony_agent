# ArkTS Overview

ArkTS in this kit is grounded in the ETS plugin documentation and the current `ets2panda` implementation, not in generic TypeScript intuition.

## Primary References

- `plugins/ets/doc/spec`
- `plugins/ets/doc/cookbook`
- `plugins/ets/doc/tutorial`
- `ets2panda/linter/src/lib/CookBookMsg.ts`
- `ets2panda/lsp/src/register_code_fix/*`

## Working Assumptions

- Prefer explicit ArkTS forms over flexible TypeScript forms.
- Treat `frontend_status` in the spec as a maturity signal.
- Use the `arkts-*` / `arkui-*` console scripts before treating output as correct.

## Fast Path

1. Read the relevant cookbook or migration card.
2. Start from the closest minimal example in `examples/minimal/`.
3. Generate or edit code.
4. Run `arkts-check ... --json`.
5. Use `arkts-lint --fix --json` or a linked repair recipe when the remaining work is a bounded lint rewrite.

## Card-First Routing

Use `docs/cards/*` first and `docs/curated/*` second for skill-time execution. Fall back to this higher-level overview only when the curated markdown layers do not answer the question.
