# Compiler Design

The F&T compiler is intentionally small and deterministic. It parses a Lua-like
assignment dialect used by weapon authors and converters.

Supported source features:

- `using "Namespace"` imports.
- Namespaced assignments such as `TFA.Primary.Damage = 35`.
- Unprefixed assignments when imports make the field unambiguous.
- Lua-like strings, numbers, booleans, `nil`, table constructors, `Vector(...)`,
  and `Angle(...)` value literals.
- Merge configuration through `FT.Merge`.
- Priority configuration through `FT.Priority`.

Unsupported executable Lua is not run by the compiler. Unknown statements are
reported instead of executed. This keeps conversion and validation predictable.

## Conflict Model

Each assignment maps to one or more IR paths. If two namespaces write the same IR
path, the configured merge strategy decides the result.

Strategies:

- `override` / `last`
- `first`
- `average`
- `maximum`
- `minimum`
- `multiply`
- custom function supplied by Lua code through the API

`FT.Priority = { "ARC9", "MW", "TFA" }` means ARC9 has the highest priority. Lower
priority operations are applied first, so higher priority values win when using
`override` or `last`.

## Readable Errors

Ambiguous unprefixed fields produce suggestions, for example:

```text
Damage is ambiguous after using ARC9, MW, and SWB.
Use ARC9.Damage, MW.Damage, SWB.Damage, or FT.Damage.Base.
```
