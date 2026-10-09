---
name: testing-arkts
description: Write, update, and validate tests using the ArkTS framework and runner already configured by the project.
---

# Testing ArkTS

## Read first

- `arkts-skills/arkts-skill/WORKFLOW.md`
- `docs/cookbook/testing-arkts.md`
- the target project's manifests, build profiles, existing tests, runner configuration, and nearby test conventions
- `references/windows-deveco-development.md` for Windows/DevEco/Hvigor projects

## Workflow

1. Determine the requested test level and observable behavior before editing.
2. Detect the framework from project dependencies and existing tests. Do not replace it with a preferred framework.
3. Choose the smallest adequate scope:
   - pure computation or state transition: unit test;
   - module, storage, service, or API boundary: integration test;
   - reproduced defect: regression test that fails for the original behavior;
   - UI, lifecycle, permission, or device behavior: the project's supported OHOS test surface.
4. Map each behavior to an observable assertion. Cover relevant success, boundary, invalid-input, asynchronous failure, cancellation, and cleanup cases without manufacturing irrelevant combinations.
5. Follow ArkTS typing rules and the project's test registration pattern. Await asynchronous work and ensure a test cannot pass before its assertions execute.
6. Keep production edits bounded to stable test seams and preserve behavior.
7. Build the touched source and tests with the project-native toolchain. Run the narrowest supported test target, then the containing suite when proportionate and available.
8. Separate compiler, runner, device/environment, and assertion failures. Fix one bounded cause and rerun the same command.
9. Restore files, storage, permissions, mocks, services, and global state changed by a test.

## Evidence

Do not claim a test pass from compilation alone. Report separately whether tests compiled, whether the runner executed, and whether a device or emulator was involved.

Summarize changed tests, behaviors covered, exact commands and results, and any remaining device, runner, or environment gap.
