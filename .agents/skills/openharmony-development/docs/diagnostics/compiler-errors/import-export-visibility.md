# Import And Export Visibility

## Meaning

The module surface or import placement violates ArkTS expectations for explicit imports, exports, or public signatures.

## Likely Causes

- imports appear after other statements
- CommonJS or assignment-style export migration
- exported APIs reference non-exported internal types

## Fix Strategy

- move imports to the top of the file
- simplify the exported surface
- ensure public signatures reference public types only

## Related Guides

- `docs/cards/core/module-visibility.md`
- `docs/cards/fixes/fix-import-export-visibility.md`

## References

- `plugins/ets/doc/spec/13_modules.rst`
- `plugins/ets/doc/spec/24_build_system.rst`
