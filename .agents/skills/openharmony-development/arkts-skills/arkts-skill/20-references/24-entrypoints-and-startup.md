# Entrypoints and startup

Use this when the program starts from the wrong function, the entry signature is rejected, or top-level code runs in an unexpected order.

## CLI vs OHOS — two different entry paths

**CLI / standalone VM:**

```ts
export function main() { }
export function main(args: FixedArray<string>) { }
export async function main(): Promise<void> { }
export async function main(args: FixedArray<string>): Promise<void> { }
```

No exported non-`main` entry.

**Production OHOS app — no `main()`:**

```
module.json5 → UIAbility → loadContent → @Entry @Component
```

For OHOS app startup, switch to `../../35-ohos-app-path/35-10-app-model-and-system-apis.md`.

## Import must come first

Any top-level code before the first `import` is a compile error:

```ts
// WRONG
let x = 1; import { sin } from "std/math"  // error

// RIGHT
import { sin } from "std/math"; let x = 1
```

## Top-level statements

Technically compile but most project policies warn/reject them. Wrap in `main()`:

```ts
// AVOID
print("booted")

// PREFER
function main(): void { print("booted") }
```

## Verify
- compile
- run one real startup path
- if top-level code and entry coexist, confirm observed order

## Return
- CLI entry fixed → return to `../SKILL.md`
- OHOS app entry → `../../35-ohos-app-path/35-10-app-model-and-system-apis.md`
- startup config or project layout wrong → `../../10-playbooks/15-toolchain-and-startup.md`
