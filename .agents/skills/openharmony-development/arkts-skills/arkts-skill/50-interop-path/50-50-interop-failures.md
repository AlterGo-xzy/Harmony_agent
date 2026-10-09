# Interop failures

Use when the smallest failing crossing is on the ECMAScript interop side.

## Recovery loop
1. isolate one crossing
2. name the exact failing surface: `ESValue`, transfer helper, serializer, or reference handle
3. apply one first move
4. rerun the same crossing

## Failure family -> first move

### `ESValue` conversion failure
```ts
let value = ESValue.wrap(raw)
let field = value.getPropertySafe("name")
```
First move:
- keep the value wrapped longer
- add the matching `isX()` check before `toX()`

### Buffer or typed-array transfer failure
```ts
let staticInts = InteropTransferHelper.transferInt32ArrayToStatic(dynamicInts) as Int32Array
```
First move:
- stop manual reconstruction
- use the exact helper pair for the same family
- verify one element and one offset

### Worker serialization failure
```ts
let helper = new InteropSerializeHelper(args)
let roundTrip = helper.deserialize()
```
First move:
- inspect serializer classification first
- keep the payload on the existing serializer path

### Seamless interop reference-handle failure
```ts
let refValue = ESValue.wrap(rawRef)
```
First move:
- stop flattening the handle into plain state
- keep it wrapped until the identity-sensitive step finishes

## Verify
- one crossing only
- one observed result only
- widen only after the smallest crossing works
