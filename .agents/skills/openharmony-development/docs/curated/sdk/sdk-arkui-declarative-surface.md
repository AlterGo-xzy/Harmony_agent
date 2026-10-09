---
summary_id: sdk/arkui-declarative-surface
domain: sdk
tags: sdk, arkui, components, modifiers, declarative-ui, buildernode, state-management
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Map ArkUI Declarative Components Across Three Declaration Layers

## Overview

The ArkUI declarative component surface is split across three SDK zones: `api/arkui` (modifier classes, BuilderNode, AttributeUpdater), `api/arkui/component` (static `.d.ets` component declarations), and `api/@internal/component/ets` (legacy `.d.ts` internal component definitions). These layers overlap -- many components have both an internal `.d.ts` definition and a newer static `.d.ets` declaration. The static declarations are the forward path; the internal definitions are retained for backward compatibility but many are deprecated. BuilderNode and AttributeUpdater provide programmatic control over component trees outside the declarative template syntax.

## Use For

- resolving which declaration layer to import a component from
- choosing between modifier-based and template-based component configuration
- identifying deprecated internal component definitions during migration
- understanding BuilderNode for dynamic node creation outside @Builder functions

## Patterns

- prefer `api/arkui/component/*.static.d.ets` declarations over `api/@internal/component/ets/*.d.ts` when both exist
- use modifier classes (e.g., `AlphabetIndexerModifier`) for programmatic attribute changes without re-rendering the template
- use `BuilderNode` when component subtrees must be constructed dynamically at runtime
- use `AttributeUpdater` to batch attribute mutations on existing component instances
- treat internal component `.d.ts` files as legacy reference; check `deprecated` and `systemapi` flags before using them
- cross-reference `syscap` metadata to confirm the component is available on the target device profile

## Watch For

- internal component definitions marked `systemapi: true` that are not available in third-party apps
- deprecated internal declarations that have no static `.d.ets` replacement yet
- mixing internal and static import paths for the same component, causing duplicate type conflicts
- assuming all modifier classes exist; only components with committed modifier declarations support this pattern

## Evidence

- Modifier and node-control declarations (`AlphabetIndexerModifier`, `AttributeUpdater`, `BuilderNode`) are public ArkUI Full surfaces; they are cross-platform and not marked system-only or deprecated.
- Static component declarations for `actionSheet`, `button`, and `text` use `.static.d.ets` files, are non-system public ArkUI Full declarations, and start at static SDK availability rather than the older dynamic-only model.
- Internal component declarations are mixed compatibility evidence: `ability_component` is deprecated and system-only, while internal `button` and `text` are still non-system but remain legacy `.d.ts` surfaces.
- Prefer static `.d.ets` declarations when present; use internal `.d.ts` only to understand older dynamic declarations or compatibility gaps.

## Status

Active summary for ArkUI declaration files, static component declarations, and internal component declarations.
