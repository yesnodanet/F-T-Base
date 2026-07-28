FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Visuals = FTBase.Module.Define("Visuals", {})
local Host = FTBase.Runtime.ProviderHost

if CLIENT and surface and surface.CreateFont then
    surface.CreateFont("FT_TFA_Inter", {font = "Inter", size = 22, weight = 500, antialias = true})
    surface.CreateFont("FT_ARC9_Venryn", {font = "Venryn Sans", size = 22, weight = 600, antialias = true})
    surface.CreateFont("FT_ArcCW_Bahnschrift", {font = "Bahnschrift", size = 22, weight = 500, antialias = true})
    surface.CreateFont("FT_MW_8MM6Z", {font = "8MM6Z", size = 22, weight = 500, antialias = true})
    surface.CreateFont("FT_TacRP_Myriad", {font = "Myriad Pro", size = 22, weight = 500, antialias = true})
    surface.CreateFont("SWB_HUD48", {font = "Default", size = 48, weight = 700, antialias = true})
    surface.CreateFont("SWB_HUD24", {font = "Default", size = 24, weight = 700, antialias = true})
    surface.CreateFont("SWB_HUD16", {font = "Default", size = 16, weight = 700, antialias = true})
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

local function color(value, fallback)
    value = value or fallback or {255, 255, 255, 255}

    if Color then
        return Color(value[1] or 255, value[2] or 255, value[3] or 255, value[4] or 255)
    end

    return value
end

local function drawText(text, font, x, y, textColor, xAlign, yAlign)
    if draw and draw.SimpleText then
        draw.SimpleText(text, font or "DermaDefault", x, y, textColor, xAlign or TEXT_ALIGN_LEFT, yAlign or TEXT_ALIGN_TOP)
    end
end

local function drawRect(x, y, width, height, rectColor)
    if draw and draw.RoundedBox then
        draw.RoundedBox(0, x, y, width, height, rectColor)
    elseif surface and surface.SetDrawColor and surface.DrawRect then
        surface.SetDrawColor(rectColor)
        surface.DrawRect(x, y, width, height)
    end
end

local function drawCrosshair(provider, x, y, alpha)
    if not surface or not surface.SetDrawColor or not surface.DrawRect then
        return
    end

    local accent = color(provider.accent, provider.accent)
    surface.SetDrawColor(accent.r or accent[1], accent.g or accent[2], accent.b or accent[3], alpha or 220)
    surface.DrawRect(x - 10, y - 1, 7, 2)
    surface.DrawRect(x + 3, y - 1, 7, 2)
    surface.DrawRect(x - 1, y - 10, 2, 7)
    surface.DrawRect(x - 1, y + 3, 2, 7)
end

local function hudContext(swep)
    local runtime = swep and swep.FTRuntime
    local ir = runtime and FTBase.Runtime.Attachments.GetEffectiveIR(runtime) or nil
    local owner = swep and swep.GetOwner and swep:GetOwner() or nil
    local ammoType = ir and ir.ammo and ir.ammo.type or "SMG1"
    local clip = swep and swep.Clip1 and swep:Clip1() or 0
    local reserve = owner and owner.GetAmmoCount and owner:GetAmmoCount(ammoType) or 0

    return {
        swep = swep,
        runtime = runtime,
        ir = ir,
        owner = owner,
        clip = clip,
        reserve = reserve,
        width = ScrW and ScrW() or 0,
        height = ScrH and ScrH() or 0
    }
end

local function drawDefaultHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)
    local muted = color(provider.muted, provider.muted)
    local name = Visuals.GetDisplayName(context.ir, context.swep)
    local ammo = tostring(context.clip) .. " / " .. tostring(context.reserve)

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 220)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(width - 258, height - 112, 238, 72, muted)
    drawText(name, provider.font, width - 244, height - 103, accent)
    drawText(ammo, provider.ammoFont, width - 244, height - 75, accent)

    if provider.showHint then
        drawText("USE + RELOAD", provider.hintFont, width - 125, height - 45, accent, TEXT_ALIGN_CENTER)
    end

    return true
