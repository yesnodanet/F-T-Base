FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Physics = FTBase.Module.Define("Physics", {})

function Physics.SpringStep(state, target, dt, stiffness, damping)
    state = state or {
        position = 0,
        velocity = 0
    }

    local displacement = target - state.position
    local acceleration = displacement * stiffness - state.velocity * damping

    state.velocity = state.velocity + acceleration * dt
    state.position = state.position + state.velocity * dt

    return state
end

function Physics.ProjectileStep(projectile, dt, environment)
    environment = environment or {}

    local gravity = environment.gravity or projectile.gravity or 0
    local drag = environment.drag or projectile.drag or 0
    local wind = environment.wind or {0, 0, 0}

    projectile.velocity[1] = projectile.velocity[1] + (wind[1] or 0) * dt
    projectile.velocity[2] = projectile.velocity[2] + (wind[2] or 0) * dt
    projectile.velocity[3] = projectile.velocity[3] + ((wind[3] or 0) - gravity) * dt

    projectile.velocity[1] = projectile.velocity[1] * (1 - drag * dt)
    projectile.velocity[2] = projectile.velocity[2] * (1 - drag * dt)
    projectile.velocity[3] = projectile.velocity[3] * (1 - drag * dt)

    projectile.position[1] = projectile.position[1] + projectile.velocity[1] * dt
    projectile.position[2] = projectile.position[2] + projectile.velocity[2] * dt
    projectile.position[3] = projectile.position[3] + projectile.velocity[3] * dt

    return projectile
end

FTBase.Runtime.Physics = Physics
