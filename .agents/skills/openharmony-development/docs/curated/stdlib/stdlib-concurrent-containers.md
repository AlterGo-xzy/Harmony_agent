---
summary_id: stdlib/stdlib-concurrent-containers
domain: stdlib
tags: stdlib, concurrency, containers, async, lock, mutex, atomics, hashmap, queue, launch
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Concurrency Primitives and Container Types

## Overview

ArkTS provides its own concurrency model through `std.concurrency` rather than relying on Web Workers or SharedArrayBuffer. The package exposes coroutine-style primitives — `launch` for spawning concurrent tasks, `AsyncLock` and `AsyncMutex` for mutual exclusion, and `Atomics` for lock-free shared-state operations. The `std.containers` package complements this with thread-safe and general-purpose collection types including `ConcurrentHashMap`, `BlockingQueue`, and `ArrayList`. Together these 28 entries define how ArkTS programs handle parallelism and structured data storage.

## Use For

- migrating Worker-based or SharedArrayBuffer concurrency patterns to ArkTS-native equivalents
- selecting the correct synchronization primitive (AsyncLock vs AsyncMutex vs Atomics)
- choosing between standard containers (ArrayList) and concurrent containers (ConcurrentHashMap, BlockingQueue)
- implementing producer-consumer or task-fan-out patterns in ArkTS

## Patterns

- use `launch` to spawn concurrent coroutines; avoid manual thread management
- protect shared mutable state with `AsyncLock` for simple critical sections or `AsyncMutex` when lock ownership transfer is needed
- prefer `Atomics` for single-word shared counters or flags where a full lock is unnecessary
- use `ConcurrentHashMap` for shared key-value stores accessed from multiple coroutines
- use `BlockingQueue` for producer-consumer channels between concurrent tasks
- prefer `ArrayList` (via ArrayAsListInt and similar typed variants) over raw Array when dynamic sizing and list-interface semantics are needed

## Watch For

- mixing JS Worker/postMessage patterns with ArkTS coroutines — they are incompatible models
- forgetting that `ConcurrentHashMap` iteration order is undefined
- using standard (non-concurrent) containers across coroutine boundaries without synchronization
- deadlocking on `AsyncMutex` by re-entering from the same coroutine without unlock

## Evidence

- `AsyncLock` and `AsyncMutex` are `std.concurrency` synchronization primitives with small public surfaces; `AsyncMutex` is gated by `SystemCapability.Utils.Lang` at API 24.
- `Launch.ets` is native-backed and exports the coroutine launch surface; use it as the concurrency entrypoint rather than worker-style constructs.
- `Atomics` is native-heavy (`native_count` 65) and provides the low-level shared-state operation surface under `std.concurrency`.
- `ConcurrentHashMap`, `ArrayAsListInt`, and `BlockingQueue` live in `std.containers`; each has a narrow public export surface, with `ConcurrentHashMap` also carrying native support.

## Status

Active summary covering std.concurrency and std.containers.
