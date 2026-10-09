---
summary_id: sdk/kit-surface
domain: sdk
tags: sdk, kits, re-export, module-aggregation, abilitykit, arkdata, arkts
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Use @kit.* Re-Exports As The Preferred Import Surface

## Overview

The `kits/` zone (49 entries) contains `@kit.*` module declarations that aggregate and re-export APIs from multiple `@ohos.*` modules. Kits are the recommended import surface for new ArkTS code -- they provide a stable, versioned facade over the underlying `@ohos.*` namespace. Each kit declaration file lists its re-exported symbols, making it the canonical source for which APIs belong together. Common kits include AbilityKit (ability lifecycle), ArkData (data management), ArkTS (language utilities), ArkGraphics2D (2D rendering), BackgroundTasksKit (deferred work), and MediaKit (audio/video).

## Use For

- choosing `@kit.*` imports over raw `@ohos.*` imports in new code
- understanding which `@ohos.*` modules a kit aggregates
- verifying that a kit re-exports the specific symbol needed before importing
- identifying the correct kit when migrating scattered `@ohos.*` imports

## Patterns

- import from `@kit.AbilityKit` instead of individual `@ohos.app.ability.*` modules
- import from `@kit.ArkTS` for language-level utilities (collections, lang, utils)
- check the kit declaration file to confirm a symbol is re-exported before using the kit path
- when multiple kits could provide a symbol, prefer the narrower domain-specific kit

## Watch For

- not all `@ohos.*` modules are re-exported through a kit; some must still be imported directly
- kit declarations do not carry `since` or `syscap` metadata themselves; check the underlying `@ohos.*` declaration for stability
- importing a kit does not guarantee all its re-exports are available on every device profile
- using a kit import path that does not exist in the target SDK version causes a hard compile error

## Evidence

- Extracted kit declarations are in the `kits` scope with module names such as `@kit.AbilityKit`, `@kit.ArkData`, `@kit.ArkTS`, `@kit.ArkGraphics2D`, `@kit.BackgroundTasksKit`, and `@kit.MediaKit`.
- The sampled kit declarations are not marked system-only or deprecated and do not carry direct permission gates in the extracted SDK index.
- Treat kits as aggregation facades: they provide stable import names, while the underlying re-exported APIs may still carry their own syscap, permission, or deprecation metadata.

## Status

Active summary for kit-level SDK declaration files.
