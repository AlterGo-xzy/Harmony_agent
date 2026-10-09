# Replace `any` With An Explicit Type

## Intent

Convert a loose TypeScript-style type escape hatch into a stable ArkTS contract.

## Safe Fixes

- introduce a named interface or class
- introduce a generic parameter with a useful bound
- split dynamic logic into explicit branches

## Avoid

- swapping `any` for `unknown` without a real narrowing plan
- forcing casts that only silence the type checker

## Related Tools

- `arkts-lint --fix`
- `arkts-migrate --from typescript`

## Related Guides

- `docs/cards/core/explicit-types.md`
- `docs/cards/fixes/fix-missing-explicit-types.md`
- `docs/cards/migration/dynamic-values-and-undefined.md`

## References

- `docs/diagnostics/linter-rules/arkts-no-any-unknown.md`
- `plugins/ets/doc/cookbook/TS_compatibility.rst`
