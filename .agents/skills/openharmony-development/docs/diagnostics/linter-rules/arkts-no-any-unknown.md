# `arkts-no-any-unknown`

## Meaning

The code uses `any` or `unknown`, which the ArkTS guidance and linter treat as non-canonical for product code.

## Typical Causes

- untyped migration from TypeScript
- placeholder types left in generated code
- avoiding explicit modeling work

## Preferred Fix

Replace the loose type with:

- an explicit class or interface
- a constrained generic
- a precise union only when explicitly supported and justified

## Related Guides

- `docs/cards/core/explicit-types.md`
- `docs/cards/fixes/fix-missing-explicit-types.md`

## References

- `ets2panda/linter/src/lib/CookBookMsg.ts`
- `plugins/ets/doc/cookbook/recipes.rst`
