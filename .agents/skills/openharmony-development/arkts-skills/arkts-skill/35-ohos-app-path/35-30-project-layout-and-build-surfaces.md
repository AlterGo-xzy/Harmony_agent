# OpenHarmony project layout and build surfaces

Use this when the blocker is where the app keeps its config, pages, resources, or module wiring.

## Default Stage app shape
```text
AppScope/
  app.json5
build-profile.json5
hvigorfile.ts
oh-package.json5
entry/
  src/main/module.json5
  src/main/ets/
  src/main/resources/
```

## Copy these config shapes first

### `AppScope/app.json5`
```json
{
  "app": {
    "bundleName": "com.example.demo",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name"
  }
}
```

### `entry/src/main/module.json5`
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "mainElement": "EntryAbility",
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "exported": true
      }
    ]
  }
}
```

### `entry/src/main/resources/base/profile/main_pages.json`
```json
{
  "src": [
    "pages/Index",
    "pages/details/DetailsPage"
  ]
}
```

### `build-profile.json5`
```json
{
  "app": {
    "products": [
      {
        "name": "default",
        "arkTSVersion": "1.2",
        "compatibleSdkVersion": "6.0.0(20)",
        "targetSdkVersion": "6.0.0(20)",
        "runtimeOS": "HarmonyOS"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry"
    }
  ]
}
```

### `hvigorfile.ts`
```ts
import { appTasks } from '@ohos/hvigor-ohos-plugin'

export default {
    system: appTasks,
    plugins: []
}
```

### `oh-package.json5`
```json
{
  "modelVersion": "5.0.2",
  "dependencies": {},
  "devDependencies": {}
}
```

## Added a page file, but router or startup cannot reach it
```text
new page exists under `pages/`, but runtime still says the page cannot be opened
```
Next move:
- add the route to `main_pages.json`
- keep the same path in the page file location and in `pushUrl(...)` or `loadContent(...)`

## Add a local feature module
```text
entry imports helpers from a local package-like module
```
Next move:
- add the module to app `build-profile.json5`
- add a file dependency in `entry/oh-package.json5`
- export a typed surface from the feature module `index.ets`

`build-profile.json5`:
```json
{
  "modules": [
    { "name": "entry", "srcPath": "./entry" },
    { "name": "feature_starter", "srcPath": "./feature_starter" }
  ]
}
```

`entry/oh-package.json5`:
```json
{
  "dependencies": {
    "feature_starter": "file:../feature_starter"
  }
}
```

`feature_starter/index.ets`:
```ts
export final class FeatureSummary {
    label: string
    constructor(label: string) { this.label = label }
}

export function createFeatureSummary(): FeatureSummary {
    return new FeatureSummary('ready')
}
```

## Startup should load one ability page
```text
app should start in one page, but home routing is unclear
```
Next move:
- keep `entry/src/main/module.json5` pointing `mainElement` at the entry ability
- keep the entry ability loading one page from `main_pages.json`
- do not point `mainElement` directly at an ArkUI page file

## New app-level identity change
```text
bundle name, label, or icon changed
```
Next move:
- edit `AppScope/app.json5` for app identity
- keep module-specific page wiring in `entry/src/main/module.json5`

## Build target or sdk mismatch
```text
project builds against the wrong API level or wrong product target
```
Next move:
- fix `build-profile.json5` first
- keep `arkTSVersion`, `compatibleSdkVersion`, and `targetSdkVersion` aligned with the intended product

## Resolver or packaging confusion after adding files
```text
page or resource exists, but build or runtime still behaves like the file is absent
```
Next move:
- prove three facts only:
  1. file is under `entry/`
  2. route is in `main_pages.json`
  3. `module.json5` still points at `$profile:main_pages`

## Generated build outputs should stay out of source control
```text
HAP build added noisy generated files
```
Track:
```text
oh-package.json5
build-profile.json5
hvigorfile.ts
module.json5
src/main/ets/
src/main/resources/
```

Ignore unless local repo policy says otherwise:
```gitignore
oh_modules/
build/
.hvigor/
*.hap
*.hsp
*.har
oh-package-lock.json5
```

## Verify
- for a new page, prove all three together: page file path, `main_pages.json` entry, and router or startup string
- for startup issues, also prove `mainElement` and entry ability path in `module.json5`

## Return
- ability startup or system API call issues -> `35-10-app-model-and-system-apis.md`
- if the first direct config fix fails -> `35-40-ohos-app-failures.md`
