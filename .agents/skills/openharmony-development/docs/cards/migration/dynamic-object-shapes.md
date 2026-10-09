---
guide_id: migration/dynamic-object-shapes
family: migration
tags: dynamic-objects, object-mutation, delete, migration, explicit-contracts, structural-typing, public-api
related_skills: arkts-skill, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:ObjectLiteralNoContextType, linter-fault:ObjectLiteralProperty, linter-fault:FieldTypeMismatch
related_migration_patterns: implicit-dynamic-shapes, structural-typing-assumptions, export-signature-consistency
status: active
---
# Replace Dynamic Object Mutation With Explicit ArkTS Contracts

## Intent

Replace dynamic object shapes, structural typing assumptions, and incomplete public
contracts with named ArkTS types.

## Use When

- migrated code mutates object shape after construction
- code relies on computed property writes to introduce fields dynamically
- a JavaScript or TypeScript object stops matching a stable ArkTS contract over time
- TypeScript accepts an object only because it has a compatible shape
- an exported API mentions a local class, interface, alias, or generic constraint
  that is not exported

## Do

- define the target class or interface before using the object across APIs
- create a fresh value when the shape changes instead of mutating the old one
- keep field presence and types explicit in the model
- give object literals a contextual class or interface type
- export every local type that is intentionally part of a public signature
- redesign the public signature when its implementation type must remain internal

## Avoid

- carrying over `delete` semantics as a normal state transition
- widening the type just to preserve ad hoc object mutation
- treating computed property writes as a substitute for a named contract
- assuming two unrelated types are interchangeable because their current fields match
- leaking an internal type through an exported function, property, heritage clause, or
  generic bound

## Migration Notes

Preserve the states, not the source's dynamic mechanics:

```typescript
// Avoid: inferred shape, computed mutation, and delete.
let user = { name: "Ada" }
user["active"] = true
delete user.name

// ArkTS: use a contextual, stable contract.
interface ActiveUser {
  name: string
  active: boolean
}
let activeUser: ActiveUser = { name: "Ada", active: true }
```

Use separate named types when the shape really changes. For exported APIs,
export every local type used in parameters, results, properties, heritage
clauses, aliases, or generic bounds. If the implementation type must remain
private, expose a separate public interface.

## Related Diagnostics

- `linter-fault:ObjectLiteralNoContextType`
- `linter-fault:ObjectLiteralProperty`
- `linter-fault:FieldTypeMismatch`

## References

Object literals require a target contract; fields cannot evolve through computed
writes or `delete`. Types exposed by a public API must also be exported.

## Status

Active. Use when migration findings point at dynamic object mutation or structural typing leakage.
