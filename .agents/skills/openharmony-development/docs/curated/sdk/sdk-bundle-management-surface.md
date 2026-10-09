---
summary_id: sdk/bundle-management-surface
domain: sdk
tags: sdk, bundlemanager, bundle-info, ability-info, element-name, package-metadata
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Use Bundle Manager Types For Package And Ability Metadata

## Overview

The `api/bundleManager` zone (21 entries) defines the type surface for querying and inspecting installed bundles, abilities, and application metadata at runtime. These types are consumed by the `@ohos.bundle.bundleManager` API and appear in ability launch, permission checking, and dynamic feature discovery workflows. Key types include AbilityInfo (ability metadata), ApplicationInfo (app-level metadata), BundleInfo (full bundle manifest), BundlePackInfo (pack metadata), and ElementName (the canonical ability identifier tuple of bundleName + moduleName + abilityName).

## Use For

- typing return values from `bundleManager.getBundleInfoForSelf` and related queries
- constructing `ElementName` values for explicit ability launches via Want
- reading ability and application metadata for conditional feature enablement
- inspecting bundle pack structure during multi-HAP deployments

## Patterns

- use `ElementName` as the canonical identifier when launching abilities by name
- prefer `getBundleInfoForSelf` over `getBundleInfo` to avoid requiring `ohos.permission.GET_BUNDLE_INFO`
- treat `AbilityInfo` and `ApplicationInfo` as read-only snapshots; do not cache across lifecycle events
- use `BundlePackInfo` to check module and HAP relationships in multi-module projects
- always check the `deprecated` flag on bundle manager types; the older `api/bundle` surface is superseded

## Watch For

- confusion between `api/bundle` (legacy, deprecated) and `api/bundleManager` (current) type surfaces
- `AbilityInfo.type` values that differ between FA model and Stage model abilities
- `BundleInfo` queries that require permissions not declared in the manifest
- `ElementName` fields that are case-sensitive and must match `module.json5` declarations exactly

## Evidence

- `AbilityInfo` is a public cross-platform BundleFramework Core type for ability metadata.
- `ApplicationInfo` is cross-platform but both deprecated and system-only in the extracted metadata; avoid it as a fresh product dependency.
- `BundleInfo` and `BundlePackInfo` expose broader bundle/package state and are system-only; `BundlePackInfo` is tied to the FreeInstall syscap.
- `ElementName` is the public BundleFramework Core identifier type and is the safest evidence for explicit ability targeting.

## Status

Active summary for bundle manager declaration files.
