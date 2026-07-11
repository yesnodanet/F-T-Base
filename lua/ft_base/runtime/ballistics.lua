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

function Ballistics.BuildBullet(swep, owner, ir)
    return {
        Num = ir.ballistics.pellets or 1,
        Src = ownerShootPos(owner),
        Dir = ownerAimVector(owner),
        Spread = Vector and Vector(ir.spread.hip or 0, ir.spread.hip or 0, 0) or nil,
        Tracer = 1,
        TracerName = ir.effects.tracer,
        Force = (ir.damage.base or 0) * 0.5,
        Damage = ir.damage.base or 0,
        AmmoType = ir.ammo.type
    }
end

function Ballistics.FireHitscan(swep, owner, ir)
    if not owner or not owner.FireBullets then
        return
    end

    owner:FireBullets(Ballistics.BuildBullet(swep, owner, ir))
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

function Ballistics.Fire(swep, owner, ir)
    local mode = ir.ballistics.mode or "hitscan"

    if mode == "projectile" then
        return Ballistics.FireProjectile(swep, owner, ir)
    end

    if mode == "hybrid" and (ir.ballistics.muzzleVelocity or 0) > 0 then
        return Ballistics.FireProjectile(swep, owner, ir)
    end

    return Ballistics.FireHitscan(swep, owner, ir)
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
