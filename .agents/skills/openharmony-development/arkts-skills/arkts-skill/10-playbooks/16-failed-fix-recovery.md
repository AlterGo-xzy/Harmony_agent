# Failed-fix recovery

Use this only after the first obvious fix failed and you still need a second move.

Do not load this for first-pass coding.
Do not use it to teach ordinary patterns already covered by `../SKILL.md`.

## Recovery loop
1. rerun the smallest failing compile or runtime check
2. keep only the first real error
3. name one failure family
4. apply one second-move rewrite
5. rerun the same check
6. switch docs if the failure is really a state-shape or toolchain problem

## Proof must survive the branch -> move it to a local
```ts
class Profile {
    name: string

    constructor(name: string) {
        this.name = name
    }
}

class Session {
    profile: Profile | undefined = undefined

    profileName(): string {
        let profile = this.profile
        if (profile == undefined) {
            return "guest"
        }
        return profile.name
    }
}
```
Use this when the first fix checked a field/global/captured value directly and the proof still did not carry.

## `typeof` branch did not help
```ts
class User {
    name: string

    constructor(name: string) {
        this.name = name
    }
}

class Guest {}

function label(value: User | Guest): string {
    if (value instanceof User) {
        return value.name
    }
    return "unknown"
}
```
Use this when the first fix tried a JS-style `typeof` probe and the branch still did not unlock class-specific use.

## Predefined union still does not narrow
```ts
type CountOrFlag = number | boolean

function countOrZero(v: CountOrFlag): number {
    if (v instanceof number) {
        return v
    }
    return 0
}
```
Use this when the first fix treated `number` like plain TS primitive syntax and the numeric branch still stayed weak.
Keep `instanceof number` as the preferred numeric runtime probe here; do not switch back to `typeof`.

## Repeated indexed read keeps losing the proof
```ts
let item = items[i]
if (item == undefined) {
    continue
}
return item.name
```
Use this when the first fix kept reading `items[i]` again after the branch and the proof did not carry.

## Numeric `as` cast is rejected
```ts
let ratio: double = Int.toDouble(done) / Int.toDouble(total)
```
Use this when the first fix tried `as double`.

`n as SomeEnum` is also a compile error — use `int` constants or explicit conversion instead.

Avoid mixed-type arithmetic (`int + long` etc.) — convert to a common type first.

## String literal types exist but stay out of the normal path

## Generic reference still fails after the first signature cleanup
```ts
let names: string[] = ["a", "b"]
let first = firstOrUndefined<string>(names)
```
Use this when a generic helper call or reference still stays ambiguous.

## Verify
- rerun the same smallest failing check
- stop when that family clears
- if the failure is really about stored shape -> `11-data-and-state.md`
- if the failure is really about root/config/startup -> `15-toolchain-and-startup.md`

## Return
Return to `../SKILL.md` after the failure family clears.
