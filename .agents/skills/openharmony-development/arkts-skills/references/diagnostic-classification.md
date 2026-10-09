# Diagnostic Classification

Single authority for classifying ArkTS diagnostics before repair. Skills reference this doc; they must not restate classification procedures.

## Classify Before Editing

Every diagnostic result must be classified into one of these categories before any code change:

| Classification | Meaning | Next Action |
|---------------|---------|-------------|
| `failed` | Diagnose root cause from the diagnostic family | Load matching fix cards from `docs/cards/fixes/` |
| `blocked` | Missing capability from environment or toolchain | Explain the missing capability; do not claim a clean repair |
| `migration-leakage` | Source-language pattern detected in migration context | Load migration cards from `docs/cards/migration/` before fix cards |

## Group by Root Cause

- Group diagnostics by likely root cause before editing
- Separate migration leakage from ordinary ArkTS mistakes
- For `arkts-compile --json`, use `primary_diagnostic`, `summary`, `actions`, `guide_refs`, and `llm_guidance` as the first triage surface
- Fall back to `raw_output` only when normalization is missing or incomplete

## Diagnostic Differential (for FAIL/PARTIAL verdicts)

For every FAIL or PARTIAL verdict, produce a Diagnostic Differential list of all plausible root causes before selecting one. Minimum three hypotheses:

| Hypothesis Family | Example Checks |
|------------------|----------------|
| **Tooling/device** | Tap not reaching component, coordinate drift, display mismatch, bridge reliability, app not foreground |
| **Code — event propagation** | Component not receiving touch, layout clipping, hit-test blocked by parent wrapper, touch target below threshold |
| **Code — state update** | Handler fires but produces no visible change, missing `@State` assignment, missing re-render trigger, stale closure capture |

If the tooling hypothesis is selected: report what code-level checks were performed to rule out the code hypotheses. A code hypothesis cannot be ruled out without reading the source file at the failure site.

## Static Frontend Triage

- Use for non-UI ArkTS files failing in raw frontend compilation
- Prefer a known-good file or module from the same project as the minimal compile baseline
- Compare the failing file against the minimal compile path before broad edits
- If `arkts-compile` succeeds but `arkts-lint` fails: treat as style, migration, or policy repair rather than frontend breakage

## Sources

- `docs/diagnostics/` — human-readable rule and fix catalog
- `docs/cards/` — diagnostic relations and repair guidance
- `docs/cards/fixes/` — 21 per-family fix cards with `related_diagnostics` frontmatter
