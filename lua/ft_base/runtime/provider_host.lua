FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

-- The provider host is deliberately data-oriented. A provider receives the
-- compiled IR/runtime and may only build F&T panels, HUD primitives, and
-- attachment requests; it never loads or calls a vendor weapon base.
local ProviderHost = FTBase.Module.Define("ProviderHost", {})

local Table = FTBase.Util.Table
local Providers = {}
local Domains = {
    "attachments",
    "inspect",
    "hud",
    "presentation"
}

local function normalize(value)
    return string.lower(tostring(value or ""))
end

local function nonEmpty(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    return ""
end

local function sortedSlots(runtime, provider)
    local slots = Table.ArrayCopy(runtime and runtime.attachments and runtime.attachments.slots or {})
    local order = provider.slotOrder or {}

    table.sort(slots, function(left, right)
        local leftOrder = tonumber(order[left.type or left.id]) or 1000
        local rightOrder = tonumber(order[right.type or right.id]) or 1000

        if leftOrder == rightOrder then
            return tostring(left.name or left.id) < tostring(right.name or right.id)
        end

        return leftOrder < rightOrder
    end)

    return slots
end

local function canInstall(runtime, slotId, attachmentId)
    return FTBase.Runtime.Attachments
        and FTBase.Runtime.Attachments.CanInstall
        and FTBase.Runtime.Attachments.CanInstall(runtime, slotId, attachmentId)
end

local function defaultOptions(runtime, slotId)
    local options = {}
    local definitions = runtime and runtime.ir and runtime.ir.attachments
        and runtime.ir.attachments.definitions or {}

    for _, attachmentId in ipairs(Table.Keys(definitions)) do
        local definition = definitions[attachmentId]

        if type(definition) == "table" and not definition.hidden and not definition.disabled
            and canInstall(runtime, slotId, attachmentId) then
            options[#options + 1] = {
                id = attachmentId,
                name = nonEmpty(definition.name, attachmentId, "Attachment"),
                description = definition.description or "",
                definition = definition,
                icon = definition.icon or definition.iconMaterial
            }
        end
    end

    return options
end

local function installLabel(runtime, slot)
    local installed = runtime and runtime.attachments and runtime.attachments.installed
        and runtime.attachments.installed[slot and slot.id]
    local definition = installed and runtime.ir.attachments.definitions[installed]

    return installed, definition
end

local function addDefaults(provider)
    provider.frame = provider.frame or {width = 920, height = 600}
    provider.preview = provider.preview or {height = 220, fov = 45, camera = {45, 45, 32}, lookAt = {0, 0, 0}}
    provider.stats = provider.stats or {}
    provider.shell = provider.shell or {
        title = provider.title or "F&T Customization",
        frame = provider.frame,
        background = provider.muted or {20, 26, 32, 225},
        accent = provider.accent or {94, 190, 235, 255},
        titleFont = provider.font or "DermaDefaultBold"
    }

    provider.Open = provider.Open or function()
        return false
    end

    provider.Close = provider.Close or function()
        return false
    end

    provider.Refresh = provider.Refresh or function()
        return false
    end

    provider.HandleInput = provider.HandleInput or function()
        return false
    end

    provider.DrawHUD = provider.DrawHUD or function()
        return false
    end

    provider.ApplyPresentation = provider.ApplyPresentation or function()
        return false
    end

    provider.GetSlots = provider.GetSlots or function(self, runtime)
        return sortedSlots(runtime, self)
    end

    provider.GetOptions = provider.GetOptions or function(_, runtime, slotId)
        return defaultOptions(runtime, slotId)
    end

    provider.GetInspectData = provider.GetInspectData or function(self, runtime, slotId)
        local slot

        for _, candidate in ipairs(self:GetSlots(runtime)) do
            if candidate.id == slotId then
                slot = candidate
                break
            end
        end

        local installed, definition = installLabel(runtime, slot)
        local ir = runtime and (runtime.effectiveIR or runtime.ir) or {}

        return {
            slot = slot,
            installed = installed,
            definition = definition,
            ir = ir,
            stats = self.stats or {}
        }
    end

    provider.BuildAttachmentRequest = provider.BuildAttachmentRequest or function(_, slotId, attachmentId)
        return {
            slotId = tostring(slotId or ""),
            attachmentId = tostring(attachmentId or "")
        }
    end

    -- Compatibility with the original F&T provider draft.
    provider.BuildRequest = provider.BuildRequest or provider.BuildAttachmentRequest
    provider.GetSlotLabel = provider.GetSlotLabel or function(self, slot)
        local label = nonEmpty(slot and slot.name, slot and slot.id, "Attachment")
        local kind = nonEmpty(slot and slot.type, slot and slot.category)

        if self.id == "tfa" then
            return (kind ~= "" and string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2) .. ": " or "") .. label
        end

        if self.id == "mw" then
            return "Gunsmith / " .. label
        end

        if self.id == "arc9" then
            return "ARC9 / " .. label
        end

        if self.id == "arccw" then
            return "Customize / " .. label
        end

        if self.id == "tacrp" then
            return "Workbench / " .. label
        end

        return label
    end
    provider.GetInstalledLabel = provider.GetInstalledLabel or function(self, definition, attachmentId)
        if not definition and self.id == "mw" then
            return "No attachment"
        end

        return nonEmpty(definition and definition.name, attachmentId, "Empty")
    end
    provider.GetOptionLabel = provider.GetOptionLabel or function(self, option)
        local label = nonEmpty(option and option.name, option and option.id, "Attachment")

        if self.id == "mw" or self.id == "tacrp" then
            return "Install / " .. label
        end

        if self.id == "arc9" then
            return "Equip / " .. label
        end

        if self.id == "arccw" then
            return "Attach / " .. label
        end

        return label
    end
    provider.GetOptionDescription = provider.GetOptionDescription or function(_, option)
        return option and option.description or ""
    end

    return provider
