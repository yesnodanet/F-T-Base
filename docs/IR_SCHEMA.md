# F&T IR Schema

F&T IR is the only representation consumed by the runtime.

Top-level domains:

- `meta`
- `developer`
- `damage`
- `fire`
- `ammo`
- `ballistics`
- `recoil`
- `camera`
- `animations`
- `attachments`
- `sounds`
- `effects`
- `networking`
- `prediction`
- `movement`
- `npc`
- `vehicles`
- `physics`
- `rendering`
- `ui`
- `runtime`

The schema is intentionally permissive. Validators warn about likely mistakes,
while plugins may add stricter domain-specific rules.

## Recoil Pattern Entry

Pattern entries may be compact arrays or explicit objects.

```lua
{0.4, 1.2}
```

normalizes to:

```lua
{
    horizontal = 0.4,
    vertical = 1.2,
    roll = 0,
    camera = 1,
    weapon = 1,
    recovery = 1,
    randomness = 0
}
```

## Ballistics

`ballistics.mode` may be `hitscan`, `projectile`, or `hybrid`.

Supported data includes muzzle velocity, drag, gravity, wind, penetration,
armor, ricochet, fragments, material responses, and custom damage curves.

## Presentation And Attachment Visuals

`ui.visual.providers` and `ui.visual.sources` contain scalar values for the
`inspect`, `attachments`, `hud`, and `presentation` domains. Runtime selection
is deterministic and external provider code is never stored in IR.

`rendering` carries the view/world models, FOV/flip flags, bodygroups, skins,
materials, elements, model offsets, and muzzle/shell attachment names.
`camera.poses` carries active, crouch, sprint, holster, customize, inspect,
near-wall, and blind-fire pose data. `ads` carries scopes, reticle, overlay,
magnification, and view-hiding behavior.

Attachment definitions may contain `icon` and a `visuals` table. Each `view` or
`world` visual supports `model`, `bone` or `attachment`, `pos`, `ang`, `scale`,
`skin`, `material`, `materials`, `bodygroups`, `elements`, and `color`. The
client runtime creates only models declared by validated IR and rebuilds them
after every authoritative install/uninstall state change.

## Provider Metadata

The inspect and customization providers consume declarative metadata from IR;
they never execute source weapon code. `ui.inspect` supports `title`, `type`,
`description`, `credits`, `preview`, `stats`, `falloff`, `hints`, `blur`, and
`hideHud` in addition to its command, pose, and animation fields. The
`ui.customization` table supports `title`, `openCommand`, `provider`,
`source`, `presets`, `controls`, `stats`, `hints`, `preview`, and `animations`.

Attachment slots and definitions expose the canonical metadata keys `name`,
`shortName`, `category`, `folder`, `description`, `pros`, `cons`, `trivia`,
`credits`, `stats`, `toggles`, and `sliders`. Dialect adapters populate these
keys from source aliases such as `PrintName`, `ShortName`, `Description`,
`ToggleStats`, and `SliderValues` while retaining the original fields for
provenance and conversion. Rich metadata is data-only and is validated for
finite values and bounded nesting; functions and other executable values are
rejected.
