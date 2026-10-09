# Native code

Use only for `native`, ANI, or static-side C++ binding.

## Workflow
1. declare one tiny native function
2. wrap it in one tiny ArkTS helper only if needed
3. bind one exact name on the native side
4. run one exact expected-value check

## 1. Native declaration
```ts
native function nativeAdd(a: int, b: int): int
```

## 2. Thin ArkTS wrapper
```ts
export function addViaNative(a: int, b: int): int {
    return nativeAdd(a, b)
}
```

## 3. Native bind table

Descriptors use dots, not slashes:

```cpp
// RIGHT
ani_native_function methods[] = {
    {"nativeAdd", "C{std.core.String}:C{std.core.String}", (void*)NativeEcho},
    {nullptr}
};

// WRONG — slash paths are rejected
{"echo", "C{std/core/String}:C{std/core/String}", ...}  // ANI_INVALID_DESCRIPTOR
```

Overloaded methods need signatures; single methods can use `nullptr`:

```cpp
// Overloaded
{"foo", "i:i",   (void*)FooInt},
{"foo", "d:d",   (void*)FooDouble},

// Single
{"bar", nullptr, (void*)Bar},
```

## 4. Bind call — context-specific

```cpp
env->Class_BindNativeMethods(klass, methods, count)       // instance methods
env->Class_BindStaticNativeMethods(klass, methods, count) // static methods
env->Module_BindNativeFunctions(module, methods, count)   // module functions
env->Namespace_BindNativeFunctions(ns, methods, count)    // namespace functions
```

Using the wrong binder returns `ANI_NOT_FOUND` even with a correct name and descriptor.

## 5. Calling managed code from native — return-kind-specific helpers

```cpp
env->Function_Call_Int(func, &result)     // int return
env->Function_Call_Void(func)             // void return
env->Function_Call_Ref(func, &result)     // object return
```

Must match the declared return type or get `ANI_INVALID_TYPE`.

## Native-generated audio files for playback

Use native code when audio generation or media-file construction is too heavy for ArkTS. Device verification showed synchronous ArkTS-side audio generation can trigger `APP_FREEZE`. Keep ArkTS as a thin orchestration layer; render PCM and write the final playable file in C++.

For generated playback files, prefer OGG/FLAC output and expose three tiny native functions:

```ts
native function _renderOggFlacFile(events: string, sampleRate: int, totalSamples: int, startFrame: int, outPath: string): boolean
native function _openReadOnlyFd(path: string): int
native function _closeFd(fd: int): boolean
```

Native file generation pattern:

```cpp
bool WriteBytesToFile(const std::string& path, const std::string& bytes)
{
    int fd = open(path.c_str(), O_CREAT | O_WRONLY | O_TRUNC, 0600);
    if (fd < 0) {
        return false;
    }

    const char* data = bytes.data();
    size_t remaining = bytes.size();
    while (remaining > 0) {
        ssize_t written = write(fd, data, remaining);
        if (written <= 0) {
            close(fd);
            return false;
        }
        data += written;
        remaining -= static_cast<size_t>(written);
    }

    return close(fd) == 0;
}
```

Native fd handoff pattern:

```cpp
int OpenReadOnlyFd(const std::string& path)
{
    return open(path.c_str(), O_RDONLY);
}

bool CloseFd(int fd)
{
    return fd >= 0 && close(fd) == 0;
}
```

Rules for generated audio playback:
- write the whole OGG file in native code before creating `AVPlayer`
- use `open(..., O_CREAT | O_WRONLY | O_TRUNC, 0600)` and loop until all bytes are written
- expose `openReadOnlyFd(path)` for AVPlayer `fdSrc`; do not hand a managed `@ohos.file.fs` fd to `fdSrc`
- expose `closeFd(fd)` only for setup-failure cleanup before `fdSrc` succeeds
- after a successful `fdSrc` assignment, AVPlayer owns the fd; release it with `AVPlayer.release()`

## Rules
- exact same name across ArkTS declaration and bind table
- no body on the `native` declaration
- prove one binding before adding more
- if the failure surface becomes `ESValue` or serializer logic, switch to the interop path

## Verify
- compile ArkTS
- build native code
- run one direct expected-value call

## Return
Return to `../SKILL.md` after the binding passes the expected-value check.