end

function ProviderHost.Register(id, definition)
    if not id or type(definition) ~= "table" then
        return false
    end

    local provider = definition
    provider.id = normalize(id)
    addDefaults(provider)
    Providers[provider.id] = provider
    return true
end

function ProviderHost.Get(id)
    return Providers[normalize(id)]
end

function ProviderHost.GetAll()
    return Providers
end

function ProviderHost.GetDomains()
    return Table.ArrayCopy(Domains)
end

local function configuredProvider(runtime, domain)
    local ir = runtime and runtime.ir
    local ui = ir and ir.ui or {}
    local visual = ui.visual or {}
    local providers = visual.providers or {}
    local normalizedDomain = normalize(domain)
    local id = nil

    if type(providers) == "string" then
        id = providers
    elseif type(providers) == "table" then
        id = providers[normalizedDomain]

        if id == nil then
            for _, key in ipairs(Table.Keys(providers)) do
                local value = providers[key]

                if normalize(key) == normalizedDomain then
                    id = value
                    break
                end
            end
        end
    end

    if id == nil and normalizedDomain == "attachments" then
        id = ui.customization and ui.customization.provider
    end

    if id == nil then
        id = type(providers) == "table" and providers.default or visual.default
    end

    return normalize(id ~= "" and id or "ft")
end

function ProviderHost.GetProvider(runtime, domain)
    local id = configuredProvider(runtime, domain)
    local provider = Providers[id] or Providers.ft
    return provider, provider and provider.id or "ft"
end

function ProviderHost.GetProviderId(runtime, domain)
    local _, id = ProviderHost.GetProvider(runtime, domain)
    return id
end

function ProviderHost.BuildContext(swep, domain)
    local runtime = swep and swep.FTRuntime
    local ir = runtime and (runtime.effectiveIR or runtime.ir)

    return {
        swep = swep,
        runtime = runtime,
        ir = ir,
        domain = normalize(domain),
        provider = ProviderHost.GetProvider(runtime, domain)
    }
end

FTBase.Runtime.ProviderHost = ProviderHost
