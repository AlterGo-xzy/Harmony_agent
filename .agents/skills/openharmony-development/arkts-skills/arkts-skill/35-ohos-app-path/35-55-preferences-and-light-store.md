# Preferences and lightweight key-value storage

Use this when the blocker is storing small app settings, user preferences, or simple key-value pairs that must persist across app restarts.

## Load this doc when you see
- `preferences`, `getPreferences`, `putSync`, `getSync`, `flushSync`
- `@ohos.data.preferences`
- "store a setting" or "save user preference" without a full database

## Open or create one preferences store
```ts
import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'

function openStore(context: common.UIAbilityContext): preferences.Preferences {
    return preferences.getPreferencesSync(context, {
        name: 'appSettings',
        storageType: preferences.StorageType.GSKV   // auto-flushed
    } as preferences.Options)
}
```

## Write one value
```ts
let prefs = openStore(context)
prefs.putSync('username', 'Alice')
prefs.putSync('score', 42 as long)
prefs.putSync('notifications', true)

// for XML-type storage only, flush to persist:
prefs.flushSync()
```

## Read one value with a default fallback
```ts
let prefs = openStore(context)
let username: string = prefs.getSync('username', 'Guest') as string
let score: int = (prefs.getSync('score', 0 as long) as long).toInt()
let notifications: boolean = prefs.getSync('notifications', true) as boolean
```

## Delete one key
```ts
prefs.deleteSync('obsolete_key')
```

## Check if a key exists
```ts
if (prefs.hasSync('username')) {
    // key is set, read it
}
```

## React to changes in another process
```text
one setting changes in a widget or service, the page should refresh
```
```ts
prefs.onChange((key: string): void => {
    if (key == 'theme') {
        let theme: string = prefs.getSync('theme', 'light') as string
        this.currentTheme = theme
    }
})
```

## Store a boolean, number, or string only
Preferences supports: `string`, `number` (`long`/`double`), `boolean`, and `Uint8Array`. For structured objects, serialize to JSON:
```ts
let data = JSON.stringify({ name: 'Alice', level: 5 })
prefs.putSync('userProfile', data)
// read back:
let raw: string = prefs.getSync('userProfile', '{}') as string
let profile = JSON.parse(raw) as Record<string, Object>
```

## Read fails with wrong type — check the default value
```text
getSync returns type mismatch or undefined
```
Next move:
- verify the default value type matches the stored type
- `number` values are always returned as `long`; cast with `.toInt()` for `int`
- `getSync` returns `ValueType`, always cast to the expected type with `as`

## Store is null or read after app restart breaks
```text
preferences throws or returns stale data
```
Next move:
- verify the context is still valid (not a stale reference)
- for XML storage, call `flushSync()` after every write batch
- prefer `StorageType.GSKV` for auto-flush behavior

## Verify
- write one string value, close the store, reopen, read it back
- write one integer, verify read returns the same value after a flush
- delete a key, verify `hasSync` returns false
- if using XML storage, confirm flushSync() is called before the app suspends

## Return
- full relational database needs → `35-50-rdb-and-storage.md`
- file read/write in app sandbox → `35-10-app-model-and-system-apis.md`
- app context retrieval → `35-10-app-model-and-system-apis.md` (GlobalContext pattern)
- if the first direct fix fails → `35-40-ohos-app-failures.md`
