AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local function valid(entity)
    return IsValid and IsValid(entity)
end

function ENT:ShouldCollide(entity)
    local owner = self:GetOwner()

    return entity ~= owner and entity ~= self.FTProjectileWeapon
end

function ENT:Initialize()
    self:SetModel(self.FTProjectileModel or "models/Items/AR2_Grenade.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    if COLLISION_GROUP_PROJECTILE then
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    end

    self.FTExpireAt = CurTime() + (tonumber(self.FTProjectileTTL) or 10)
    self.FTLastThink = CurTime()

    local physics = self:GetPhysicsObject()

    if valid(physics) then
        physics:Wake()
        physics:EnableGravity(false)
        physics:EnableDrag(false)
    end
end

function ENT:Launch(velocity)
    local physics = self:GetPhysicsObject()

    if valid(physics) then
        physics:SetVelocity(velocity)
        return true
    end

    return false
end

function ENT:Think()
    local time = CurTime()

    if time >= (self.FTExpireAt or 0) then
        self:Remove()
        return false
    end

    local physics = self:GetPhysicsObject()

    if valid(physics) then
        local dt = math.max(0, math.min(0.1, time - (self.FTLastThink or time)))
        local velocity = physics:GetVelocity()
        local gravity = tonumber(self.FTProjectileGravity) or 0
        local drag = math.max(0, tonumber(self.FTProjectileDrag) or 0)

        if gravity ~= 0 and Vector then
            velocity = velocity + Vector(0, 0, -gravity) * dt
        end

        if drag > 0 then
            velocity = velocity * math.max(0, 1 - drag * dt)
        end

        physics:SetVelocity(velocity)

        if velocity.Angle and velocity:LengthSqr() > 1 then
            self:SetAngles(velocity:Angle())
        end
    end

    self.FTLastThink = time
    self:NextThink(time)
    return true
end

function ENT:PhysicsCollide(data)
    if self.FTProjectileImpacted then
        return
    end

    local target = data and data.HitEntity
    local owner = self:GetOwner()
    local weapon = self.FTProjectileWeapon

    if target == owner or target == weapon then
        local physics = self:GetPhysicsObject()

        if valid(physics) and data and data.OurOldVelocity then
            physics:SetVelocity(data.OurOldVelocity)
        end

        return
    end

    self.FTProjectileImpacted = true

    if valid(target) and target ~= owner and target ~= weapon and target.TakeDamageInfo and DamageInfo then
        local damage = tonumber(self.FTProjectileDamage) or 0
        local source = self.FTProjectileSource
        local hitPosition = data.HitPos or self:GetPos()

        local hitGroup = data and data.HitGroup

        if hitGroup == nil and util and util.TraceLine and source and hitPosition then
            local trace = util.TraceLine({
                start = source,
                endpos = hitPosition,
                filter = {owner, weapon, self}
            })

            if trace and trace.Entity == target then
                hitGroup = trace.HitGroup
            end
        end

        if self.FTProjectileIR and source and source.Distance
            and FTBase and FTBase.Runtime and FTBase.Runtime.Ballistics then
            damage = FTBase.Runtime.Ballistics.DamageAtDistance(
                self.FTProjectileIR,
                source:Distance(hitPosition),
                hitGroup
            )
        end

        local damageInfo = DamageInfo()
        damageInfo:SetDamage(damage)
        damageInfo:SetDamageType(DMG_BULLET or 2)
        damageInfo:SetAttacker(valid(owner) and owner or self)
        damageInfo:SetInflictor(valid(weapon) and weapon or self)

        if damageInfo.SetDamagePosition then
            damageInfo:SetDamagePosition(hitPosition)
        end

        if damageInfo.SetDamageForce and data.OurOldVelocity then
            damageInfo:SetDamageForce(data.OurOldVelocity:GetNormalized() * damage)
        end

        local dispatched = false

        if target.DispatchTraceAttack and util and util.TraceLine and source and hitPosition then
            local trace = util.TraceLine({
                start = source,
                endpos = hitPosition,
                filter = {owner, weapon, self}
            })

            if trace and trace.Entity == target then
                local direction = data and data.OurOldVelocity

                if direction and direction.GetNormalized then
                    direction = direction:GetNormalized()
                end

                target:DispatchTraceAttack(damageInfo, trace, direction)
                dispatched = true
            end
        end

        if not dispatched then
            target:TakeDamageInfo(damageInfo)
        end
    end

    if self.FTProjectileIR and FTBase and FTBase.Runtime and FTBase.Runtime.Effects then
        FTBase.Runtime.Effects.Impact(self.FTProjectileIR, {
            HitPos = data and data.HitPos or self:GetPos(),
            HitEntity = target
        })
    end

    self:Remove()
end

function ENT:OnRemove()
    if FTBase and FTBase.Runtime and FTBase.Runtime.Ballistics then
        FTBase.Runtime.Ballistics.ReleaseProjectile(self)
    end
end
