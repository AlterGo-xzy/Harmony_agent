# Runtime debugging and exceptions

Use this when the bug is about whether a failure is thrown, rejected, uncaught, or only looks like a code bug because startup/runtime packaging is wrong.

## Keep these distinctions
- thrown direct code path -> fix the throw site or catch path
- thrown worker/job result -> handle the rejected `Promise`
- main-job throw or unhandleable runtime-created failure -> treat it as uncaught
- if you already have `catch (e)`, treat `e` as `Error` and inspect or rethrow that object instead of rebuilding failure state from scratch

## First classification
- startup or entry failure -> `../10-playbooks/15-toolchain-and-startup.md`
- rejected `Promise` from a job result -> handle the rejection path
- uncaught throw on the main job -> fix the throw site or wrap it in `try` / `catch`
- native-boundary failure -> `23-10-native-code.md`, `23-20-any-signatures.md` 
- interop-boundary failure -> `../50-interop-path/50-50-interop-failures.md`

## Throw path -> `try` / `catch`
```ts
function parsePort(text: string): int {
    if (text.length == 0) {
        throw new Error()
    }
    return parseInt(text).toInt()
}

function safePort(text: string): int {
    try {
        return parsePort(text)
    } catch (e) {
        return 0
    }
}
```

## Rejected promise path -> handle the rejection
```ts
let task = launch((): int => {
    throw new Error()
})

try {
    await task
} catch (e) {
}
```

## Plain string throw from old code -> migrate it
```ts
throw new Error()
```
Do not keep plain-string throws as the default pattern in touched code.

## Smallest runtime repro loop
1. reduce to one failing startup path, callback path, or awaited job
2. decide whether the failure is thrown directly or arrives as promise rejection
3. rerun one tiny repro for that path only
4. fix one boundary at a time

## Verify
- keep one tiny repro or one tiny startup path
- if the failure comes from `await`, verify the rejection path directly
- if the failure comes from the main job, verify the direct throw path separately

## Return
- debugging successful -> return to `../SKILL.md`
- the failure is a code-shape or state-shape issue -> `../../10-playbooks/16-failed-fix-recovery.md`
