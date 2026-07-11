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
        local owner = self.GetOwner and self:GetOwner()

        if owner and owner == LocalPlayer() and owner.KeyDown then
            if IN_USE and IN_RELOAD and owner:KeyDown(IN_USE) and owner:KeyDown(IN_RELOAD) then
                self.FTNextCustomizeOpen = self.FTNextCustomizeOpen or 0

                if CurTime() >= self.FTNextCustomizeOpen then
                    self.FTNextCustomizeOpen = CurTime() + 0.5
                    FTBase.Runtime.Inspect.Toggle(self)
                end
            end
        end
    end
end

function SWEP:DrawHUD()
    if not CLIENT or not self.FTRuntime then
        return
    end

    if not draw or not ScrW or not ScrH then
        return
    end

    local text = "F&T: hold USE + RELOAD to customize"
    draw.SimpleText(text, "DermaDefault", ScrW() / 2, ScrH() - 96, Color(230, 235, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

function SWEP:FTOpenCustomization()
    if CLIENT and FTBase.Runtime.Inspect then
        return FTBase.Runtime.Inspect.Open(self)
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

    return FTBase.Runtime.NPC.GetRest(runtime.ir)
end

function SWEP:GetNPCBurstSettings()
    local runtime = self.FTRuntime

    if not runtime then
        return 1, 3, 0.25
    end

    local minimum, maximum = FTBase.Runtime.NPC.GetBurst(runtime.ir)
    return minimum, maximum, runtime.ir.fire.delay or 0.1
end
