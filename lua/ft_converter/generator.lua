FTConverter = FTConverter or {}

local Generator = {}

local Path = FTBase.Util.Path

local function firstFireSound(ir)
    local layer = ir.sounds.fire.layers and ir.sounds.fire.layers[1]

    if type(layer) == "table" then
        return layer.sound
    end

    return layer
end

local function add(assignments, path, value)
    if value ~= nil then
        assignments[#assignments + 1] = {
            path = path,
            value = value
        }
    end
end

local function addCommon(assignments, prefix, ir)
    add(assignments, prefix .. ".PrintName", ir.meta.printName)
    add(assignments, prefix .. ".Category", ir.meta.category)
    add(assignments, prefix .. ".ViewModel", ir.rendering.viewModel)
    add(assignments, prefix .. ".WorldModel", ir.rendering.worldModel)
end

function Generator.ToFT(ir)
    local assignments = {}

    add(assignments, "FT.Meta.PrintName", ir.meta.printName)
    add(assignments, "FT.Meta.Category", ir.meta.category)
    add(assignments, "FT.Damage.Base", ir.damage.base)
    add(assignments, "FT.Damage.Minimum", ir.damage.minimum)
    add(assignments, "FT.Fire.RPM", ir.fire.rpm)
    add(assignments, "FT.Fire.Modes", ir.fire.modes)
    add(assignments, "FT.Ammo.ClipSize", ir.ammo.clipSize)
    add(assignments, "FT.Ammo.DefaultClip", ir.ammo.defaultClip)
    add(assignments, "FT.Ammo.Type", ir.ammo.type)
    add(assignments, "FT.Spread.Hip", ir.spread.hip)
    add(assignments, "FT.Spread.ADS", ir.spread.ads)
    add(assignments, "FT.Ballistics.Mode", ir.ballistics.mode)
    add(assignments, "FT.Ballistics.Penetration", ir.ballistics.penetration)
    add(assignments, "FT.Recoil.Pattern", ir.recoil.pattern)
    add(assignments, "FT.Camera.Shake", ir.camera.shake)
    add(assignments, "FT.Camera.Sway", ir.camera.sway)
    add(assignments, "FT.Sounds.Fire.Layers", ir.sounds.fire.layers)
    add(assignments, "FT.Attachments.Slots", ir.attachments.slots)

    return assignments
end

function Generator.ToTFA(ir)
    local assignments = {}

    addCommon(assignments, "TFA", ir)
    add(assignments, "TFA.Primary.Damage", ir.damage.base)
    add(assignments, "TFA.Primary.NumShots", ir.ballistics.pellets)
    add(assignments, "TFA.Primary.Cone", ir.spread.hip)
    add(assignments, "TFA.Primary.IronAccuracy", ir.spread.ads)
    add(assignments, "TFA.Primary.RPM", ir.fire.rpm)
    add(assignments, "TFA.Primary.Automatic", ir.fire.automatic)
    add(assignments, "TFA.Primary.ClipSize", ir.ammo.clipSize)
    add(assignments, "TFA.Primary.DefaultClip", ir.ammo.defaultClip)
    add(assignments, "TFA.Primary.Ammo", ir.ammo.type)
    add(assignments, "TFA.Primary.Sound", firstFireSound(ir))
    add(assignments, "TFA.RecoilInstructions", ir.recoil.pattern)
    add(assignments, "TFA.MuzzleFlashEffect", ir.effects.muzzle)

    return assignments
end

function Generator.ToARC9(ir)
    local assignments = {}

    addCommon(assignments, "ARC9", ir)
    add(assignments, "ARC9.DamageMax", ir.damage.base)
    add(assignments, "ARC9.DamageMin", ir.damage.minimum)
    add(assignments, "ARC9.Num", ir.ballistics.pellets)
    add(assignments, "ARC9.PhysBulletMuzzleVelocity", ir.ballistics.muzzleVelocity)
    add(assignments, "ARC9.Penetration", Path.Get(ir, "ballistics.penetration.power"))
    add(assignments, "ARC9.RPM", ir.fire.rpm)
    add(assignments, "ARC9.ClipSize", ir.ammo.clipSize)
    add(assignments, "ARC9.Ammo", ir.ammo.type)
    add(assignments, "ARC9.Spread", ir.spread.hip)
    add(assignments, "ARC9.Recoil.Up", Path.Get(ir, "recoil.procedural.vertical"))
    add(assignments, "ARC9.Recoil.Side", Path.Get(ir, "recoil.procedural.horizontal"))
    add(assignments, "ARC9.Recoil.Pattern", ir.recoil.pattern)
    add(assignments, "ARC9.ShootSound", firstFireSound(ir))
    add(assignments, "ARC9.DistantShootSound", ir.sounds.fire.distant)
    add(assignments, "ARC9.Attachments", ir.attachments.slots)

    return assignments
end

