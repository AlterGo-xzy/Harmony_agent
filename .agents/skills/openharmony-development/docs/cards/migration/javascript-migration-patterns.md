---
guide_id: migration/javascript-migration-patterns
family: migration
tags: javascript, js-migration, commonjs, dynamic-objects, truthy-falsy, null-safety, untyped
related_skills: arkts-skill, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:ExportAssignment, linter-fault:ImportAssignment, linter-fault:ImportAfterStatement, linter-fault:ObjectLiteralNoContextType, linter-fault:ObjectLiteralProperty
related_migration_patterns: implicit-dynamic-shapes, commonjs-exports, truthy-falsy-control-flow, undefined-and-dynamic-values
source_refs: examples/migration-before-after/js-commonjs-before.js, examples/migration-before-after/arkts-module-after.ets
status: active
---
# Migrate Untyped JavaScript to Explicit ArkTS Contracts

## Intent

Guide the migration of plain JavaScript codebases to ArkTS by addressing the four patterns that have no TypeScript-level mitigation: untyped dynamic shapes, CommonJS module boundaries, pervasive truthy/falsy control flow, and unconstrained undefined usage in the absence of any type annotations.

## Use When

- the source codebase is JavaScript with no TypeScript annotations, JSDoc types, or `.d.ts` files to bootstrap from
- modules use `module.exports`, `exports.name`, or `require()` instead of ES module syntax
- control flow relies on truthiness checks such as `if (val)`, `val || fallback`, or `val && val.prop` rather than explicit null or type guards
- values flow through the codebase as `undefined` without any compiler enforcement from `strictNullChecks` or similar settings

## Do

- define explicit ArkTS classes or interfaces for every object shape before it crosses an API boundary; in JavaScript there are no existing type annotations to refine, so every shape must be authored from scratch (implicit-dynamic-shapes)
- replace all `module.exports = ...`, `exports.x = ...`, and `require()` calls with named ArkTS `export` declarations and `import` statements; treat each file as a module boundary audit (commonjs-exports)
- convert every truthy/falsy branch into an explicit boolean or nullable check; replace `if (arr.length)` with `if (arr.length > 0)` and `val || default` with `val !== null ? val : default` because JavaScript has no type-guard narrowing to fall back on (truthy-falsy-control-flow)
- replace `undefined` sentinels with nullable types or result-bearing wrappers; audit every function that can return `undefined` and make the absent state part of the return contract (undefined-and-dynamic-values)
- inventory the codebase for implicit type coercions (`==`, `+` on mixed types, `!!` casts) and replace each with an explicit conversion or comparison before migrating
- start migration at leaf modules with the fewest dynamic dependencies and work inward, since untyped JavaScript offers no incremental type boundary to lean on

## Avoid

- assuming that an existing TypeScript migration card covers JavaScript; the TS cards for dynamic-object-shapes and dynamic-values-and-undefined assume type annotations already exist and only need refinement
- treating `require()` as a simple find-and-replace to `import`; CommonJS allows conditional requires, re-exports via assignment, and mid-file imports that must be restructured
- preserving truthy/falsy idioms as comments or TODOs; ArkTS will reject them at compile time, so they must be resolved before the code can build
- widening every value to `Object` or `any` to force compilation; this defers the real migration work and produces an unmaintainable result

## Migration Notes

Plain JavaScript has no contracts to refine, so author them during migration.
The four recurring rewrites are:

1. Give shared objects a class or interface instead of adding or deleting fields.
2. Replace CommonJS assignments and `require()` with explicit modules:

```javascript
exports.add = (a, b) => a + b
```

```typescript
export function add(a: number, b: number): number {
  return a + b
}
```

3. Replace truthiness with the intended condition:

```typescript
if (items.length > 0) {
  process(items)
}
```

4. Replace implicit `undefined` with a nullable result and narrow it:

```typescript
let user: User | null = findUser()
if (user != null) {
  showUser(user)
}
```

Conditional or mid-file `require()` and implicit coercions require redesign,
not textual replacement.

## References

ArkTS uses explicit contracts, declaration-based modules, non-nullable types,
and Boolean conditions without JavaScript coercion.

## Status

Active. Covers all four committed JavaScript migration patterns in a
self-contained form.
