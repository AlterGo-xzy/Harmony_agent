# Writing mixed static and dynamic code

Use this first when one feature crosses between static ArkTS logic and ECMAScript-side values.

Load this when the next move is unclear:
- keep wrapped longer, or
- convert now and return to ordinary ArkTS

## If the next line does this -> do this
- reads a dynamic property -> keep the value wrapped
- uses globals or dynamic calls -> keep the value wrapped
- depends on reference identity -> keep the value wrapped
- passes plain data into ordinary typed ArkTS -> convert once and return to the main playbook
- bounces the same value back and forth -> stop and keep one narrow boundary

## Dynamic read then static conversion
```ts
let value = ESValue.wrap(raw)
let nameValue = value.getPropertySafe("name")
if (nameValue.isString()) {
    let name = nameValue.toString()
    consumeName(name)
}
```

## Static value crossing into dynamic code
```ts
let obj = ESValue.instantiateEmptyObject()
obj.setProperty("count", 3)
```

## Handle-like value -> stay wrapped
```ts
let refValue = ESValue.wrap(rawRef)
```
Do not flatten the handle into plain app state while identity still matters.

## Worker hop with interop value
```ts
let helper = new InteropSerializeHelper(args)
let payload = helper.deserialize()
```
Use the existing serializer path instead of ad-hoc cloning.

## If the next line does this -> do this
- reads a dynamic property -> stay wrapped
- uses globals or dynamic calls -> stay wrapped
- depends on reference identity -> stay wrapped
- passes plain data into ordinary typed ArkTS logic -> convert once and return to the main playbook
- crosses a worker boundary -> switch to `50-30-interop-workers-and-serialization.md`

## Verify
- verify one crossing only
- verify one conversion or one property path only
- widen the mixed flow only after the smallest crossing works
