# F&T Base

[English](README.md) | [Русский](README.ru.md)

**Familia & Tarka Base** is an original weapon development platform for
Garry's Mod.

F&T Base is not a clone of TFA, ARC9, ArcCW, MW Base, SWB, or TacRP. Those bases
are useful references for ergonomics and feature expectations, but F&T Base has
its own architecture, compiler pipeline, intermediate representation, runtime,
APIs, and module boundaries.

The central idea is simple:

> Weapon authors describe intent. F&T Base compiles that intent into one internal
> representation. The runtime executes only that representation.

## Project Status

This repository currently contains the first architectural implementation of the
platform:

- addon bootstrap and loader;
- original lexer, parser, resolver, compiler, emitter;
- F&T IR schema;
- style adapters for `FT`, `TFA`, `ARC9`, `ArcCW`, `MW`, `TacRP`, and `SWB`;
- validation, optimization, merge strategies, and compile reports;
- modular weapon runtime;
- base SWEP implementation;
- mixed-dialect example weapon;
- standalone converter API;
- developer-facing documentation.

It is an early foundation, not a finished production weapon base yet. The shape
is intentionally engine-like so that future work can add richer behavior without
rewriting the core.

## Why F&T Base Exists

Most weapon bases make developers write for one specific runtime style. F&T Base
instead treats weapon files as source code.

Different weapon dialects can be parsed, normalized, validated, optimized, and
executed through the same runtime. This makes the project useful for:

- creating new weapons with a clean F&T-native API;
- migrating legacy weapons;
- mixing familiar syntax styles during transition;
- building converters between weapon formats;
- experimenting with new recoil, animation, camera, and attachment systems;
- extending the platform through plugins instead of core edits.

## Compilation Pipeline

```text
Weapon File
  -> Lexer
  -> Parser
  -> Style Resolver
  -> AST
  -> F&T IR
  -> Validation
  -> Optimization
  -> Runtime Objects
  -> Weapon Engine
```

The runtime does not execute external weapon-base logic. External namespaces are
accepted only as source dialects and are translated into F&T IR.

## Namespace Mixing

One weapon file can use several styles at the same time:

```lua
using "TFA"
using "ARC9"
using "MW"
using "TacRP"

FT.Priority = {
    "ARC9",
    "MW",
    "TFA"
}

TFA.Primary.Damage = 35
TFA.Primary.ClipSize = 30

ARC9.Recoil.Up = 0.8
ARC9.Recoil.Side = 0.24

MW.Camera.Shake = 0.35
MW.Camera.Sway = 0.15

TacRP.BlindFire = true

FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
```

Each namespace is parsed by its own adapter. The adapters do not run gameplay
logic. They only translate fields into IR operations.

## Using Directives

`using` imports a namespace so fields can be written without a prefix when the
meaning is unambiguous:

```lua
using "TFA"

Primary.Damage = 35
Primary.ClipSize = 30
```

If several imported styles can understand the same field, the compiler reports a
readable error and suggests explicit alternatives.

## Merge System

When multiple styles write to the same IR field, F&T Base applies configurable
merge rules.

Supported strategies include:

- `override`;
- `first`;
- `last`;
- `average`;
- `maximum`;
- `minimum`;
- `multiply`;
- custom Lua functions through the compiler API.

Example:

```lua
FT.Priority = {
    "ARC9",
    "MW",
    "TFA"
}

FT.Merge = {
    ["damage.base"] = "maximum",
    ["recoil.scalar"] = "multiply"
}
```

## Compile Reports

Every compile produces a report with:

- applied properties;
- ignored properties;
- conflicts;
- warnings;
- optimization notes;
- unknown fields;
- deprecated syntax;
- missing animations;
- missing sounds;
- invalid attachments;
- performance suggestions.

Reports are designed for developers, not machines only. The goal is to make
weapon authoring feel closer to working in a real SDK.

## Runtime Modules

The runtime is split into independent modules:

- Core;
- Prediction;
- Networking;
- Weapon Lifecycle;
- Ballistics;
- Precision Recoil;
- Camera;
- Animation;
- Attachments;
- Sound;
- Movement;
- Effects;
- Rendering;
- NPC;
- Vehicles;
- Physics;
- Customization;
- Developer Tools;
- Debug;
- Profiler;
- Utilities.

Each module consumes F&T IR and exposes a clear interface.

## Ballistics

The IR is designed to represent:

- hitscan weapons;
- projectile weapons;
- hybrid weapons;
- travel time;
- drag;
- gravity;
- wind;
- penetration;
- armor;
- ricochet;
- fragments;
- material responses;
- custom damage curves.

The current runtime contains the first implementation layer for hitscan and
projectile dispatch. More advanced physical simulation can be added behind the
same IR contract.

## Precision Recoil

F&T Base includes a precision recoil model with exact per-shot pattern support.

