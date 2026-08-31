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
compatibility, runtime, template, and native-template server regression suites
against the active map. Change both
`sv_password` and `rcon_password` before making the server reachable outside the
local network. No TFA, ARC9, ArcCW, MW, SWB, or TacRP addon needs to be mounted
for this run; it verifies that visual providers and all F&T weapon gameplay have
no external runtime dependency. Connect a local GMod client and spawn each
`ft_template_*` weapon to review HUD, inspect, and attachment UI.

To rerun the smoke test without restarting, execute `exec ft_base_test.cfg`
through local Source RCON.

## Native template mode

Native fixtures inherit `ft_base`, not an external sample SWEP. Their
`SWEP.FTSource`, gameplay, stats, attachment state, and networking run entirely
in F&T. The matching base/sample addon is only required on a client that should
render the vendor HUD, inspect, or customization UI. The dedicated-server suite
therefore does not require or validate vendor classes.

The normal dedicated command always includes
`lua/ft_base/tests/native_server.lua`; it verifies that all six native
templates spawn with `ft_base` and F&T runtime state while no vendor class is
required. Run it without any vendor addon directories:

```powershell
$env:GARRYSMOD_SERVER_ROOT = "D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod"
npm.cmd run test:gmod -- -CleanAddon
```

For a separate client UI pass, install the prepared snapshots into isolated
addon folders. This is optional for the server test and only prepares the
external base/sample assets for a client that joins the test server:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/server/install_native_dependencies.ps1 `
  -ServerRoot "D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod" `
  -SourceRoot "C:\Users\ameri\AppData\Local\Temp\gmpublisher\bases" `
  -Clean

```

`-InstallNativeDependencies` remains available on the runner as a convenience
for that explicit client-asset deployment. It does not change the dedicated
test config or make a vendor class a server requirement. Only the exact
`ft_base_visual_test` addon (and the `ft_native_dep_*` directories when
`-Clean` is used) is eligible for cleanup; unrelated addons are left untouched.

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
