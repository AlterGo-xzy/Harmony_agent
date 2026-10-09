# Compile And Fix Loop

This is the default operational loop used by `implement-arkts`, `migrate-to-arkts`, and `fix-arkts-errors`.

## Commands

```bash
arkts-compile path/to/file.ets --json
arkts-check path/to/file.ets --json
arkts-lint path/to/file-or-dir --json
arkts-lint path/to/file-or-dir --fix --json
```

## Loop

1. Compile and lint the target.
2. Group failures into compile and lint phases.
3. For plain compiler failures, prefer the compact `diagnostics`, `primary_diagnostic`, `summary`, `actions`, `guide_refs`, and `llm_guidance` fields from `arkts-compile --json`.
4. Read the matching guide in `docs/diagnostics/` or the linked compact guide refs from the wrapper payload.
5. Use `raw_output` only when normalization is incomplete or the target was routed through a non-normalized compile path.
6. Use `arkts-lint --fix --json` only when the remaining work is a bounded linter-backed rewrite.
7. Apply the bounded fix.
8. Re-run the check.

## Why

The purpose is to stop agents from treating compiler output as a vague hint. Diagnostics should be normalized, categorized, and tied to recipes.
