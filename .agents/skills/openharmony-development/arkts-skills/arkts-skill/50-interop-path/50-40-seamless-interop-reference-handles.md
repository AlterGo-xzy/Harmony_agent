# Seamless interop reference handles

Use this when the boundary value is identity-bearing and must stay a handle, not copied plain data.

## First moves
- identity still matters -> keep it wrapped
- code tries to flatten the value into plain state -> stop
- worker hop also matters -> pair this with `50-30-interop-workers-and-serialization.md`

## Keep the reference wrapped
```ts
let refValue = ESValue.wrap(rawRef)
```

## If identity still matters -> do this
- keep the object on the interop side while identity still matters
- do not flatten it into plain copied data
- convert only after the identity-sensitive step is over

## Verify
1. cross one reference-bearing value
2. confirm the receiving side still treats it as a handle or reference
