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

-- A compiled IR normally carries the provider id directly.  Keep a small
-- source-to-provider map as a runtime repair path for definitions compiled by
-- an older client/server pair where `ui.visual.providers` was left at the FT
-- defaults while provenance was still preserved.
local SourceProviders = {
    ft = "ft",
    tfa = "tfa",
    tfa_base = "tfa",
    arc9 = "arc9",
    arccw = "arccw",
    arccw_base = "arccw",
    mw = "mw",
    modern_wokefare = "mw",
    tacrp = "tacrp",
    swb = "swb"
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

local function providerFromSource(source)
    return SourceProviders[normalize(source)]
end

local function isExplicitSource(source)
    local value = normalize(source)
    return value == "explicit" or string.find(value, "explicit", 1, true) ~= nil
end

local function inferProvider(runtime, domain, configured, source)
    local ir = runtime and runtime.ir

    -- Explicit FT.Visual.* and the legacy FT.Customization.Provider override
    -- must remain authoritative, including an explicit request for `ft`.
    if isExplicitSource(source) then
        return configured
    end

    -- Provenance for this domain is more precise than a stale default value.
    local provenanceProvider = providerFromSource(source)

    if configured == "ft" and provenanceProvider then
        return provenanceProvider
    end

    if configured ~= "ft" then
        return configured
    end

    if not ir then
        return configured
    end

    -- Prefer the declared priority when no domain origin is available. This
    -- mirrors resolver precedence and keeps mixed weapons deterministic.
    for _, prioritySource in ipairs(ir.developer and ir.developer.priority or {}) do
        local provider = providerFromSource(prioritySource)

        if provider and provider ~= "ft" then
            return provider
        end
    end

    -- Finally use stable source-style order as a compatibility fallback.
    local styles = ir.meta and ir.meta.sourceStyles or {}

    for _, style in ipairs(Table.Keys(styles)) do
        local provider = providerFromSource(style)

        if provider and provider ~= "ft" then
            return provider
        end
    end

    return configured
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
    provider.shell = provider.shell or {}
    provider.shell.title = provider.shell.title or provider.title or "F&T Customization"
    provider.shell.frame = provider.shell.frame or provider.frame
    provider.shell.background = provider.shell.background or provider.muted or {20, 26, 32, 225}
    provider.shell.accent = provider.shell.accent or provider.accent or {94, 190, 235, 255}
    provider.shell.titleFont = provider.shell.titleFont or provider.font or "DermaDefaultBold"

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

    -- UI composition belongs to the selected visual provider.  The host only
    -- supplies a namespaced renderer fallback so custom providers can replace
    -- it without reintroducing the old generic inspect shell.
    provider.CreateUI = provider.CreateUI or function(self, context, root)
        local ui = FTBase.Runtime.UI
        local renderers = ui and ui.Renderers
        local renderer = renderers and renderers.Get and renderers.Get(self.id)

        if not renderer then
            return false
        end

        context = context or {}
        context.root = root or context.root
        return renderer(context, root)
    end

    provider.CreateAttachmentSurface = provider.CreateAttachmentSurface or function(self, context, parent)
        local ui = FTBase.Runtime.UI
        local renderers = ui and ui.Renderers
        local renderer = renderers and renderers.GetAttachmentSurface
            and renderers.GetAttachmentSurface(self.id)

        if not renderer then
            return false
        end

        return renderer(context, parent)
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
    local sources = visual.sources or {}
    local normalizedDomain = normalize(domain)
    local id = nil
    local source = nil

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

    if type(sources) == "table" then
        source = sources[normalizedDomain]

        if source == nil then
            for _, key in ipairs(Table.Keys(sources)) do
                if normalize(key) == normalizedDomain then
                    source = sources[key]
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

    id = normalize(id ~= "" and id or "ft")
    return inferProvider(runtime, normalizedDomain, id, source)
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

    if FTBase.Runtime.UI and FTBase.Runtime.UI.Context
        and FTBase.Runtime.UI.Context.New then
        local inspectProvider = ProviderHost.GetProvider(runtime, "inspect")
        local attachmentProvider = ProviderHost.GetProvider(runtime, "attachments")
        return FTBase.Runtime.UI.Context.New(swep, runtime, domain,
            nil, inspectProvider, attachmentProvider)
    end

    return {
        swep = swep,
        runtime = runtime,
        ir = ir,
        domain = normalize(domain),
        provider = ProviderHost.GetProvider(runtime, domain)
    }
end

FTBase.Runtime.ProviderHost = ProviderHost
