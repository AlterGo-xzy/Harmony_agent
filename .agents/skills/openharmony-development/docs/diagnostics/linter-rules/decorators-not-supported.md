# Decorators Not Supported

## Meaning

The code uses a decorator pattern that does not map to supported ArkTS behavior.

## Typical Causes

- direct migration from TypeScript framework code
- preserving metadata-driven API design
- assuming any annotation-like syntax remains valid

## Preferred Fix

- replace the decorator with explicit code or a supported construct
- make the behavior visible in the source rather than implicit in metadata

## Related Guides

- `docs/cards/migration/unsupported-decorators.md`

## References

- `ets2panda/linter/src/lib/FaultDesc.ts`
- `plugins/ets/doc/cookbook/recipes.rst`
