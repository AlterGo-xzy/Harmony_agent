---
summary_id: ui/component-surface-and-attributes
domain: ui
tags: ui, arkui, components, attributes, samples
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Use Committed ArkUI Metadata Before Guessing Component APIs

## Overview

The ArkUI metadata snapshot is the fastest way to confirm component names, attribute surfaces, and sample shapes without browsing the live framework repo. Use it as a contract check before inventing component props or lifecycle hooks.

## Use For

- checking whether a component or attribute name is real
- estimating how wide a component API surface is before generating UI code
- reviewing whether an ArkUI migration is using sample-supported shapes

## Patterns

- confirm component and attribute names from static SDK declarations before writing UI code
- treat high-attribute-count components as a signal to stay narrow and explicit
- use committed sample metadata as a shape hint, not as a substitute for exact compile checks

## Watch For

- internal or system-only components
- broad UI wrappers that guess unsupported attributes
- entry-point code that mixes ArkUI assumptions with non-UI ArkTS compile expectations

## Evidence

- Component metadata exposes exact attribute counts and child rules: `AlphabetIndexer` has 27 public attributes and no children, while `Button` has 14 style/content attributes and accepts a single child.
- System-only flags matter: `AbilityComponent` and `Animator` are system API components, while `AlphabetIndexer`, `ArcList`, `Badge`, and `Button` are not system-only in the extracted component index.
- Composite metadata matters for layout: `ArcList` is non-atomic, has 19 attributes, and declares `ArcListItem` as a child; `Badge` has no extracted attributes and should not be treated as a broad styling surface.
- Sample metadata distinguishes structure from APIs: `app.ets` is an entry file with no component counts, while `pages/home.ets` has one entry component and uses Column, Row, Text, and Button.

## Status

Active summary for ArkUI component lookup. Use static declarations and wrapper compile feedback for exact confirmation.
