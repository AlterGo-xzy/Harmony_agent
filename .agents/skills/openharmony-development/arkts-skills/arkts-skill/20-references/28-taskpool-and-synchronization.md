# Taskpool

`taskpool` is a legacy API. Always prefer `launch` (see `22-launch-and-eaworker.md`) for background work. Use taskpool only when `launch` is genuinely unavailable.

## Offload work to taskpool (legacy)

```ts
async function slowQuery(): Promise<string[]> { return ['Alice', 'Bob'] }

export async function runQuery(): Promise<string[]> {
    try {
        let task = new taskpool.Task(slowQuery)
        let result = await taskpool.execute(task) as string[]
        return result
    } catch (err: Error) { return [] as string[] }
}
```
`taskpool` is a runtime global; no import needed.

## Pick up the result on the UI thread

```ts
@Component
struct ContactListPage {
    @State contacts: Array<string> = new Array<string>()
    aboutToAppear(): void {
        runQuery().then((result: string[]) => { this.contacts = result })
    }
}
```

## Taskpool function must be a standalone function, not a method

```ts
// Good: standalone
async function queryAll(): Promise<string[]> { return await DatabaseHelper.getInstance().query() }
// Bad: method passed to Task
// let task = new taskpool.Task(helper.query)
```

## Coordinate multiple async tasks -> `AsyncLock`

```ts
import { AsyncLock, AsyncLockMode } from '@kit.ArkTS'
let lock = new AsyncLock()
lock.lockAsync(async () => { await taskA() }, AsyncLockMode.SHARED)
lock.lockAsync(async () => { await taskB() }, AsyncLockMode.SHARED)
lock.lockAsync(async () => { await taskC() }, AsyncLockMode.EXCLUSIVE)
```

## Pick the right primitive
- one job, one result → `launch` (preferred)
- launch unavailable or need multiple args → `taskpool`
- dedicated worker lane → `EAWorker`
- callback timing or execution order → `26-scheduler-and-promise-runtime.md`

## Verify
- compile after wrapping the function in `taskpool.Task`
- run one tiny offloaded call and confirm the result arrives on the UI thread
- if using AsyncLock, verify task C starts only after A and B finish

## Return
Return to `../SKILL.md` after the offload resolves the blocker.
