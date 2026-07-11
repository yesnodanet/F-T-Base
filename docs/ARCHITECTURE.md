# F&T Base Architecture

F&T Base is organized as a platform rather than a monolithic weapon base.

## Pipeline

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

The compiler accepts multiple dialect namespaces in one source file. Adapters
only translate source syntax into IR operations. Runtime modules only consume IR.

## Core Modules

- Core: module registry, plugin registry, weapon registry, schema, IR.
- Prediction: stable shot identifiers and client/server prediction helpers.
- Networking: compact runtime state synchronization.
- Lifecycle: compile and attach runtime objects to SWEPs.
- Animations: layered animation state, reload stages, events.
- Ballistics: hitscan, projectile, hybrid, penetration, ricochet, fragments.
- Camera: shake, sway, free aim, springs, breathing, sprint and landing motion.
- Effects: muzzle, shell, impact, tracer, suppression hooks.
- Rendering: view/world model render interfaces.
- Movement: speed, stance, aim, sprint, blind-fire modifiers.
- Attachments: nested slots, inheritance, dynamic modifiers.
- Customization: developer-facing attachment and tuning APIs.
- NPC: NPC fire behavior and proficiency hints.
- Vehicles: vehicle pose and fire constraints.
- Physics: projectile and spring helpers.
- Developer Tools: console, overlay, report and documentation helpers.
- Debug: structured logging and diagnostics.
- Profiler: scoped timing records for compiler and runtime modules.

## Isolation Rule

The runtime has no dependency on TFA, ARC9, ArcCW, MW Base, TacRP, or SWB. Dialect
names may appear in adapter files and compiler reports only.

## Extension Rule

Extensions register plugins, adapters, validators, optimizers, or runtime module
hooks. They do not patch engine internals.
