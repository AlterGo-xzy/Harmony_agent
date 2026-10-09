---
summary_id: interop/js-interop-boundaries
domain: interop
tags: interop, javascript, typescript, ESObject, conversion, boundaries, type-mapping, runtime-proxy, primitives, import
related_skills: migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
status: active
---
# Keep JavaScript Interop Behind Explicit ArkTS Boundaries

## Overview

ArkTS enforces a static nominal type system; all JS/TS values entering ArkTS must cross a well-defined boundary that maps dynamic semantics onto concrete ArkTS types. The boundary uses `ESObject`, a special interop type independent of `Object`, to represent opaque JS/TS values inside ArkTS code. Primitive values are copied across the boundary; reference values are proxied, meaning mutations on one side are visible on the other. Compile-time type-mapping tables govern which ArkTS types correspond to TS types (and vice-versa), while a separate set of runtime conversion rules handles the actual value transfer. Structural typing is forbidden in ArkTS, so interop adapters must convert JS/TS shapes into declared ArkTS classes or interfaces before wider use.

## Use For

- migrations that import JS/TS modules, objects, classes, or functions into ArkTS
- reviews of dynamic property access, indexing, or operator use across the interop boundary
- diagnosing compile-time type-mapping failures (ArkTS-to-TS and TS-to-ArkTS directions)
- investigating runtime conversion bugs involving primitives, references, or copy semantics
- triaging interop diagnostics

## Patterns

- import JS/TS modules via the interop import mechanism; do not re-declare JS globals
- receive JS/TS values as `ESObject` at the boundary, then convert to typed ArkTS values immediately
- isolate all interop behind adapter functions or boundary modules so ordinary ArkTS code never touches `ESObject` directly
- for primitives: treat the boundary as a copy — changes on either side are independent
- for references: understand the proxy model — the ArkTS proxy and the JS object share state
- consult the compile-time type-mapping tables (ch. 3) when a type error occurs at an import boundary
- consult the runtime conversion rules (ch. 4) when a value arrives with an unexpected type or is silently coerced

## Watch For

- `long` values above 2^53 lose precision when crossing the boundary (wide limitation)
- direct dynamic property access or bracket indexing on interop values in ordinary ArkTS code
- assuming JS structural subtyping works in ArkTS — nominal declarations are required
- using JS operators on interop values without checking the operator restriction rules (ch. 5)
- hiding conversion risks behind generic helpers or reasoning about values as `any`
- mutating a proxied reference without realizing the mutation is visible on the JS side

## Evidence

- ArkTS migration diagnostics reject `any` and `unknown`; for JS/TS values that do not have static type information, `ESObject` is the explicit interop escape hatch, with reduced type checking and runtime overhead.
- `ESObject` is intentionally narrow: use it at local interop boundaries, initialize it only from dynamic or interop-origin values, and convert it before ordinary ArkTS code needs property, index, or method access.
- Ambient TypeScript module declarations are not the normal path for JS interop; ArkTS uses explicit interop declarations such as `.d.ets` files and imports from the JS/TS module.
- The interop tutorial examples route primitive calls through a JS/TS implementation, a matching `.d.ets` declaration, and an ArkTS import, so the declared function signature is the checked boundary.
- Advanced interop notes call out callbacks, rest/spread, interfaces, generics, async operations, exceptions, JSON, type conversion, precision, indexers, and user casts for `ESObject` as boundary-risk areas.
- The JS interop model treats dynamic property access, invocation, index access, and instantiation as the core operators that need explicit boundary handling.

## Status

Active summary for JS interop boundaries, diagnostics, and migration triage.
