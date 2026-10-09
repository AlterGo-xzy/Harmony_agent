# Warning Treated As Error

## Meaning

Compiler or strict-quality warning output has been escalated into a build-blocking failure.

## Likely Causes

- `ets-werror` is enabled
- strict-typing or warning categories are part of the local quality gate
- the code still follows TypeScript-era patterns that the compiler warns about

## Fix Strategy

- identify the warning family
- apply the suggested rewrite
- suppress only when the rewrite is intentionally rejected and documented

## Related Guides

- `docs/cards/core/warnings-as-quality-gates.md`
- `docs/cards/fixes/fix-warning-as-error.md`
