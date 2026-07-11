FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Customization = FTBase.Module.Define("Customization", {})

local Table = FTBase.Util.Table
local Providers = {}

local function titleCase(value)
    value = tostring(value or "")

    return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

local function sortedSlots(runtime, provider)
    local slots = Table.ArrayCopy(runtime.attachments and runtime.attachments.slots or {})

    table.sort(slots, function(left, right)
        local leftOrder = provider.slotOrder and provider.slotOrder[left.type or left.id] or 100
        local rightOrder = provider.slotOrder and provider.slotOrder[right.type or right.id] or 100

        if leftOrder == rightOrder then
            return tostring(left.name or left.id) < tostring(right.name or right.id)
        end

        return leftOrder < rightOrder
    end)

    return slots
end

local function makeProvider(definition)
    local provider = Table.DeepCopy(definition)

    provider.id = string.lower(provider.id)
    provider.title = provider.title or (titleCase(provider.id) .. " Customization")
    provider.frame = provider.frame or {width = 920, height = 600}
    provider.slotOrder = provider.slotOrder or {}

    function provider:GetSlots(runtime)
        return sortedSlots(runtime, self)
    end

    function provider:GetSlotLabel(slot)
        local label = slot.name or titleCase(slot.id)

        if self.id == "tfa" then
            return titleCase(slot.type or "attachment") .. ": " .. label
        end

        if self.id == "mw" then
            return "Gunsmith / " .. label
        end

        if self.id == "mixed" then
            return "Mixed / " .. label
        end

        return label
    end

    function provider:GetInstalledLabel(definition, attachmentId)
        if not definition then
            return self.id == "mw" and "No attachment" or "Empty"
        end

        return definition.name or attachmentId
    end

    function provider:GetOptionLabel(option)
        if self.id == "swb" then
            return option.name or option.id
        end

        if self.id == "mw" then
            return "Install / " .. (option.name or option.id)
        end

        return option.name or option.id
    end

    function provider:GetOptionDescription(option)
        if self.id == "mixed" then
            return "Mixed-style attachment: " .. (option.description or "No description")
        end

        return option.description or ""
    end

    function provider:GetOptions(runtime, slotId)
        return Customization.GetOptions(runtime, slotId)
    end

    function provider:GetGroup(slot)
        return slot.category or slot.type or "general"
    end

    function provider:BuildRequest(slotId, attachmentId)
        return {
            slotId = slotId,
            attachmentId = attachmentId
        }
    end

    return provider
end

function Customization.RegisterProvider(id, provider)
    if not id or type(provider) ~= "table" then
        return false
    end

    local normalized = string.lower(tostring(id))
    provider.id = normalized
    Providers[normalized] = provider
    return true
end

function Customization.GetProvider(runtime)
    local id = runtime and runtime.ir and runtime.ir.ui and runtime.ir.ui.customization
        and runtime.ir.ui.customization.provider or "ft"
    id = string.lower(tostring(id))

    return Providers[id] or Providers.ft, Providers[id] and id or "ft"
end

function Customization.Open(swep)
    if not swep or not swep.FTRuntime then
        return false
    end

    local provider, providerId = Customization.GetProvider(swep.FTRuntime)

    if provider and provider.Open then
        return provider.Open(swep, providerId)
    end

    if FTBase.Runtime.Inspect then
        return FTBase.Runtime.Inspect.Open(swep, providerId)
    end

    return false
end

function Customization.GetSlots(runtime)
    return runtime.attachments and runtime.attachments.slots or {}
end

function Customization.Install(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments.Install(runtime, slotId, attachmentId)
end

function Customization.Uninstall(runtime, slotId)
    return FTBase.Runtime.Attachments.Uninstall(runtime, slotId)
end

function Customization.CanInstall(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments.CanInstall(runtime, slotId, attachmentId)
end

function Customization.GetOptions(runtime, slotId)
    local options = {}
    local definitions = runtime and runtime.ir.attachments.definitions or {}

    for _, attachmentId in ipairs(Table.Keys(definitions)) do
        local allowed = Customization.CanInstall(runtime, slotId, attachmentId)

        if allowed then
            local definition = definitions[attachmentId]
            options[#options + 1] = {
                id = attachmentId,
                name = definition.name or attachmentId,
                description = definition.description or "",
                definition = definition
            }
        end
    end

    return options
end

function Customization.GetEffectiveIR(runtime)
    return FTBase.Runtime.Attachments.GetEffectiveIR(runtime)
end

Customization.RegisterProvider("ft", makeProvider({
    id = "ft",
    title = "F&T Customization",
    frame = {width = 920, height = 600}
}))

Customization.RegisterProvider("tfa", makeProvider({
    id = "tfa",
    title = "TFA Attachments",
    frame = {width = 960, height = 620},
    slotOrder = {
        optic = 10,
        muzzle = 20,
        underbarrel = 30,
        stock = 40
    }
}))

Customization.RegisterProvider("swb", makeProvider({
    id = "swb",
    title = "SWB Attachments",
    frame = {width = 760, height = 520},
    slotOrder = {
        optic = 10,
        stock = 20,
        muzzle = 30
    }
}))

Customization.RegisterProvider("mw", makeProvider({
    id = "mw",
    title = "MW Gunsmith",
    frame = {width = 1080, height = 680},
    slotOrder = {
        optic = 10,
        barrel = 20,
        muzzle = 30,
        stock = 40
    }
}))

Customization.RegisterProvider("mixed", makeProvider({
    id = "mixed",
    title = "Mixed Style Customization",
    frame = {width = 1000, height = 640}
}))

FTBase.Runtime.Customization = Customization
