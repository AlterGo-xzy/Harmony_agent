---
summary_id: sdk/api-core-surface
domain: sdk
tags: sdk, ohos-api, application, ability, extension, window, uitest
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Navigate The Broad @ohos.* And Application Framework API Surface

## Overview

The `api/` root zone (663 entries) holds the `@ohos.*` namespace -- the primary system API surface for HarmonyOS. It spans connectivity, input method extensions, window management, UI testing, multimedia, and dozens of other subsystems. The `api/application` subzone (79 entries) contains the ability lifecycle framework: contexts, delegators, monitors, and running-info types that underpin every HarmonyOS application. Together these two zones constitute the largest SDK surface and the most common import source for non-UI ArkTS code.

## Use For

- locating the correct `@ohos.*` module for a system capability before writing imports
- understanding ability lifecycle types (AbilityStageContext, AbilityDelegator, AbilityRunningInfo)
- confirming extension ability patterns (InputMethodExtensionAbility, partner agent extensions)
- verifying window and PiP API availability via `syscap` and `since` metadata

## Patterns

- always import from the public `@ohos.*` module path, not from internal declaration paths
- check `systemapi` before using any `@ohos.*` API; system-only APIs fail silently or at install time on third-party apps
- use `AbilityStageContext` as the primary context type in ability stage lifecycle hooks
- use `AbilityDelegator` for test harness automation, not for production ability management
- treat `AbilityRunningInfo` as a read-only diagnostic type; do not cache or mutate its fields
- verify `syscap` compatibility when using subsystem-specific APIs like PiPWindow or FusionConnectivity

## Watch For

- `@ohos.*` modules that require permissions not declared in the app manifest
- extension abilities that demand a matching `extensionAbilityType` in `module.json5`
- deprecated `@ohos.*` modules that have been superseded by kit re-exports
- AbilityDelegator methods that only work in test runner contexts, not in production code
- PiPWindow and similar APIs gated behind specific device form factors via `syscap`

## Evidence

- `@ohos.FusionConnectivity.partnerAgent` is gated by `SystemCapability.Communication.FusionConnectivity.Core`, requires `ohos.permission.ACCESS_BLUETOOTH`, and is system-only.
- `@ohos.InputMethodExtensionAbility` is a public input-method extension surface under `SystemCapability.MiscServices.InputMethodFramework`.
- `@ohos.PiPWindow` is a system-only window/session-manager API; `@ohos.UiTest` is cross-platform but deprecated and belongs to test automation, not application runtime.
- `AbilityDelegator`, `AbilityStageContext`, and `AbilityRunningInfo` all sit under `SystemCapability.Ability.AbilityRuntime.Core`; the first is test-harness oriented, while the latter two support ability lifecycle and runtime inspection.

## Status

Active summary for the broad @ohos.* API root and application lifecycle declarations.
