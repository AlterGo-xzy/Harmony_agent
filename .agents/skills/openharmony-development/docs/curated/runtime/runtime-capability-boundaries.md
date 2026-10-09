---
summary_id: runtime/runtime-capability-boundaries
domain: runtime
tags: runtime, capabilities, binary-format, naming, packaging
related_skills: implement-arkts, review-arkts
status: active
---
# Use Runtime Docs As Boundary Guidance, Not As Product API Surface

## Overview

The runtime corpus explains execution and packaging boundaries around ArkTS rather than day-to-day application APIs. It is useful when code generation or review needs to understand naming, binary, or runtime-model constraints, not when searching for a callable SDK symbol.

## Use For

- reviewing runtime-facing assumptions in generated code or tooling
- checking whether a design is mixing product APIs with low-level runtime concerns
- understanding fully-qualified naming and binary-format constraints at a high level

## Patterns

- keep product code on SDK and documented language surfaces unless runtime constraints are the actual task
- use runtime docs to explain boundary conditions, not to invent new APIs
- escalate runtime-sensitive questions to wrapper or build validation quickly

## Watch For

- designs that depend on low-level runtime behavior without wrapper confirmation
- code reviews that confuse runtime packaging details with ordinary ArkTS coding guidance
- broad “optimization” ideas that rest on runtime internals rather than committed language or SDK evidence

## Evidence

- The runtime corpus describes the runtime system structure, binary file structure, type system, and public runtime-facing interfaces; it is boundary evidence, not an application API catalog.
- Fully qualified names identify runtime and binary-file entities uniquely; build systems generate them from unqualified names, while the runtime expects specific names for predefined types.
- The binary file format optimizes for compactness, fast information access, low memory footprint, extensibility, and compatibility, including 4-byte direct references, compact 16-bit indices, tagged values, and version compatibility rules.
- Binary entities distinguish foreign definitions referenced from other files from local definitions in the current file; offsets and foreign regions are part of the runtime lookup model.
- Runtime binary data is generally 4-byte aligned unless an entity description says otherwise, so low-level layout assumptions should be validated through wrappers or runtime docs.
- Runtime names cover primitive, array, reference, and union forms; reference names use fully qualified names, and union runtime names must be canonicalized by sorted constituent runtime names.

## Status

Active summary for runtime-boundary context. Follow with exact wrappers or raw evidence when a task genuinely depends on runtime internals.
