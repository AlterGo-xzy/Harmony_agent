# Interop specialist path entry

Use only for ECMAScript interop or mixed ArkTS + ECMAScript code.
Do not use this path for ordinary app code.
Do not use this path for plain static native binding.

## Load order
1. read `50-05-writing-mixed-static-and-dynamic-code.md`
2. then load exactly one surface doc by next move:
   - wrapped value, property access, globals, equality, typed conversion -> `50-10-esvalue.md`
   - `ArrayBuffer` or typed-array transfer -> `50-20-buffer-and-transfer-helpers.md`
   - worker hop or serializer path -> `50-30-interop-workers-and-serialization.md`
   - identity-bearing handle must stay wrapped -> `50-40-seamless-interop-reference-handles.md`
   - smallest failing crossing is already known -> `50-50-interop-failures.md`

## Interop loop
1. isolate one boundary crossing
2. decide whether the next line stays dynamic or converts to static
3. use one existing helper path
4. verify one crossing before widening
5. return to the main playbook when the rest is ordinary ArkTS logic
