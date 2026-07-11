FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Rendering = FTBase.Module.Define("Rendering", {})

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
