---
guide_id: core/object-literals-and-contracts
family: core
tags: object-literals, interfaces, classes, explicit-contracts
related_skills: arkts-skill, implement-arkts, migrate-to-arkts, fix-arkts-errors, modernize-arkts, review-arkts
related_diagnostics: linter-fault:ObjectLiteralNoContextType, linter-fault:ObjectLiteralProperty
related_migration_patterns: structural-typing-assumptions
status: active
---
# Use Object Literals Only Under Explicit Contracts

## Intent

Keep ArkTS object literal usage tied to known classes or interfaces instead of loose structural assumptions.

## Use When

- creating data carriers
- porting ad hoc TypeScript object shapes
- fixing object literal checker complaints

## Do

- bind object literals to an explicit class or interface
- define the contract before using the literal across APIs
- keep literal properties consistent with the declared model

## Avoid

- using object literals as implicit type declarations
- extending object shapes dynamically
- depending on structural compatibility to make APIs line up

## Migration Notes

TypeScript patterns that freely shape-shift object literals usually need to become named contracts in ArkTS.

## Related Diagnostics

- `linter-fault:ObjectLiteralNoContextType`
- `linter-fault:ObjectLiteralProperty`

## Status

Active. Use this card early when migrating data-heavy TypeScript code.
