# Dedicated Test Server

The visual smoke test uses the dedicated server at:

```text
D:\CMD_STEAM\steamapps\common\GarrysModDS\garrysmod
```

Deploy this repository as `garrysmod/addons/ft_base_visual_test`, copy
`tools/server/ft_base_test.cfg` to `garrysmod/cfg/`, then start:

```text
srcds.exe -console -condebug -game garrysmod +servercfgfile ft_base_test.cfg +map gm_construct +maxplayers 1
```

The local connection and RCON password is `ft_base_visual_test`. Source loads
the server config after mounting addons, so it runs the smoke, compiler, and
runtime regression suites against the active map. Change both
`sv_password` and `rcon_password` before making the server reachable outside the
local network. The server does not mount
TFA, ARC9, ArcCW, MW, SWB, or TacRP; this verifies that visual providers have no
external runtime dependency. Connect a local GMod client and spawn each
`ft_template_*` weapon to review HUD, inspect, and attachment UI.

To rerun the smoke test without restarting, execute `exec ft_base_test.cfg`
through local Source RCON.

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
npm run test:gmod
```

The dedicated command deploys `lua` and `tools` to
`garrysmod/addons/ft_base_visual_test` before startup. Set `FT_BASE_GMOD_ADDON_ROOT` when
a different test-addon directory is required.