end

local function drawTFAHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)
    local dark = color({12, 14, 16, 205})

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 220)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(width - 300, height - 118, 270, 88, dark)
    drawText(Visuals.GetDisplayName(context.ir, context.swep), "DermaDefaultBold", width - 282, height - 108, accent)
    drawText(tostring(context.clip), provider.ammoFont, width - 282, height - 88, accent)
    drawText("/ " .. tostring(context.reserve), "DermaDefaultBold", width - 184, height - 70, accent)
    drawRect(width - 282, height - 43, 224, 4, color({80, 80, 80, 180}))
    local ratio = math.max(0, math.min(1, context.clip / math.max(1, context.ir.ammo.clipSize or 1)))
    drawRect(width - 282, height - 43, 224 * ratio, 4, accent)
    return true
end

local function drawMWHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)
    local panel = color({10, 13, 15, 215})

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 180)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(width - 350, height - 126, 320, 96, panel)
    drawText(Visuals.GetDisplayName(context.ir, context.swep), provider.font, width - 328, height - 116, color({188, 196, 201, 255}))
    drawText(string.format("%02d", math.max(0, context.clip)), "Trebuchet48", width - 328, height - 91, accent)
    drawText("/ " .. tostring(context.reserve), "DermaDefaultBold", width - 188, height - 67, color({185, 192, 198, 255}))
    drawRect(width - 328, height - 39, 276, 2, color({55, 72, 80, 220}))
    drawRect(width - 328, height - 39, 276 * math.max(0, math.min(1, context.clip / math.max(1, context.ir.ammo.clipSize or 1))), 2, accent)
    return true
end

local function drawARC9HUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 210)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(30, height - 104, 268, 72, color({10, 23, 29, 220}))
    drawText("ARC9", "DermaDefaultBold", 48, height - 94, accent)
    drawText(Visuals.GetDisplayName(context.ir, context.swep), "DermaDefault", 48, height - 72, color({208, 230, 235, 255}))
    drawText(tostring(context.clip) .. " / " .. tostring(context.reserve), "Trebuchet24", 48, height - 49, accent)
    return true
end

local function drawArcCWHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 220)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(width - 250, height - 90, 220, 54, color({0, 0, 0, 170}))
    drawText(tostring(context.clip), "Trebuchet24", width - 232, height - 82, accent)
    drawText("/ " .. tostring(context.reserve), "DermaDefault", width - 175, height - 73, color({230, 230, 230, 230}))
    return true
end

local function drawSWBHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 210)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawText(tostring(context.clip), "Trebuchet48", width - 84, height - 88, accent, TEXT_ALIGN_RIGHT)
    drawText("/ " .. tostring(context.reserve), "DermaDefaultBold", width - 82, height - 49, accent, TEXT_ALIGN_RIGHT)
    drawRect(width - 222, height - 38, 136, 3, color({0, 0, 0, 210}))
    drawRect(width - 222, height - 38, 136 * math.max(0, math.min(1, context.clip / math.max(1, context.ir.ammo.clipSize or 1))), 3, accent)
    return true
end

local function drawTacRPHUD(provider, context)
    if not context.ir or not draw then
        return false
    end

    local width, height = context.width, context.height
    local accent = color(provider.accent, provider.accent)

    if context.ir.ui.crosshair ~= false then
        drawCrosshair(provider, width * 0.5, height * 0.5, 220)
    end

    if context.ir.ui.drawAmmo == false or context.swep.DrawAmmo == false then
        return true
    end

    drawRect(width - 290, 16, 264, 58, color({0, 0, 0, 150}))
    drawText(Visuals.GetDisplayName(context.ir, context.swep), "DermaDefaultBold", width - 274, 25, color({255, 255, 255, 255}))
    drawText(tostring(context.clip) .. " / " .. tostring(context.reserve), provider.ammoFont, width - 274, 47, accent)
    return true
