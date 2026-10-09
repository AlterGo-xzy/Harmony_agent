# ArkTS Type System Notes

These notes are grounded primarily in `plugins/ets/doc/spec/3_types.rst`, `plugins/ets/doc/spec/15_semantics.rst`, and `plugins/ets/doc/cookbook/TS_compatibility.rst`.

## High-Signal Differences From TypeScript

- `number` semantics are context-sensitive and can lead to integer behavior where TypeScript would keep floating-point semantics.
- `any` and `unknown` are not acceptable default escape hatches for product code.
- Structural typing assumptions are unsafe; prefer explicit class or interface contracts.
- Generic inference is more limited than in TypeScript; write explicit type arguments when inference becomes ambiguous.
- Function type compatibility is stricter than TypeScript compatibility.

## Review Questions

- Did the code rely on structural compatibility instead of an explicit contract?
- Did a migration preserve TypeScript overload-signature-only patterns?
- Did numeric code assume JS/TS division behavior?
- Did the generated code sneak `any` or `unknown` back in?
