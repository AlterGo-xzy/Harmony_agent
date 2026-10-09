---
guide_id: migration/static-member-inheritance
family: migration
tags: static-members, inheritance, fields, methods, ts-migration, modernization
related_skills: migrate-to-arkts, modernize-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: ESE0087, ESE0172, ESE225047
related_migration_patterns: static-member-inheritance
source_refs: examples/migration-before-after/ts-static-member-inheritance-before.ts, examples/migration-before-after/arkts-static-member-inheritance-after.ets
status: active
---
# Replace Invalid Static Member Inheritance With Declaring-Class Access

## Intent

Handle TypeScript or legacy ArkTS code that assumes static fields and static methods are inherited through subclass names.

## Use When

- code reads a static field through a subclass name even though the field is declared in a base class
- code calls a static method through a subclass name even though the callable declaration exists only in a base class
- a subclass redeclares a same-name static field that conflicts with a base static field
- a subclass defines a different static method signature and code still calls the base-class shape through the subclass name

## Do

- rewrite direct class-qualified static field access to the class that actually declares the field
- rewrite direct class-qualified static method calls to the first base class that declares an exact callable match for the current argument list
- rename invalid derived static fields instead of preserving illegal same-name reuse
- retarget subclass-specific field accesses to the renamed derived field after the rename
- keep valid direct calls to derived static methods unchanged when the derived declaration already accepts the existing argument list
- report ambiguous, indirect, or non-direct access patterns for manual review instead of guessing

## Avoid

- assuming `Derived.field` is valid just because `Base.field` exists
- assuming static methods participate in superclass overriding or inheritance
- rewriting by method name alone when the derived and base static signatures differ
- promising safe autofix for method references, aliased class references, computed member access, or reflective patterns
- renaming a conflicting derived static field without retargeting subclass-specific direct call sites

## Migration Notes


The default modernization shape is explicit declaring-class access:

- `D1.field` -> `C.field` when `field` is declared in `C` and `D1` only inherits from `C`
- `Derived.bar()` -> `Base.bar()` when `Derived` does not declare a callable static `bar`
- `Derived.foo()` -> `Base.foo()` when `Derived` declares `foo(p: string)` and only `Base.foo()` matches the current zero-argument call

When a derived class illegally redeclares a static field, the safe mechanical shape is rename-and-retarget:

- rename the derived static field to a distinct name such as `field2`
- keep base-class field access on the base declaring class
- retarget subclass-specific direct accesses to the renamed field

Do not promise autofix outside direct class-qualified access. Method references like `const ref = Derived.foo`, aliased classes, or computed member access require manual review.

This guide remains available to `migrate-to-arkts` and `modernize-arkts`, but it is currently intended to be selected explicitly or surfaced from diagnostics rather than auto-detected by the repo's TypeScript source-scan heuristics.

Static members must be accessed through their declaring class:

```typescript
class Base {
  static count: number = 1
}
class Derived extends Base {}

console.log(Derived.count) // compile-time error
console.log(Base.count)
```

For methods, retarget a call only when the base declaration accepts the existing
arguments exactly. References, aliases, and computed access require manual
review. Rename a derived static field when both classes need separate values.

## Related Diagnostics

- `ESE0087`
- `ESE0172`
- `ESE225047`

## References

Static members are not inherited. Access them through their declaring class;
static methods cannot use `abstract`, `final`, `override`, `this`, or `super`.

## Status

Active. Use for migration or modernization when static field or static method access relies on forbidden superclass inheritance semantics.
