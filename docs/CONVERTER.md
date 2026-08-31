# F&T Converter

F&T Converter parses a source dialect into F&T IR, then emits another dialect.

```lua
local result = FTConverter.Convert(sourceText, "TFA", "ARC9")
```

Result fields:

- `ir`: compiled F&T IR.
- `ast`: parser AST.
- `output`: generated target source.
- `report`: compiler and converter report.
- `warnings`: converter-specific warnings.

The converter preserves intent through IR. Some dialects cannot express every F&T
feature directly, so the generator emits warnings when it approximates or drops a
feature.

Caller-provided `options.imports` are copied, canonicalized, and deduplicated; the
converter never mutates the options table. Every supported target emits default
clip data plus attachment slots and definitions.

Generated Lua is data-only. The emitter accepts primitive/table values,
`Vector(...)`, `Angle(...)`, and a fixed allowlist of animation constants. Unknown
symbols and arbitrary calls are reported as errors and produce no converter
output.
