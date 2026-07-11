FTBase = FTBase or {}

local FT = FTBase

FT.Name = "F&T Base"
FT.Version = "0.1.0"
FT.BootedAt = os.time()

local function includeShared(path)
    if SERVER then
        AddCSLuaFile(path)
    end

    return include(path)
end

FT.IncludeShared = includeShared

local files = {
    "ft_base/util/table.lua",
    "ft_base/util/path.lua",
    "ft_base/util/math.lua",

    "ft_base/core/report.lua",
    "ft_base/core/ir.lua",
    "ft_base/core/merge.lua",
    "ft_base/core/schema.lua",
    "ft_base/core/validator.lua",
    "ft_base/core/optimizer.lua",
    "ft_base/core/module.lua",
    "ft_base/core/plugin.lua",
    "ft_base/core/weapon_registry.lua",

    "ft_base/compiler/lexer.lua",
    "ft_base/compiler/parser.lua",
    "ft_base/compiler/resolver.lua",
    "ft_base/compiler/compiler.lua",
    "ft_base/compiler/emitter.lua",

    "ft_base/adapters/base.lua",
    "ft_base/adapters/ft.lua",
    "ft_base/adapters/tfa.lua",
    "ft_base/adapters/arc9.lua",
    "ft_base/adapters/arccw.lua",
    "ft_base/adapters/mw.lua",
    "ft_base/adapters/tacrp.lua",
    "ft_base/adapters/swb.lua",

    "ft_base/runtime/profiler.lua",
    "ft_base/runtime/debug.lua",
    "ft_base/runtime/prediction.lua",
    "ft_base/runtime/networking.lua",
    "ft_base/runtime/lifecycle.lua",
    "ft_base/runtime/ballistics.lua",
    "ft_base/runtime/recoil.lua",
    "ft_base/runtime/camera.lua",
    "ft_base/runtime/animation.lua",
    "ft_base/runtime/attachments.lua",
    "ft_base/runtime/sound.lua",
    "ft_base/runtime/movement.lua",
    "ft_base/runtime/effects.lua",
    "ft_base/runtime/rendering.lua",
    "ft_base/runtime/npc.lua",
    "ft_base/runtime/vehicles.lua",
    "ft_base/runtime/physics.lua",
    "ft_base/runtime/customization.lua",
    "ft_base/runtime/devtools.lua",
    "ft_base/runtime/engine.lua",

    "ft_converter/generator.lua",
    "ft_converter/converter.lua"
}

for _, path in ipairs(files) do
    includeShared(path)
end

if FT.Compiler and FT.Compiler.RegisterDefaultAdapters then
    FT.Compiler.RegisterDefaultAdapters()
end

FT.Booted = true
