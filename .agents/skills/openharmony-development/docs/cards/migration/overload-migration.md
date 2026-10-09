---
guide_id: migration/overload-migration
family: migration
tags: overloads, ts-migration, functions, api-rewrite
related_skills: migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:TsOverload, linter-fault:DeclWithDuplicateName
related_migration_patterns: overload-signatures-with-single-body
status: active
---
# Replace TypeScript Overload Signature Patterns With Concrete ArkTS APIs

## Intent

Turn TypeScript overload-style declarations into ArkTS APIs with explicit bodies and behavior.

## Use When

- the source has multiple overload signatures with one implementation
- a migration surfaces duplicate-name or overload-related failures
- an API becomes unclear after direct syntax translation

## Do

- give each ArkTS overload its own body when supported
- split behavior into clearly named functions when that is simpler
- preserve semantics, not the exact TypeScript surface

## Avoid

- copying TypeScript overload headers directly
- hiding incompatible behaviors behind a weak single implementation
- using casts to fake overload compatibility

## Migration Notes

Replace TypeScript's bodyless signatures plus broad implementation with named,
concrete ArkTS functions:

```typescript
function formatNumber(value: number): string {
  return value.toString()
}
function formatText(value: string): string {
  return value
}
```

If one name is required, combine concrete methods with an ArkTS `overload`
declaration. Update callers and preserve each source behavior.

## Related Diagnostics

- `linter-fault:TsOverload`
- `linter-fault:DeclWithDuplicateName`

## References

Each overload alternative needs a real implementation, and resolution must
select one callable for the supplied arguments.

## Status

Active. High-value migration card for real codebases.
