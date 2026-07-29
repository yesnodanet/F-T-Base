# Dedicated Test Server

The visual smoke test uses the dedicated server at:

```text
D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod
```

Deploy this repository as `garrysmod/addons/ft_base_visual_test`, copy the
matching test config to `garrysmod/cfg/`, then start:

```text
srcds.exe -console -condebug -game garrysmod +servercfgfile ft_base_test.cfg +map gm_construct +maxplayers 1
```

The local connection and RCON password is `ft_base_visual_test`. Source loads
the server config after mounting addons, so it runs the smoke, compiler,
compatibility, and runtime regression suites against the active map. Change both
`sv_password` and `rcon_password` before making the server reachable outside the
local network. The server does not mount
TFA, ARC9, ArcCW, MW, SWB, or TacRP; this verifies that visual providers have no
external runtime dependency. Connect a local GMod client and spawn each
`ft_template_*` weapon to review HUD, inspect, and attachment UI.

To rerun the smoke test without restarting, execute `exec ft_base_test.cfg`
through local Source RCON.

## Native template mode

Native fixtures intentionally inherit the external sample SWEP and therefore
require the matching base and Workshop sample addon on both server and client.
Install the prepared snapshots into isolated addon folders, clean the previous
F&T test/native folders, and run the native suite with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/server/install_native_dependencies.ps1 `
  -ServerRoot "D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod" `
  -SourceRoot "C:\Users\ameri\AppData\Local\Temp\gmpublisher\bases" `
  -Clean

$env:GARRYSMOD_SERVER_ROOT = "D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod"
npm.cmd run test:gmod -- -UseInstalledNativeDependencies -CleanAddon
```

Alternatively, omit the separate installer and pass
`-InstallNativeDependencies -CleanAddon` to the runner; it performs the same
validated copy before starting `srcds`. `run-gmod-tests.ps1` selects
`ft_base_native_test.cfg` for native mode. That
configuration runs `lua/ft_base/tests/native_server.lua`, which checks every
manifest dependency, verifies registration of every native template, and
creates/spawns/removes each `ft_native_template_*`. Without
`-InstallNativeDependencies`, the runner uses the dependency-free F&T config.
Only the exact `ft_base_visual_test` addon (and the `ft_native_dep_*` directories
when `-Clean` is used) is eligible for cleanup; unrelated addons are left
untouched.

## CI and headless checks

The repository's portable regression command is:

```text
npm ci
npm test
```

It parses every Lua file with Lua 5.1 grammar and runs the visual smoke test,
compiler regressions, runtime regressions, and the full converter smoke test in
a Fengari-based GMod stub. On a Windows machine with a dedicated server, run
the additional in-engine suite with:

```text
$env:GARRYSMOD_SERVER_ROOT = "D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod"
npm.cmd run test:gmod
```

The dedicated command deploys `lua` and `tools` to
`garrysmod/addons/ft_base_visual_test` before startup and removes that exact
previous test copy before copying the new tree. Set `FT_BASE_GMOD_ADDON_ROOT` when
a different test-addon directory is required; use `-CleanAddon` only for an
explicit F&T-named addon path.
