---
guide_id: fixes/fix-import-export-visibility
family: fixes
tags: fix, imports, exports, visibility, modules
related_skills: implement-arkts, migrate-to-arkts, fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:ImportAfterStatement, ESE0355, ESE0356
related_migration_patterns: commonjs-exports, export-signature-consistency
source_refs: examples/migration-before-after/js-commonjs-before.js, examples/migration-before-after/arkts-module-after.ets
status: active
---
# Fix Import, Export, And Visibility Errors By Simplifying Module Boundaries

## Intent

Repair module-surface failures by making imports, exports, and visible types explicit and conventional.

## Use When

- imports appear after other statements
- an exported API leaks an internal type
- CommonJS-like patterns appear after migration
- exported type aliases, generic bounds, or heritage clauses reference local non-exported declarations
- exported namespace members or public members of exported classes/interfaces mention internal local types

## Do

- move imports to the top
- trim the exported surface to intentional symbols
- ensure public signatures reference public types only
- add `export` to local declarations used by exported functions, methods, classes, interfaces, and type aliases
- keep imported symbols as-is; if a type is imported into the file, treat it as already public

## Avoid

- keeping assignment-style exports
- papering over visibility with re-export tricks
- leaving duplicate or ambiguous names in module scope
- leaking local namespace-only or file-local declarations through exported generic constraints or `extends` / `implements` clauses

## Migration Notes

This is usually easier to fix by simplifying the module API than by preserving the original TypeScript module mechanics. When an exported signature references a non-exported local type, prefer exporting that declaration directly. If the type must stay internal, redesign the public API so the internal type no longer appears in the exported signature.

## Related Diagnostics

- `linter-fault:ImportAfterStatement`

## Status

Active. First repair card for module-boundary issues.
