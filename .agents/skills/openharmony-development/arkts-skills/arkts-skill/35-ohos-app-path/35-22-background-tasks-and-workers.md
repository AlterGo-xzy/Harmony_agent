# Background tasks and workers

Use this when the blocker is running work off the UI thread, or scheduling background tasks.

## Pick the right primitive
- default, one job one result → `launch` (always preferred)
- need a pinned long-lived thread → `EAWorker` + `attachThread` (see `20-references/22-launch-and-eaworker.md`)
- `launch` is genuinely unavailable → `taskpool` (legacy — last resort)

## Offload computation with `launch` (preferred)
```ts
import { launch } from '@kit.ArkTS'

async function computeHeavy(input: int): Promise<int> {
    let result = await launch((): int => {
        let sum: int = 0
        for (let i: int = 0; i < 1000000; i++) {
            sum += i * input
        }
        return sum
    })
    return result
}
```

## UI update after launch — wire result back to @State
```ts
@Component
struct CalcPage {
    @State result: int = 0
    @State loading: boolean = false

    aboutToAppear(): void { this.doCompute() }

    doCompute(): void {
        this.loading = true
        computeHeavy(5).then((val: int): void => {
            this.result = val
            this.loading = false
        })
    }
}
```

## Multiple parallel tasks -> `Promise.all` with `launch`
```ts
async function loadDashboard(): Promise<[string[], int[]]> {
    let usersPromise = launch((): string[] => { return fetchUsers() })
    let scoresPromise = launch((): int[] => { return fetchScores() as int[] })

    let users = await usersPromise
    let scores = await scoresPromise
    return [users, scores]
}

// In component:
loadDashboard().then(([users, scores]: [string[], int[]]): void => {
    this.users = users
    this.scores = scores
})
```

## Sequential dependency chain -> `AsyncLock`
```ts
import { AsyncLock, AsyncLockMode } from '@kit.ArkTS'

let lock = new AsyncLock()

lock.lockAsync(async (): Promise<void> => {
    await taskA()
}, AsyncLockMode.EXCLUSIVE)

lock.lockAsync(async (): Promise<void> => {
    await taskB()  // starts only after taskA completes
}, AsyncLockMode.EXCLUSIVE)

lock.lockAsync(async (): Promise<void> => {
    await taskC()  // starts only after taskB completes
}, AsyncLockMode.EXCLUSIVE)
```

## Background task that must complete even if the app is in background
```ts
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'

async function requestBackgroundTime(context: common.UIAbilityContext): Promise<void> {
    backgroundTaskManager.requestSuspendDelay('download', (): void => {
        // called when time is about to expire — wrap up quickly
        console.warn('Background time expiring')
    })
}
```

## Long-running background service -> ServiceExtensionAbility
```ts
import { ServiceExtensionAbility } from '@kit.AbilityKit'

export default class MyService extends ServiceExtensionAbility {
    onCreate(want: Want): void { /* init */ }
    onRequest(want: Want, startId: int): void { /* handle request */ }
    onDestroy(): Promise<void> | undefined { /* cleanup */ }
}
```

## taskpool: legacy fallback (use only when launch is unavailable)
```ts
// taskpool is a runtime global; no import needed.
// Functions passed to taskpool.Task must be standalone, not methods.

// Bad: method
// let task = new taskpool.Task(this.method)

// Good: standalone function
async function slowQuery(): Promise<string[]> { return ['Alice', 'Bob'] }

async function runWithTaskpool(): Promise<string[]> {
    let task = new taskpool.Task(slowQuery)
    let result = await taskpool.execute(task) as string[]
    return result
}

// UI wiring:
@Component
struct LegacyLoader {
    @State items: Array<string> = new Array<string>()
    aboutToAppear(): void {
        runWithTaskpool().then((result: string[]): void => { this.items = result })
    }
}
```

## Verify
- run one launch call, confirm result arrives on UI thread
- post one @State update from launch callback, confirm UI rerenders
- chain two AsyncLock tasks, confirm execution order
- if launch is unavailable, verify taskpool.Task uses a standalone function

## Return
- launch and EAWorker details → `20-references/22-launch-and-eaworker.md`
- taskpool details (legacy) → `20-references/28-taskpool-and-synchronization.md`
- scheduler/promise order → `20-references/26-scheduler-and-promise-runtime.md`
- app model lifecycle → `35-10-app-model-and-system-apis.md`
- if the first direct fix fails → `35-40-ohos-app-failures.md`