end

local function makePresentation(provider)
    return function(self, swep, runtime)
        if not swep then
            return false
        end

        swep.FTVisualPresentation = self.id
        swep.FTVisualAssetRoot = self.assetRoot
        swep.FTVisualStyle = self.presentation
        return true
    end
end

local function register(id, definition)
    definition.id = id
    definition.assetRoot = definition.assetRoot or "materials/ft_base/providers/" .. id
    definition.ApplyPresentation = definition.ApplyPresentation or makePresentation(definition)
    definition.DrawHUD = definition.DrawHUD or drawDefaultHUD
    return Host.Register(id, definition)
end

function Visuals.RegisterProvider(id, definition)
    return register(id, definition)
end

function Visuals.GetProvider(runtime, domain)
    return Host.GetProvider(runtime, domain)
end

function Visuals.GetInspectStyle(runtime)
    return Host.GetProvider(runtime, "inspect")
end

function Visuals.GetDisplayName(ir, swep)
    return nonEmpty(ir and ir.meta and ir.meta.printName, swep and swep.PrintName, "Weapon")
end

function Visuals.GetContext(swep)
    return hudContext(swep)
end

function Visuals.ApplyPresentation(swep, runtime)
    local provider = Host.GetProvider(runtime, "presentation")

    if provider and provider.ApplyPresentation then
        provider:ApplyPresentation(swep, runtime)
    end

    return provider
end

function Visuals.DrawHUD(swep)
    if not CLIENT or not draw or not swep or not swep.FTRuntime then
        return false
    end

    local context = hudContext(swep)

    if not context.ir then
        return false
    end

    local provider = Host.GetProvider(context.runtime, "hud")

    if provider and provider.DrawHUD then
        return provider:DrawHUD(context)
    end

    return drawDefaultHUD(provider or Host.Get("ft"), context)
end

register("ft", {
    title = "F&T Customization",
    frame = {width = 920, height = 600},
    accent = {94, 190, 235, 255},
    muted = {20, 26, 32, 225},
    font = "DermaDefaultBold",
    ammoFont = "Trebuchet24",
    hintFont = "DermaDefault",
    presentation = "neutral",
    stats = {
        {label = "Damage", path = "damage.base"},
        {label = "RPM", path = "fire.rpm"},
        {label = "Hip spread", path = "spread.hip"},
        {label = "ADS spread", path = "spread.ads"}
    }
})

register("tfa", {
    title = "TFA Attachments",
    frame = {width = 960, height = 620},
    sidebarWidth = 300,
    accent = {239, 187, 61, 255},
    muted = {25, 27, 30, 230},
    font = "FT_TFA_Inter",
    ammoFont = "Trebuchet48",
    hintFont = "DermaDefault",
    presentation = "tfa",
    iconMaterial = "ft_base/providers/tfa/inspectionhud/selector_bar",
    preview = {height = 240, fov = 45, camera = {48, 48, 34}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, muzzle = 20, underbarrel = 30, stock = 40},
    stats = {{label = "Damage", path = "damage.base"}, {label = "RPM", path = "fire.rpm"}, {label = "Hip accuracy", path = "spread.hip"}, {label = "Iron accuracy", path = "spread.ads"}},
    DrawHUD = drawTFAHUD
})

register("mw", {
    title = "MW Gunsmith",
    frame = {width = 1080, height = 680},
    sidebarWidth = 390,
    accent = {220, 137, 45, 255},
    muted = {17, 19, 21, 235},
    font = "FT_MW_8MM6Z",
    ammoFont = "Trebuchet48",
    hintFont = "DermaDefault",
    presentation = "mw",
    iconMaterial = "ft_base/providers/mw/mg/customizemenuopen",
    preview = {height = 250, fov = 48, camera = {52, 52, 36}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, barrel = 20, muzzle = 30, stock = 40},
    stats = {{label = "Damage", path = "damage.base"}, {label = "Effective range", path = "ballistics.damageCurve.maxRange"}, {label = "RPM", path = "fire.rpm"}, {label = "Aim speed", path = "ads.speed"}},
    DrawHUD = drawMWHUD
})

