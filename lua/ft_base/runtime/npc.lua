FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local NPC = FTBase.Module.Define("NPC", {})

function NPC.GetCapabilities(ir)
    if not ir.npc.enabled then
        return 0
    end

    if CAP_WEAPON_RANGE_ATTACK1 then
        return CAP_WEAPON_RANGE_ATTACK1
    end

    return 0
end

function NPC.GetBurst(ir)
    local burst = ir.npc.burst or {}
    return burst.minimum or 1, burst.maximum or 3
end

function NPC.GetRest(ir)
    local rest = ir.npc.rest or {}
    return rest.minimum or 0.2, rest.maximum or 0.5
end

FTBase.Runtime.NPC = NPC
