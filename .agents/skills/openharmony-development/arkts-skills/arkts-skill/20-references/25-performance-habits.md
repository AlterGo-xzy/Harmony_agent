# Performance habits

Use only for measured hot-path cleanup.

## Grounding you can trust
- `ValueArray<T>` is more performant than `FixedArray<T>` under its tighter rules: `spec/17_experimental.rst:390-399`
- `FixedArray<T>` gives fixed length and constant-time indexed access: `spec/17_experimental.rst:248-255`
- `for-of` is legal iteration over arrays and iterables: `spec/8_statements.rst:599-659`
- the spec does not say `for-of` is the fast path
- ArkTS has distinct numeric types including `byte`, `short`, `int`, `long`, `float`, and `double`: `spec/7_expressions.rst:3303-3319, 4378-4381, 4726-4784`

## Keep these distinctions
- Use `ValueArray<T>` for hot primitive fixed-size lanes, `FixedArray<T>` for non-value fixed-size lanes
- Use counted `for` loops as the hot-path baseline
- Every rewrite below is a measured candidate only — compare before and after

## Hot array loop is already measured
```text
one measured `Array<T>` loop is hot
```

Next move:
- rewrite that loop to a counted loop first
- cache `length` once inside that loop rewrite
- compare the same workload before and after

```ts
function step(values: int[]): int {
    let total: int = 0
    let n: int = values.length
    for (let i: int = 0; i < n; i++) {
        total += values[i]
    }
    return total
}
```

## Fixed-size non-value lane may justify `Array<T>` -> `FixedArray<T>`
```text
one measured fixed-size lane is hot and its element type is not a value type such as `string`
```

Next move:
- keep this as a measured candidate rewrite only
- switch one fixed-size non-value lane from `Array<T>` to `FixedArray<T>`
- keep primitive fixed-size lanes on the `ValueArray<T>` path instead
- keep the rest of the app on ordinary arrays unless the same lane keeps winning

```ts
function totalNameLength(names: string[]): int {
    let total: int = 0
    for (let i: int = 0; i < names.length; i++) {
        total += names[i].length
    }
    return total
}

function totalFixedNameLength(names: FixedArray<string>): int {
    let total: int = 0
    for (let i: int = 0; i < names.length; i++) {
        total += names[i].length
    }
    return total
}
```

```ts
let hotNames: string[] = ["slime", "bat", "mage"]
let fixedNames: FixedArray<string> = ["slime", "bat", "mage"]
```

## Fixed-size primitive lane may justify `Array<T>` -> `ValueArray<T>`
```text
one measured fixed-size primitive numeric lane is hot
```

Next move:
- switch that primitive lane straight from `Array<T>` to `ValueArray<T>`
- do not stop at `FixedArray<T>` for the primitive lane in this path
- keep the surrounding app unchanged
- compare the same workload before and after

```ts
function sumArray(values: int[]): int {
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) {
        total += values[i]
    }
    return total
}

function sumValues(values: ValueArray<int>): int {
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) {
        total += values[i]
    }
    return total
}
```

```ts
let hotHp: int[] = [10, 10, 10]
let packedHp: ValueArray<int> = [10, 10, 10]
```

## Numeric conversion churn shows up while reading the lane
```text
one measured hot loop keeps converting each element while reading it
```

Next move:
- stop converting each element inside the hot loop if the lane can be stored in the needed type already
- keep the loop on one numeric type when the algorithm allows it
- move conversion to the boundary when possible

```ts
function sumConverted(values: ValueArray<int>): double {
    let total: double = 0.0
    for (let i: int = 0; i < values.length; i++) {
        total += values[i].toDouble()
    }
    return total
}

function sumDoubles(values: ValueArray<double>): double {
    let total: double = 0.0
    for (let i: int = 0; i < values.length; i++) {
        total += values[i]
    }
    return total
}
```

```ts
function parseWeights(args: FixedArray<string>): ValueArray<double> {
    let weights = new ValueArray<double>(args.length, 0.0)
    for (let i: int = 0; i < args.length; i++) {
        weights[i] = parseFloat(args[i])
    }
    return weights
}
```

## Primitive hot lane keeps carrying optional or union state
```text
one measured hot primitive lane is really `primitive | undefined` or another small primitive union
```

Next move:
- keep this as a measured candidate rewrite only
- split only when the lane is truly a small primitive union or optional primitive
- using a primitive through unions, optionals, or plain value positions can force implicit boxing on the hot path
- keep the rewritten hot storage and hot parameters on primitive lanes or primitive parameters too
- use one primitive lane plus flags for `primitive | undefined`
- use paired primitive lanes for small tagged unions such as `int | boolean`
- keep boolean flag lanes on `ValueArray<boolean>` too

