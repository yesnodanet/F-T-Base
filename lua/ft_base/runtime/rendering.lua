FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Rendering = FTBase.Module.Define("Rendering", {})

function Rendering.GetAimPose(ir)
    local ads = ir and ir.ads or {}
    local position = FTBase.Util.Types.Vector(ads.pos)
    local angle = FTBase.Util.Types.Angle(ads.ang)

    return position, angle
end

function Rendering.ApplyModels(swep, ir)
    if not swep then
        return
    end

    swep.ViewModel = ir.rendering.viewModel or swep.ViewModel
    swep.WorldModel = ir.rendering.worldModel or swep.WorldModel
    swep.UseHands = ir.rendering.useHands
end

function Rendering.GetHoldType(ir)
    return ir.rendering.holdType or "ar2"
end

FTBase.Runtime.Rendering = Rendering
