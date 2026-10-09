# ANI Signatures Quick Reference

Use it only for ANI descriptors used by C++ lookup/call APIs.

## Shape
The ANI signature has a specific format defined by the following formula:

```text
SignatureEncoding ::= (TypeEncoding)* ':' (TypeEncoding)?
```

- Parameters go before `:` with no separators.
- Return type goes after `:`.
- Empty return type means `void`.
- `:` is required.

Examples:

```text
:                                     // no parameters, void
i:                                    // int parameter, void
:i                                    // no parameters, int return
ii:i                                  // two int parameters, int return
C{std.core.String}:C{std.core.String} // string parameter, string return 
```

## Type Codes
Use this table to map types to ANI codes.

| ArkTS type | ANI code |
| --- | --- |
| `boolean` | `z` |
| `byte` | `b` |
| `char` | `c` |
| `short` | `s` |
| `int` | `i` |
| `long` | `l` |
| `float` | `f` |
| `double` | `d` |
| `undefined` | `U` |
| `Any` | `Y` |
| `never` as reference | `N` |
| `never` / no-value | `w` |

## Reference Types
`QualifiedName` uses dots: `std.core.String`, `app.ns.Klass`. Do not use `/` or `:` inside `C{}` / `E{}`.

```text
C{std.core.String}:C{std.core.Object}
E{a.b.c.Color}:
```

`null` is represented as `C{std.core.Null}` in signatures.

## Fixed Arrays

```text
A{i}:                     // FixedArray<int> parameter, void
:A{C{std.core.String}}    // returns FixedArray<String>
```

## Function Types
`N` is the required-parameter count. `FunctionR` is used for rest parameters.

```text
C{std.core.Function1}:
C{std.core.FunctionR0}:C{std.core.Double}
```

## Unions
Union constituent types are canonicalized by ANI encoding. `undefined` is removed from union
representation, value types are promoted to boxed primitive types, and generic constraints are substituted.

Documented union constituents are class/interface, enum, fixed array, and function encodings. 

```text
X{C{std.core.Double}C{std.core.String}}
X{A{c}C{std.core.Double}C{std.core.String}}:
X{C{std.core.Double}C{std.core.Null}C{std.core.String}}
```

## ANI API Examples
Function and method lookup:

```cpp
env->Module_FindFunction(module, "sum", "ii:i", &fn);
env->Module_FindFunction(module, "getIntValue", "C{std.core.String}:i", &fn);
env->Namespace_FindFunction(ns, "c", "i:C{std.core.Promise}", &fn);
env->Class_FindMethod(cls, "<ctor>", "C{std.core.String}i:", &ctor);
env->Class_FindStaticMethod(cls, "addIntValue", "ii:i", &method);
```

By-name calls:

```cpp
env->Class_CallStaticMethodByName_Int(cls, "foo", "iii:i", &result, 1, 2U, 3U);
env->Object_CallMethodByName_Int(object, "foo", "ii:i", &result, 1, 2U);
env->Object_CallMethodByName_Ref(object, "fooAny", ":Y", &ref);
```

Native binding:

```cpp
ani_native_function {"sum", "ii:i", reinterpret_cast<void *>(Sum)};
ani_native_function {"foo", "C{std.core.Array}:C{std.core.Array}", nativePtr};
ani_native_function {"foo", "C{std.core.Array}C{std.core.Function1}:", nativePtr};
```

## Common Invalid Forms

```text
""              // empty
"sbz"           // no colon
"::"            // more than one colon
"i:i:z"         // more than one colon
":C{T};"        // extra trailing semicolon
"C{a:b}:f"      // ':' inside qualified name
"C{a/b}:"       // '/' inside qualified name
"A{A{c}}"       // no colon
"b:A{A{c}"      // malformed array
```

## Verify
- compile ArkTS
- build native code
- run one direct expected-value call

## Return
Return to `../SKILL.md` after the binding passes the expected-value check.
