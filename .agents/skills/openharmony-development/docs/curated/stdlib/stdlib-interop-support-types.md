---
summary_id: stdlib/stdlib-interop-support-types
domain: stdlib
tags: stdlib, interop, js, esobject, jsvalue, jsruntime, promise, error, bridging
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# JS Interop Support Types (std.interop.js)

## Overview

The `std.interop.js` package provides the runtime-level types that underpin the ArkTS-to-JavaScript interop boundary. `ESObject` is the opaque handle representing any JS/TS value inside ArkTS code. `JSValue` exposes lower-level value manipulation. `JSRuntime` manages the JS execution context lifecycle. `ESError` maps JS exceptions into ArkTS-catchable errors. `PromiseInterop` bridges JS Promises with ArkTS async/await. These 7 entries are the stdlib counterparts to the interop boundary rules described in the docs-layer interop summaries.

## Use For

- understanding the runtime types behind `ESObject` when debugging interop boundary crossings
- bridging JS Promises into ArkTS async workflows via `PromiseInterop`
- catching and inspecting JS-originating exceptions through `ESError`
- advanced interop scenarios requiring direct `JSRuntime` or `JSValue` access

## Patterns

- receive JS values as `ESObject` at the boundary; convert to concrete ArkTS types before passing deeper into application code
- use `PromiseInterop` to await JS Promises from ArkTS coroutines rather than manual callback wiring
- catch `ESError` to handle JS exceptions with structured error information instead of generic Error
- access `JSRuntime` only when managing JS context lifecycle (initialization, teardown) — most application code should not touch it
- treat `JSValue` as an implementation detail; prefer `ESObject` for typed interop unless low-level control is required

## Watch For

- holding `ESObject` references beyond the JS runtime lifecycle — the backing JS object may be garbage-collected
- confusing `ESObject` (interop handle) with `Object` (ArkTS root type) — they are unrelated nominal types
- swallowing `ESError` without inspecting the JS-side stack trace, losing diagnostic information
- using `JSRuntime` or `JSValue` in application-layer code where `ESObject` and typed conversions suffice

## Evidence

- `ESError` and `ESObject` are the narrow public `std.interop.js` boundary types for JS-originating errors and opaque JS values.
- `JSRuntime` and `JSValue` are native-backed lower-level interop helpers; the extracted index shows direct public exports plus runtime/native hooks.
- `PromiseInterop` is native-backed bridge infrastructure with no public exports in the old stdlib index, so ordinary app code should prefer higher-level async wrappers.
- None of the sampled `std.interop.js` entries carry syscap or since metadata in the extracted index; treat lifecycle safety and explicit boundary conversion as the main constraints.

## Status

Active summary covering std.interop.js support types.
