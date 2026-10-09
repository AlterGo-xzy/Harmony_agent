# Static JSON data surfaces

Use this when code parses, stringifies, or walks JSON in static ArkTS.

Do not import `.json` files. If JSON comes from an OHOS app asset, first route through `../30-arkui-path/30-16-resources-and-assets.md` for rawfile placement/read, then return here for parsing.

## JSON text -> typed data with defaults
```text
JSON should populate app data/config and defaults matter
```
Next move:
- define typed classes with field defaults
- create the instance yourself
- call `JSON.parseUpdate<T>(json, instance)`
- keep absent-key defaults on the instance

```ts
final class AppConfig {
    host: string = 'localhost'
    port: int = 8080
    debug: boolean = false
}

function parseConfig(json: string): AppConfig {
    let config = new AppConfig()
    return JSON.parseUpdate<AppConfig>(json, config)
}
```

Proof anchors:
- `Json.static.d.ets:459` declares `parseUpdate<T>(json: string, instance: T): T` as `staticonly`
- `JsonParseUpdateTest.ets:83` populates all fields and returns the same instance
- `JsonParseUpdateTest.ets:101` preserves existing fields when keys are absent
- `JsonParseUpdateTest.ets:185` populates nested objects

## JSON text -> fresh typed object
```text
JSON should construct a new typed object and a class/type token is available
```
Next move:
- use `JSON.parse<T>(json, Class.from<T>())` or `Type.from<T>()`
- cast the nullable result after the parse site if needed
- prefer `parseUpdate<T>()` when defaults or merge semantics matter

```ts
final class Address {
    city: string = ''
}

function parseAddress(json: string): Address {
    return JSON.parse<Address>(json, Class.from<Address>()) as Address
}
```

Proof anchors:
- `JsonParseTest.ets:404` parses `Address` with `Class.from<Address>()`
- `JsonParseEnumTest.ets:45` parses typed objects containing enum values

## Dynamic JSON -> local tree walk
```text
JSON shape is dynamic or only a few fields are needed
```
Next move:
- call `JSON.parseJsonElement(json)`
- read with typed accessors
- convert to typed classes before app logic grows

```ts
function readTitle(json: string): string {
    let root = JSON.parseJsonElement(json)
    return root.getString('title')
}
```

Useful accessors proven in tests:
- `jsonType`, `asArray()`, `asString()`, `asInteger()`, `asDouble()`, `asBoolean()`
- `getString(key)`, `getInteger(key)`, `getDouble(key)`, `getBoolean(key)`, `getArray(key)`, `getElement(key)`
- `tryGetElement(key)`, `tryGetString(key)`

Proof anchors:
- `JsonElementParseTest.ets:230` parses arrays
- `JsonElementParseTest.ets:278` reads object fields
- `JsonElementParseTest.ets:377` reads nested config fields
- `JsonElementTest.ets:199` exercises object accessors

## Reviver -> one local transform
```text
One JSON field needs transformation or suppression during parse
```
Next move:
- keep the reviver local
- accept `Any` and cast explicitly
- in `parseUpdate<T>()`, return `undefined` to keep the existing instance field

```ts
final class Point {
    x: double = 0
    y: double = 0
}

function parsePoint(json: string): Point {
    let point = new Point()
    let reviver = (key: string, value: Any): Any => {
        if (key == 'x') { return (value as Double) * 10 }
        return value
    }
    return JSON.parseUpdate<Point>(json, reviver, point)
}
```

Proof anchors:
- `JsonParseUpdateTest.ets:134` transforms a field with reviver
- `JsonParseUpdateTest.ets:156` returns `undefined` to preserve an existing value

## Stable wire keys -> annotations
```text
JSON key name differs from the ArkTS field name, or a field must not parse from JSON
```
Next move:
- use `@JSONRename('wireName')` for wire-key compatibility
- use `@JSONParseIgnore` for fields that must not be populated
- do not duplicate wire names across inheritance

```ts
final class UserWire {
    @JSONRename('display_name')
    displayName: string = ''

    @JSONParseIgnore
    localOnly: string = ''
}
```

Proof anchors:
- `JsonAnnotationTest.ets:20` uses `@JSONRename`
- `JsonAnnotationTest.ets:23` uses `@JSONParseIgnore`
- `JsonAnnotationTest.ets:184` expects duplicate renamed keys to throw

## Stringify -> persistence/debug output
```text
Typed ArkTS data should become JSON text
```
Next move:
- use `JSON.stringify(value)`
- add `space` only for human-readable output
- use a replacer function or field list only when filtering is needed

```ts
let compact: string = JSON.stringify(config)
let pretty: string = JSON.stringify(config, null, 2)
let onlyHost: string = JSON.stringify(config, ['host'])
```

Proof anchors:
- `jsonStringifySpaceTest.ets:54` uses numeric `space`
- `JsonStringifyTest2.ets:159` uses a replacer function
- `JsonStringifyTest2.ets:166` uses a field-list replacer

## Large integers -> explicit BigInt mode
```text
JSON contains large integer values where precision matters
```
Next move:
- use `jsonx.ParseOptions`
- choose `jsonx.BigIntMode.DEFAULT`, `PARSE_AS_BIGINT`, or `ALWAYS_PARSE_AS_BIGINT`
- do not assume default number parsing preserves large integers

```ts
let options = { bigIntMode: jsonx.BigIntMode.ALWAYS_PARSE_AS_BIGINT } as jsonx.ParseOptions
let parsed = JSON.parse<BigBox>(json, undefined, Type.from<BigBox>(), options) as BigBox
```

Proof anchors:
- `JsonParseTest.ets:197` parses with `BigIntMode.ALWAYS_PARSE_AS_BIGINT`
- `JsonElementParseBigIntTest.ets:28` parses JsonElement with BigInt mode
- `JsonParseUpdateTest.ets:198` passes `ParseOptions` to `parseUpdate<T>()`

## Verify
- compile the file that owns the parser
- run one parse path with representative JSON text
- for OHOS rawfile JSON, also build/launch the HAP enough to prove the rawfile is packaged

## Return
- JSON came from OHOS rawfile/assets -> `../30-arkui-path/30-16-resources-and-assets.md`
- collection containers or maps after parsing -> `40-10-collections-and-data-surfaces.md`
- runtime class/reflection blocker -> `40-30-interop-and-boundary-surfaces.md`
