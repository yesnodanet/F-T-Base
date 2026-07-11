FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Engine = FTBase.Module.Define("WeaponEngine", {})

local function ownerOf(swep)
    if swep and swep.GetOwner then
        return swep:GetOwner()
    end

    return nil
end

local function isValidOwner(owner)
    if IsValid then
        return IsValid(owner)
    end

    return owner ~= nil
end

function Engine.BuildRuntime(swep, ir, report)
    local runtime = {
        swep = swep,
        ir = FTBase.IR.Clone(ir),
        report = report,
        profiler = FTBase.Runtime.Profiler.New(),
        recoil = FTBase.Runtime.Recoil.NewState(ir),
        camera = FTBase.Runtime.Camera.NewState(ir),
        animation = FTBase.Runtime.Animation.NewState(ir),
        attachments = FTBase.Runtime.Attachments.NewState(ir),
        prediction = {
            shotId = 0
        },
        aiming = false,
        reloading = false,
        nextPrimaryFire = 0
    }

    FTBase.Runtime.Attachments.RebuildModifiers(runtime)
    return runtime
end

function Engine.AttachSWEP(swep, ir, report)
    swep.FTRuntime = Engine.BuildRuntime(swep, ir, report)
    FTBase.Runtime.Rendering.ApplyModels(swep, ir)
    return swep.FTRuntime
end

function Engine.EnsureRuntime(swep)
    if not swep.FTRuntime then
        FTBase.Runtime.Lifecycle.Initialize(swep)
    end

    return swep.FTRuntime
end

function Engine.CanPrimaryAttack(swep, runtime)
    if not runtime then
        return false
    end

    local now = CurTime and CurTime() or os.clock()

    if now < (runtime.nextPrimaryFire or 0) then
        return false
    end

    if swep.Clip1 and swep:Clip1() <= 0 then
        if swep.EmitSound then
            swep:EmitSound("Weapon_Pistol.Empty")
        end

        if swep.Reload then
            swep:Reload()
        end

        return false
    end

    return true
end

function Engine.PrimaryAttack(swep)
    local runtime = Engine.EnsureRuntime(swep)

    if not Engine.CanPrimaryAttack(swep, runtime) then
        return
    end

    local owner = ownerOf(swep)

    if not isValidOwner(owner) then
        return
    end

    if not FTBase.Runtime.Prediction.ShouldRun() then
        return
    end

    local shotId = FTBase.Runtime.Prediction.NextShotId(runtime)
    local seed = FTBase.Runtime.Prediction.Seed(owner, shotId)
    local recoil = FTBase.Runtime.Recoil.Next(runtime.ir, runtime.recoil, seed)

    if swep.TakePrimaryAmmo then
        swep:TakePrimaryAmmo(1)
    end

    FTBase.Runtime.Sound.Fire(swep, runtime.ir)
    FTBase.Runtime.Ballistics.Fire(swep, owner, runtime.ir)
    FTBase.Runtime.Recoil.Apply(owner, recoil)
    FTBase.Runtime.Camera.AddImpulse(runtime.camera, recoil)
    FTBase.Runtime.Effects.Muzzle(swep, runtime.ir)
    FTBase.Runtime.Animation.Play(swep, runtime, "fire")

    local now = CurTime and CurTime() or os.clock()
    runtime.nextPrimaryFire = now + (runtime.ir.fire.delay or 0.1)

    if swep.SetNextPrimaryFire then
        swep:SetNextPrimaryFire(runtime.nextPrimaryFire)
    end
end

function Engine.Reload(swep)
    local runtime = Engine.EnsureRuntime(swep)

    runtime.reloading = true
    FTBase.Runtime.Sound.Reload(swep, runtime.ir, "reload")
    FTBase.Runtime.Animation.Play(swep, runtime, "reload")

    if swep.DefaultReload and ACT_VM_RELOAD then
        swep:DefaultReload(ACT_VM_RELOAD)
    end

    runtime.reloading = false
end

function Engine.Think(swep)
    local runtime = Engine.EnsureRuntime(swep)
    local dt = FrameTime and FrameTime() or 0.016

    FTBase.Runtime.Recoil.Decay(runtime.recoil, dt)
    FTBase.Runtime.Camera.Update(runtime.camera, dt)
end

function Engine.SecondaryAttack(swep)
    local runtime = Engine.EnsureRuntime(swep)
    runtime.aiming = not runtime.aiming
end

FTBase.Runtime.Engine = Engine
