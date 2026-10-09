# Buffer and transfer helpers

Use this when the boundary problem is `ArrayBuffer` or typed-array transfer.

Do not use this for ordinary arrays or ordinary collection choice.

## First moves
- raw `ArrayBuffer` crossing -> use the exact buffer helper pair
- typed-array crossing -> use the exact typed-array helper pair
- transfer bug after manual rebuild -> stop rebuilding by hand

## Raw buffer transfer
```ts
let staticBuffer = InteropTransferHelper.transferArrayBufferToStatic(dynamicBuffer) as ArrayBuffer
let dynamicBuffer2 = InteropTransferHelper.transferArrayBufferToDynamic(staticBuffer)
```

## Typed-array transfer
```ts
let staticInts = InteropTransferHelper.transferInt32ArrayToStatic(dynamicInts) as Int32Array
let dynamicInts2 = InteropTransferHelper.transferInt32ArrayToDynamic(staticInts)
```

## Transfer rule
1. read buffer metadata first
2. use the exact helper for that family
3. verify offset, length, and one element value
4. do not mix helper families

## Verify
1. transfer one small known buffer
2. verify length and byte offset
3. verify one element value on the far side
