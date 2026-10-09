---
summary_id: ui/ui-system-components-and-samples
domain: ui
tags: ui, arkui, samples, ace, compiler, page-routing, preview, component-composition
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# ArkUI Sample Applications and Composition Patterns

## Overview

The ace_ets2bundle compiler test suite includes 35 sample ArkUI source files that demonstrate idiomatic component composition, page routing, and preview configuration. These samples serve as shape references for how real ArkUI application code should be structured: an app entry point, page-level structs decorated with @Entry and @Component, and test-case pages that exercise individual components in isolation. The samples also cover Grid and List composition patterns, constructor usage, and the @Preview decorator for in-IDE rendering.

## Use For

- understanding the expected file and folder layout of an ArkUI application (app.ets, pages/, testcases/)
- learning how @Entry, @Component, and @Preview decorators are applied in practice
- referencing idiomatic component composition when reviewing or generating ArkUI code
- verifying that migrated code follows the same structural patterns as compiler-validated samples
- checking page routing setup between index and sub-pages

## Patterns

- app.ets serves as the application entry point; pages are registered via a page config
- each page file exports a single @Entry @Component struct with a build method
- test-case pages isolate one component or pattern per file for focused validation
- @Preview is placed on a separate struct or alongside @Entry to enable IDE preview rendering
- Grid and List test cases show ForEach-based dynamic child rendering within containers
- constructor test cases demonstrate positional parameter passing in component builders

## Watch For

- treating sample code as production-grade — these are compiler test fixtures, not best-practice templates
- assuming every decorator combination in samples is valid outside the test harness
- copying test-case file naming conventions (e.g., component_01.ets) into real project structures

## Evidence

- The extracted sample corpus contains 35 ArkUI source files used by the compiler suite to exercise app entry, page, preview, routing, and component-composition shapes.
- The app entry sample is structural evidence rather than component evidence: the old index records no `@Entry`, component, state, or basic layout usage in that file.
- The home-page sample records one entry component and uses Column, Row, Text, and Button, making it the concrete sample for basic page composition.
- Sample evidence is shape-oriented, not product guidance: use it to confirm decorator/layout patterns, then rely on SDK declarations and wrapper compilation for exact API validity.

## Status

Active summary covering ArkUI sample structure from the compiler sample suite.
