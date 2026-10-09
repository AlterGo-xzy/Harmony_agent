---
guide_id: fixes/fix-classes-and-inheritance
family: fixes
tags: fix, class, constructor, implements, extends, override, private, static
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:BuiltinFinalClass, linter-fault:ClassAsObject, linter-fault:ClassExpression, linter-fault:ClassstaticInitialization, linter-fault:ConstructorFuncs, linter-fault:ConstructorIface, linter-fault:ConstructorIfaceFromSdk, linter-fault:ConstructorType, linter-fault:ConstructorTypesDeprecated, linter-fault:DynamicCtorCall, linter-fault:ExtendsExpression, linter-fault:ImplementsClass, linter-fault:IntefaceExtendDifProps, linter-fault:InterfaceExtendsClass, linter-fault:InteropJsObjectInheritance, linter-fault:MakeObservedCannotObserveCustomClass, linter-fault:MultipleStaticBlocks, linter-fault:NoConstructorOnClass, linter-fault:NoLocalClass, linter-fault:NoStaticOnClass, linter-fault:PersistenceV2ConnectNeedAddParam, linter-fault:PersistentPropNeedImplementMethod, linter-fault:PersistentPropsNeedImplementMethod, linter-fault:PrivateIdentifier, linter-fault:SendableCapturedVars, linter-fault:SendableClassDecorator, linter-fault:SendableClassInheritance, linter-fault:SendableDefiniteAssignment, linter-fault:SendableExplicitFieldType, linter-fault:SuperInStaticContext, ESE0136, ESE0145, ESE0192, ESE0201
related_migration_patterns: structural-typing-assumptions, override-fields
status: active
---
# Fix Class Construction, Inheritance, and Static Members

## Intent

Fix class construction, inheritance, and static member errors by aligning with the ArkTS class model, which enforces stricter rules than TypeScript on constructors, inheritance, and member visibility.

## Use When

- code uses `new Type()` via a constructor type or constructor signature
- code uses `implements SomeClass` instead of `implements SomeInterface`
- code redeclares a superclass field with an incompatible type or accessor shape
- code uses `#privateField` syntax or multiple static initializer blocks
- code uses TS-style constructor overloads or constructor-based interface patterns

## Do

- replace constructor type references (`new (...args) => T`) with factory functions or explicit class instantiation
- replace `implements Class` with `implements Interface` by extracting an interface from the class
- rename invalid derived fields and retarget subclass-specific call sites when ArkTS does not allow the inherited name to be reused
- replace `#privateField` with `private` keyword modifier on the field
- consolidate multiple `static {}` blocks into a single static initializer block
- rewrite TS-style constructor overloads as a single constructor with optional parameters or use static factory methods

## Avoid

- using constructor types as first-class values or generic parameters
- assuming `implements Class` works like `extends Class`
- assuming a base-typed caller will keep observing a renamed derived field after migration
- relying on ES `#field` syntax; use `private` keyword instead

## Migration Notes

ArkTS enforces a nominal class model where constructors are not types, `implements` only accepts interfaces, and illegal field redeclarations usually need a rename or API redesign instead of a direct syntax carry-over.


## Related Diagnostics

- `linter-fault:BuiltinFinalClass`
- `linter-fault:ClassAsObject`
- `linter-fault:ClassExpression`
- `linter-fault:ClassstaticInitialization`
- `linter-fault:ConstructorFuncs`
- `linter-fault:ConstructorIface`
- `linter-fault:ConstructorIfaceFromSdk`
- `linter-fault:ConstructorType`
- `linter-fault:ConstructorTypesDeprecated`
- `linter-fault:DynamicCtorCall`
- `linter-fault:ExtendsExpression`
- `linter-fault:ImplementsClass`
- `linter-fault:IntefaceExtendDifProps`
- `linter-fault:InterfaceExtendsClass`
- `linter-fault:InteropJsObjectInheritance`
- `linter-fault:MakeObservedCannotObserveCustomClass`
- `linter-fault:MultipleStaticBlocks`
- `linter-fault:NoConstructorOnClass`
- `linter-fault:NoLocalClass`
- `linter-fault:NoStaticOnClass`
- `linter-fault:PersistenceV2ConnectNeedAddParam`
- `linter-fault:PersistentPropNeedImplementMethod`
- `linter-fault:PersistentPropsNeedImplementMethod`
- `linter-fault:PrivateIdentifier`
- `linter-fault:SendableCapturedVars`
- `linter-fault:SendableClassDecorator`
- `linter-fault:SendableClassInheritance`
- `linter-fault:SendableDefiniteAssignment`
- `linter-fault:SendableExplicitFieldType`
- `linter-fault:SuperInStaticContext`

## Status
Active. Use this card when fixing class-related diagnostic errors during ArkTS migration.
