---
summary_id: stdlib/stdlib-surface-and-restrictions
domain: stdlib
tags: stdlib, package-surface, concurrency, restrictions, deprecation
related_skills: implement-arkts, migrate-to-arkts, explain-arkts-diagnostic, review-arkts
status: active
---
# Treat Stdlib Metadata As A Supported-Surface Filter

## Overview

The stdlib snapshot is a source of supported package surface, export breadth, and restricted feature signals. Read it as a boundary for what ArkTS actually wants you to depend on, especially when migrations arrive with worker-style or shared-buffer assumptions.

## Use For

- checking whether a standard-library package is broad, narrow, or already marked deprecated
- reviewing code that leans on concurrency-adjacent stdlib features
- deciding whether a migrated helper should stay in stdlib form or be rewritten around ArkTS-native APIs

## Patterns

- prefer packages with clear public exports over ad hoc compatibility shims
- treat deprecated stdlib entries as migration pressure rather than as a safe default
- use concurrency diagnostics to decide when a stdlib-based design needs an architectural rewrite

## Watch For

- deprecated compatibility-oriented entries in standard-library declarations
- - code that assumes `Worker`, `SharedArrayBuffer`, or unrestricted decorator-driven concurrency support

## Evidence

- `escompat` includes non-deprecated error surfaces and native-heavy typed-array compatibility, but adjacent escompat helpers such as `Functions` are deprecated.
- `std.core` contains API 24 language surfaces such as `Array`, with native-backed methods and explicit `SystemCapability.Utils.Lang` metadata.
- `std.concurrency` and `std.containers` expose narrow, purpose-built concurrency/container APIs such as `AsyncLock` and `ConcurrentHashMap` rather than web-worker-style primitives.
- `std.interop` entries such as `ESValue` are separate from ordinary `Object`/`Array` surfaces and should stay at interop boundaries.

## Status

Active summary for stdlib lookup and migration review. Read the exact package or symbol declaration after this summary.
