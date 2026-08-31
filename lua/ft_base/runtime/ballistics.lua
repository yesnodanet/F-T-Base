FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local projectileState = FTBase.Runtime.ProjectileCounterState or {
    count = 0,
    byOwner = setmetatable({}, {__mode = "k"})
}

FTBase.Runtime.ProjectileCounterState = projectileState

local Ballistics = FTBase.Module.Define("Ballistics", {
    ProjectileTTL = 10,
    MaxProjectilesPerOwner = 64,
    MaxProjectilesGlobal = 512,
    ActiveProjectileCount = projectileState.count,
    ActiveProjectilesByOwner = projectileState.byOwner
})

local function syncProjectileState()
    projectileState.count = Ballistics.ActiveProjectileCount or 0
    projectileState.byOwner = Ballistics.ActiveProjectilesByOwner or setmetatable({}, {__mode = "k"})
    Ballistics.ActiveProjectilesByOwner = projectileState.byOwner
end

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

function Ballistics.DamageAtDistance(ir, distance, hitgroup)
    local damage = damageAtDistance(ir, distance or 0)

    if hitgroup ~= nil then
        damage = damage * hitgroupScale(ir, hitgroup)
    end

    return damage
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
        return false
    end

    owner:FireBullets(Ballistics.BuildBullet(swep, owner, ir, runtime))
    return true
end

function Ballistics.CanSpawnProjectile(owner)
    syncProjectileState()

    if Ballistics.ActiveProjectileCount >= Ballistics.MaxProjectilesGlobal then
        return false, "Global projectile limit reached"
    end

    if owner and (Ballistics.ActiveProjectilesByOwner[owner] or 0) >= Ballistics.MaxProjectilesPerOwner then
        return false, "Owner projectile limit reached"
    end

    return true
end

function Ballistics.RegisterProjectile(entity, owner)
    if not entity or entity.FTProjectileCounted then
        return false
    end

    local allowed = Ballistics.CanSpawnProjectile(owner)

    if not allowed then
        return false
    end

    entity.FTProjectileCounted = true
    entity.FTProjectileCountOwner = owner
    Ballistics.ActiveProjectileCount = Ballistics.ActiveProjectileCount + 1

    if owner then
        Ballistics.ActiveProjectilesByOwner[owner] = (Ballistics.ActiveProjectilesByOwner[owner] or 0) + 1
    end

    syncProjectileState()

    return true
end


function Ballistics.ReleaseProjectile(entity)
    if not entity or not entity.FTProjectileCounted then
        return
    end

    entity.FTProjectileCounted = false
    Ballistics.ActiveProjectileCount = math.max(0, Ballistics.ActiveProjectileCount - 1)

    local owner = entity.FTProjectileCountOwner

    if owner then
        local count = math.max(0, (Ballistics.ActiveProjectilesByOwner[owner] or 0) - 1)
        Ballistics.ActiveProjectilesByOwner[owner] = count > 0 and count or nil
    end

    entity.FTProjectileCountOwner = nil
    syncProjectileState()
end

function Ballistics.FireProjectile(swep, owner, ir)
    if not SERVER then
        return true
    end

    if not ents or not owner then
        return false
    end

    local velocity = tonumber(ir.ballistics.muzzleVelocity)

    if not velocity or velocity <= 0 then
        return false
    end

    local allowed = Ballistics.CanSpawnProjectile(owner)

    if not allowed then
        return false
    end

    local entity = ents.Create("ft_base_projectile")

    if not IsValid or not IsValid(entity) then
        return false
    end

    local source = ownerShootPos(owner)
    local direction = ownerAimVector(owner)
    local projectile = ir.physics and ir.physics.projectile or {}

    if not source or not direction then
        entity:Remove()
        return false
    end

    entity.FTProjectileIR = ir
    entity.FTProjectileWeapon = swep
    entity.FTProjectileSource = source
    entity.FTProjectileDamage = ir.damage.base or 0
    entity.FTProjectileTTL = Ballistics.ProjectileTTL
    entity.FTProjectileModel = projectile.model or "models/Items/AR2_Grenade.mdl"
    entity.FTProjectileGravity = tonumber(ir.ballistics.gravity) or 0
    entity.FTProjectileDrag = tonumber(ir.ballistics.drag) or 0
    entity:SetOwner(owner)

    if entity.SetCreator then
        entity:SetCreator(owner)
    end

    -- Start just beyond the muzzle so the projectile cannot immediately hit
    -- the shooter's own hull before its collision filter takes effect.
    local spawnPosition = source

    if source and direction then
        local ok, offset = pcall(function()
            return source + direction * 12
        end)

        if ok and offset then
            spawnPosition = offset
        end
    end

    entity:SetPos(spawnPosition)

    if direction and direction.Angle then
        entity:SetAngles(direction:Angle())
    elseif owner.EyeAngles then
        entity:SetAngles(owner:EyeAngles())
    end

    entity:Spawn()

    if entity.Activate then
        entity:Activate()
    end

    local physics = entity.GetPhysicsObject and entity:GetPhysicsObject() or nil

    if (IsValid and not IsValid(physics)) or (not IsValid and not physics) then
        entity:Remove()
        return false
    end

    if not Ballistics.RegisterProjectile(entity, owner) then
        entity:Remove()
        return false
    end

    if entity.Launch then
        if entity:Launch(direction * velocity) == false then
            entity:Remove()
            return false
        end
    else
        local physics = entity:GetPhysicsObject()

        if IsValid and IsValid(physics) or (not IsValid and physics) then
            physics:SetVelocity(direction * velocity)
        else
            entity:Remove()
            return false
        end
    end

    return entity
end

function Ballistics.Fire(swep, owner, ir, runtime)
    local mode = ir.ballistics.mode or "hitscan"

    if mode == "projectile" then
        return Ballistics.FireProjectile(swep, owner, ir)
    end

    if mode == "hybrid" and (tonumber(ir.ballistics.muzzleVelocity) or 0) > 0 then
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
