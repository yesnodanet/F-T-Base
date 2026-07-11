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

function Camera.AddImpulse(state, recoil)
    if not state then
        return
    end

    state.shake = state.shake + math.abs(recoil and recoil.vertical or 0) * (state.ir.shake or 0)
end

function Camera.Update(state, dt)
    if not state then
        return
    end

    state.shake = math.max(0, state.shake - dt * 8)
    state.sway = (state.ir.sway or 0)

    if FTBase.Runtime.Physics then
        state.spring = FTBase.Runtime.Physics.SpringStep(
            state.spring,
            0,
            dt,
            state.ir.spring and state.ir.spring.stiffness or 180,
            state.ir.spring and state.ir.spring.damping or 22
        )
    end
end

function Camera.CalcView(runtime, ply, origin, angles, fov)
    local state = runtime and runtime.camera

    if not state then
        return nil
    end

    return {
        origin = origin,
        angles = angles,
        fov = fov,
        drawviewer = false
    }
end

FTBase.Runtime.Camera = Camera
