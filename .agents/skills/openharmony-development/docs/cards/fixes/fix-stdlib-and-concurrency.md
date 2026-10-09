---
guide_id: fixes/fix-stdlib-and-concurrency
family: fixes
tags: fix, worker, sharedarraybuffer, concurrency, sendable, taskpool, atomics, stdlib
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:LimitedStdLibNoDoncurrentDecorator, linter-fault:LimitedStdLibNoSendableDecorator, linter-fault:NoNeedStdLibSendableContainer, linter-fault:NoNeedStdlibWorker, linter-fault:SendableAsExpr, linter-fault:SendableBetaCompatible, linter-fault:SendableDecoratorLimited
related_migration_patterns: any-or-unknown
status: active
---
# Fix Stdlib and Concurrency Usage Errors

## Intent

Fix stdlib and concurrency usage errors by using ArkTS-approved concurrency primitives instead of restricted web and worker APIs.

## Use When

- code uses `SharedArrayBuffer` for cross-thread shared memory
- code uses `Worker` with `postMessage` for inter-thread communication
- code uses `Atomics` operations that ArkTS restricts
- code passes non-Sendable types across thread boundaries

## Do

- replace `SharedArrayBuffer` with Sendable containers provided by ArkTS
- replace `Worker` message passing with `TaskPool` for concurrent task execution
- use Sendable-compatible types for all data shared across threads
- apply ArkTS concurrent decorators (`@Sendable`, `@Concurrent`) to mark shareable types and functions
- use ArkTS `taskpool.execute()` for parallel work instead of manual worker management
- for ArkUI page-facing background work, verify how results return to the UI thread, not just how work starts on the worker
- when a worker finishes but the page never resumes, move result delivery to explicit `taskpool.Task` callbacks such as `onReceiveData`, `Task.sendData`, and `onExecutionFailed`

## Avoid

- using `SharedArrayBuffer` or `Atomics` directly, as ArkTS restricts these APIs
- passing non-Sendable objects between threads or tasks
- relying on `Worker.postMessage` and `onmessage` patterns from web APIs
- assuming standard library concurrency types from TypeScript are available in ArkTS
- assuming that a background worker finishing implies the page's `await` or `.then(...)` continuation ran
- stopping debugging after proving the worker computed a result when the visible ArkUI state is still stale

## Migration Notes

ArkTS replaces web-standard concurrency APIs with its own Sendable and TaskPool model. All cross-thread data must be Sendable-compatible, and thread management uses TaskPool rather than raw Worker instances.

For ArkUI apps, "background task works" has two separate obligations:
- the computation must finish on the worker side
- the result must be delivered back to the page in a way the runtime actually resumes

If previewer or runtime logs show `taskpool` or `launch(...)` work finishing but the page never leaves its loading state, treat that as a result-handoff bug, not a search/compute bug. In that case, prefer an explicit task callback channel over a promise chain:

```ts
const task = new taskpool.Task(runTask, request)
task.onReceiveData((value: string): void => {
    this.applyResult(value)
})
task.onExecutionFailed((_err: Error): void => {
    this.handleFailure()
})
taskpool.execute(task)
```

Inside the task:

```ts
async function runTask(request: Request): Promise<string> {
    const result = compute(request)
    taskpool.Task.sendData(result)
    return result
}
```

Use logs to prove the whole chain: page request start, worker start, worker finish, UI callback fire, and visible state change.

## Related Diagnostics

- `linter-fault:LimitedStdLibNoDoncurrentDecorator`
- `linter-fault:LimitedStdLibNoSendableDecorator`
- `linter-fault:NoNeedStdLibSendableContainer`
- `linter-fault:NoNeedStdlibWorker`
- `linter-fault:SendableAsExpr`
- `linter-fault:SendableBetaCompatible`
- `linter-fault:SendableDecoratorLimited`

## Status

Active. Use this card when fixing stdlib or concurrency diagnostic errors during ArkTS migration.
