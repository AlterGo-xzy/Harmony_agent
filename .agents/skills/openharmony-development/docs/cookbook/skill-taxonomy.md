# Packaged workflow map

This distribution installs one skill: `openharmony-development` at the package root. Files below `arkts-skills/` are supporting workflows and references; they are not independently installed skills.

## Primary workflows

- `implement-arkts`: code changes and project-native verification
- `fix-arkts-errors`: diagnostic-driven repair
- `explain-arkts-diagnostic`: read-only explanation
- `design-arkts-ui-app`: UI blueprint and design-system selection
- `review-arkts`: bounded source and evidence review
- `testing-arkts`: project-framework-aware tests
- `migrate-to-arkts`: TypeScript or JavaScript migration
- `modernize-arkts`: warning- and rule-driven modernization
- `optimize-arkts`: measured performance and resource work
- `arkts-skill`: ArkTS, ArkUI, OHOS, standard-library, and interop routing tree

## Verification

Root `VERIFICATION.md` is the verification workflow. It uses the previewer, device, screenshots, logs, UI trees, or user-provided evidence that is actually available and authorized. `arkts-skills/verify-arkts-ui/references/scenario-matrix.md` provides optional detailed scenario coverage.

## Tooling

Use the project's native build and test commands. `references/windows-deveco-development.md` documents the current Windows/DevEco environment. ArkTS Agent Kit wrappers and MCP tools are optional adapters and must not be assumed.
