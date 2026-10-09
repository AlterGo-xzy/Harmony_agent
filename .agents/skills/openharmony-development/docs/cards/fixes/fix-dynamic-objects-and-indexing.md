---
guide_id: fixes/fix-dynamic-objects-and-indexing
family: fixes
tags: fix, object literal, computed, property, index, record, delete, mapped type
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:ArrayIndexExprType, linter-fault:BuilderNodeUpdateNoLiteral, linter-fault:BuiltinGetOwnPropertyNames, linter-fault:ComputedPropertyName, linter-fault:DeleteOperator, linter-fault:IndexMember, linter-fault:IndexNegative, linter-fault:IndexedAccessType, linter-fault:InteropNoHaveNum, linter-fault:InteropObjectLiteralAmbiguity, linter-fault:InteropObjectLiteralClass, linter-fault:InteropObjectProperty, linter-fault:InteropStaticObjectLiterals, linter-fault:LiteralAsPropertyName, linter-fault:NewTarget, linter-fault:NoClassSuperPropReadonly, linter-fault:NoPropertyDescriptor, linter-fault:ObjectLiteralKeyType, linter-fault:ObjectLiteralNoContextType, linter-fault:ObjectLiteralProperty, linter-fault:ObjectLiteralUnionNeedsCast, linter-fault:PropertyAccessByIndex, linter-fault:PropertyAccessByIndexFromSdk, linter-fault:PropertyDeclOnFunction, linter-fault:SendableComputedPropName, linter-fault:SendableFunctionProperty, linter-fault:SendablePropType, linter-fault:TupleIndex, ESE0087
related_migration_patterns: implicit-dynamic-shapes
status: active
---
# Fix Dynamic Object Access and Indexing Patterns

## Intent

Fix dynamic object access patterns by replacing computed and indexed access with explicit contracts, since ArkTS requires statically verifiable property access.

## Use When

- code uses computed property names in object literals (`{ [key]: value }`)
- code declares index signatures on classes or interfaces (`[key: string]: T`)
- code accesses properties by index expression (`obj[expr]`)
- code uses the `delete` operator to remove object properties

## Do

- replace computed property names with explicit class or interface fields
- replace index signatures with `Record<K, V>` or `Map<K, V>` types
- replace dynamic property access (`obj[key]`) with typed getter methods or Map lookups
- replace `delete obj.prop` with setting the property to a sentinel value, or restructure to use a Map with `.delete()`
- replace indexed access types (`T[K]`) with explicit type aliases or interface fields

## Avoid

- using computed property names in object literals or class declarations
- declaring index signatures (`[key: string]: T`) on interfaces or classes
- relying on `delete` to manage object shape at runtime
- using TypeScript indexed access types (`T["prop"]`) in type positions

## Migration Notes

ArkTS requires all property access to be statically resolvable. Replace dynamic property patterns with `Record`, `Map`, or explicit interface/class fields. The `delete` operator is forbidden; use `Map.delete()` or nullify fields instead.


## Related Diagnostics

- `linter-fault:ArrayIndexExprType`
- `linter-fault:BuilderNodeUpdateNoLiteral`
- `linter-fault:BuiltinGetOwnPropertyNames`
- `linter-fault:ComputedPropertyName`
- `linter-fault:DeleteOperator`
- `linter-fault:IndexMember`
- `linter-fault:IndexNegative`
- `linter-fault:IndexedAccessType`
- `linter-fault:InteropNoHaveNum`
- `linter-fault:InteropObjectLiteralAmbiguity`
- `linter-fault:InteropObjectLiteralClass`
- `linter-fault:InteropObjectProperty`
- `linter-fault:InteropStaticObjectLiterals`
- `linter-fault:LiteralAsPropertyName`
- `linter-fault:NewTarget`
- `linter-fault:NoClassSuperPropReadonly`
- `linter-fault:NoPropertyDescriptor`
- `linter-fault:ObjectLiteralKeyType`
- `linter-fault:ObjectLiteralNoContextType`
- `linter-fault:ObjectLiteralProperty`
- `linter-fault:ObjectLiteralUnionNeedsCast`
- `linter-fault:PropertyAccessByIndex`
- `linter-fault:PropertyAccessByIndexFromSdk`
- `linter-fault:PropertyDeclOnFunction`
- `linter-fault:SendableComputedPropName`
- `linter-fault:SendableFunctionProperty`
- `linter-fault:SendablePropType`
- `linter-fault:TupleIndex`

## Status

Active. Use this card when fixing object access and indexing diagnostic errors during ArkTS migration.
