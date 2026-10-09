# Separate Overloads Into Concrete Bodies

## Intent

Repair TypeScript overload-style APIs by turning them into ArkTS functions or methods with explicit bodies and contracts.

## Safe Fixes

- give each supported overload its own body
- split one overloaded API into clearly named functions when that improves clarity
- tighten parameter and return contracts during the rewrite

## Avoid

- preserving declaration-only overload headers
- using broad unions or casts to simulate compatibility

## Related Guides

- `docs/cards/migration/overload-migration.md`
- `docs/cards/core/overrides-and-function-types.md`

## References

- `plugins/ets/doc/cookbook/TS_compatibility.rst`
- `plugins/ets/doc/spec/15_semantics.rst`
