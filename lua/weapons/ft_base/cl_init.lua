include("shared.lua")

function SWEP:CalcView(ply, origin, angles, fov)
    if not self.FTRuntime then
        return nil
    end

    return FTBase.Runtime.Camera.CalcView(self.FTRuntime, ply, origin, angles, fov)
end
