# Scheduler and promise runtime

Use this when callbacks fire in the wrong order, a suspended async function lands on the wrong worker, or timing assumptions break.

## Execution order bug → reduce to one tiny repro
Reduce to one worker claim or one suspension claim. Build a tiny repro and prove registration/execution order before touching the real app. If the issue becomes locks, atomics, or task groups → `28-taskpool-and-synchronization.md`.

## Callback-order repro
```ts
let events: string[] = []
Promise.resolve().then((): void => { events.push("callback") })
events.push("after-register")
```

## Suspension repro
```ts
let task = launch(async (): Promise<int> => {
    await Promise.resolve()
    return 1
})
```

## Abstract async functions are prohibiited
Abstract declarations are the exception: do not combine abstract + async.

// WRONG
```ts
abstract class Engine {
    abstract async request(): Promise<string> 
}
```
// RIGHT
```ts
abstract class Engine {
    abstract request(): Promise<string>
}

final class HttpEngine extends Engine {
    async request(): Promise<string> {
        return "ok"
    }
}
```

## No async getters and setters
Do not write async getters and setters as there is no support of them.
```ts
class C {
    async get(): Promise<string> { return "ok" }    // ESY0107: Modifiers of getter/setter limited
}
```

## Order assumptions keep failing → rewrite them
- callback registered now does not run inline → treat it as later job work
- async helper has no real `await` → do not invent an extra scheduling boundary
- same-worker order matters → test the observed registration order first
- resumed async work touches worker-local assumptions → do not assume it stays on one worker after suspension
- two jobs expected to run at same time on one worker → split them across workers
- Promise callbacks are FIFO among same priority and fire before timer/message callbacks on the same worker

## Verify
1. keep one tiny repro
2. log registration order and execution order
3. prove same-worker behavior first
4. prove cross-worker behavior separately only if needed

## Return
Return to `../SKILL.md` after the scheduling behavior is understood.
