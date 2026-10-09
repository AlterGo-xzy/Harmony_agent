# `launch` and `EAWorker`

Prefer `launch` for one background result. Use `EAWorker` + `attachThread` only when you need a pinned dedicated thread. `taskpool` is legacy — avoid it unless `launch` is genuinely unavailable.

## Pick the right primitive
- default one-shot work → `launch`
- pinned, long-lived dedicated thread → `EAWorker` + `attachThread`
- `taskpool` is legacy — see `28-taskpool-and-synchronization.md` only as a last resort
- one worker runs one job at a time; `EAWorker.start()` takes no task lambda — call `run<T>(...)` after start
- task groups, cancellation, locks → `28-taskpool-and-synchronization.md`
- callback firing order or suspension is wrong → `26-scheduler-and-promise-runtime.md`

## Preferred `launch` shape
Use the importable package path, not the source file path. Pass a top-level non-capturing function.

```ts
import { launch } from 'std/concurrency'

function expensiveStep(): int {
    let total: int = 0
    for (let i: int = 0; i < 12; i++) { total += i + 1 }
    return total
}

async function loadScore(): Promise<int> {
    return await launch<int>(expensiveStep)
}
```

## ArkUI lifecycle: keep hooks synchronous
Lifecycle hooks such as `aboutToAppear()` return `void`. Start async work from the hook; do not make the hook `async`.

```ts
import { Component, Entry, Text } from '@ohos.arkui.component'
import { State } from '@ohos.arkui.stateManagement'
import { launch } from 'std/concurrency'

function computeStartupScore(): int {
    let score: int = 0
    for (let i: int = 0; i < 12; i++) { score += (i + 1) * 3 }
    return score
}

@Entry
@Component
struct HomePage {
    @State score: int = 0

    aboutToAppear(): void {
        this.loadStartupScore()
    }

    private async loadStartupScore(): Promise<void> {
        let result: int = await launch<int>(computeStartupScore)
        this.score = result
    }

    build(): void {
        Text(this.score.toString())
    }
}
```

## With params
The checked stdlib overload takes params first, then the task.

```ts
import { launch, LaunchParams } from 'std/concurrency'

let result: int = await launch<int>(new LaunchParams(), expensiveStep)
```

## `EAWorker` shape
```ts
let worker = new EAWorker()
worker.start()
let result = await worker.run<int>(expensiveStep)
await worker.join()
```

## Troubleshooting
- import fails for `std/concurrency/Launch` → use `std/concurrency`
- lifecycle error says `aboutToAppear` returns `Promise<undefined>` → keep `aboutToAppear(): void` and call a private async method
- launch task is an inline closure or captures component state → move the work to a top-level non-capturing function and pass that function
- you tried to pass a task lambda to `EAWorker.start()` → start the worker first, then call `run(...)`
- two jobs on one worker expected to run at the same time → they will not; one worker runs one job at a time
- resumed async code expected to stay on the same worker → do not assume that after suspension

## Verify
- run one tiny task with the chosen primitive
- for OHOS apps, run the HAP build, not only file lint
- prove completion before widening the flow

## Return
Return to `../SKILL.md` after the pattern resolves the blocker.
