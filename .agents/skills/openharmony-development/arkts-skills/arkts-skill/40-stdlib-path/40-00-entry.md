# Standard library path entry

Load this path only when the task is stdlib/library-surface work, not ordinary app code.

## Load this path when you see
- `JSON.parse`, `JSON.parseUpdate`, `JSON.parseJsonElement`, `JSON.stringify`, `@JSONRename`, `@JSONParseIgnore` -> `40-15-json-data-surfaces.md`
- `String`, string indexing, `charAt`, padding, locale compare, `Array`, `ArrayList`, `HashMap` -> `40-10-collections-and-data-surfaces.md`
- `Promise`, scheduler behavior, `launch`, `EAWorker`, `taskpool`, `AsyncLock` in stdlib context -> `40-20-async-concurrency-and-workers.md`
- runtime class handles, annotations, boundary helpers -> `40-30-interop-and-boundary-surfaces.md`
- stdlib implementation or extension work -> `40-40-stdlib-internals-and-extension-patterns.md`

## Return
- app resource/rawfile packaging -> `../30-arkui-path/30-16-resources-and-assets.md`
- OHOS app wiring or `resourceManager` context acquisition -> `../35-ohos-app-path/35-00-entry.md`
- ordinary typed app code -> `../SKILL.md`
