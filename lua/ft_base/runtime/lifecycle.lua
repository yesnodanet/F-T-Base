FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Lifecycle = FTBase.Module.Define("Lifecycle", {})

local function configureSWEP(swep, ir)
    swep.Primary = swep.Primary or {}
    swep.Primary.ClipSize = ir.ammo.clipSize or swep.Primary.ClipSize
    swep.Primary.DefaultClip = ir.ammo.defaultClip or swep.Primary.DefaultClip
    swep.Primary.Automatic = ir.fire.automatic and true or false
    swep.Primary.Ammo = ir.ammo.type or swep.Primary.Ammo
    swep.DrawAmmo = ir.ui.drawAmmo ~= false

    if ir.meta.printName and ir.meta.printName ~= "" then
        swep.PrintName = ir.meta.printName
    end

    if ir.meta.category and ir.meta.category ~= "" then
        swep.Category = ir.meta.category
    end
end

function Lifecycle.ApplyConfig(swep, ir)
    configureSWEP(swep, ir)
end

function Lifecycle.PrepareDefinition(swep)
    if not swep or not swep.FTSource then
        return nil
    end

    local result = FTBase.Compiler.CompileSource(swep.FTSource, {
        name = swep.ClassName or swep.PrintName or "weapon_definition",
        imports = swep.FTImports
    })

    if not result.report:HasErrors() then
        configureSWEP(swep, result.ir)
    end

    return result
end

function Lifecycle.Compile(swep)
    local result = FTBase.Compiler.CompileWeapon(swep)

    swep.FTCompileResult = result
    swep.FTIR = result.ir
    swep.FTCompileFailed = result.report and result.report:HasErrors() or false

    return result
end

function Lifecycle.Initialize(swep)
    if not swep then
        return false
    end

    if swep.FTCompileFailed and swep.FTCompileResult then
        swep.FTRuntime = nil
        return false
    end

    local result = swep.FTCompileResult or Lifecycle.Compile(swep)

    if not result or not result.ir or not result.report or result.report:HasErrors() then
        swep.FTCompileFailed = true
        swep.FTRuntime = nil
        return false
    end

    swep.FTCompileFailed = false
    configureSWEP(swep, result.ir)
    FTBase.Runtime.Engine.AttachSWEP(swep, result.ir, result.report)

    if swep.SetHoldType then
        swep:SetHoldType(FTBase.Runtime.Rendering.GetHoldType(result.ir))
    end

    return swep.FTRuntime ~= nil
end

function Lifecycle.Deploy(swep)
    if not swep.FTRuntime then
        if not Lifecycle.Initialize(swep) then
            return false
        end
    end

    FTBase.Runtime.Animation.Play(swep, swep.FTRuntime, "deploy")

    if SERVER and FTBase.Runtime.Networking then
        FTBase.Runtime.Networking.SendAttachmentState(swep)
    end

    return true
end

function Lifecycle.Holster(swep)
    if swep.FTRuntime then
        swep.FTRuntime.aiming = false
        swep.FTRuntime.reloading = false
    end

    if CLIENT and FTBase.Runtime.Inspect then
        FTBase.Runtime.Inspect.Close(swep)
    end

    return true
end

function Lifecycle.Remove(swep)
    if CLIENT and FTBase.Runtime.Inspect then
        FTBase.Runtime.Inspect.Close(swep)
    end

    if CLIENT and swep and swep.FTRuntime and FTBase.Runtime.AttachmentVisuals then
        FTBase.Runtime.AttachmentVisuals.Cleanup(swep.FTRuntime)
    end
end

FTBase.Runtime.Lifecycle = Lifecycle
