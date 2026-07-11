FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Networking = FTBase.Module.Define("Networking", {
    NetString = "ft_base_state",
    CustomizationNetString = "ft_base_customization"
})

function Networking.Register()
    if SERVER and util and util.AddNetworkString then
        util.AddNetworkString(Networking.NetString)
        util.AddNetworkString(Networking.CustomizationNetString)
    end
end

function Networking.SendAttachmentState(swep, recipient)
    if not SERVER or not net or not swep or not swep.FTRuntime then
        return
    end

    net.Start(Networking.CustomizationNetString)
    net.WriteBool(true)
    net.WriteEntity(swep)
    net.WriteTable(swep.FTRuntime.attachments.installed or {})

    if recipient then
        net.Send(recipient)
    else
        net.Broadcast()
    end
end

function Networking.RequestAttachment(swep, slotId, attachmentId)
    if not CLIENT or not net or not swep then
        return false
    end

    net.Start(Networking.CustomizationNetString)
    net.WriteBool(false)
    net.WriteEntity(swep)
    net.WriteString(tostring(slotId or ""))
    net.WriteString(tostring(attachmentId or ""))
    net.SendToServer()
    return true
end

local function receiveCustomization(_, player)
    local isState = net.ReadBool()
    local swep = net.ReadEntity()

    if isState then
        if SERVER then
            return
        end

        local installed = net.ReadTable() or {}

        if IsValid(swep) and swep.FTRuntime then
            swep.FTRuntime.attachments.installed = installed
            FTBase.Runtime.Attachments.RebuildModifiers(swep.FTRuntime)

            if FTBase.Runtime.Inspect then
                FTBase.Runtime.Inspect.Refresh(swep)
            end
        end

        return
    end

    if not SERVER or not IsValid(player) or not IsValid(swep) then
        return
    end

    local slotId = string.sub(net.ReadString() or "", 1, 64)
    local attachmentId = string.sub(net.ReadString() or "", 1, 64)

    if swep:GetOwner() ~= player or not swep.FTRuntime then
        return
    end

    local changed = false

    if attachmentId == "" then
        changed = FTBase.Runtime.Customization.Uninstall(swep.FTRuntime, slotId)
    else
        changed = FTBase.Runtime.Customization.Install(swep.FTRuntime, slotId, attachmentId)
    end

    if changed then
        Networking.SendAttachmentState(swep, player)
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

if net and net.Receive then
    net.Receive(Networking.CustomizationNetString, receiveCustomization)
end

FTBase.Runtime.Networking = Networking
