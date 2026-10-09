---
guide_id: fixes/fix-functions-and-overloads
family: fixes
tags: fix, function, overload, parameter, call signature, return type, yield, generator
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:ArgumentsObject, linter-fault:CallJSFunction, linter-fault:CallSignature, linter-fault:DeclWithDuplicateName, linter-fault:DefaultArgsBehindRequiredArgs, linter-fault:EntryAnnotation, linter-fault:EntryHasInvalidParamsWithV2, linter-fault:ExplicitFunctionType, linter-fault:FunctionApplyCall, linter-fault:FunctionBind, linter-fault:FunctionContainsThis, linter-fault:FunctionExpression, linter-fault:GeneratorFunction, linter-fault:IncompationbleFunctionType, linter-fault:InstanceOfFunction, linter-fault:InteropCallObjectParam, linter-fault:InteropJSFunctionInvoke, linter-fault:InteropJsObjectCallStaticFunc, linter-fault:InteropJsObjectExpandStaticInstance, linter-fault:InteropTSFunctionInvoke, linter-fault:InvalidAbstractOverrideReturnType, linter-fault:LimitedReturnTypeInference, linter-fault:LocalFunction, linter-fault:MethodInheritRule, linter-fault:NoDuplicateFunctionName, linter-fault:NoFunctionReturnThis, linter-fault:ParameterProperties, linter-fault:ParameterType, linter-fault:PropFunctionNotSupported, linter-fault:ProvideAnnotation, linter-fault:SendableFunctionAsExpr, linter-fault:SendableFunctionAssignment, linter-fault:SendableFunctionDecorator, linter-fault:SendableFunctionOverloadDecorator, linter-fault:SetAndPropFunctionNotSupported, linter-fault:StateStylesBlockNeedArrowFunc, linter-fault:TsOverload, linter-fault:WrapBuilderGenericNeedArrowFunc, linter-fault:WrappedBuilderGenericNeedArrowFunc, linter-fault:YieldExpression, ESE0091, ESE0103
related_migration_patterns: overload-signatures-with-single-body
status: active
---
# Fix Function Declaration and Usage Patterns

## Intent

Fix function declaration and usage patterns that ArkTS rejects, including overload syntax, missing parameter types, and restricted function expression contexts.

## Use When

- code uses TS-style overload signatures followed by an implementation signature
- code omits explicit parameter types in function declarations
- code uses standalone call signatures in interfaces or object types
- code declares local named functions inside other functions

## Do

- rewrite TS-style overload signatures into ArkTS-compatible overloads or a single function with union/optional parameters
- add explicit type annotations to all function parameters
- replace standalone call signatures (`(x: T): R`) with named method signatures
- replace local `function` declarations with arrow-function (lambda) variables
- add explicit return type annotations where ArkTS cannot infer the return type

## Avoid

- relying on return type inference for complex control flow
- using function expressions where ArkTS expects a lambda
- declaring named functions inside function bodies

## Migration Notes

ArkTS supports method overloads in classes and interfaces but restricts TS-style standalone overload signatures. Local function declarations must be converted to lambdas.


## Related Diagnostics

- `linter-fault:ArgumentsObject`
- `linter-fault:CallJSFunction`
- `linter-fault:CallSignature`
- `linter-fault:DeclWithDuplicateName`
- `linter-fault:DefaultArgsBehindRequiredArgs`
- `linter-fault:EntryAnnotation`
- `linter-fault:EntryHasInvalidParamsWithV2`
- `linter-fault:ExplicitFunctionType`
- `linter-fault:FunctionApplyCall`
- `linter-fault:FunctionBind`
- `linter-fault:FunctionContainsThis`
- `linter-fault:FunctionExpression`
- `linter-fault:GeneratorFunction`
- `linter-fault:IncompationbleFunctionType`
- `linter-fault:InstanceOfFunction`
- `linter-fault:InteropCallObjectParam`
- `linter-fault:InteropJSFunctionInvoke`
- `linter-fault:InteropJsObjectCallStaticFunc`
- `linter-fault:InteropJsObjectExpandStaticInstance`
- `linter-fault:InteropTSFunctionInvoke`
- `linter-fault:InvalidAbstractOverrideReturnType`
- `linter-fault:LimitedReturnTypeInference`
- `linter-fault:LocalFunction`
- `linter-fault:MethodInheritRule`
- `linter-fault:NoDuplicateFunctionName`
- `linter-fault:NoFunctionReturnThis`
- `linter-fault:ParameterProperties`
- `linter-fault:ParameterType`
- `linter-fault:PropFunctionNotSupported`
- `linter-fault:ProvideAnnotation`
- `linter-fault:SendableFunctionAsExpr`
- `linter-fault:SendableFunctionAssignment`
- `linter-fault:SendableFunctionDecorator`
- `linter-fault:SendableFunctionOverloadDecorator`
- `linter-fault:SetAndPropFunctionNotSupported`
- `linter-fault:StateStylesBlockNeedArrowFunc`
- `linter-fault:TsOverload`
- `linter-fault:WrapBuilderGenericNeedArrowFunc`
- `linter-fault:WrappedBuilderGenericNeedArrowFunc`
- `linter-fault:YieldExpression`

## Status
Active. Use this card when fixing function-related diagnostic errors during ArkTS migration.
