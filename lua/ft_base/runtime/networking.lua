FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Networking = FTBase.Module.Define("Networking", {
    NetString = "ft_base_state",
    CustomizationNetString = "ft_base_customization",
    CustomizationCooldown = 0.1,
    MaxAttachmentSlots = 64,
    MaxIdentifierLength = 64
})

local lastCustomizationRequest = setmetatable({}, {__mode = "k"})

local function currentTime()
    return CurTime and CurTime() or os.clock()
end

local function isValidEntity(entity)
    if IsValid then
        return IsValid(entity)
    end

    return entity ~= nil
end

local function sortedAttachmentState(runtime)
    local state = {}

    for slotId, attachmentId in pairs(runtime.attachments.installed or {}) do
        slotId = tostring(slotId or "")
        attachmentId = tostring(attachmentId or "")

        if #slotId > 0 and #slotId <= Networking.MaxIdentifierLength
            and #attachmentId > 0 and #attachmentId <= Networking.MaxIdentifierLength then
            state[#state + 1] = {slotId, attachmentId}
        end
    end

    table.sort(state, function(left, right)
        return left[1] < right[1]
    end)

    while #state > Networking.MaxAttachmentSlots do
        state[#state] = nil
    end

    return state
end

local function canRequestCustomization(player, swep)
    if not isValidEntity(player) or not isValidEntity(swep) or not swep.FTRuntime then
        return false
    end

    if not swep.GetOwner or swep:GetOwner() ~= player then
        return false
    end

    if not player.Alive or not player:Alive() then
        return false
    end

    if not player.GetActiveWeapon or player:GetActiveWeapon() ~= swep then
        return false
    end

    local byWeapon = lastCustomizationRequest[player]

    if not byWeapon then
        byWeapon = setmetatable({}, {__mode = "k"})
        lastCustomizationRequest[player] = byWeapon
    end

    local time = currentTime()

    if time < (byWeapon[swep] or 0) then
        return false
    end

    byWeapon[swep] = time + Networking.CustomizationCooldown
    return true
end

function Networking.CanRequestCustomization(player, swep)
    return canRequestCustomization(player, swep)
end

function Networking.IsValidAttachmentRequest(slotId, attachmentId)
    return type(slotId) == "string" and type(attachmentId) == "string"
        and #slotId > 0 and #slotId <= Networking.MaxIdentifierLength
        and #attachmentId <= Networking.MaxIdentifierLength
end

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

    local state = sortedAttachmentState(swep.FTRuntime)

    net.Start(Networking.CustomizationNetString)
    net.WriteBool(true)
    net.WriteEntity(swep)
    net.WriteUInt(#state, 7)

    for _, entry in ipairs(state) do
        net.WriteString(entry[1])
        net.WriteString(entry[2])
    end

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

    slotId = tostring(slotId or "")
    attachmentId = tostring(attachmentId or "")

    if not Networking.IsValidAttachmentRequest(slotId, attachmentId) then
        return false
    end

    net.Start(Networking.CustomizationNetString)
    net.WriteBool(false)
    net.WriteEntity(swep)
    net.WriteString(slotId)
    net.WriteString(attachmentId)
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

        local count = net.ReadUInt(7)
        local installed = {}

        for index = 1, count do
            local slotId = net.ReadString() or ""
            local attachmentId = net.ReadString() or ""

            if index <= Networking.MaxAttachmentSlots
                and #slotId > 0 and #slotId <= Networking.MaxIdentifierLength
                and #attachmentId > 0 and #attachmentId <= Networking.MaxIdentifierLength then
                installed[slotId] = attachmentId
            end
        end

        if isValidEntity(swep) and swep.FTRuntime then
            local verified = {}

            for slotId, attachmentId in pairs(installed) do
                local allowed = FTBase.Runtime.Attachments.CanInstall(swep.FTRuntime, slotId, attachmentId)

                if allowed then
                    verified[slotId] = attachmentId
                end
            end

            swep.FTRuntime.attachments.installed = verified
            FTBase.Runtime.Attachments.RebuildModifiers(swep.FTRuntime)

            if FTBase.Runtime.Inspect then
                FTBase.Runtime.Inspect.Refresh(swep)
            end
        end

        return
    end

    if not SERVER then
        return
    end

    local slotId = net.ReadString() or ""
    local attachmentId = net.ReadString() or ""

    -- Consume the per-player/per-weapon budget before inspecting attacker-
    -- controlled payload sizes so malformed spam cannot bypass the limiter.
    if not canRequestCustomization(player, swep) then
        return
    end

    if not Networking.IsValidAttachmentRequest(slotId, attachmentId) then
        return
    end

    local changed = false

    if attachmentId == "" then
        changed = FTBase.Runtime.Customization.Uninstall(swep.FTRuntime, slotId)
    else
        changed = FTBase.Runtime.Customization.Install(swep.FTRuntime, slotId, attachmentId)
    end

    if changed then
        Networking.SendAttachmentState(swep)
    else
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
