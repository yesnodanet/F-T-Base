# Weapon Templates

F&T Base ships four spawnable reference weapons under `lua/weapons/`:

- `ft_template_tfa` demonstrates the `TFA` dialect;
- `ft_template_swb` demonstrates the `SWB` dialect;
- `ft_template_mw` demonstrates the `MW` dialect;
- `ft_template_mixed` combines `TFA`, `SWB`, and `MW` in one source file.

They are ordinary F&T weapons. Each one extends `ft_base`, declares a
`SWEP.FTSource` string, and is compiled into F&T IR during weapon
initialization. The shipped templates also call `PrepareDefinition` after the
source declaration, which applies their clip and ammo configuration before the
weapon entity is created. No external weapon base needs to be installed.

## Creating A Weapon

1. Copy one template directory and give it a unique weapon class name.
2. Keep `SWEP.Base = "ft_base"`.
3. Edit only `SWEP.FTSource` until a custom Lua hook is actually required.
4. Spawn the weapon and use `ft_report <class>` to inspect the compile report.

The base applies `Ammo.ClipSize`, `Ammo.DefaultClip`, `Ammo.Type`, and
`Fire.Automatic` from the compiled IR to the standard SWEP fields. Firing,
reload timing, hitscan damage, recoil, sound, animations, aiming, and movement
are then executed by the F&T runtime.

## Attachments And Inspect

An attachment needs a slot and a compatible definition. Slots are arrays;
definitions are maps indexed by attachment id.

```lua
TFA.Attachments = {
    { id = "optic", name = "Optic", type = "optic" }
}

TFA.AttachmentDefinitions = {
    reflex = {
        name = "Reflex Sight",
        type = "optic",
        modifiers = {
            ["spread.ads"] = { multiply = 0.75 },
            ["ads.fov"] = { add = -4 }
        }
    }
}
```

`MW.Attachments` writes the complete F&T attachment object, so it uses
lowercase `slots` and `definitions` keys:

```lua
MW.Attachments = {
    slots = {
        { id = "barrel", type = "barrel" }
    },
    definitions = {
        long_barrel = {
            type = "barrel",
            modifiers = {
                ["damage.minimum"] = { add = 4 }
            }
        }
    }
}
```

While holding an F&T weapon, run `ft_customize`, or hold the Use key and press
secondary attack. The client opens the inspect panel. Installation requests are
validated by the server against the weapon owner, slot, attachment id, and
declared attachment type; the authoritative result is sent back to the client.

Supported modifier forms are:

- a number, which replaces the current value;
- `{ add = number }`;
- `{ multiply = number }`;
- `{ minimum = number }` or `{ maximum = number }`;
- `{ set = value }`;
- `{ append = { ... } }` for array fields.

The source IR is never modified by installation. The attachment runtime builds
an effective IR, and firing, recoil, camera, and movement consume that result.

## Dialect Notes

The adapters translate field names into F&T semantics. They do not load, call,
or inherit any external base.

| Dialect | Useful fields in the shipped template |
| --- | --- |
| `TFA` | `Primary.*`, `KickUp`, `RecoilInstructions`, `Animations`, `Attachments`, `AttachmentDefinitions` |
| `SWB` | `Damage`, `FireDelay`, `HipSpread`, `AimSpread`, `RecoilPattern`, `Animations`, `Attachments`, `AttachmentDefinitions` |
| `MW` | `Damage`, `DamageMin`, `RPM`, `Recoil.*`, `Camera.*`, `Aim.*`, `Sound.*`, `Reload.Duration`, `Attachments` |

For mixed weapons, use explicit namespaces for values that are intentionally
drawn from a particular dialect. Set `FT.Priority` and `FT.Merge` whenever two
sources write to the same IR property.
