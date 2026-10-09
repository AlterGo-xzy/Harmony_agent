# `ESValue`

Use this when the boundary problem is wrapped dynamic values themselves: property access, globals, equality, or typed conversion.

## First moves
- unknown raw dynamic value -> wrap it
- property read might fail -> use safe property access first
- conversion might fail -> check `isX()` before `toX()`
- equality depends on dynamic semantics -> use safe equality

## Wrap values
```ts
let a = ESValue.wrapInt(3)
let b = ESValue.wrapString("ok")
let c = ESValue.wrap(raw)
```

## Check before convert
```ts
if (value.isString()) {
    let s = value.toString()
}
```

## Global lookup and safe property access
```ts
let module = ESValue.getGlobal()
let entry = module.getPropertySafe("wrapobjTS")
```

## Object creation and property write
```ts
let obj = ESValue.instantiateEmptyObject()
obj.setProperty("count", 3)
let count = obj.getProperty("count")
```

## Safe equality
```ts
if (left.isEqualToSafe(right)) {
    return true
}
return false
```

## If you see this -> do this next
- raw dynamic value enters static code -> wrap first
- property access may be absent or unsafe -> use `getPropertySafe(...)`
- conversion may throw or misread -> add the matching `isX()` check
- identity/equality matters -> use safe equality instead of flattening first

## Verify
- verify one wrapped value crosses correctly
- verify one property read or one typed conversion
