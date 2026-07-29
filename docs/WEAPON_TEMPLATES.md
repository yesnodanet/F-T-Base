# Weapon Templates

F&T Base ships seven spawnable reference weapons under `lua/weapons/`:

- `ft_template_tfa` demonstrates the `TFA` dialect;
- `ft_template_swb` demonstrates the `SWB` dialect;
- `ft_template_mw` demonstrates the `MW` dialect;
- `ft_template_arc9` demonstrates the `ARC9` dialect;
- `ft_template_arccw` demonstrates the `ArcCW` dialect;
- `ft_template_tacrp` demonstrates the `TacRP` dialect;
- `ft_template_mixed` combines `TFA`, `SWB`, and `MW` in one source file.

`ft_example_mixed` is a second mixed profile kept under the examples category.
It uses the same provider-selection rules as `ft_template_mixed`, but carries a
larger MW attachment set for quick gunsmith testing.

They are ordinary F&T weapons. Each one extends `ft_base`, declares a
`SWEP.FTSource` string, and is compiled into F&T IR during weapon
initialization. The shipped templates also call `PrepareDefinition` after the
source declaration, which applies their clip and ammo configuration before the
weapon entity is created. No external weapon base needs to be installed.

## Temporary Native Templates

The addon also ships six `ft_native_template_*` fixtures. These are deliberately
different from the IR templates above: each fixture inherits the real sample
SWEP, so the external base owns its HUD, inspect/customization screen,
attachments, animations, models, and ADS behavior. F&T does not replace those
hooks and does not provide an IR fallback when a native dependency is missing.

| Template | Native base/sample | Workshop dependencies | Declared surface |
| --- | --- | --- | --- |
| `ft_native_template_tfa` | `tfa_ins2_cw_ar15` | `2840031720`, `1676032134` | HUD, inspect, customization, attachments, presentation |
| `ft_native_template_arc9` | `arc9_go_ak47` | `2910505837`, `2910537020` | HUD, inspect, customization, attachments, presentation |
| `ft_native_template_arccw` | `arccw_go_ak47` | `2131057232`, `2257255110` | HUD, inspect, customization, attachments, presentation |
| `ft_native_template_mw` | `mg_mike4` | `2459720887`, `2528829149` | HUD, inspect, customization, attachments, presentation |
| `ft_native_template_tacrp` | `tacrp_eo_masada` | `3734712166`, `3271554982` | HUD, inspect, customization, attachments, presentation |
| `ft_native_template_swb` | `swb_base` | `1967187358` | HUD, ADS, presentation; no customization claim |

Native dependencies are installed outside this repository. The compatibility
registry is available as `FTBase.Compat`; `GetManifest()` returns the stable
Workshop/base/sample manifest and `Check()` reports unavailable weapon classes.
Use `tools/server/install_native_dependencies.ps1` to copy the prepared addon
snapshots from `C:\Users\ameri\AppData\Local\Temp\gmpublisher\bases` into
separate `ft_native_dep_*` addon directories. The installer only removes those
known directories and `ft_base_visual_test` when `-Clean` is supplied.

The native templates are intended for client/server integration checks while
the UI is being transferred into F&T providers. Do not mix their addon folders
with raw vendor snapshots or with the ordinary F&T test addon.

## Creating A Weapon

1. Copy one template directory and give it a unique weapon class name.
2. Keep `SWEP.Base = "ft_base"`.
3. Edit only `SWEP.FTSource` until a custom Lua hook is actually required.
4. Spawn the weapon and use `ft_report <class>` to inspect the compile report.

The base applies `Ammo.ClipSize`, `Ammo.DefaultClip`, `Ammo.Type`, and
`Fire.Automatic` from the compiled IR to the standard SWEP fields. Firing,
reload timing, hitscan damage, recoil, sound, animations, aiming, and movement
are then executed by the F&T runtime.

The templates are deliberately feature-complete reference profiles. They use
dialect-native fields for view/world models, bodygroups or elements, ADS or
scope data, inspect/customize camera poses, inspect/customize animations,
provider selection, and attachment visual descriptors. The regression suite
compiles the real `shared.lua` files so template drift is caught automatically.

## Attachments And Inspect

An attachment needs a slot and a compatible definition. Slots are arrays;
definitions are maps indexed by attachment id.