register("swb", {
    title = "SWB Attachments",
    frame = {width = 760, height = 520},
    sidebarWidth = 235,
    accent = {116, 196, 106, 255},
    muted = {24, 31, 25, 230},
    font = "SWB_HUD24",
    ammoFont = "SWB_HUD48",
    hintFont = "SWB_HUD16",
    presentation = "swb",
    preview = {height = 200, fov = 44, camera = {42, 42, 30}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, stock = 20, muzzle = 30},
    stats = {{label = "Damage", path = "damage.base"}, {label = "Fire delay", path = "fire.delay"}, {label = "Hip spread", path = "spread.hip"}, {label = "Aim spread", path = "spread.ads"}},
    DrawHUD = drawSWBHUD
})

register("arc9", {
    title = "ARC9 Customization",
    frame = {width = 1020, height = 640},
    sidebarWidth = 360,
    accent = {83, 196, 224, 255},
    muted = {15, 25, 31, 235},
    font = "FT_ARC9_Venryn",
    ammoFont = "Trebuchet24",
    hintFont = "DermaDefault",
    presentation = "arc9",
    iconMaterial = "ft_base/providers/arc9/ui/att.png",
    preview = {height = 230, fov = 46, camera = {46, 46, 32}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, barrel = 20, underbarrel = 30, stock = 40},
    stats = {{label = "Damage max", path = "damage.base"}, {label = "Damage min", path = "damage.minimum"}, {label = "Muzzle velocity", path = "ballistics.muzzleVelocity"}, {label = "Recoil", path = "recoil.scalar"}},
    DrawHUD = drawARC9HUD
})

register("arccw", {
    title = "ArcCW Customize",
    frame = {width = 980, height = 620},
    sidebarWidth = 300,
    accent = {226, 153, 73, 255},
    muted = {31, 25, 19, 230},
    font = "FT_ArcCW_Bahnschrift",
    ammoFont = "Trebuchet24",
    hintFont = "DermaDefault",
    presentation = "arccw",
    iconMaterial = "ft_base/providers/arccw/hud/default.png",
    preview = {height = 235, fov = 45, camera = {45, 45, 31}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, barrel = 20, underbarrel = 30, stock = 40},
    stats = {{label = "Damage", path = "damage.base"}, {label = "Range", path = "ballistics.damageCurve.maxRange"}, {label = "Dispersion", path = "spread.hip"}, {label = "Recoil", path = "recoil.scalar"}},
    DrawHUD = drawArcCWHUD
})

register("tacrp", {
    title = "TacRP Customization",
    frame = {width = 940, height = 600},
    sidebarWidth = 320,
    accent = {202, 89, 80, 255},
    muted = {33, 20, 20, 235},
    font = "FT_TacRP_Myriad",
    ammoFont = "Trebuchet24",
    hintFont = "DermaDefault",
    presentation = "tacrp",
    iconMaterial = "ft_base/providers/tacrp/hud/news.png",
    preview = {height = 220, fov = 45, camera = {44, 44, 31}, lookAt = {0, 0, 0}},
    slotOrder = {optic = 10, barrel = 20, muzzle = 30, stock = 40},
    stats = {{label = "Damage max", path = "damage.base"}, {label = "Damage min", path = "damage.minimum"}, {label = "Armor penetration", path = "ballistics.armor.scale"}, {label = "Free aim", path = "camera.freeAim.radius"}},
    DrawHUD = drawTacRPHUD
})

FTBase.Runtime.Visuals = Visuals
