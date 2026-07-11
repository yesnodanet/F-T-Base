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
