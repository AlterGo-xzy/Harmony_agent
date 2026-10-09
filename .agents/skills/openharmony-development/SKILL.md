---
name: openharmony-development
description: Implement, debug, test, review, migrate, or optimize OpenHarmony and HarmonyOS application code using ArkTS, ArkUI, DevEco Studio, Hvigor, and OHOS APIs. Use for development requests involving 鸿蒙应用、ArkTS、ArkUI、DevEco、编译报错 or device capabilities. Do not use for HarmonyOS consumer support, product news, or ecosystem discussion without a software-development task.
---

# OpenHarmony / ArkTS / ArkUI Development

Use this skill as the routing layer for application-development work based on the bundled ArkTS Agent Kit material. Load only the smallest relevant support files for the current task.

## Core operating rules

1. **Ground code in the bundled ArkTS guidance.** Before writing or changing ArkTS, read `arkts-skills/arkts-skill/WORKFLOW.md`, then open the most specific route document it names for the surface being touched.
2. **Use project evidence over memory.** Existing project code, `build-profile.json5`, `module.json5`, SDK/compiler diagnostics, API declarations, and actual tool output take precedence when they conflict with a generic example or version-specific reference.
3. **Do not guess SDK ownership or API availability.** For OHOS/SDK/API questions, read the matching `35-ohos-app-path` document and, when needed, the curated SDK references under `docs/curated/sdk/`.
4. **Keep context narrow.** Do not load the whole package. Route by task, read the relevant entry document, then only its specialist references.
5. **Production implementation only.** Do not silently replace requested functionality with hard-coded mock behavior, placeholder logic, fake live data, or decorative controls that do nothing. Explicitly label unavoidable stubs.
6. **Never claim verification that did not happen.** Build, lint, launch, device, previewer, screenshot, or interaction success requires actual evidence from an available tool or user-provided output.
7. **Tool availability is a hard boundary.** Some upstream workflows assume repository-specific wrappers, scripts, or subagents. Follow `ADAPTATION.md`; invoke such tools only when they are actually available in the current environment.
8. **Prefer the project's native build surface.** On Windows/DevEco projects, detect the checked-in or DevEco-bundled Hvigor launcher and read `references/windows-deveco-development.md`. Optional ArkTS Agent Kit wrappers may be used when present, but they are never required.

## Task routing

| User intent | Read first | Then read as needed |
|---|---|---|
| Write/modify ArkTS | `arkts-skills/implement-arkts/WORKFLOW.md` | `arkts-skills/arkts-skill/WORKFLOW.md` + specialist route docs |
| Explain ArkTS/compiler diagnostic | `arkts-skills/explain-arkts-diagnostic/WORKFLOW.md` | `docs/diagnostics/` + `docs/cards/fixes/` |
| Fix compiler/linter errors | `arkts-skills/fix-arkts-errors/WORKFLOW.md` | matching diagnostic/fix card + core route docs |
| Design an ArkUI app/screen | `arkts-skills/design-arkts-ui-app/WORKFLOW.md` | `arkts-skills/arkts-skill/30-arkui-path/30-00-entry.md`, selected design-system files |
| ArkUI state/layout/components/navigation/dialogs | `arkts-skills/arkts-skill/30-arkui-path/30-00-entry.md` | the matching `30-*` specialist document |
| Ability/app model/window/background work | `arkts-skills/arkts-skill/35-ohos-app-path/35-00-entry.md` | `35-10`, `35-12`, `35-20`, `35-22`, or `35-25` |
| Storage/RDB/Preferences | same OHOS entry | `35-50-rdb-and-storage.md`, `35-55-preferences-and-light-store.md` |
| Notifications/network/HTTP | same OHOS entry | `35-56-notifications.md`, `35-57-network-and-http.md` |
| Image/media/audio | same OHOS entry | `35-58-image-and-media.md`, `35-59-audio-playback.md` |
| Sensors/location/file picker/camera | same OHOS entry | `35-61` through `35-64` |
| Biometrics/calendar/contacts/Bluetooth/telephony | same OHOS entry | `35-65` through `35-69` |
| Standard library/concurrency/TaskPool | `arkts-skills/arkts-skill/40-stdlib-path/40-00-entry.md` | matching `40-*` and `20-references/26-*`/`28-*` |
| JS/TS/native interop | `arkts-skills/arkts-skill/50-interop-path/50-00-entry.md` | matching `50-*` and `20-references/23-*` |
| Review code | `arkts-skills/review-arkts/WORKFLOW.md` | core route docs + quality references |
| Write/repair tests | `arkts-skills/testing-arkts/WORKFLOW.md` | `docs/cookbook/testing-arkts.md` |
| Migrate JS/TS to ArkTS | `arkts-skills/migrate-to-arkts/WORKFLOW.md` | `docs/migration/` + migration cards |
| Modernize ArkTS | `arkts-skills/modernize-arkts/WORKFLOW.md` | style/core/fix references |
| Optimize performance/resources | `arkts-skills/optimize-arkts/WORKFLOW.md` | `docs/style/performance.md`, `20-references/25-performance-habits.md` |
| UI/device verification | `VERIFICATION.md` | `arkts-skills/references/ui-ux-quality-bar.md`, `arkts-skills/verify-arkts-ui/references/scenario-matrix.md` |
| Windows DevEco/Hvigor development | `references/windows-deveco-development.md` | project `build-profile.json5`, `hvigorfile.ts`, module profiles, and actual build output |

