---
guide_id: fixes/fix-arkui-components
family: fixes
tags: fix, arkui, builder, buildernode, component, entry, localbuilder
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:BuilderNodeNoNestingBuilderSupported, linter-fault:LocalBuilderDecoratorNotSupported
related_migration_patterns: decorators-not-supported
status: active
---
# Fix ArkUI Component and Builder Errors

## Intent

Fix ArkUI component and builder errors by following the ArkUI decorator and component lifecycle model, which enforces strict rules on builder functions, component entry points, and dynamic UI composition.

## Use When

- code uses `@Builder` or `@LocalBuilder` decorators incorrectly
- code violates `@Entry` or `@Component` lifecycle contracts
- code attempts dynamic UI composition without `BuilderNode`
- code mixes UI and non-UI logic inside builder functions

## Do

- use `@Builder` for component-level builder functions and `@LocalBuilder` for local builder scopes
- follow `@Entry` and `@Component` lifecycle contracts including required lifecycle callbacks
- use `BuilderNode` for dynamic UI composition instead of imperative DOM-style manipulation
- keep builder functions pure by separating UI declaration from business logic
- follow SDK component API stability rules and avoid deprecated component APIs

## Avoid

- calling builder functions outside their intended decorator scope
- omitting required lifecycle callbacks in `@Entry` or `@Component` classes
- mixing imperative logic with declarative UI inside builder functions
- using deprecated or unstable ArkUI SDK component APIs without checking stability annotations

## Migration Notes

ArkUI uses a declarative component model with strict decorator semantics. Builder functions must follow scoping rules, and component lifecycle is enforced through mandatory callbacks in `@Entry` and `@Component` classes.


## Related Diagnostics

- `linter-fault:BuilderNodeNoNestingBuilderSupported`
- `linter-fault:LocalBuilderDecoratorNotSupported`

## Status

Active. Use this card when fixing ArkUI component and builder diagnostic errors during ArkTS migration.
