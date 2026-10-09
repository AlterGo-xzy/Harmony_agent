# Stdlib collections and data surfaces

## String

`str[i]` returns a single-character `String`, not `char`. Out-of-bounds indexing throws:

```ts
"hello"[0]   // "h" (String)
"hello"[100] // StringIndexOutOfBoundsError
```

`charAt` returns `char`:

```ts
"hello".charAt(0)  // char
```

Construct from any primitive:

```ts
String(42)     // "42"
String(true)   // "true"
```

Padding:

```ts
"7".padLeft(3, "0")    // "007"
"x".padRight(2, ".")   // "x."
```

Locale-sensitive comparison:

```ts
"ä".localeCompare("z", "de")  // ä before z
"ä".localeCompare("z", "sv")  // ä after z
```

## Array

`length` is shrink-only — setting it larger or negative throws `RangeError`:

```ts
let arr = [1, 2, 3]
arr.length = 5   // throws RangeError
```

Construction with initializer:

```ts
new Array<int>(4, (i: int) => i * 10)  // [0, 10, 20, 30]
Array.create<int>(3, 0)                // [0, 0, 0]
Array.from(source, (x: int) => x * 2)  // from iterable with mapper
```

## ArrayList

```ts
import { ArrayList } from "@ohos.util.ArrayList"

let list = new ArrayList<int>()
list.add(1)
list.insert(5, 0)            // insert at index
list.sort((a, b) => a - b)
let arr = list.convertToArray()
```

Throws `BusinessError` (with numeric code) on capacity or bounds violations.

## JSON data surfaces

JSON parsing/stringify owns a separate route: `40-15-json-data-surfaces.md`.

## HashMap

`undefined` keys are rejected:

```ts
import { HashMap } from "@ohos.util.HashMap"

let m = new HashMap<string, int>()
m.set(undefined, 1)  // throws BusinessError
```

Iteration is insertion-order:

```ts
for (let [k, v] of m) { }
```

## Verify
- compile
- run one operation on each collection type used

## Return
Return to `../../SKILL.md`.
