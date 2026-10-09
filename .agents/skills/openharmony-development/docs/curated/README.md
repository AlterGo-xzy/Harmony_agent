# Curated Summaries

`docs/curated/*` is the second curated markdown layer for source-heavy ArkTS evidence.

## Read Order

1. `docs/cards/*` for short operational guidance
2. `docs/curated/*` for compressed domain summaries
3. SDK and standard-library declarations for exact API lookup

## Scope

Use this layer for domains where raw or derived evidence is too broad to drop directly into a skill loop:

- `sdk`
- `stdlib`
- `ui`
- `runtime`
- `interop`
- `concurrency`

## Rules

- Keep summaries short enough for an agent to read before acting.
- Do not copy raw JSON or declaration files verbatim.
- Summaries should compress recurring patterns, capability gates, and high-value constraints.
- Cite authoritative source paths in markdown so maintainers can trace each claim.
- Treat summaries as context compression, not as a replacement for the indexes.

## Evidence

- Curated summaries are committed markdown artifacts intended for agent-time reading, so they must carry the useful source conclusions directly instead of depending on generated lookup trees.
- Domain files under this directory compress source-heavy material from SDK declarations, standard-library sources, ArkUI metadata, runtime docs, interop docs, concurrency docs, diagnostics, and migration guides.
- Exact API and behavior checks still belong in the authoritative local sources and wrappers; curated summaries provide the high-signal routing context before those exact lookups.

## Maintainer Flow

- committed summaries live under `docs/curated/*`
- draft summaries live under `.generated/curation/draft-summaries/*`
- summary changes require normal maintainer review
