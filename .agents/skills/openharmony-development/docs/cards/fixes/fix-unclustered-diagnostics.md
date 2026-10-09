---
guide_id: fixes/fix-unclustered
family: fixes
tags: fix, miscellaneous, uncategorized, mixed diagnostics, assorted restrictions
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:AnimatableExtendDecoratorTransform, linter-fault:ConstAssertion, linter-fault:CustomLayoutNeedAddDecorator, linter-fault:DataObservation, linter-fault:DecoratorsNotSupported, linter-fault:DefiniteAssignment, linter-fault:DollarBindingNotSupported, linter-fault:DoubleDollarBindingNotSupported, linter-fault:DoubleExclaBindingNotSupported, linter-fault:ErrorSuppression, linter-fault:ExtendDecoratorNotSupported, linter-fault:GlobalThis, linter-fault:InterfaceFieldNotImplemented, linter-fault:InterfaceMerging, linter-fault:InvalidIdentifier, linter-fault:LocalStoragePropDecoratorNotSupported, linter-fault:MathPow, linter-fault:MethodOverridingField, linter-fault:OhmUrlFullPath, linter-fault:PropDecoratorNotSupported, linter-fault:PropNeedCallMethodForDeepCopy, linter-fault:RepeatDisableVirtualScroll, linter-fault:StoragePropDecoratorNotSupported, linter-fault:StrictDiagnostic, linter-fault:StylesDecoratorNotSupported, linter-fault:TaggedTemplates, ESE0143
related_migration_patterns: any-or-unknown
status: active
---
# Fix Unclustered Diagnostic Errors

## Intent

Fix miscellaneous diagnostic errors that do not belong to a specific themed cluster.

## Use When

- a diagnostic error does not match any themed fix card cluster
- code triggers spread operator restrictions in unsupported contexts
- code uses template literal patterns that ArkTS restricts
- code uses labels or ambient declarations in ways ArkTS forbids

## Do

- check the diagnostics-map for specific guidance on each individual diagnostic
- replace restricted spread expressions with explicit element enumeration or `Array.from()`
- remove label statements and replace unsupported template literals with string concatenation

## Avoid

- using this card when a themed fix card already covers the diagnostic
- assuming spread syntax works identically to TypeScript in all contexts
- declaring ambient modules or values that ArkTS does not support

## Migration Notes

Check each diagnostic individually against the diagnostics-map; always prefer a themed fix card when one exists.


## Related Diagnostics

- `linter-fault:AnimatableExtendDecoratorTransform`
- `linter-fault:ConstAssertion`
- `linter-fault:CustomLayoutNeedAddDecorator`
- `linter-fault:DataObservation`
- `linter-fault:DecoratorsNotSupported`
- `linter-fault:DefiniteAssignment`
- `linter-fault:DollarBindingNotSupported`
- `linter-fault:DoubleDollarBindingNotSupported`
- `linter-fault:DoubleExclaBindingNotSupported`
- `linter-fault:ErrorSuppression`
- `linter-fault:ExtendDecoratorNotSupported`
- `linter-fault:GlobalThis`
- `linter-fault:InterfaceFieldNotImplemented`
- `linter-fault:InterfaceMerging`
- `linter-fault:InvalidIdentifier`
- `linter-fault:LocalStoragePropDecoratorNotSupported`
- `linter-fault:MathPow`
- `linter-fault:MethodOverridingField`
- `linter-fault:OhmUrlFullPath`
- `linter-fault:PropDecoratorNotSupported`
- `linter-fault:PropNeedCallMethodForDeepCopy`
- `linter-fault:RepeatDisableVirtualScroll`
- `linter-fault:StoragePropDecoratorNotSupported`
- `linter-fault:StrictDiagnostic`
- `linter-fault:StylesDecoratorNotSupported`
- `linter-fault:TaggedTemplates`

## Status

Active. Use this card as a fallback when no themed fix card covers the diagnostic error encountered during ArkTS migration.