function Generator.ToArcCW(ir)
    local assignments = {}

    addCommon(assignments, "ArcCW", ir)
    add(assignments, "ArcCW.Damage", ir.damage.base)
    add(assignments, "ArcCW.DamageMin", ir.damage.minimum)
    add(assignments, "ArcCW.Num", ir.ballistics.pellets)
    add(assignments, "ArcCW.Penetration", Path.Get(ir, "ballistics.penetration.power"))
    add(assignments, "ArcCW.RPM", ir.fire.rpm)
    add(assignments, "ArcCW.Primary.ClipSize", ir.ammo.clipSize)
    add(assignments, "ArcCW.Primary.Ammo", ir.ammo.type)
    add(assignments, "ArcCW.Dispersion", ir.spread.hip)
    add(assignments, "ArcCW.Recoil", ir.recoil.scalar)
    add(assignments, "ArcCW.ShootSound", firstFireSound(ir))
    add(assignments, "ArcCW.Attachments", ir.attachments.slots)

    return assignments
end

function Generator.ToMW(ir)
    local assignments = {}

    addCommon(assignments, "MW", ir)
    add(assignments, "MW.Damage", ir.damage.base)
    add(assignments, "MW.DamageMin", ir.damage.minimum)
    add(assignments, "MW.Penetration", Path.Get(ir, "ballistics.penetration.power"))
    add(assignments, "MW.RPM", ir.fire.rpm)
    add(assignments, "MW.ClipSize", ir.ammo.clipSize)
    add(assignments, "MW.Ammo", ir.ammo.type)
    add(assignments, "MW.Spread", ir.spread.hip)
    add(assignments, "MW.Recoil.Vertical", Path.Get(ir, "recoil.procedural.vertical"))
    add(assignments, "MW.Recoil.Horizontal", Path.Get(ir, "recoil.procedural.horizontal"))
    add(assignments, "MW.Recoil.Pattern", ir.recoil.pattern)
    add(assignments, "MW.Camera.Shake", ir.camera.shake)
    add(assignments, "MW.Camera.Sway", ir.camera.sway)
    add(assignments, "MW.Sound.Fire", firstFireSound(ir))
    add(assignments, "MW.Attachments", ir.attachments.slots)

    return assignments
end

function Generator.ToTacRP(ir)
    local assignments = {}

    addCommon(assignments, "TacRP", ir)
    add(assignments, "TacRP.Damage_Max", ir.damage.base)
    add(assignments, "TacRP.Damage_Min", ir.damage.minimum)
    add(assignments, "TacRP.Num", ir.ballistics.pellets)
    add(assignments, "TacRP.Penetration", Path.Get(ir, "ballistics.penetration.power"))
    add(assignments, "TacRP.RPM", ir.fire.rpm)
    add(assignments, "TacRP.ClipSize", ir.ammo.clipSize)
    add(assignments, "TacRP.Ammo", ir.ammo.type)
    add(assignments, "TacRP.Spread", ir.spread.hip)
    add(assignments, "TacRP.RecoilKick", Path.Get(ir, "recoil.procedural.vertical"))
    add(assignments, "TacRP.FreeAimAngle", Path.Get(ir, "camera.freeAim.radius"))
    add(assignments, "TacRP.BlindFire", Path.Get(ir, "movement.blindFire"))
    add(assignments, "TacRP.Sound_Shoot", firstFireSound(ir))
    add(assignments, "TacRP.Attachments", ir.attachments.slots)

    return assignments
end

function Generator.ToSWB(ir)
    local assignments = {}

    addCommon(assignments, "SWB", ir)
    add(assignments, "SWB.Damage", ir.damage.base)
    add(assignments, "SWB.NumShots", ir.ballistics.pellets)
    add(assignments, "SWB.FireDelay", ir.fire.delay)
    add(assignments, "SWB.Automatic", ir.fire.automatic)
    add(assignments, "SWB.ClipSize", ir.ammo.clipSize)
    add(assignments, "SWB.Ammo", ir.ammo.type)
    add(assignments, "SWB.HipSpread", ir.spread.hip)
    add(assignments, "SWB.AimSpread", ir.spread.ads)
    add(assignments, "SWB.Recoil", ir.recoil.scalar)
    add(assignments, "SWB.RecoilPattern", ir.recoil.pattern)
    add(assignments, "SWB.FireSound", firstFireSound(ir))
    add(assignments, "SWB.Attachments", ir.attachments.slots)

    return assignments
end

function Generator.Generate(ir, targetStyle, report)
    local normalized = string.lower(tostring(targetStyle or "FT"))
    local method = nil

    if normalized == "ft" or normalized == "f&t" then
        method = Generator.ToFT
    elseif normalized == "tfa" then
        method = Generator.ToTFA
    elseif normalized == "arc9" then
        method = Generator.ToARC9
    elseif normalized == "arccw" or normalized == "arcw" then
        method = Generator.ToArcCW
    elseif normalized == "mw" or normalized == "mwbase" or normalized == "mw base" then
        method = Generator.ToMW
    elseif normalized == "tacrp" then
        method = Generator.ToTacRP
    elseif normalized == "swb" then
        method = Generator.ToSWB
    end

    if not method then
        if report then
            report:AddError("Unknown converter target '" .. tostring(targetStyle) .. "'")
        end

        return ""
    end

    local assignments = method(ir)

    if report and #ir.recoil.pattern > 0 and normalized ~= "ft" then
        report:AddWarning("Target " .. tostring(targetStyle) .. " may not express the full precision recoil metadata")
    end

    return FTBase.Compiler.Emitter.EmitAssignments(assignments)
end

FTConverter.Generator = Generator
