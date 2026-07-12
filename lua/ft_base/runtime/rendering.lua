FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Rendering = FTBase.Module.Define("Rendering", {})

local function vectorOrNil(value)
    value = FTBase.Util.Types.Vector(value)

    if not value then
        return nil
    end

    if isvector then
        return isvector(value) and value or nil
    end

    return type(value) ~= "table" and value or nil
end

local function angleOrNil(value)
    value = FTBase.Util.Types.Angle(value)

    if not value then
        return nil
    end

    if isangle then
        return isangle(value) and value or nil
    end

    return type(value) ~= "table" and value or nil
end

function Rendering.GetAimPose(ir)
    local ads = ir and ir.ads or {}
    local position = vectorOrNil(ads.pos)
    local angle = angleOrNil(ads.ang)

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
