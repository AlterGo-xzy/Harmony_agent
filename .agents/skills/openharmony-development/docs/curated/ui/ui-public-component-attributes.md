---
summary_id: ui/ui-public-component-attributes
domain: ui
tags: ui, arkui, components, layout, content, list, input, navigation, declarative
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Public ArkUI Component Catalog

## Overview

ArkUI provides a declarative component set that all HarmonyOS applications can use to build user interfaces. The catalog spans layout containers (Column, Row, Flex, Stack, Grid), content primitives (Text, Image, Button, Badge, Blank), scrollable lists (List, Grid, AlphabetIndexer), and input controls (TextInput, TextArea, Toggle). Each component is instantiated through a builder function, configured via chained attribute methods, and composed inside a parent's build closure. The full public catalog contains 165 component entries covering standard, arc-layout, and composite variants.

## Use For

- selecting the correct layout container for a given screen structure (Column vs. Row vs. Flex vs. Stack)
- identifying which content component to use for text, images, badges, or spacers
- building scrollable or indexed lists with List, Grid, and AlphabetIndexer
- setting up input surfaces with TextInput, TextArea, and navigation components
- reviewing whether a migration target uses only public (non-system) components

## Patterns

- use Column for vertical stacking, Row for horizontal, Flex for wrap-aware flow, Stack for z-order layering
- pass required data through the component constructor; apply optional styling through chained attribute calls
- nest child components inside the parent's build lambda — do not construct components outside build
- use ForEach or LazyForEach inside List or Grid to render dynamic data sets efficiently
- prefer Blank as a flexible spacer rather than fixed-size empty containers
- use AlphabetIndexer alongside List for quick-jump alphabetical navigation

## Watch For

- mixing up Grid (layout) with List (scrollable) — Grid does not scroll by default
- applying attributes that belong to one component on another (e.g., fontSize on a non-text component)
- using system-only components (prefixed with system or internal) in a public app context
- forgetting that component constructors are positional — named parameters follow ArkTS rules

## Evidence

- `AlphabetIndexer` is an atomic public component with 27 navigation, popup, font, selection, and haptic-feedback attributes.
- Layout primitives are narrow and compositional: `Column` has alignment/justification/reverse attributes, `Flex` has no extracted attributes, and `Blank` is an atomic spacer allowed under Row, Column, and Flex.
- Content components vary in width: `Button` is single-child with 14 style/content attributes, while `Image` is atomic with 23 source, rendering, completion, privacy, and analyzer attributes.
- Scrollable containers are broad: `List` exposes 53 attributes and accepts ListItem, Section, and ListItemGroup children; `Grid` is similarly wide and accepts GridItem children.
- Input components are high-risk surfaces: `TextInput` has 70 extracted attributes and `TextArea` has 56, so generation should stay explicit and compile-checked.

## Status

Active summary covering the public ArkUI component catalog.
