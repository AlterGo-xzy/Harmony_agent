---
guide_id: core/generic-inference-limits
family: core
tags: generics, inference, type-arguments, api-design
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, modernize-arkts, review-arkts
related_diagnostics: linter-fault:GenericCallNoTypeArgs
related_migration_patterns: structural-typing-assumptions
status: active
---
# Assume Generic Inference Is More Limited Than In TypeScript

## Intent

Design and call generic APIs so the intended type arguments remain obvious to the checker and to future readers.

## Use When

- defining reusable abstractions
- porting generic helpers from TypeScript
- investigating surprising inference failures

## Do

- make generic contracts explicit
- pass type arguments when inference is borderline
- keep generic APIs narrow and purposeful

## Avoid

- leaning on complex TypeScript-style inference chains
- hiding key type information in callback bodies
- fixing inference issues by widening everything

## Migration Notes

TypeScript helpers that feel ergonomic because inference is aggressive may need explicit type arguments or API reshaping in ArkTS.

## Related Diagnostics

- `linter-fault:GenericCallNoTypeArgs`

## Status

Active. Use during both API design and migration.
