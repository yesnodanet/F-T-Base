FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Camera = FTBase.Module.Define("Camera", {})

function Camera.NewState(ir)
    return {
        shake = 0,
        sway = 0,
        freeAim = {
            x = 0,
            y = 0
        },
        spring = {
            position = 0,
            velocity = 0
        },
        ir = ir.camera
    }
end

function Camera.AddImpulse(state, recoil, camera)
    if not state then
        return
    end

    camera = camera or state.ir or {}
    state.shake = state.shake + math.abs(recoil and recoil.vertical or 0) * (camera.shake or 0)
end

function Camera.Update(state, dt, camera)
    if not state then
        return
    end

    camera = camera or state.ir or {}
    state.shake = math.max(0, state.shake - dt * 8)
    state.sway = camera.sway or 0

    if FTBase.Runtime.Physics then
        state.spring = FTBase.Runtime.Physics.SpringStep(
            state.spring,
            0,
            dt,
            camera.spring and camera.spring.stiffness or 180,
            camera.spring and camera.spring.damping or 22
        )
    end
end

function Camera.CalcView(runtime, ply, origin, angles, fov)
    local state = runtime and runtime.camera

    if not state then
        return nil
    end

    local ir = FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or runtime.ir
    local targetFov = fov

    if runtime.aimFraction and ir.ads and type(ir.ads.fov) == "number" then
        targetFov = FTBase.Util.Math.Lerp(runtime.aimFraction, fov, ir.ads.fov)
    end

    if angles and Angle then
        local time = CurTime and CurTime() or os.clock()
        local shake = state.shake or 0
        local breathing = ir.camera and ir.camera.breathing or 0
        local pitch = math.sin(time * 17) * shake + math.sin(time * 1.2) * breathing
        local yaw = math.cos(time * 13) * shake * 0.6 + math.cos(time * 0.9) * breathing * 0.5

        angles = Angle(angles.p + pitch, angles.y + yaw, angles.r)
    end

    return {
        origin = origin,
        angles = angles,
        fov = targetFov,
        drawviewer = false
    }
end

FTBase.Runtime.Camera = Camera
