FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Ballistics = FTBase.Module.Define("Ballistics", {})

local function ownerAimVector(owner)
    if owner and owner.GetAimVector then
        return owner:GetAimVector()
    end

    if Vector then
        return Vector(1, 0, 0)
    end

    return nil
end

local function ownerShootPos(owner)
    if owner and owner.GetShootPos then
        return owner:GetShootPos()
    end

    if Vector then
        return Vector(0, 0, 0)
    end

    return nil
end

local function damageAtDistance(ir, distance)
    local curve = ir.damage.curve or {}
    local ballisticCurve = ir.ballistics.damageCurve or {}
    local maximumRange = curve.maxRange or curve.range or ballisticCurve.maxRange or ballisticCurve.range
    local minimum = ir.damage.minimum or ir.damage.base or 0

    if type(maximumRange) ~= "number" or maximumRange <= 0 then
        return ir.damage.base or 0
    end

    local fraction = math.min(1, math.max(0, distance / maximumRange))
    return (ir.damage.base or 0) + (minimum - (ir.damage.base or 0)) * fraction
end

local function hitgroupScale(ir, hitgroup)
    local hitgroups = ir.damage.hitgroups or {}
    local scale = hitgroups[hitgroup]

    if scale == nil and HITGROUP_HEAD and hitgroup == HITGROUP_HEAD then
        scale = hitgroups.head
    end

    return tonumber(scale) or 1
end

function Ballistics.BuildBullet(swep, owner, ir, runtime)
    local source = ownerShootPos(owner)
    local spread = runtime and runtime.aiming and ir.spread.ads or ir.spread.hip

    return {
        Num = ir.ballistics.pellets or 1,
        Src = source,
        Dir = ownerAimVector(owner),
        Spread = Vector and Vector(spread or 0, spread or 0, 0) or nil,
        Tracer = 1,
        TracerName = ir.effects.tracer,
        Force = (ir.damage.base or 0) * 0.5,
        Damage = ir.damage.base or 0,
        AmmoType = ir.ammo.type,
        Callback = function(attacker, trace, damageInfo)
            if damageInfo and damageInfo.SetDamage and trace and trace.HitPos and source and source.Distance then
                local damage = damageAtDistance(ir, source:Distance(trace.HitPos))
                damageInfo:SetDamage(damage * hitgroupScale(ir, trace.HitGroup))
            end

            FTBase.Runtime.Effects.Impact(ir, trace)
        end
    }
end

function Ballistics.FireHitscan(swep, owner, ir, runtime)
    if not owner or not owner.FireBullets then
        return
    end

    owner:FireBullets(Ballistics.BuildBullet(swep, owner, ir, runtime))
end

function Ballistics.FireProjectile(swep, owner, ir)
    if not SERVER or not ents or not owner then
        return Ballistics.FireHitscan(swep, owner, ir)
    end

    local entity = ents.Create("prop_physics")

    if not IsValid(entity) then
        return Ballistics.FireHitscan(swep, owner, ir)
    end

    entity:SetModel("models/Items/AR2_Grenade.mdl")
    entity:SetPos(ownerShootPos(owner))
    entity:SetAngles(owner:EyeAngles())
    entity:Spawn()

    local velocity = ir.ballistics.muzzleVelocity or 4000
    local physics = entity:GetPhysicsObject()

    if IsValid(physics) then
        physics:SetVelocity(ownerAimVector(owner) * velocity)
    end
end

function Ballistics.Fire(swep, owner, ir, runtime)
    local mode = ir.ballistics.mode or "hitscan"

    if mode == "projectile" then
        return Ballistics.FireProjectile(swep, owner, ir)
    end

    if mode == "hybrid" and (ir.ballistics.muzzleVelocity or 0) > 0 then
        return Ballistics.FireProjectile(swep, owner, ir)
    end

    return Ballistics.FireHitscan(swep, owner, ir, runtime)
end

function Ballistics.ResolveMaterial(ir, material)
    local response = ir.ballistics.materialResponses and ir.ballistics.materialResponses[material]

    if response then
        return response
    end

    return {
        penetrationScale = 1,
        ricochetScale = 1,
        damageScale = 1
    }
end

FTBase.Runtime.Ballistics = Ballistics
