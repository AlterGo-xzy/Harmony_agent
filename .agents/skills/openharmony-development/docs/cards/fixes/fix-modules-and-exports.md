---
guide_id: fixes/fix-modules-and-exports
family: fixes
tags: fix, export, import, module, namespace, visibility, re-export
related_skills: fix-arkts-errors, explain-arkts-diagnostic, review-arkts
related_diagnostics: linter-fault:DynamicImport, linter-fault:ExportAssignment, linter-fault:ImportAfterStatement, linter-fault:ImportAssertion, linter-fault:ImportAssignment, linter-fault:ImportLazyIdentifier, linter-fault:ImportType, linter-fault:InterOpConvertImport, linter-fault:InterOpImportJs, linter-fault:InterOpImportJsDataCompare, linter-fault:InterOpImportJsForTypeOf, linter-fault:InterOpImportJsIndex, linter-fault:InteropJsObjectExport, linter-fault:LimitedStdLibNoImportConcurrency, linter-fault:NamespaceAsObject, linter-fault:NoImportJsonFile, linter-fault:NoImportNamespaceStarAsVar, linter-fault:NoNameSpaceImportEtsToTs, linter-fault:NoSideEffectImport, linter-fault:NoSideEffectImportEtsToTs, linter-fault:NoTsImportEts, linter-fault:NoTsReExportEts, linter-fault:NonDeclarationInNamespace, linter-fault:SendableFunctionImportedVariables, linter-fault:SendableTypeExported, linter-fault:SharedModuleExports, linter-fault:SharedModuleExportsWarning, linter-fault:SharedModuleNoWildcardExport, linter-fault:SharedNoSideEffectImport, linter-fault:ShorthandAmbientModuleDecl, linter-fault:UIInterfaceImport, linter-fault:UMDModuleDefinition, linter-fault:WildcardsInModuleName, ESE0355, ESE0356
related_migration_patterns: commonjs-exports
source_refs: examples/migration-before-after/js-commonjs-before.js, examples/migration-before-after/arkts-module-after.ets
status: active
---
# Fix Module Boundary and Export/Import Errors

## Intent

Fix module boundary errors by converting assignment-style exports and imports to ArkTS module syntax, which requires ES-module-style named exports and imports exclusively.

## Use When

- code uses `export = value` or `export default = value` assignment syntax
- code uses `import x = require('module')` assignment syntax
- code places import statements after other statements in a module
- code uses namespace merging or ambient module declarations

## Do

- replace `export = value` with `export default value` or named `export { value }`
- replace `import x = require('module')` with `import x from 'module'` or `import { x } from 'module'`
- move all import statements to the top of the file, before any other statements
- replace namespace-based re-exports with explicit named re-exports (`export { A, B } from './mod'`)

## Avoid

- using `export =` or `import =` CommonJS-style module syntax
- placing import statements after executable code or variable declarations
- relying on TypeScript namespace merging for module augmentation
- using `require()` calls anywhere in ArkTS source

## Migration Notes

ArkTS enforces strict ES module semantics. All `export =` and `import = require()` patterns from CommonJS or legacy TypeScript must be converted to standard named or default exports/imports. This card complements `fix-import-export-visibility.md` which covers import ordering and export visibility.


## Related Diagnostics

- `linter-fault:DynamicImport`
- `linter-fault:ExportAssignment`
- `linter-fault:ImportAfterStatement`
- `linter-fault:ImportAssertion`
- `linter-fault:ImportAssignment`
- `linter-fault:ImportLazyIdentifier`
- `linter-fault:ImportType`
- `linter-fault:InterOpConvertImport`
- `linter-fault:InterOpImportJs`
- `linter-fault:InterOpImportJsDataCompare`
- `linter-fault:InterOpImportJsForTypeOf`
- `linter-fault:InterOpImportJsIndex`
- `linter-fault:InteropJsObjectExport`
- `linter-fault:LimitedStdLibNoImportConcurrency`
- `linter-fault:NamespaceAsObject`
- `linter-fault:NoImportJsonFile`
- `linter-fault:NoImportNamespaceStarAsVar`
- `linter-fault:NoNameSpaceImportEtsToTs`
- `linter-fault:NoSideEffectImport`
- `linter-fault:NoSideEffectImportEtsToTs`
- `linter-fault:NoTsImportEts`
- `linter-fault:NoTsReExportEts`
- `linter-fault:NonDeclarationInNamespace`
- `linter-fault:SendableFunctionImportedVariables`
- `linter-fault:SendableTypeExported`
- `linter-fault:SharedModuleExports`
- `linter-fault:SharedModuleExportsWarning`
- `linter-fault:SharedModuleNoWildcardExport`
- `linter-fault:SharedNoSideEffectImport`
- `linter-fault:ShorthandAmbientModuleDecl`
- `linter-fault:UIInterfaceImport`
- `linter-fault:UMDModuleDefinition`
- `linter-fault:WildcardsInModuleName`

## Status

Active. Use this card when fixing module and export/import diagnostic errors during ArkTS migration, alongside the existing import-export-visibility card.
