# Maps, sets, and weak collections

Use this when the code needs open-ended keyed lookup, membership checks, or deduplication.

## Pick one
- fixed known fields -> use one small data class
- open-ended keyed lookup with missing-key handling -> use `Map<K, V>` and branch on `undefined` once
- membership or deduplication -> use `Set<T>`
- queue workflow -> use the `Array<T>` fallback below
- if plain `Array<T>` or one small owner class already solves the task, stay with that

## Keyed lookup -> `Map<K, V>`
```ts
let scores = new Map<string, int>()
scores.set("alice", 10)

let score = scores.get("alice")
if (score == undefined) {
    return 0
}
return score
```

## Membership check -> `Set<T>`
```ts
let seen = new Set<string>()
seen.add("wall")

if (seen.has("wall")) {
    return true
}
return false
```

## Dedup one array -> `Set<T>` plus one pass
```ts
function uniqueNames(names: string[]): string[] {
    let seen = new Set<string>()
    let out: string[] = []
    for (let name of names) {
        if (!seen.has(name)) {
            seen.add(name)
            out.push(name)
        }
    }
    return out
}
```

## Queue fallback -> plain array with `push()` and `shift()`
```ts
export final class NameQueue {
    private items: string[]

    constructor() {
        this.items = []
    }

    enqueue(name: string): void {
        this.items.push(name)
    }

    dequeue(): string | undefined {
        let value = this.items.shift()
        if (value == null) {
            return undefined
        }
        return value
    }
}
```

Next move:
- use this only for a small, simple, non-hot FIFO queue
- use `push(...)` to enqueue
- use `shift()` once at the dequeue boundary
- normalize `null` to `undefined` once if the rest of the app uses `undefined`
- if the queue is hot, large, bounded, or concurrent, do not assume `shift()` is the long-term shape; switch to a queue-specific structure instead

## Verify
- compile immediately after switching from array/manual lookup to `Map` or `Set`
- rerun one lookup, membership, or dedup path
- keep null/absence handling explicit after `map.get(...)`

## Return
Return to `../SKILL.md` after the collection pattern works.
