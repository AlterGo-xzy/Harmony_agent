---
summary_id: sdk/api-gating-and-stability
domain: sdk
tags: sdk, api-surface, deprecation, syscap, overloads, compatibility
related_skills: implement-arkts, migrate-to-arkts, explain-arkts-diagnostic, review-arkts
status: active
---
# Read SDK Metadata As A Capability And Stability Gate

## Overview

The committed SDK evidence is most useful as a capability and compatibility filter before code generation. Treat `since`, `deprecated`, `systemapi`, and `syscap` metadata as part of the API contract, not as optional commentary.

## Use For

- choosing between multiple SDK entrypoints before writing ArkTS code
- checking whether an API is public, internal, or obviously deprecated
- reviewing migrations that hit SDK overload renaming, disabled APIs, or numeric conversion diagnostics

## Patterns

- prefer stable public API surfaces over internal or deprecated declaration trees
- verify `syscap` and `since` before depending on a feature in portable product code
- treat overload-renaming and `num2int` diagnostics as SDK surface-shape constraints, not as local syntax noise

## Watch For

- declarations that are already marked deprecated in SDK metadata
- internal component declarations that look available in type space but are not suitable as product-facing contracts
- SDK diagnostics around disabled, deprecated, internal, system-only, and overload-shaped APIs

## Evidence

- Internal component declarations carry strong gating signals: `ability_component` is both `systemapi` and deprecated, while `action_sheet` is deprecated even though it is cross-platform.
- Internal global declarations can mix ArkUI and language syscaps and may still be `systemapi`; do not treat internal `.d.ts` visibility as product availability.
- Public-looking `@ohos.*` modules still need metadata checks: `partnerAgent` requires Bluetooth permission and is `systemapi`, `PiPWindow` is window-manager `systemapi`, and `UiTest` is a deprecated test surface.
- `since` metadata is not a single version: extracted declarations include dynamic, dynamiconly, static, and combined dynamic&static availability markers.

## Status

Active summary for skill-time SDK triage. Read the exact SDK declaration after this summary narrows the decision.
