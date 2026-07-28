-- Runtime regression checks. Run with:
-- lua_run include("ft_base/tests/runtime_regression.lua")

local function compile(name, source)
    local result = FTBase.Compiler.CompileSource(source, {name = name})
    assert(not result.report:HasErrors(), result.report:ToString())
    return result
end

local invalidSWEP = {
    FTSource = [[FT.Damage.Base = "invalid"]],
    PrintName = "Invalid F&T Regression Weapon",
    GetClass = function()
        return "ft_invalid_regression"
    end
}

assert(not FTBase.Runtime.Lifecycle.Initialize(invalidSWEP), "Invalid weapon initialized a runtime")
assert(invalidSWEP.FTCompileFailed == true, "Invalid weapon was not marked as failed")
assert(invalidSWEP.FTRuntime == nil, "Invalid weapon retained a runtime")
assert(FTBase.Runtime.Engine.EnsureRuntime(invalidSWEP) == nil, "Invalid weapon retried runtime creation")

local effective = compile("ft_effective_ir_regression", [[
FT.Ammo.ClipSize = 30
FT.Ammo.DefaultClip = 90
FT.Ammo.Type = "SMG1"
FT.Rendering.HoldType = "ar2"
FT.Attachments.Slots = {
    { id = "magazine", type = "magazine" }
}
FT.Attachments.Definitions = {
    extended_magazine = {
        type = "magazine",
        modifiers = {
            ["ammo.clipSize"] = { set = 45 },
            ["animations.reloadDuration"] = { set = 2.5 },
            ["animations.base.fire"] = { set = "fire_alt" },
            ["rendering.holdType"] = { set = "smg" },
            ["rendering.viewModel"] = { set = "models/weapons/c_smg1.mdl" },
            ["rendering.worldModel"] = { set = "models/weapons/w_smg1.mdl" }
        }
    }
}
]])

local clip = 30
local holdType = nil
local worldModel = nil
local playedAnimation = nil
local effectiveSWEP = {
    Primary = {},
    Clip1 = function()
        return clip
    end,
    SetClip1 = function(_, value)
        clip = value
    end,
    SetHoldType = function(_, value)
        holdType = value
    end,
    SetModel = function(_, value)
        worldModel = value
    end,
    LookupSequence = function(_, name)
        return name == "fire_alt" and 7 or -1
    end,
    SendWeaponAnim = function(_, sequence)
        playedAnimation = sequence
    end
}
local runtime = FTBase.Runtime.Engine.BuildRuntime(effectiveSWEP, effective.ir, effective.report)

assert(effectiveSWEP.Primary.ClipSize == 30, "Base ammo config was not applied")
assert(FTBase.Runtime.Customization.Install(runtime, "magazine", "extended_magazine"),
    "Effective attachment installation failed")
assert(FTBase.Runtime.Attachments.GetEffectiveIR(runtime).ammo.clipSize == 45,
    "Effective IR did not update ammo.clipSize")
assert(effectiveSWEP.Primary.ClipSize == 45, "Effective ammo config was not applied to SWEP")
assert(FTBase.Runtime.Animation.GetReloadDuration(nil, runtime) == 2.5,
    "Effective reload duration was not applied")
assert(holdType == "smg", "Effective hold type was not applied")
assert(effectiveSWEP.ViewModel == "models/weapons/c_smg1.mdl", "Effective view model was not applied")
assert(effectiveSWEP.WorldModel == "models/weapons/w_smg1.mdl" and worldModel == effectiveSWEP.WorldModel,
    "Effective world model was not applied")
FTBase.Runtime.Animation.Play(effectiveSWEP, runtime, "fire")
assert(playedAnimation == 7, "Effective animation map was not applied")
FTBase.Runtime.Animation.PlaySequence(effectiveSWEP, runtime, "inspect", "fire_alt")
assert(playedAnimation == 7 and runtime.animation.current == "inspect",
    "Configured inspect animation was not applied")
assert(not FTBase.Runtime.Customization.Install(runtime, "magazine", "missing_attachment"),
    "Unknown attachment id was accepted")

local visualIR = FTBase.IR.Clone(effective.ir)
visualIR.attachments.slots = {
    {id = "optic", type = "optic", default = "visual_optic"}
}
visualIR.attachments.definitions = {
    visual_optic = {
        type = "optic",
        visuals = {
            view = {
                model = "models/weapons/c_pistol.mdl",
                bone = "ValveBiped.Bip01_R_Hand",
                position = Vector(1, 2, 3),
                angle = Angle(4, 5, 6)
            },
            world = {
                model = "models/weapons/w_pistol.mdl",
                attachment = "muzzle",
                scale = 0.8
            }
        }
    }
}

local visualRuntime = FTBase.Runtime.Engine.BuildRuntime({}, visualIR, effective.report)
local viewDescriptors = FTBase.Runtime.AttachmentVisuals.GetDescriptors(visualRuntime, "view")
local worldDescriptors = FTBase.Runtime.AttachmentVisuals.GetDescriptors(visualRuntime, "world")
assert(#viewDescriptors == 1 and viewDescriptors[1].slotId == "optic",
    "View attachment visual descriptor was not built")
assert(viewDescriptors[1].model == "models/weapons/c_pistol.mdl"
    and viewDescriptors[1].bone == "ValveBiped.Bip01_R_Hand",
    "View attachment visual fields were not preserved")
assert(#worldDescriptors == 1 and worldDescriptors[1].model == "models/weapons/w_pistol.mdl"
    and worldDescriptors[1].attachment == "muzzle" and worldDescriptors[1].scale == 0.8,
    "World attachment visual fields were not preserved")
