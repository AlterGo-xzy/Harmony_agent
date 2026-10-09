---
summary_id: concurrency/concurrency-api-boundaries
domain: concurrency
tags: concurrency, async, workers, stdlib, restrictions
related_skills: implement-arkts, migrate-to-arkts, explain-arkts-diagnostic, review-arkts
status: active
---
# Start From Supported ArkTS Concurrency APIs, Not Worker-Era Habits

## Overview

The concurrency docs define the supported execution model and API boundaries. Use them to reshape migrated or reviewed code toward supported async and parallel patterns instead of preserving worker-style or unrestricted shared-state assumptions.

## Use For

- migration review when code expects `Worker` or shared-buffer style behavior
- checking whether a concurrency design matches the documented ArkTS execution model
- framing fixes for restricted stdlib concurrency diagnostics

## Patterns

- begin from the documented execution model and supported APIs
- rewrite old worker-style designs instead of hiding them behind utility shims
- treat concurrency diagnostics as architecture-level signals, not as local syntax issues

## Watch For

- `Worker` assumptions, shared-buffer assumptions, or decorator-driven concurrency shortcuts
- stdlib concurrency usage that conflicts with documented restrictions
- async rewrites that keep the old concurrency model conceptually intact

## Evidence

- The concurrency model is built around jobs executed by workers: one job runs on a worker at a time, jobs on different workers can run in parallel, and multiple jobs on the same worker execute asynchronously rather than in parallel.
- Every program has an implicit main job, and jobs can suspend at suspension points so another job can run on the same worker until the suspended job resumes.
- ArkTS exposes asynchronous execution through `async`, `await`, and standard-library `Promise`; use this for waits on external events, timers, user input, or status from another job.
- Parallel execution is a standard-library capability for running functions or methods on different workers, with dependency management and load balancing across available CPU cores or OS threads.
- Program memory is shared between jobs, so shared data requires synchronization to avoid races and preserve exclusive access across both parallel execution and coroutine suspension.
- Supported synchronization includes asynchronous locking APIs, asynchronous mutex/read-write lock/condition-variable APIs, atomics, and supplemental standard-library synchronization helpers; API-specific restrictions live with the detailed concurrency API docs.

## Status

Active summary for concurrency-boundary review. Pair it with migration cards and diagnostics when a change needs concrete rewrites.