```ts
function sumMaybe(values: (int | undefined)[]): int {
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) {
        let value = values[i]
        if (value !== undefined) {
            total += value
        }
    }
    return total
}

class OptionalIntLane {
    values: ValueArray<int>
    present: ValueArray<boolean>

    constructor(values: ValueArray<int>, present: ValueArray<boolean>) {
        this.values = values
        this.present = present
    }
}

function sumPresent(lane: OptionalIntLane): int {
    let values = lane.values
    let present = lane.present
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) {
        if (present[i]) {
            total += values[i]
        }
    }
    return total
}
```

```ts
class IntOrBoolLane {
    isInt: ValueArray<boolean>
    intValues: ValueArray<int>
    boolValues: ValueArray<boolean>

    constructor(isInt: ValueArray<boolean>, intValues: ValueArray<int>, boolValues: ValueArray<boolean>) {
        this.isInt = isInt
        this.intValues = intValues
        this.boolValues = boolValues
    }
}
```

## Optional primitive parameter sits on the hot path
```text
one measured hot helper keeps branching on an optional primitive parameter
```

Next move:
- keep the boundary helper with the optional parameter
- move the hot inner helper to a non-optional primitive parameter
- make the branch once at the boundary instead of inside the repeated hot work

```ts
function scoreHit(rawDamage: int | undefined, armor: int): int {
    if (rawDamage === undefined) {
        return 0
    }
    return scoreHitValue(rawDamage, armor)
}

function scoreHitValue(rawDamage: int, armor: int): int {
    let reduced: int = rawDamage - armor
    if (reduced < 0) {
        return 0
    }
    return reduced
}
```

## Tiny accessor calls sit inside the hot loop
```text
one measured hot loop keeps calling tiny getters or setters you own
```

Next move:
- keep this as a measured candidate rewrite only
- if the accessor does no real work, use a more direct hot-lane shape in that loop
- keep the rewrite local to the hot owner or hot loop

```ts
class Stats {
    values: int[]

    constructor(values: int[]) {
        this.values = values
    }

    valueAt(i: int): int {
        return this.values[i]
    }
}

function sum(stats: Stats): int {
    let total: int = 0
    for (let i: int = 0; i < stats.values.length; i++) {
        total += stats.values[i]
    }
    return total
}
```

## Flat grid or index math is the hot shape
```text
grid or board indirection is part of the measured hot path
```

Next move:
- flatten only the hot lane
- compute the index in one helper
- avoid redesigning unrelated state

```ts
function cellIndex(width: int, x: int, y: int): int {
    return y * width + x
}
```

## Expensive independent job is hot
```text
one expensive pure or mostly isolated job dominates runtime
```

Next move:
- rewrite that job to `launch` before considering native
- keep the job boundary small
- verify the same workload and result after offloading
- load `22-launch-and-eaworker.md` before widening the parallel path

```ts
function expensiveStep(values: int[]): int {
    let total: int = 0
    for (let i: int = 0; i < values.length; i++) {
        total += values[i]
    }
    return total
}

async function runInline(values: int[]): Promise<int> {
    return expensiveStep(values)
}

async function runLaunched(values: int[]): Promise<int> {
    let task = launch((): int => {
        return expensiveStep(values)
    })
    return await task
}
```

## Native may be worth it only after simpler rewrites fail
```text
one tiny hotspot is still dominant after local loop, lane, and `launch` rewrites
```

Next move:
- keep native as a later move than loop or `launch` cleanup
- move only one tiny stable function across the boundary
- load `23-native-code.md` before introducing bindings

```ts
native function nativeAdd(a: int, b: int): int
```

## Arrow calls inside the hot loop
```text
one measured hot loop keeps calling through inline arrow functions you own
```

Next move:
- keep this as a measured candidate rewrite only
- extract the arrow body into a named `function` declaration
- compare the same workload before and after
- keep arrow functions for short local captures where readability matters more than the lane cost

```ts
let step = (i: int): int => { return i + 1 }

function stepFn(i: int): int {
    return i + 1
}
```

## Micro-optimization is still uncertain
```text
the code looks expensive, but nothing is measured yet
```

Next move:
- leave a local TODO
- do not rewrite the surrounding code yet

```ts
// TODO: verify whether this loop form is faster in the real target build
// TODO: verify whether this container switch helps the actual hot lane
```

## Verify
- compile
- keep one correctness path unchanged
- compare the same hot path before and after
- widen only the one measured winner

## Return
Return to `../SKILL.md`. If offload is needed → `22-launch-and-eaworker.md`. If native is needed → `23-native-code.md`.