assert(FTBase.Runtime.Customization.Uninstall(visualRuntime, "optic"),
    "Visual attachment uninstall failed")
assert(#FTBase.Runtime.AttachmentVisuals.GetDescriptors(visualRuntime, "view") == 0,
    "Uninstalled attachment retained its visual descriptor")

local hiddenDefault = compile("ft_hidden_default_regression", [[
FT.Attachments.Slots = {
    { id = "optic", type = "optic", default = "hidden_optic" }
}
FT.Attachments.Definitions = {
    hidden_optic = { type = "optic", hidden = true }
}
]])
local hiddenState = FTBase.Runtime.Attachments.NewState(hiddenDefault.ir)
assert(hiddenState.installed.optic == nil, "Hidden default attachment was installed")

local vehicleIR = FTBase.IR.Clone(effective.ir)
vehicleIR.vehicles.enabled = true
vehicleIR.vehicles.allowFire = false
local vehicleRuntime = FTBase.Runtime.Engine.BuildRuntime({}, vehicleIR, effective.report)
local vehicleOwner = {
    InVehicle = function()
        return true
    end
}
assert(not FTBase.Runtime.Vehicles.CanFire(vehicleRuntime, vehicleOwner),
    "Vehicle fire restriction was ignored")

local Networking = FTBase.Runtime.Networking
local previousCurTime = CurTime
local previousIsValid = IsValid
local networkTime = 100
CurTime = function()
    return networkTime
end
IsValid = function(value)
    return value ~= nil and value ~= false
end

local networkSucceeded, networkError = pcall(function()
    local networkSWEP = {
        FTRuntime = runtime
    }
    local networkPlayer = {
        Alive = function()
            return true
        end,
        GetActiveWeapon = function()
            return networkSWEP
        end
    }
    networkSWEP.GetOwner = function()
        return networkPlayer
    end

    assert(Networking.CanRequestCustomization(networkPlayer, networkSWEP),
        "Valid customization request was rejected")
    assert(not Networking.CanRequestCustomization(networkPlayer, networkSWEP),
        "Customization cooldown was not enforced")

    networkTime = networkTime + Networking.CustomizationCooldown
    assert(Networking.CanRequestCustomization(networkPlayer, networkSWEP),
        "Customization cooldown did not expire")

    local foreignPlayer = {
        Alive = function()
            return true
        end,
        GetActiveWeapon = function()
            return networkSWEP
        end
    }
    assert(not Networking.CanRequestCustomization(foreignPlayer, networkSWEP),
        "Foreign weapon customization was accepted")

    local inactiveSWEP = {
        FTRuntime = runtime,
        GetOwner = function()
            return networkPlayer
        end
    }
    assert(not Networking.CanRequestCustomization(networkPlayer, inactiveSWEP),
        "Inactive weapon customization was accepted")

    local deadPlayer = {
        Alive = function()
            return false
        end,
        GetActiveWeapon = function()
            return networkSWEP
        end
    }
    local deadSWEP = {
        FTRuntime = runtime,
        GetOwner = function()
            return deadPlayer
        end
    }
    assert(not Networking.CanRequestCustomization(deadPlayer, deadSWEP),
        "Dead owner customization was accepted")
    assert(not Networking.IsValidAttachmentRequest(string.rep("x", Networking.MaxIdentifierLength + 1), ""),
        "Oversized attachment slot id was accepted")
    assert(not Networking.IsValidAttachmentRequest("optic", string.rep("x", Networking.MaxIdentifierLength + 1)),
        "Oversized attachment id was accepted")
end)

CurTime = previousCurTime
IsValid = previousIsValid

if not networkSucceeded then
    error(networkError, 0)
end

local Ballistics = FTBase.Runtime.Ballistics
local previousGlobalLimit = Ballistics.MaxProjectilesGlobal
local previousOwnerLimit = Ballistics.MaxProjectilesPerOwner
local previousGlobalCount = Ballistics.ActiveProjectileCount
local previousOwnerCounts = Ballistics.ActiveProjectilesByOwner

Ballistics.MaxProjectilesGlobal = 1
Ballistics.MaxProjectilesPerOwner = 1
Ballistics.ActiveProjectileCount = 0
Ballistics.ActiveProjectilesByOwner = setmetatable({}, {__mode = "k"})

local projectileOwner = {}
local projectile = {}
assert(Ballistics.RegisterProjectile(projectile, projectileOwner), "Projectile registration failed")
assert(not Ballistics.CanSpawnProjectile(projectileOwner), "Per-owner projectile limit was ignored")
Ballistics.ReleaseProjectile(projectile)
assert(Ballistics.CanSpawnProjectile(projectileOwner), "Projectile counter was not released")

Ballistics.MaxProjectilesGlobal = previousGlobalLimit
Ballistics.MaxProjectilesPerOwner = previousOwnerLimit
Ballistics.ActiveProjectileCount = previousGlobalCount
Ballistics.ActiveProjectilesByOwner = previousOwnerCounts

local cameraRuntime = {
    ir = effective.ir,
    effectiveIR = effective.ir,
    camera = FTBase.Runtime.Camera.NewState(effective.ir),
    aimFraction = 0
}
local origin = {}
local angles = {}
local returnedOrigin, returnedAngles, returnedFov = FTBase.Runtime.Camera.CalcView(
    cameraRuntime,
    nil,
    origin,
    angles,
    90
)

assert(returnedOrigin == origin and returnedAngles == angles and returnedFov == 90,
    "CalcView did not return origin, angles, and fov")

print("F&T runtime regression tests passed")
return true
