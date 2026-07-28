if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "F&T Base Weapon"
SWEP.Author = "Familia & Tarka"
SWEP.Category = "F&T Base"
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Primary = SWEP.Primary or {}
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 90
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "SMG1"
SWEP.Secondary = SWEP.Secondary or {}
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:FTCompile()
    return FTBase.Runtime.Lifecycle.Compile(self)
end

function SWEP:Initialize()
    FTBase.Runtime.Lifecycle.Initialize(self)
end

function SWEP:Deploy()
    return FTBase.Runtime.Lifecycle.Deploy(self)
end

function SWEP:Holster()
    return FTBase.Runtime.Lifecycle.Holster(self)
end

function SWEP:PrimaryAttack()
    return FTBase.Runtime.Engine.PrimaryAttack(self)
end

function SWEP:SecondaryAttack()
    return FTBase.Runtime.Engine.SecondaryAttack(self)
end

function SWEP:Reload()
    return FTBase.Runtime.Engine.Reload(self)
end

function SWEP:Think()
    FTBase.Runtime.Engine.Think(self)

    if CLIENT and FTBase.Runtime.Inspect and self.FTRuntime then
        FTBase.Runtime.Inspect.UpdateInput(self)
    end
end

function SWEP:DrawHUD()
    if not CLIENT or not self.FTRuntime or not FTBase.Runtime.Visuals then
        return
    end

    FTBase.Runtime.Visuals.DrawHUD(self)
end

function SWEP:PostDrawViewModel(viewModel)
    if CLIENT and self.FTRuntime and FTBase.Runtime.AttachmentVisuals then
        FTBase.Runtime.AttachmentVisuals.DrawViewModel(self, viewModel)
    end
end

function SWEP:DrawWorldModel()
    if self.DrawModel then
        self:DrawModel()
    end

    if CLIENT and self.FTRuntime and FTBase.Runtime.AttachmentVisuals then
        FTBase.Runtime.AttachmentVisuals.DrawWorldModel(self)
    end
end

function SWEP:Move(ply, moveData)
    if self.FTRuntime then
        FTBase.Runtime.Movement.SetupMove(self.FTRuntime, ply, moveData)
    end
end

function SWEP:CalcView(ply, origin, angles, fov)
    if not self.FTRuntime then
        return nil
    end

    return FTBase.Runtime.Camera.CalcView(self.FTRuntime, ply, origin, angles, fov)
end

function SWEP:GetViewModelPosition(position, angle)
    if not self.FTRuntime then
        return position, angle
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(self.FTRuntime) or self.FTRuntime.ir
    local aimPosition, aimAngle = FTBase.Runtime.Rendering.GetAimPose(ir)
    local fraction = self.FTRuntime.aimFraction or 0
    local customizationFraction = self.FTRuntime.customizationFraction or 0

    if aimPosition and position then
        position = position + aimPosition * fraction
    end

    if aimAngle and angle then
        angle = angle + aimAngle * fraction
    end

    if customizationFraction > 0 then
        local poses = ir.camera and ir.camera.poses or {}
        local pose = poses.customize or poses.inspect or {}
        local posePosition = pose.pos or pose.position
        local poseAngle = pose.ang or pose.angle

        if posePosition and position then
            position = position + posePosition * customizationFraction
        end

        if poseAngle and angle then
            angle = angle + poseAngle * customizationFraction
        end
    end

    return position, angle
end

function SWEP:FTOpenCustomization()
    if CLIENT and FTBase.Runtime.Customization then
        return FTBase.Runtime.Customization.Open(self)
    end

    return false
end

function SWEP:OnRemove()
    FTBase.Runtime.Lifecycle.Remove(self)
end

function SWEP:CanPrimaryAttack()
    return FTBase.Runtime.Engine.CanPrimaryAttack(self, self.FTRuntime)
end

function SWEP:GetNPCRestTimes()
    local runtime = self.FTRuntime

    if not runtime then
        return 0.2, 0.5
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
    return FTBase.Runtime.NPC.GetRest(ir)
end

function SWEP:GetNPCBurstSettings()
    local runtime = self.FTRuntime

    if not runtime then
        return 1, 3, 0.25
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
    local minimum, maximum = FTBase.Runtime.NPC.GetBurst(ir)
    return minimum, maximum, ir.fire.delay or 0.1
end
