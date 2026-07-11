FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Lifecycle = FTBase.Module.Define("Lifecycle", {})

function Lifecycle.Compile(swep)
    local result = FTBase.Compiler.CompileWeapon(swep)

    swep.FTCompileResult = result
    swep.FTIR = result.ir

    return result
end

function Lifecycle.Initialize(swep)
    local result = swep.FTCompileResult or Lifecycle.Compile(swep)

    FTBase.Runtime.Engine.AttachSWEP(swep, result.ir, result.report)

    if swep.SetHoldType then
        swep:SetHoldType(FTBase.Runtime.Rendering.GetHoldType(result.ir))
    end
end

function Lifecycle.Deploy(swep)
    if not swep.FTRuntime then
        Lifecycle.Initialize(swep)
    end

    FTBase.Runtime.Animation.Play(swep, swep.FTRuntime, "deploy")
    return true
end

function Lifecycle.Holster(swep)
    return true
end

FTBase.Runtime.Lifecycle = Lifecycle