```lua
TFA.Attachments = {
    { id = "optic", name = "Optic", type = "optic", default = "reflex" }
}

TFA.AttachmentDefinitions = {
    reflex = {
        name = "Reflex Sight",
        type = "optic",
        icon = "ft_base/providers/tfa/inspectionhud/qmark",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                pos = Vector(4, -1.5, 0.7),
                ang = Angle(0, 90, 0),
                scale = 0.18,
                bodygroups = {[0] = 0}
            },
            world = {
                model = "models/weapons/w_pistol.mdl",
                attachment = "muzzle",
                pos = Vector(-10, 0, 2),
                ang = Angle(0, 180, 0),
                scale = 0.16,
                material = "models/shiny"
            }
        },
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
        { id = "barrel", type = "barrel", default = "long_barrel" }
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

While holding an F&T weapon, press the Context Menu key (`C`), run
`ft_customize`, or hold the Use key and press secondary attack. The client opens
the inspect panel. Installation requests are
validated by the server against the weapon owner, slot, attachment id, and
declared attachment type; the authoritative result is sent back to the client.
Slots may declare `default` or `defaultAttachment`; valid defaults are installed
when runtime state is created, which makes the shipped visual descriptors
visible immediately after spawn.

## Visual Providers

The compiler records an independent provider for `inspect`, `attachments`,
`hud`, and `presentation` in `ir.ui.visual.providers`. The provider comes from
the dialect whose effective operation owns the corresponding domain. This lets
TFA control a weapon's inspect and HUD while MW controls only its attachment
selection UI.

The supported providers are `ft`, `tfa`, `swb`, `mw`, `arc9`, `arccw`, and
`tacrp`. Authors can override a domain explicitly:

```lua
FT.Visual.Default = "TFA"
FT.Visual.Inspect = "TFA"
FT.Visual.Attachments = "MW"
FT.Visual.HUD = "TFA"
FT.Visual.Presentation = "TFA"
```

`FT.Customization.Provider` remains a backward-compatible alias for the
attachment domain. Its legacy `mixed` value enables automatic per-domain
selection. Providers control layout, slot ordering, labels, preview framing,
HUD styling, and request construction; attachment installation still uses the
shared server-side IR validation path.

The provider contract is `Open`, `Close`, `Refresh`, `HandleInput`, `DrawHUD`,
`ApplyPresentation`, `GetSlots`, `GetOptions`, `GetInspectData`, and
`BuildAttachmentRequest`. Its request result remains exactly
`{slotId, attachmentId}`; providers cannot bypass the shared networking or
server validation path.

Attachment definitions may also provide namespaced UI and model presentation:

```lua
reflex = {
    type = "optic",
    icon = "ft_base/providers/tfa/inspectionhud/qmark",
    visuals = {
        view = {
            model = "models/weapons/c_pistol.mdl",
            bone = "ValveBiped.Bip01_R_Hand",
            pos = Vector(2, 0, 1),
            ang = Angle(0, 0, 0),
            scale = 0.22,
            bodygroups = {[0] = 1}
        },
        world = {
            model = "models/weapons/w_pistol.mdl",
            attachment = "muzzle"
        }
    }
}
```

Clientside models are removed and rebuilt after install/uninstall and when the
weapon is removed. Material, submaterial, skin, bodygroup, element, color, and
scale overrides are applied from validated IR.

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
| `TFA` | `Primary.*`, `Secondary.Scope`, `IronSights*`, `Inspect*`, `Customize*`, `Bodygroups_*`, `VElements/WElements`, `Attachments`, `AttachmentDefinitions` |
| `SWB` | `Damage`, `FireDelay`, `AimPos/Ang/FOV`, `ZoomAmount`, `RecoilPattern`, `Bodygroups_*`, `VElements/WElements`, `Attachments`, `AttachmentDefinitions` |
| `MW` | `Damage`, `DamageMin`, `RPM`, `Recoil.*`, `Camera.*`, `Aim.*`, `Inspect*`, `Customize*`, `Sound.*`, `Reload.Duration`, `Attachments` |
| `ARC9` | `DamageMax`, `DamageMin`, `Scope`, `Customize*`, `Inspect*`, `DefaultBodygroups`, `DefaultSkin`, `Elements`, `AttachmentDefinitions` |
| `ArcCW` | `Damage`, `RPM`, `Automatic`, `Primary.*`, `Scope`, `Customize*`, `Inspect*`, `DefaultBodygroups`, `DefaultSkin`, `Elements`, `AttachmentDefinitions` |
| `TacRP` | `Damage_Max`, `RPM`, `Scope`, `Customize*`, `Inspect*`, `DefaultBodygroups`, `DefaultSkin`, `Elements`, `AttachmentDefinitions` |

For mixed weapons, use explicit namespaces for values that are intentionally
drawn from a particular dialect. Set `FT.Priority` and `FT.Merge` whenever two
sources write to the same IR property.
