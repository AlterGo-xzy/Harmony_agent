---
guide_id: migration/override-fields
family: migration
tags: override-fields, inheritance, fields, accessors, ts-migration, modernization
related_skills: migrate-to-arkts, modernize-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:FieldTypeMismatch
related_migration_patterns: override-fields
source_refs: examples/migration-before-after/ts-override-fields-before.ts, examples/migration-before-after/arkts-override-fields-after.ets
status: active
---
# Replace Invalid Field Overrides With Explicit ArkTS Class Contracts

## Intent

Handle TypeScript class hierarchies that rely on same-name field redeclarations or field/accessor clashes that do not map directly to ArkTS.

## Use When

- modernizing existing ArkTS that redeclares inherited fields in a subclass
- a subclass redeclares a superclass field with a different type
- a subclass redeclares a superclass field with the same type but leaves the override implicitly uninitialized
- a subclass uses `override` on a field that does not come from the superclass
- a subclass combines `static` with `override` on a field
- a subclass narrows an inherited writable field to `readonly`
- a field in one class clashes with a getter or setter in the direct superclass
- a getter or setter in a subclass clashes with an inherited field
- a generic derived class overrides a field with a type that does not match the instantiated base-field type

## Do

- allow field overriding only for instance fields with the same name and same type as the inherited field
- require every overriding field to be initialized explicitly with an initializer or constructor assignment
- rename invalid derived fields instead of preserving illegal same-name overrides
- retarget subclass-specific reads and writes to the renamed field
- keep valid same-type overrides and preserve their explicit initializer behavior
- compare generic field overrides against the instantiated base type, not against an unconstrained type parameter name
- keep valid same-type field overrides explicitly initialized with an initializer or constructor assignment
- redesign the API when base-typed reads depended on TypeScript shadowing semantics
- treat field-versus-accessor clashes in either direction as rename-or-redesign work, not as legal overriding

## Avoid

- assuming same-name field redeclaration is just harmless shadowing
- changing the field type in a subclass and treating it as a valid override
- adding `readonly` to an overriding field when the base field is writable
- mixing `static` and `override` on fields
- using `override` on a field that has no matching superclass field
- preserving field/accessor collisions with casts or loose typing
- leaving an overriding field without an explicit initializer or constructor assignment
- claiming rename-only migration preserves behavior when `Base`-typed callers observed the derived value before

## Migration Notes


ArkTS allows same-name field overriding only for same-type instance fields, and explicit `override` is optional. A field marked `override` must actually override an inherited field, cannot be `static`, cannot change the inherited field type, and cannot add `readonly` when the base field is writable. Field/accessor clashes across the superclass boundary are also invalid.

The default migration or modernization shape for invalid overrides is rename-and-retarget in the subclass layer:

- rename the invalid derived field to a distinct name such as `fld2`
- retarget subclass-specific reads, writes, and helper functions to the new name
- keep the inherited base field in place for `Base`-typed access

Do not claim that this rename preserves behavior for `Base`-typed callers. If legacy code relied on `f1(new B())` observing the derived declaration, that behavior is not preserved by a safe mechanical rename and requires API redesign or call-site restructuring.

A valid same-type override must initialize the field:

```typescript
class Base {
  value: number = 1
}

class Derived extends Base {
  override value: number = 2
}
```

Constructor initialization is also valid. A different type, field/accessor
collision, or generic mismatch requires rename-and-retarget or API redesign.

## Related Diagnostics

- `linter-fault:FieldTypeMismatch`

## References

Only a same-type instance field can override an inherited field, and it must be
initialized. `static override`, type changes, invalid `readonly`, and
field/accessor collisions are compile-time errors.

## Status

Active. Use for migration or modernization when inherited fields are redeclared illegally, clash with accessors, or need explicit initialization to stay valid in ArkTS.
