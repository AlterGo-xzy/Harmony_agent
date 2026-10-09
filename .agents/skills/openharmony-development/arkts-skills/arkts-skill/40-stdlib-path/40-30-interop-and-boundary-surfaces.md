# Interop and boundary surfaces

## Class reflection

```ts
import { Class } from "std/core/Class"

Class.of(obj)      // Class instance, undefined for primitives
Class.ofAny(val)   // undefined for non-object non-null; null handled specially
Class.ofCaller()   // class of calling context
```

## Annotations

Define with retention and target:

```ts
@Retention("RUNTIME")
@Target(["class", "function"])
@interface MyAnno { value: string }
```

Retention policies:
- `"SOURCE"` — no runtime type, compiler-only
- `"BYTECODE"` — survives compilation, not reflection-readable
- `"RUNTIME"` — reflection-visible

Target positions: `class`, `interface`, `function`, `method`, `field`, `parameter`, `constructor`, `lambda`, `enum`, `namespace`, `variable`, `struct`, `type`.

Built-in annotations use different retentions — `@Retention("BYTECODE")` for `ani.unsafe.Quick`/`Direct`, `@Retention("RUNTIME")` for `InterfaceObjectLiteral`.

## Verify
- compile
- for runtime annotations, confirm retention policy before relying on reflection

## Return
Return to `../../SKILL.md`.
