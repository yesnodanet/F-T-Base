# Third-Party Workshop Snapshots

F&T Base includes reference snapshots supplied by the repository owner for
compatibility development. They live under `third_party/workshop/<id>/`, outside
the Garry's Mod `lua/` tree. F&T does not execute their autorun files, register
their original SWEPs, inherit from their globals, or require the corresponding
addons at runtime. Active F&T behavior remains implemented in the F&T compiler,
IR, and runtime modules.

A selected UI-only subset is copied into `materials/ft_base/providers/` and
`resource/fonts/` under F&T-specific paths. It contains TFA inspection
textures/Inter, ARC9 UI and attachment icons/Venryn Sans, ArcCW HUD
icons/Bahnschrift, MW customization marker/logo/UI font, SWB HUD reticles,
and TacRP HUD icons/Myriad Pro. These files remain attributed to their
respective snapshots; the path namespace does not claim authorship. Active
providers are adapted F&T Lua modules and never execute copied vendor Lua.

## Snapshot inventory

| Base | Workshop source | Files | Bytes | `MANIFEST.sha256` SHA-256 |
| --- | --- | ---: | ---: | --- |
| TFA Base | [2840031720](https://steamcommunity.com/sharedfiles/filedetails/?id=2840031720) | 496 | 43,374,268 | `deaa33e21fad15822630a84c7bf534a8293fb8479c61b655183254e0ba3ea028` |
| ARC9 Weapon Base | [2910505837](https://steamcommunity.com/sharedfiles/filedetails/?id=2910505837) | 1,460 | 97,709,068 | `cb086e9cec2b2db16c3568386c5753613f85d29b0b566955e05589dc1a606119` |
| ArcCW | [2131057232](https://steamcommunity.com/sharedfiles/filedetails/?id=2131057232) | 376 | 60,482,541 | `fae7b29897b04d53819b9537f18f880914bd4302ad28f6624325e9fb49144ccc` |
| Modern Wokefare Base | [2459720887](https://steamcommunity.com/sharedfiles/filedetails/?id=2459720887) | 3,019 | 1,078,503,018 | `2094913dc77817005ab7da4d87634cc1cbbcd9688aa24f8466f34473d4849460` |
| SWB | [1967187358](https://steamcommunity.com/sharedfiles/filedetails/?id=1967187358) | 233 | 23,745,980 | `b18e83dbca91a6c1231e68ae3e4cc44eeb2539fa3a438fac62259f62a62486d0` |
| TacRP official weapons | [3734712166](https://steamcommunity.com/sharedfiles/filedetails/?id=3734712166) | 3,282 | 463,011,248 | `4b25ee4d76cb27e823fa69f50c23bc181b64157caaa6a84f357117949cc5d68c` |

The snapshots were imported on 2026-07-28 from
`C:\Users\ameri\AppData\Local\Temp\gmpublisher`. Each directory contains
the original relative file tree, a deterministic per-file SHA-256 manifest, and
`SNAPSHOT.json` with its source directory, byte count, and manifest digest.

## Credits found in the supplied material

- TFA Base identifies The Forgotten Architect as author; YuRaNnNzZZ and
  DBotThePony as maintainers; and INCONCEIVABLE!, Generic Default, Clavus,
  Nemole/Scotch, Daniel Stevens, code_gs, Juckey, RalphORama, Iamgoofball,
  Alexander Grist-Hucker, Zombine, FlorianLeChat, Global, TheAsian EggrollMaker,
  Kris, and DaNike_ as contributors. It also credits the Inter Project Authors
  for the Inter font and Clavus for SCK-derived work.
- ARC9 is credited to Arctic, Darsu, TheOnly8Z, and its contributors. Embedded
  localization files credit their individual translators, and the source also
  thanks feusg.
- ArcCW is credited to Arctic, TheOnly8Z, Darsu, and its contributors.
- Modern Wokefare Base's supplied `addon.json` does not contain author fields.
  Attribution embedded in individual source/assets remains intact in the raw
  snapshot.
- SWB's base SWEP identifies `Spy` as its author. The supplied Workshop package
  is also associated with muscovite massacre and its contributors.
- TacRP identifies 8Z/theonly8z and contributors. Its embedded news and content
  files additionally credit speedonerd, Moka, chen, Tactical Intervention, and
  the many model, texture, sound, and animation authors listed per weapon. Those
  detailed credits remain alongside each asset in the snapshot.

## Licensing and publication statement

No standalone `LICENSE` or `COPYING` file was found in any of the six supplied
snapshot roots during import. Accordingly, this notice does not claim an
official license, transfer of copyright, endorsement, or authorship of the
third-party material. Original copyright and other rights remain with their
respective owners.

The repository owner supplied these exact local snapshots and explicitly
directed that they be included and published with this repository. This records
that direction; it is not a substitute for permission from any applicable
rightsholder. If a rightsholder identifies material that may not be published,
remove it from the active provider immediately and coordinate snapshot removal
with the repository owner while preserving the issue history and attribution
record.
