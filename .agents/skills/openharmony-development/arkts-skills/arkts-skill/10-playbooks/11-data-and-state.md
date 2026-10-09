# Data and state

Use this only when the bug is in the stored shape itself, not in one local helper.

Load this when one of these is true:
- one class-owned array keeps getting pushed, copied, or rewritten from many places
- one nullable member field keeps needing repeated proofs across methods
- one stored total/label/cache goes stale after updates
- one lifecycle phase is encoded as loose nullable fields
- one nested object-heavy grid should become one flat lane

Do not load this for ordinary local null checks, one helper function, or one small class edit.

## Owned repair loop
1. pick one unstable field or collection owner
2. change the stored shape once
3. keep the write path single-owner
4. rerun one create/update/read path

---

## Stale derived field -> derive it
```ts
export final class CartLine {
    price: int; count: int
    constructor(price: int, count: int) { this.price = price; this.count = count }
}

export final class CartState {
    private lines: CartLine[] = []
    replaceLines(next: CartLine[]): void { this.lines = next }
    totalPrice(): int {
        let total: int = 0
        for (let i: int = 0; i < this.lines.length; i++) {
            let line = this.lines[i]; total += line.price * line.count
        }
        return total
    }
}
```

---

## Class-owned array keeps breaking from direct push/index/update edits -> local build, replace once

```ts
export final class QueueState {
    private jobs: string[] = []
    replaceJobs(next: string[]): void { this.jobs = next }
    count(): int { return this.jobs.length }
    jobAt(index: int): string { return this.jobs[index] }
}

function appendJob(state: QueueState, name: string): void {
    let next: string[] = []
    for (let i: int = 0; i < state.count(); i++) { next.push(state.jobAt(i)) }
    next.push(name)
    state.replaceJobs(next)
}
```

---

## Stored-state narrowing keeps defeating local proof rewrites across methods -> change the state shape

```ts
enum SessionPhase { Empty = 0, Ready = 1 }

export final class SessionData {
    token: string
    constructor(token: string) { this.token = token }
}

export final class SessionStore {
    private phase: SessionPhase = SessionPhase.Empty
    private data: SessionData | undefined = undefined

    start(token: string): void {
        this.data = new SessionData(token)
        this.phase = SessionPhase.Ready
    }

    tokenOrGuest(): string {
        if (this.phase == SessionPhase.Empty) { return "guest" }
        let data = this.data
        if (data == undefined) { return "guest" }
        return data.token
    }
}
```

---

## Draft shape and saved shape are different
```ts
export final class ProfileDraft {
    name: string = ""; city: string = ""
}

export final class ProfileSaved {
    name: string; city: string
    constructor(name: string, city: string) { this.name = name; this.city = city }
}
```

## Data carrier call sites keep widening -> choose one named construction shape
```ts
export final class ItemView { name: string = ""; price: int = 0; stock: int = 0 }
let view: ItemView = { name: "rope", price: 25, stock: 3 }

export final class ItemPrice { name: string; price: int }
let price = new ItemPrice("rope", 25)
```

If the class is a true data carrier and named object-literal construction is allowed, prefer the object literal. If the class has required constructor invariants, use the constructor instead. Do not guess between the two shapes from TS habit alone.

---

## Helper trust is low and you need initialized storage now -> write one explicit loop
```ts
function zeros(count: int): int[] {
    let out: int[] = []
    for (let i: int = 0; i < count; i++) { out.push(0) }
    return out
}
```
If one explicit loop is clear, write it. Use `fill(...)` only when you already know that exact helper fits.

## Nested grid pressure -> flat lane
See `cellIndex` in `../20-references/25-performance-habits.md`.

## Verify
- compile
- run one create/update/read path
- run one phase transition if phase changed
- run one derived-value path if stored fields changed

## Return
Return to `../SKILL.md` after the stored shape stops causing new edits.
