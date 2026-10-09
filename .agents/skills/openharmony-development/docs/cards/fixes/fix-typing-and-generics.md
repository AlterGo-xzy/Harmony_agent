---
guide_id: fixes/fix-typing-and-generics
family: fixes
tags: fix, type, generic, structural, conditional, intersection, mapped, this type, symbol, recursive-alias
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:AnyType, linter-fault:ArrayLiteralNoContextType, linter-fault:ArrayTypeImmutable, linter-fault:AvoidUnionTypes, linter-fault:BuilderNodeGenericNoTuple, linter-fault:BuiltinNarrowTypes, linter-fault:BuiltinSymbolIterator, linter-fault:BuiltinThisArgs, linter-fault:ConditionalType, linter-fault:CreatingPrimitiveTypes, linter-fault:EsValueType, linter-fault:FieldTypeMismatch, linter-fault:GenericCallNoTypeArgs, linter-fault:InteropDirectAccessToTSTypes, linter-fault:IntersectionType, linter-fault:LimitedLiteralType, linter-fault:LimitedStdLibNoASON, linter-fault:LimitedVoidType, linter-fault:LimitedVoidTypeFromSdk, linter-fault:MappedType, linter-fault:NoESObjectSupport, linter-fault:NoEnumPropAsType, linter-fault:NoTsLikeSmartType, linter-fault:NotSupportTupleGenericValidation, linter-fault:ObjectTypeLiteral, linter-fault:Prototype, linter-fault:SendableGenericTypes, linter-fault:SendablePropTypeFromSdk, linter-fault:SendableTypeAliasDeclaration, linter-fault:SendableTypeAliasDecorator, linter-fault:SendableTypeInheritance, linter-fault:StructuralIdentity, linter-fault:SymbolType, linter-fault:TemplateStringType, linter-fault:ThisType, linter-fault:TypeAssertion, linter-fault:UnknownType, linter-fault:UtilityType
related_migration_patterns: structural-typing-assumptions
status: active
---
# Fix Advanced TypeScript Type Constructs

## Intent

Fix advanced TypeScript type constructs that ArkTS rejects by replacing them with nominal, explicit alternatives that satisfy ArkTS's stricter type system.

## Use When

- code uses intersection types (`A & B`) to compose types
- code uses conditional types (`T extends U ? X : Y`)
- code uses mapped types (`{ [K in keyof T]: V }`)
- code relies on structural identity between unrelated types
- code needs a recursive JSON-like value alias

## Do

- replace intersection types with a single interface that extends both constituent types
- replace conditional types with function overloads or explicit union return types
- replace mapped types with explicit interface declarations listing each field
- replace `Symbol` type usage with string or enum-based keys
- replace `this` type expressions with the concrete class type name
- ensure type compatibility relies on nominal (extends/implements) relationships, not structural shape matching
- keep recursive alias references behind an array element or generic type argument

## Avoid

- using `A & B` intersection syntax to merge types
- using conditional or mapped types for type-level logic
- assuming two types are compatible because they share the same shape
- declaring an unresolvable direct cycle such as `type Node = string | Node`

## Migration Notes

ArkTS uses a nominal type system where compatibility requires explicit inheritance or interface implementation. Structural identity assumptions must be replaced with declared type relationships.

Recursive aliases are valid when recursion passes through an array or generic
type argument:

```typescript
type JsonValue =
  null | boolean | int | double | string |
  JsonValue[] | Map<string, JsonValue>
```

Direct cycles such as `type Value = Value` or `type Value = string | Value`
cannot be resolved and fail at compile time.


## Related Diagnostics

- `linter-fault:AnyType`
- `linter-fault:ArrayLiteralNoContextType`
- `linter-fault:ArrayTypeImmutable`
- `linter-fault:AvoidUnionTypes`
- `linter-fault:BuilderNodeGenericNoTuple`
- `linter-fault:BuiltinNarrowTypes`
- `linter-fault:BuiltinSymbolIterator`
- `linter-fault:BuiltinThisArgs`
- `linter-fault:ConditionalType`
- `linter-fault:CreatingPrimitiveTypes`
- `linter-fault:EsValueType`
- `linter-fault:FieldTypeMismatch`
- `linter-fault:GenericCallNoTypeArgs`
- `linter-fault:InteropDirectAccessToTSTypes`
- `linter-fault:IntersectionType`
- `linter-fault:LimitedLiteralType`
- `linter-fault:LimitedStdLibNoASON`
- `linter-fault:LimitedVoidType`
- `linter-fault:LimitedVoidTypeFromSdk`
- `linter-fault:MappedType`
- `linter-fault:NoESObjectSupport`
- `linter-fault:NoEnumPropAsType`
- `linter-fault:NoTsLikeSmartType`
- `linter-fault:NotSupportTupleGenericValidation`
- `linter-fault:ObjectTypeLiteral`
- `linter-fault:Prototype`
- `linter-fault:SendableGenericTypes`
- `linter-fault:SendablePropTypeFromSdk`
- `linter-fault:SendableTypeAliasDeclaration`
- `linter-fault:SendableTypeAliasDecorator`
- `linter-fault:SendableTypeInheritance`
- `linter-fault:StructuralIdentity`
- `linter-fault:SymbolType`
- `linter-fault:TemplateStringType`
- `linter-fault:ThisType`
- `linter-fault:TypeAssertion`
- `linter-fault:UnknownType`
- `linter-fault:UtilityType`

## Status

Active. Use this card when fixing advanced type construct errors during ArkTS migration, alongside the existing generic-inference-limits card.