Pattern entries can define horizontal movement, vertical movement, roll, camera
influence, weapon influence, recovery, randomness, and animation hints.

Compact syntax:

```lua
FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
```

Expanded intent:

```lua
FT.Recoil.Pattern = {
    {
        horizontal = 0.4,
        vertical = 1.2,
        roll = 0,
        camera = 1,
        weapon = 1,
        recovery = 1,
        randomness = 0
    }
}
```

This gives the platform room for CS-style, Valorant-style, Rust-style, random,
hybrid, procedural, and fully hand-authored recoil behavior.

## Camera Engine

The camera IR supports modular behavior such as:

- shake;
- sway;
- free aim;
- spring physics;
- breathing;
- landing effects;
- sprint movement;
- micro jitter;
- deadzone;
- aim transitions.

Different source styles can contribute camera data, but the runtime still sees
one camera model.

## Animation Engine

The animation schema is built around:

- base animation maps;
- layered animation state;
- IK data;
- procedural animation hooks;
- animation events;
- animation curves;
- reload stages;
- inspect animation;
- partial-body data.

## Attachment Engine

The attachment schema supports:

- universal slots;
- nested attachments;
- runtime-generated slots;
- dynamic modifiers;
- attachment inheritance;
- custom attachment types.

## Sound Engine

F&T Base models sound as layered data:

- firing layers;
- mechanical layers;
- indoor tails;
- outdoor tails;
- distance layers;
- suppressed variants;
- occlusion configuration;
- suppression effects.

## Converter

F&T Converter parses source text, compiles it into F&T IR, then emits another
style.

```lua
local result = FTConverter.Convert(sourceText, "TFA", "ARC9")

print(result.output)
print(result.report:ToString())
```

Supported target styles in the current generator:

- `FT`;
- `TFA`;
- `ARC9`;
- `ArcCW`;
- `MW`;
- `TacRP`;
- `SWB`.

Some styles cannot express every F&T feature directly. When that happens, the
converter keeps the output readable and reports warnings.

## Minimal F&T Weapon

```lua
SWEP.Base = "ft_base"
SWEP.PrintName = "F&T Example Rifle"
SWEP.Category = "F&T Base"
SWEP.Spawnable = true

SWEP.FTSource = [[
FT.Meta.Category = "F&T Base"
FT.Damage.Base = 35
FT.Fire.RPM = 650
FT.Ammo.ClipSize = 30
FT.Ammo.DefaultClip = 90
FT.Ammo.Type = "SMG1"
FT.Rendering.HoldType = "ar2"

FT.Sounds.Fire.Layers = {
    {
        sound = "Weapon_AR2.Single",
        role = "body"
    }
}

FT.Recoil.Pattern = {
    {0, 0},
    {0.4, 1.2},
    {-0.5, 2.1}
}
]]
```

## Repository Layout

```text
lua/
  autorun/
    ft_base_loader.lua
  ft_base/
    adapters/      Style adapters
    compiler/      Lexer, parser, resolver, compiler, emitter
    core/          IR, schema, merge, report, validation, optimization
    runtime/       Weapon engine modules
    util/          Shared utility helpers
  ft_converter/    Converter API and generators
  weapons/
    ft_base/       Base SWEP
    ft_example_mixed/
tools/
  ft_converter.lua
  ft_smoke_test.lua
docs/
  ARCHITECTURE.md
  COMPILER.md
  IR_SCHEMA.md
  CONVERTER.md
```

## Development Smoke Test

Inside a Garry's Mod Lua environment after the addon is loaded:

```lua
include("tools/ft_smoke_test.lua")
```

The smoke test compiles a mixed-style source file and prints the compile report.

## Design Rules

F&T Base follows a few hard rules:

- external weapon bases are never runtime dependencies;
- adapters translate syntax only;
- the runtime consumes only F&T IR;
- conflicts must be visible and readable;
- unknown fields should be reported, not silently ignored;
- plugins extend the platform without patching internals;
- developer experience matters as much as raw feature count.

## Roadmap

Planned next steps:

- richer Lua parsing coverage for legacy weapon files;
- fuller mathematical conversion between styles;
- advanced projectile simulation;
- complete attachment UI and persistence;
- deeper animation layers and IK helpers;
- networked customization state;
- developer overlay and in-game profiler panels;
- generated documentation for weapon packs;
- plugin SDK examples.

## Documentation

More details:

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/COMPILER.md`](docs/COMPILER.md)
- [`docs/IR_SCHEMA.md`](docs/IR_SCHEMA.md)
- [`docs/CONVERTER.md`](docs/CONVERTER.md)

## Name

**F&T Base** stands for **Familia & Tarka Base**.

The long-term goal is to become a serious weapon development platform for
Garry's Mod: a compiler, SDK, runtime, toolkit, and migration layer in one addon.
