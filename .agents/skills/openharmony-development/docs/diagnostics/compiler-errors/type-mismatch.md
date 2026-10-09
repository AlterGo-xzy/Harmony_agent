# Type Mismatch

## Meaning

A value is not assignable to the target ArkTS type under the stricter ArkTS type system.

## Likely Causes

- TypeScript-style widening assumptions
- structural typing leakage
- incorrect override signatures
- nullable or `undefined` assumptions

## Fix Strategy

- make the target type explicit
- rewrite toward explicit class or interface contracts
- adjust generic arguments
- use the migration guidance in `docs/migration/ts-to-arkts.md`

## Related Guides

- `docs/cards/fixes/fix-type-mismatch.md`
- `docs/cards/core/overrides-and-function-types.md`
- `docs/cards/core/object-literals-and-contracts.md`

## References

- `plugins/ets/doc/spec/15_semantics.rst`
- `plugins/ets/doc/cookbook/TS_compatibility.rst`
