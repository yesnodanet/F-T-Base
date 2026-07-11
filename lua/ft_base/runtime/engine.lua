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

local function now()
    return CurTime and CurTime() or os.clock()
end

local function runtimeIR(runtime)
    return FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
end

local function canReload(swep, runtime)
    if not runtime or runtime.reloading then
        return false
    end

    local ir = runtimeIR(runtime)
    local clipSize = ir.ammo.clipSize or 0

    if clipSize <= 0 or not swep.Clip1 or swep:Clip1() >= clipSize then
        return false
    end

    local owner = ownerOf(swep)

    if not isValidOwner(owner) then
        return false
    end

    if owner.GetAmmoCount then
        return owner:GetAmmoCount(ir.ammo.type or "SMG1") > 0
    end

    return true
end

local function manualReload(swep, owner, ir)
    if not SERVER or not swep.SetClip1 or not owner.GetAmmoCount or not owner.RemoveAmmo then
        return false
    end

    local clip = swep.Clip1 and swep:Clip1() or 0
    local needed = math.max(0, (ir.ammo.clipSize or 0) - clip)
    local available = owner:GetAmmoCount(ir.ammo.type or "SMG1")
    local amount = math.min(needed, available)

    if amount <= 0 then
        return false
    end

    swep:SetClip1(clip + amount)
    owner:RemoveAmmo(amount, ir.ammo.type or "SMG1")
    return true
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
        nextPrimaryFire = 0,
        reloadEnds = 0,
        aimFraction = 0
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

    local currentTime = now()

    if runtime.reloading or currentTime < (runtime.nextPrimaryFire or 0) then
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

    local ir = runtimeIR(runtime)
    local shotId = FTBase.Runtime.Prediction.NextShotId(runtime)
    local seed = FTBase.Runtime.Prediction.Seed(owner, shotId)
    local recoil = FTBase.Runtime.Recoil.Next(ir, runtime.recoil, seed)

    if swep.TakePrimaryAmmo then
        swep:TakePrimaryAmmo(1)
    end

    FTBase.Runtime.Sound.Fire(swep, ir)
    FTBase.Runtime.Ballistics.Fire(swep, owner, ir, runtime)
    FTBase.Runtime.Recoil.Apply(owner, recoil)
    FTBase.Runtime.Camera.AddImpulse(runtime.camera, recoil, ir.camera)
    FTBase.Runtime.Effects.Muzzle(swep, ir)
    FTBase.Runtime.Animation.Play(swep, runtime, "fire")

    runtime.nextPrimaryFire = now() + (ir.fire.delay or 0.1)

    if swep.SetNextPrimaryFire then
        swep:SetNextPrimaryFire(runtime.nextPrimaryFire)
    end
end

function Engine.Reload(swep)
    local runtime = Engine.EnsureRuntime(swep)

    if not canReload(swep, runtime) then
        return false
    end

    local ir = runtimeIR(runtime)
    local owner = ownerOf(swep)

    runtime.reloading = true
    FTBase.Runtime.Sound.Reload(swep, ir, "reload")
    FTBase.Runtime.Animation.Play(swep, runtime, "reload")

    local performed = false

    if swep.DefaultReload and ACT_VM_RELOAD then
        performed = swep:DefaultReload(ACT_VM_RELOAD) and true or false
    end

    if not performed then
        manualReload(swep, owner, ir)
    end

    runtime.reloadEnds = now() + FTBase.Runtime.Animation.GetReloadDuration(swep, runtime)
    runtime.nextPrimaryFire = runtime.reloadEnds

    if swep.SetNextPrimaryFire then
        swep:SetNextPrimaryFire(runtime.nextPrimaryFire)
    end

    return true
end

function Engine.Think(swep)
    local runtime = Engine.EnsureRuntime(swep)
    local dt = FrameTime and FrameTime() or 0.016
    local ir = runtimeIR(runtime)
    local targetAim = runtime.aiming and 1 or 0
    local aimRate = math.max(1, (ir.ads.speed or 1) * 8)

    FTBase.Runtime.Recoil.Decay(runtime.recoil, dt)
    FTBase.Runtime.Camera.Update(runtime.camera, dt, ir.camera)

    runtime.aimFraction = FTBase.Util.Math.Lerp(math.min(1, dt * aimRate), runtime.aimFraction or 0, targetAim)

    if runtime.reloading and now() >= (runtime.reloadEnds or 0) then
        runtime.reloading = false
    end
end

function Engine.SecondaryAttack(swep)
    local runtime = Engine.EnsureRuntime(swep)

    local owner = ownerOf(swep)

    if owner and owner.KeyDown and IN_USE and owner:KeyDown(IN_USE) then
        if CLIENT and FTBase.Runtime.Inspect then
            FTBase.Runtime.Inspect.Toggle(swep)
        end

        return
    end

    runtime.aiming = not runtime.aiming

    if swep.SetNextSecondaryFire then
        swep:SetNextSecondaryFire(now() + 0.15)
    end
end

FTBase.Runtime.Engine = Engine
