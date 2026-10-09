---
summary_id: stdlib/stdlib-core-type-surface
domain: stdlib
tags: stdlib, core, primitives, array, string, object, regexp, bigint, number, boolean, types
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Core Type Surface (std.core and Unpackaged Types)

## Overview

The `std.core` package defines the foundational type surface that every ArkTS program depends on: Array, String, Object, Number, Boolean, BigInt, RegExp, and their supporting interfaces. These are nominal types with value semantics for primitives and reference semantics for composites. An additional set of unpackaged stdlib files (10 entries outside any declared package) provides compatibility types that bridge legacy patterns. Together these 91 entries form the base layer of the ArkTS type hierarchy.

## Use For

- understanding how ArkTS primitive wrappers (Number, Boolean, String) differ from their lowercase value types
- looking up Array, String, and RegExp method signatures when migrating from TypeScript
- resolving type errors involving Object vs object vs specific class types
- confirming BigInt arithmetic rules and interop with Number

## Patterns

- use lowercase primitives (`number`, `string`, `boolean`) for variables; uppercase wrappers exist for API compatibility but are distinct nominal types
- Array is generic (`Array<T>`) and supports typed element access; prefer it over raw object indexing
- String methods return new strings; ArkTS strings are immutable value types
- RegExp follows the same API surface as ES RegExp but participates in nominal type checking
- Object is the root of the reference-type hierarchy; do not confuse it with `object` (structural) or `ESObject` (interop)
- BigInt is a separate numeric type; implicit coercion between BigInt and Number is forbidden

## Watch For

- assigning a primitive to its wrapper type or vice versa without explicit conversion
- assuming structural subtyping on Object — ArkTS requires nominal class/interface declarations
- using TypedArray APIs (Int32Array, Float64Array) without importing from escompat
- RegExp literal syntax differences from TypeScript in edge cases

## Evidence

- `Array`, `String`, `Object`, `Boolean`, and `BigInt` are `std.core` API 24 surfaces under `SystemCapability.Utils.Lang`; `Array` and `String` are native-backed while `Object` is export-heavy.
- Numeric primitives are split across concrete core files such as `Int`, `Long`, `Double`, `Float`, and `Numeric`; the extracted stdlib index does not contain a single `std/core/Number.ets` record.
- `RegExp` is available under `SystemCapability.Utils.Lang` but is outside a declared package in the extracted index; it has both native and public exports.
- `TypedArrays` is an unpackaged escompat surface with a very large native backing (`native_count` 122), so migrations should treat it as compatibility infrastructure rather than ordinary collection code.

## Status

Active summary covering std.core and unpackaged stdlib files.
