# Interop workers and serialization

Use this when an interop-bearing value crosses a worker boundary.

## First moves
- existing serializer path exists -> keep using it
- worker handoff was rebuilt manually -> stop and go back to the serializer helper
- failure appears only after worker hop -> inspect serializer class first

## Worker handoff
```ts
let helper = new InteropSerializeHelper(args)
let payload = helper.deserialize()
```
Use the existing serializer path, not ad-hoc cloning.

## If you see this -> do this next
- value works before hop and fails after hop -> inspect serializer classification first
- manual clone/rebuild code appeared -> remove it and use the helper path
- reference identity still matters after hop -> pair this with `50-40-seamless-interop-reference-handles.md`

## Verify
1. send one tiny interop-bearing task
2. verify deserialize works on the far side
3. verify resolve or reject behavior