## ArkUI route map

Start at `arkts-skills/arkts-skill/30-arkui-path/30-00-entry.md` and select the narrowest specialist file:

- structure/state: `30-10-ui-structure-and-state.md`
- layout/styling: `30-15-styling-and-layout.md`
- resources/assets: `30-16-resources-and-assets.md`
- accessibility: `30-17-accessibility.md`
- routing/lifecycle/app flow: `30-20-routing-lifecycle-and-app-flow.md`
- components/patterns: `30-30-arkui-components-and-patterns.md`
- tabs/overlays/gestures: `30-32-tabs-overlays-and-gestures.md`
- input/display/web: `30-34-input-display-and-web.md`
- form controls: `30-35-form-controls.md`
- scrolling: `30-36-scroll-containers.md`
- ArkUI failures: `30-40-arkui-failures.md`
- navigation stack: `30-70-navigation-stack.md`
- dialogs: `30-80-dialogs.md`
- attribute modifiers: `30-90-attribute-modifiers.md`

## OHOS/API route map

Start at `arkts-skills/arkts-skill/35-ohos-app-path/35-00-entry.md`. The bundled route covers app model/system APIs, windows, abilities/workers/background work, forms, project/build surfaces, failures, RDB/storage, preferences, notifications, HTTP, image/media, audio, specialized APIs, sensors, location, file picker, camera, biometric auth, calendar, contacts, Bluetooth, and telephony.

For an API answer:
1. identify the feature surface and required Kit/module from the project or bundled references;
2. read the specific `35-*` route document;
3. check curated SDK boundary/gating references when API level or stability matters;
4. provide imports, permissions/configuration, lifecycle placement, error handling, and cleanup only when supported by the source/project evidence;
5. call out version uncertainty instead of inventing availability.

## Implementation loop

1. Inspect the relevant project files and task acceptance criteria.
2. Read `arkts-skills/arkts-skill/WORKFLOW.md` and specialist route docs before the first edit.
3. Make the smallest coherent implementation slice.
4. Check explicit typing, nullability/narrowing, class/interface shape, imports, state ownership, lifecycle, resource/API usage, and failure handling against the loaded guidance.
5. Compile/lint with an actually available tool when possible; otherwise provide the exact check the user should run and wait for output before claiming success.
6. On diagnostics, route through `fix-arkts-errors` and the matching diagnostic card. Fix the first concrete blocker, then re-check.
7. For UI work, compare implementation against the blueprint and `ui-ux-quality-bar.md`; verify interactions and visible state transitions with actual evidence when available.
8. Report unresolved API/version/tooling risks explicitly.

## Device capability work

For sensors, location, camera, biometrics, contacts, calendar, Bluetooth, telephony, media, notifications, storage, or networking:
- read the matching OHOS route doc before proposing code;
- inspect project permissions/configuration and lifecycle context when available;
- separate compile-time API use from runtime permission/device capability requirements;
- handle unavailable/denied/error states rather than assuming success;
- do not claim hardware behavior without device/runtime evidence.

## Package map

- `arkts-skills/arkts-skill/` — core ArkTS routing tree and specialist references
- `arkts-skills/*/WORKFLOW.md` — implementation, diagnostics, UI design, review, testing, migration, modernization, and optimization workflows
- `arkts-skills/references/` — diagnostic classification and UI quality references
- `docs/cards/` — compact core/fix/migration cards
- `docs/curated/` — curated SDK, UI, stdlib, runtime, concurrency, and interop surfaces
- `docs/diagnostics/` — compiler/linter diagnostics and fix recipes
- `docs/language/`, `docs/style/`, `docs/migration/`, `docs/cookbook/` — background and workflow references
- `arkts-design-systems/` — optional ArkUI design-system packs; load only one relevant pack for a UI design task
- `ADAPTATION.md` — environment and authorization rules for ChatGPT, Codex, and other supported surfaces
- `references/windows-deveco-development.md` — verified Windows/DevEco workflow for this development environment

## Final answer expectations

When code is produced or changed, state which route documents were used. Distinguish clearly between source-supported facts, project/compiler evidence, and unverified assumptions. For build/device/UI verification, include only evidence actually observed; otherwise give the next concrete verification command or user action without claiming a pass.
