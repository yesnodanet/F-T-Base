FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Recoil = FTBase.Module.Define("Recoil", {})

local function patternEntry(ir, index)
    local pattern = ir.recoil.pattern or {}

    if #pattern == 0 then
        local procedural = ir.recoil.procedural or {}

        return {
            horizontal = procedural.horizontal or 0,
            vertical = procedural.vertical or 0,
            roll = procedural.roll or 0,
            camera = 1,
            weapon = 1,
            recovery = procedural.recovery or 1,
            randomness = procedural.randomness or 0
        }
    end

    return pattern[((index - 1) % #pattern) + 1]
end

function Recoil.NewState(ir)
    return {
        shot = 0,
        recovery = 0,
        last = nil,
        scalar = ir.recoil.scalar or 1
    }
end

function Recoil.Next(ir, state, seed)
    state.shot = state.shot + 1

    local entry = FTBase.Util.Table.DeepCopy(patternEntry(ir, state.shot))
    local scalar = ir.recoil.scalar or state.scalar or 1
    local randomness = entry.randomness or 0

    if randomness > 0 then
        local random = seed or math.random()
        entry.horizontal = entry.horizontal + (random - 0.5) * randomness
        entry.vertical = entry.vertical + ((1 - random) - 0.5) * randomness
    end

    entry.horizontal = entry.horizontal * scalar
    entry.vertical = entry.vertical * scalar
    entry.roll = entry.roll * scalar

    state.last = entry
    state.recovery = entry.recovery or 1

    return entry
end

function Recoil.Apply(owner, recoil)
    if not owner or not recoil then
        return
    end

    if owner.ViewPunch and Angle then
        owner:ViewPunch(Angle(-(recoil.vertical or 0), recoil.horizontal or 0, recoil.roll or 0))
    end
end

function Recoil.Decay(state, dt)
    if not state then
        return
    end

    state.recovery = math.max(0, (state.recovery or 0) - dt)
end

FTBase.Runtime.Recoil = Recoil
