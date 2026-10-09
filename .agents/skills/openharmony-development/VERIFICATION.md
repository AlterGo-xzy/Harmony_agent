# Verification workflow

Use this workflow in ChatGPT, Codex, or another supported environment without assuming repository-specific wrappers or external helper scripts.

## Evidence rule

Never claim compile, lint, launch, render, device, previewer, interaction, or runtime success without actual evidence from a tool available in the current environment or output/screenshots supplied by the user.

## Code verification

1. Identify the narrowest compile/lint/build check relevant to the changed module.
2. Prefer the project-native build or test surface. For Windows/DevEco projects, read `references/windows-deveco-development.md`. If the environment cannot run the required tool, give the exact command or UI action and request its output.
3. Route diagnostics through `arkts-skills/fix-arkts-errors/WORKFLOW.md` and the matching `docs/diagnostics/` or `docs/cards/fixes/` reference.
4. Re-check after the smallest fix.

## ArkUI verification

1. Read `arkts-skills/references/ui-ux-quality-bar.md`.
2. For interaction-heavy work, also read `arkts-skills/verify-arkts-ui/references/scenario-matrix.md`.
3. Build a scenario list from the actual requirements and visible controls. Each stateful control should have an expected visible effect; when the product promise implies propagation, verify the downstream surface too.
4. Use screenshots, UI trees, logs, or user-provided evidence that are actually available. Native vision may assess screenshots; do not pretend an omitted image-analysis script was run.
5. Treat blank screens, crashes, unchanged state after an expected mutation, clipping, inaccessible controls, and fake/decorative interactions as failures requiring diagnosis.
6. Distinguish environment/tooling blockers from code failures. Read the source at the failure site before ruling out a code cause.

## Device-capability verification

For sensors, location, camera, biometrics, contacts, calendar, Bluetooth, telephony, media, notifications, networking, or storage:

- verify compile-time API usage separately from runtime permissions/capability availability;
- inspect the matching `35-ohos-app-path` reference and project configuration;
- require real device/runtime evidence before claiming hardware behavior;
- handle denied/unavailable/error states in code;
- when direct device access is unavailable, provide the smallest user-run verification procedure and interpret the returned evidence.

## Final verification report

State what was actually checked, what evidence was observed, what could not be checked, and the next concrete verification action for every unresolved item.
