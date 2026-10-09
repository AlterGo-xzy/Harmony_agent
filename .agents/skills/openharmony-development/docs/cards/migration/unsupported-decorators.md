---
guide_id: migration/unsupported-decorators
family: migration
tags: decorators, migration, annotations, unsupported-features
related_skills: migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:DecoratorsNotSupported
related_migration_patterns: decorators-not-supported
status: active
---
# Rewrite Unsupported Decorators Into Explicit ArkTS Constructs

## Intent

Remove TypeScript decorator usage that does not map to supported ArkTS behavior.

## Use When

- the source relies on class, method, or property decorators
- the linter flags unsupported decorators
- a migration attempts to preserve framework decoration syntax verbatim

## Do

- replace decorator-driven behavior with explicit code or supported annotations
- move hidden side effects into named factory or registration code
- keep the rewritten behavior obvious in the source

## Avoid

- preserving unsupported decorators as comments that still drive design
- replacing decorators with magic global setup
- assuming all annotation-like syntax is equivalent

## Migration Notes

Identify the decorator's behavior and make it explicit:

```typescript
@Route("/settings")
class SettingsPage {}

let routes = new RouteRegistry()
routes.register("/settings", "SettingsPage")
```

Use a supported ArkTS annotation only when its semantics match; otherwise use
named registration, validation, factory, or wrapper code.

## Related Diagnostics

- `linter-fault:DecoratorsNotSupported`

## References

Arbitrary TypeScript decorators are unsupported; preserve their behavior with
explicit code or an equivalent supported annotation.

## Status

Active. Use early when screening TypeScript frameworks for migration complexity.
