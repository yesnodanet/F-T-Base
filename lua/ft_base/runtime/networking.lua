FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Networking = FTBase.Module.Define("Networking", {
    NetString = "ft_base_state"
})

function Networking.Register()
    if SERVER and util and util.AddNetworkString then
        util.AddNetworkString(Networking.NetString)
    end
end

function Networking.WriteRuntimeState(runtime)
    if not net or not runtime then
        return
    end

    net.WriteUInt(runtime.prediction and runtime.prediction.shotId or 0, 24)
    net.WriteFloat(runtime.nextPrimaryFire or 0)
end

function Networking.ReadRuntimeState()
    if not net then
        return {}
    end

    return {
        shotId = net.ReadUInt(24),
        nextPrimaryFire = net.ReadFloat()
    }
end

Networking.Register()

FTBase.Runtime.Networking = Networking
