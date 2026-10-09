---
guide_id: core/overrides-and-function-types
family: core
tags: override, function-types, inheritance, compatibility
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, review-arkts
related_diagnostics: linter-fault:MethodInheritRule, linter-fault:FieldTypeMismatch, ESE0091, ESE0136
related_migration_patterns: overload-signatures-with-single-body, override-fields
status: active
---
# Keep Override And Function Compatibility Strict

## Intent

Treat method overrides and function type assignments as strict compatibility checks, not as flexible TypeScript conveniences.

## Use When

- overriding methods in class hierarchies
- reviewing field redeclarations across a superclass boundary
- assigning lambdas to function-typed variables
- reviewing migrated APIs that rely on relaxed compatibility

## Do

- keep parameter and return relationships explicit
- review field and accessor names against the direct superclass before preserving them
- review overrides with the base contract in hand
- model separate behaviors with separate functions instead of weak compatibility hacks

## Avoid

- covariant or contravariant experiments copied from TypeScript intuition
- assuming same-name fields can change type or accessor shape in a subclass
- silently changing return contracts in overrides
- assuming a function type will accept a near match

## Migration Notes

TypeScript code may compile with relaxed function compatibility, overload-like patterns, or field shadowing that need a real redesign in ArkTS.

## Related Diagnostics

- `linter-fault:MethodInheritRule`
- `linter-fault:FieldTypeMismatch`

## Status

Active. High priority for service APIs and framework-style base classes.
