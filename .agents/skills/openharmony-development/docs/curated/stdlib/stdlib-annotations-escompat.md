---
summary_id: stdlib/stdlib-annotations-escompat
domain: stdlib
tags: stdlib, annotations, escompat, decorators, retention, target, error, functions, global, compatibility
related_skills: implement-arkts, migrate-to-arkts, review-arkts
status: active
---
# Annotations and ES Compatibility Shims

## Overview

The `std.annotations` package defines the meta-annotation types that control how decorators behave at compile time and runtime: `ANI` for native interface binding, `Retention` for annotation lifecycle policy, and `Target` for restricting which declarations an annotation may decorate. The `escompat` package provides backward-compatible shims that expose familiar ES standard library functions — Error subtypes, global utility functions, and function-level helpers — so migrated TypeScript code can retain known APIs without violating ArkTS type rules. Together these 12 entries bridge decorator infrastructure and API compatibility.

## Use For

- defining custom annotations with correct retention and target policies
- understanding the ANI annotation for native (C/C++) interface bindings
- migrating code that relies on standard ES global functions (parseInt, isNaN, encodeURI, etc.)
- mapping JS Error subtypes (TypeError, RangeError) to their ArkTS escompat equivalents

## Patterns

- annotate custom annotations with `@Retention` to control whether metadata survives to runtime or is compile-only
- use `@Target` to restrict annotations to classes, methods, fields, or parameters — the compiler enforces these constraints
- use `@ANI` only on declarations that bind to native (non-JS) code through the ArkTS native interface
- import Error, TypeError, RangeError from escompat when migrating catch blocks that inspect error subtypes
- use escompat global functions as drop-in replacements for TS globals; they follow the same signatures but are nominal ArkTS types

## Watch For

- omitting `@Retention` on a custom annotation — the default policy may not match the intended lifecycle
- applying `@Target` too broadly, allowing an annotation on declarations where it has no semantic meaning
- assuming escompat Error types structurally match ArkTS core Error — they are separate nominal hierarchies
- importing escompat shims when a std.core equivalent already exists (duplication risk)
- confusing ANI (native interface) annotations with JS interop annotations — they serve different bridging layers

## Evidence

- `std.annotations` entries for ANI, retention, target, and related annotation helpers are non-deprecated `SystemCapability.Utils.Lang` surfaces introduced at API 24.
- Annotation metadata is narrow: ANI exposes a small public surface, retention has a single public export, and target has two public exports in the extracted index.
- Error and global compatibility support are non-deprecated API 24 escompat surfaces; the global surface is broad and native-backed.
- The escompat functions surface is explicitly deprecated despite being available under `SystemCapability.Utils.Lang`, so migrations should not expand new dependencies on it.

## Status

Active summary covering std.annotations and escompat helpers.
