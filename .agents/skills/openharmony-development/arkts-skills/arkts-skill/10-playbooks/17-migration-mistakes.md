# Migration mistakes

Use this only when the task is porting TS/JS/CommonJS/shared-module code into ArkTS, or when the compiler rejects TS-specific syntax that is not in the main entry doc.

Do not load this for ordinary ArkTS-first coding.

## Migration loop
1. keep the first compiler error only
2. name the TS habit
3. rewrite to the ArkTS shape below
4. compile again
5. return to `../SKILL.md` when the syntax family clears

## No `var` — use `let` and fix scope
```ts
// WRONG
function f(flag: boolean): int | undefined {
    if (flag) {
        var x = 10
    }
    return x
}

// RIGHT
function f(flag: boolean): int | undefined {
    let x: int | undefined = undefined
    if (flag) {
        x = 10
    }
    return x
}
```

## No angle-bracket casts — use `as`
```ts
// WRONG
let circle = <Circle>shape

// RIGHT
let circle = shape as Circle
```

## No type-level `typeof` — write the concrete type
```ts
// WRONG
let n1 = 42
let n2: typeof n1

// RIGHT
let n1 = 42
let n2: int
```

## No nested functions — use a lambda local
```ts
// WRONG
function addNum(a: int, b: int): void {
    function logValue(message: string): void {
    }
    logValue("ok")
}

// RIGHT
function addNum(a: int, b: int): void {
    let logValue: (message: string) => void = (message: string): void => {
    }
    logValue("ok")
}
```

## No `this` in standalone functions — pass the owner explicitly
```ts
// WRONG
function setCount(i: int): void {
    this.count = i
}

// RIGHT
final class Counter {
    count: int = 0

    setCount(i: int): void {
        this.count = i
    }
}
```

## No definite-assignment local `!:` — initialize on declaration
```ts
// WRONG
let x!: int
x = 10

// RIGHT
let x: int = 10
```

## No `as const`
```ts
// WRONG
let pair = [10, 20] as const
let y: 42 = 42        // error: no numeric literal types

// RIGHT
let pair: [int, int] = [10, 20]
const LIMIT: int = 42
```
Only `string`, `null`, and `undefined` have literal types.

## No `@ts-ignore` or `@ts-nocheck`
```ts
// WRONG
// @ts-ignore
let name: string = undefined

// RIGHT
let name: string | undefined = undefined
```

## Class is a type, not a value
```ts
// WRONG
class C {}
let c = C

// RIGHT
class C {}
let c = new C()
```

## `ESObject` is local interop-only
```ts
// WRONG
let e: ESObject = {}
e.prop

// RIGHT
declare function interopCall(): ESObject
declare function passToInterop(v: ESObject): void

let e: ESObject = interopCall()
passToInterop(e)
```

No variance modifiers on function type parameters:

```ts
// WRONG
function map<in T>(x: T): T { return x }

// RIGHT
function map<T>(x: T): T { return x }
```
`in`/`out` only on class or interface type parameters.

## No local classes or interfaces

Catch variable is `Error`, not `unknown`:

```ts
// WRONG
try { risky() } catch (e: unknown) { }

// RIGHT
try { risky() } catch (e) { console.log(e.message) }
```

```ts
// WRONG
import "module"

// RIGHT
import { run } from "module"
run()
```

## No `keyof`
```ts
// WRONG
type Point = { x: int, y: int }
type PointKey = keyof Point

// RIGHT
type PointKey = "x" | "y"
```

No variance modifiers on function type parameters:

```ts
// WRONG
function map<in T>(x: T): T { return x }

// RIGHT
function map<T>(x: T): T { return x }
```
`in`/`out` only on class or interface type parameters.

## No `module.exports` or `exports.name`
```ts
// WRONG
function foo(): string { return "ok" }
function add(a: int, b: int): int { return a + b }
module.exports = foo
exports.add = add

// RIGHT
function fooDefault(): string { return "ok" }
export default fooDefault
export function add2(a: int, b: int): int { return a + b }
```

## No TS decorators
```ts
// WRONG
@logClass
class User {}

// RIGHT
class UserLogger {
    logCreation(name: string): void {
    }
}

class User {
    private logger: UserLogger

    constructor() {
        this.logger = new UserLogger()
        this.logger.logCreation("User")
    }
}
```

## `@Sendable` classes follow extra rules
```ts
// WRONG
class A {}

@Sendable
class B {
    a: A = new A()
}

// RIGHT
@Sendable
class A {}

@Sendable
class B {
    a: A = new A()
}
```

Keep these `@Sendable` rewrites:
- `@Sendable` class -> inherit only from another `@Sendable` class
- `@Sendable` property -> use only sendable data types
- `@Sendable` property -> do not use `!:`
- generic `@Sendable` type argument -> use only sendable data
- `@Sendable` body -> use imported values/classes/functions only
- `@Sendable` class -> no extra decorators on class, fields, methods, or params
- `@Sendable` value -> construct with `new`, not object literal or array literal
- `@Sendable` class -> no computed property names
- non-sendable value -> do not cast it to a sendable type

## `'use shared'` modules follow extra rules
```ts
// WRONG
'use shared'
import 'module'
export * from 'other'

// RIGHT
'use shared'
import { X } from 'module'
export { X }
```

Keep these shared-module rewrites:
- side-effect import -> import named bindings
- export from shared module -> export sendable entities only
- `export * from ...` -> export named bindings explicitly

## If you see this -> do this next
- TS syntax is rejected but the main entry doc does not name it -> stay here
- `@Sendable` appears -> stay here until sendable restrictions clear
- `'use shared'` appears -> stay here until shared-module restrictions clear
- `ESObject` appears -> keep it local to interop boundaries only
- CommonJS export syntax appears -> rewrite to ESM exports

## Verify
- compile after each rewrite
- keep only one failing syntax family in flight
- return to `../SKILL.md` when the migration-only blocker clears
