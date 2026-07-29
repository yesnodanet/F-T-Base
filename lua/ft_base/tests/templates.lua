-- Compiles the shipped SWEP sources directly so templates cannot drift away
-- from the adapter, IR, and visual-provider contracts.

local Path = FTBase.Util.Path
local Table = FTBase.Util.Table

local profiles = {
    {class = "ft_template_tfa", provider = "tfa", adsPose = true, automatic = false},
    {class = "ft_template_arc9", provider = "arc9"},
    {class = "ft_template_arccw", provider = "arccw"},
    {class = "ft_template_mw", provider = "mw", adsPose = true},
    {class = "ft_template_swb", provider = "swb", adsPose = true, nativeHud = true},
    {class = "ft_template_tacrp", provider = "tacrp"},
    {
        class = "ft_template_mixed",
        providers = {
            inspect = "tfa",
            attachments = "mw",
            hud = "tfa",
            presentation = "tfa"
        },
        adsPose = true
    },
    {
        class = "ft_example_mixed",
        providers = {
            inspect = "tfa",
            attachments = "mw",
            hud = "tfa",
            presentation = "tfa"
        },
        adsPose = true
    }
}

local function includeDefinition(className)
    local previousSWEP = SWEP
    SWEP = {}

    local ok, message = pcall(include, "weapons/" .. className .. "/shared.lua")
    local definition = SWEP
    SWEP = previousSWEP

    assert(ok, tostring(message))
    assert(type(definition.FTSource) == "string", className .. " must declare SWEP.FTSource")
    return definition
end

local function assertPose(ir, path, className)
    local pose = Path.Get(ir, path)

    assert(type(pose) == "table", className .. " is missing " .. path)
    assert(pose.pos ~= nil, className .. " is missing " .. path .. ".pos")
    assert(pose.ang ~= nil, className .. " is missing " .. path .. ".ang")
end

local function hasAppearanceOverride(visual)
    return visual.skin ~= nil
        or visual.material ~= nil
        or type(visual.materials) == "table"
        or type(visual.bodygroups) == "table"
        or type(visual.elements) == "table"
        or type(visual.color) == "table"
end

local function assertAttachmentVisuals(ir, className)
    local definitions = ir.attachments and ir.attachments.definitions or {}
    local definitionIds = Table.Keys(definitions)

    assert(#(ir.attachments.slots or {}) >= 2, className .. " must demonstrate at least two attachment slots")
    assert(#definitionIds >= 2, className .. " must demonstrate at least two attachment definitions")

    local hasAnchoredView = false
    local hasAnchoredWorld = false
    local hasAppearance = false

    for _, attachmentId in ipairs(definitionIds) do
        local definition = definitions[attachmentId]
        local visuals = type(definition) == "table" and definition.visuals or nil
        local view = type(visuals) == "table" and (visuals.view or visuals.viewModel) or nil
        local world = type(visuals) == "table" and (visuals.world or visuals.worldModel) or nil

        if type(view) == "table" and type(view.model) == "string" then
            hasAnchoredView = hasAnchoredView
                or (type(view.bone) == "string" or type(view.attachment) == "string")
                    and view.pos ~= nil and view.ang ~= nil
            hasAppearance = hasAppearance or hasAppearanceOverride(view)
        end

        if type(world) == "table" and type(world.model) == "string" then
            hasAnchoredWorld = hasAnchoredWorld
                or (type(world.bone) == "string" or type(world.attachment) == "string")
                    and world.pos ~= nil and world.ang ~= nil
            hasAppearance = hasAppearance or hasAppearanceOverride(world)
        end
    end

    assert(hasAnchoredView, className .. " must demonstrate an anchored view attachment model")
    assert(hasAnchoredWorld, className .. " must demonstrate an anchored world attachment model")
    assert(hasAppearance, className .. " must demonstrate an attachment appearance override")
end

for _, profile in ipairs(profiles) do
    local definition = includeDefinition(profile.class)
    local result = FTBase.Compiler.CompileSource(definition.FTSource, {name = profile.class})
    local summary = result.report:Summary()

    assert(not result.report:HasErrors(), result.report:ToString())
    assert(summary.unknown == 0, profile.class .. " contains unknown dialect fields\n" .. result.report:ToString())

    local expectedProviders = profile.providers or {
        inspect = profile.provider,
        attachments = profile.provider,
        hud = profile.provider,
        presentation = profile.provider
    }

    for domain, provider in pairs(expectedProviders) do
        assert(result.ir.ui.visual.providers[domain] == provider,
            profile.class .. " selected " .. tostring(result.ir.ui.visual.providers[domain])
                .. " instead of " .. provider .. " for " .. domain)
    end

    if not profile.nativeHud then
        assertPose(result.ir, "camera.poses.inspect", profile.class)
        assertPose(result.ir, "camera.poses.customize", profile.class)
    end
    assert(result.ir.fire.automatic == (profile.automatic ~= false), profile.class .. " should preserve automatic fire setup")
    if not profile.nativeHud then
        assert(result.ir.animations.inspect ~= nil, profile.class .. " is missing its inspect animation")
        assert(result.ir.ui.inspect.animation ~= nil, profile.class .. " is missing its customization animation")
    end
    if profile.adsPose then
        assert(result.ir.ads.pos ~= nil and result.ir.ads.ang ~= nil,
            profile.class .. " must demonstrate a dialect ADS pose")
    else
        local scopes = result.ir.ads.scopes
        local hasScopes = type(scopes) == "table" and next(scopes) ~= nil
        local hasMagnification = type(result.ir.ads.magnification) == "number"
            and result.ir.ads.magnification > 1

        assert(hasScopes or hasMagnification,
            profile.class .. " must demonstrate its dialect scope/zoom metadata")
    end
    if not profile.nativeHud then
        assertAttachmentVisuals(result.ir, profile.class)
    end
end

print("F&T Base template regression passed")

return true
