FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Visuals = FTBase.Module.Define("Visuals", {})
local Host = FTBase.Runtime.ProviderHost

local RegisteredFonts = {
    Default = true,
    DermaDefault = true,
    DermaDefaultBold = true,
    DermaLarge = true,
    DermaLargeBold = true,
    Trebuchet18 = true,
    Trebuchet19 = true,
    Trebuchet20 = true,
    Trebuchet22 = true,
    Trebuchet24 = true,
    Trebuchet32 = true,
    Trebuchet48 = true
}

if CLIENT and surface and surface.CreateFont then
    local function createFont(name, face, size, weight)
        surface.CreateFont(name, {
            font = face,
            size = size,
            weight = weight or 500,
            antialias = true
        })

        RegisteredFonts[name] = true
    end

    createFont("FT_TFA_Inter", "Inter", 22, 500)
    createFont("FT_TFA_Inter_16", "Inter", 16, 500)
    createFont("FT_TFA_Inter_24", "Inter", 24, 600)
    createFont("FT_TFA_Inter_32", "Inter", 32, 700)
    createFont("FT_TFA_Inter_48", "Inter", 48, 700)
    createFont("Trebuchet48", "Trebuchet MS", 48, 700)
    createFont("FT_ARC9_Venryn", "Venryn Sans", 22, 600)
    createFont("FT_ARC9_Venryn_16", "Venryn Sans", 16, 500)
    createFont("FT_ARC9_Venryn_24", "Venryn Sans", 24, 600)
    createFont("FT_ArcCW_Bahnschrift", "Bahnschrift", 22, 500)
    createFont("FT_ArcCW_Bahnschrift_16", "Bahnschrift", 16, 500)
    createFont("FT_ArcCW_Bahnschrift_24", "Bahnschrift", 24, 600)
    createFont("FT_MW_8MM6Z", "8MM6Z", 22, 500)
    createFont("FT_MW_8MM6Z_16", "8MM6Z", 16, 500)
    createFont("FT_MW_8MM6Z_24", "8MM6Z", 24, 600)
    createFont("FT_MW_8MM6Z_48", "8MM6Z", 48, 700)
    createFont("FT_MW_BioSans", "BioSansW05-Light", 22, 500)
    createFont("FT_MW_BioSans_16", "BioSansW05-Light", 16, 500)
    createFont("FT_MW_BioSans_24", "BioSansW05-Light", 24, 600)
    createFont("FT_MW_BioSans_48", "BioSansW05-Light", 48, 700)
    createFont("FT_MW_Conduit", "Conduit ITC", 22, 500)
    createFont("FT_MW_Conduit_16", "Conduit ITC", 16, 500)
    createFont("FT_MW_Conduit_24", "Conduit ITC", 24, 600)
    createFont("FT_MW_Conduit_48", "Conduit ITC", 48, 700)
    createFont("FT_TacRP_Myriad", "Myriad Pro", 22, 500)
    createFont("FT_TacRP_Myriad_16", "Myriad Pro", 16, 500)
    createFont("FT_TacRP_Myriad_24", "Myriad Pro", 24, 600)
    createFont("FT_Default_24", "Default", 24, 600)
    createFont("FT_Default_48", "Default", 48, 700)
    createFont("SWB_HUD48", "Default", 48, 700)
    createFont("SWB_HUD24", "Default", 24, 700)
    createFont("SWB_HUD16", "Default", 16, 700)
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

local function resolveFont(font, fallback)
    font = type(font) == "string" and font or ""
    fallback = fallback or "DermaDefault"

    if font ~= "" and RegisteredFonts[font] then
        return font
    end

    if RegisteredFonts[fallback] then
        return fallback
    end

    return "DermaDefault"
end

local function drawText(text, font, x, y, textColor, xAlign, yAlign)
    if not draw or not draw.SimpleText or type(x) ~= "number" or type(y) ~= "number" then
        return false
    end

    local ok = pcall(draw.SimpleText, tostring(text or ""), resolveFont(font), x, y, textColor,
        xAlign or TEXT_ALIGN_LEFT, yAlign or TEXT_ALIGN_TOP)
    return ok
end

local function drawRect(x, y, width, height, rectColor)
    if draw and draw.RoundedBox then
        draw.RoundedBox(0, x, y, width, height, rectColor)
    elseif surface and surface.SetDrawColor and surface.DrawRect then
        surface.SetDrawColor(rectColor)
        surface.DrawRect(x, y, width, height)
    end
end

local HUDMaterials = {}

local function drawHUDMaterial(provider, key, x, y, width, height, alpha)
    if not CLIENT or not surface or not surface.SetMaterial or not surface.DrawTexturedRect then
        return false
    end

    local hud = provider and provider.hud or {}
    local path = hud[key]

    if not path or tostring(path) == "" or not Material then
        return false
    end

    local material = HUDMaterials[path]

    if not material then
        local ok, value = pcall(Material, path, "mips smooth")

        if not ok then
            return false
        end

        material = value
        HUDMaterials[path] = material
    end

    local tint = color({255, 255, 255, alpha or 255})
    surface.SetDrawColor(tint.r or tint[1], tint.g or tint[2], tint.b or tint[3], tint.a or tint[4])
    surface.SetMaterial(material)
    surface.DrawTexturedRect(x, y, width, height)
    return true
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
    drawHUDMaterial(provider, "backgroundMaterial", width - 300, height - 118, 270, 88, 80)
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
    drawHUDMaterial(provider, "backgroundMaterial", width - 350, height - 126, 320, 96, 72)
    drawText(Visuals.GetDisplayName(context.ir, context.swep), provider.font, width - 328, height - 116, color({188, 196, 201, 255}))
    drawText(string.format("%02d", math.max(0, context.clip)), provider.ammoFont, width - 328, height - 91, accent)
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
    drawHUDMaterial(provider, "backgroundMaterial", 30, height - 104, 268, 72, 90)
    drawText("ARC9", "DermaDefaultBold", 48, height - 94, accent)
    drawText(Visuals.GetDisplayName(context.ir, context.swep), "DermaDefault", 48, height - 72, color({208, 230, 235, 255}))
    drawText(tostring(context.clip) .. " / " .. tostring(context.reserve), provider.ammoFont, 48, height - 49, accent)
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
    drawHUDMaterial(provider, "backgroundMaterial", width - 250, height - 90, 220, 54, 78)
    drawText(tostring(context.clip), provider.ammoFont, width - 232, height - 82, accent)
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

    drawHUDMaterial(provider, "bullet", width - 238, height - 91, 24, 24, 220)
    drawText(tostring(context.clip), provider.ammoFont, width - 84, height - 88, accent, TEXT_ALIGN_RIGHT)
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
    drawHUDMaterial(provider, "backgroundMaterial", width - 290, 16, 264, 58, 76)
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

function Visuals.ResolveFont(font, fallback)
    return resolveFont(font, fallback)
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
    ammoFont = "FT_Default_24",
    hintFont = "DermaDefault",
    presentation = "neutral",
    shell = {
        mode = "frame",
        layout = "sidebar",
        corner = 0,
        headerHeight = 38,
        contentMargin = 0,
        detail = {padding = 12},
        button = {background = {20, 26, 32, 225}, hover = {94, 190, 235, 230}, selected = {94, 190, 235, 230}, corner = 0}
    },
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
    ammoFont = "FT_TFA_Inter_48",
    hintFont = "DermaDefault",
    presentation = "tfa",
    hud = {backgroundMaterial = "ft_base/providers/tfa/inspectionhud/hex"},
    iconMaterial = "ft_base/providers/tfa/inspectionhud/selector_bar",
    preview = {height = 240, fov = 45, camera = {48, 48, 34}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "tfa",
        background = {8, 10, 13, 238},
        headerBackground = {10, 12, 15, 245},
        headerHeight = 48,
        headerMaterial = "ft_base/providers/tfa/inspectionhud/hex",
        headerMaterialAlpha = 42,
        sidebarMaterial = "ft_base/providers/tfa/inspectionhud/sidebar",
        sidebar = {background = {18, 20, 23, 242}, material = "ft_base/providers/tfa/inspectionhud/sidebar", materialAlpha = 125},
        detail = {background = {12, 14, 17, 205}, padding = 18, previewHeight = 260, titleFont = "FT_TFA_Inter_24", valueFont = "FT_TFA_Inter_16", statsTitleFont = "FT_TFA_Inter_24", statsFont = "FT_TFA_Inter_16"},
        slot = {height = 62, marginLeft = 8, marginTop = 8},
        slotIcons = {default = "ft_base/providers/tfa/inspectionhud/qmark"},
        button = {background = {31, 34, 38, 220}, hover = {239, 187, 61, 225}, selected = {239, 187, 61, 235}, text = {239, 187, 61, 255}, hoverText = {14, 15, 17, 255}, border = {239, 187, 61, 85}, selectedMaterial = "ft_base/providers/tfa/inspectionhud/selector_bar", selectedMaterialAlpha = 120, corner = 0},
        removeLabel = "Remove attachment",
        closeLabel = "X",
        closeWidth = 44,
        statsTitle = "Weapon statistics"
    },
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
    font = "FT_MW_Conduit",
    ammoFont = "FT_MW_BioSans_48",
    hintFont = "DermaDefault",
    presentation = "mw",
    hud = {backgroundMaterial = "ft_base/providers/mw/mg/customizemenuopen"},
    iconMaterial = "ft_base/providers/mw/mg/customizemenuopen",
    preview = {height = 250, fov = 48, camera = {52, 52, 36}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "mw",
        background = {5, 7, 9, 238},
        headerBackground = {7, 9, 11, 245},
        headerHeight = 72,
        titleAlign = "center",
        headerMaterial = "ft_base/providers/mw/mg/customizemenuopen",
        headerMaterialAlpha = 12,
        sidebar = {background = {9, 12, 15, 232}, material = "ft_base/providers/mw/mw_logo", materialAlpha = 8},
        detail = {background = {8, 10, 12, 212}, padding = 22, previewHeight = 280, titleFont = "FT_MW_BioSans_24", valueFont = "FT_MW_Conduit_16", statsTitleFont = "FT_MW_BioSans_24", statsFont = "FT_MW_BioSans_16"},
        slot = {height = 58, marginLeft = 12, marginTop = 8},
        slotIcons = {default = "ft_base/providers/mw/mg/customizemenuopen"},
        button = {background = {17, 22, 26, 225}, hover = {220, 137, 45, 235}, selected = {220, 137, 45, 245}, text = {210, 217, 221, 255}, hoverText = {12, 14, 16, 255}, border = {220, 137, 45, 90}, selectedMaterial = "ft_base/providers/mw/mg/customizemenuopen", selectedMaterialAlpha = 42, corner = 0},
        removeLabel = "Remove from gunsmith",
        closeLabel = "CLOSE",
        closeWidth = 72,
        statsTitle = "GUNSMITH STATS",
        previewHint = "Selected modifiers are previewed before installation."
    },
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
    hud = {bullet = "ft_base/providers/swb/bullet"},
    preview = {height = 200, fov = 44, camera = {42, 42, 30}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "swb",
        background = {6, 10, 7, 232},
        headerBackground = {10, 16, 11, 242},
        headerHeight = 40,
        titleAlign = "left",
        detail = {background = {8, 13, 9, 206}, padding = 14, previewHeight = 220, titleFont = "SWB_HUD24", valueFont = "SWB_HUD16", statsTitleFont = "SWB_HUD24", statsFont = "SWB_HUD16"},
        slot = {height = 48, marginLeft = 8, marginTop = 6},
        button = {background = {19, 30, 20, 222}, hover = {116, 196, 106, 230}, selected = {116, 196, 106, 240}, text = {180, 224, 174, 255}, hoverText = {9, 15, 10, 255}, border = {116, 196, 106, 85}, corner = 0},
        removeLabel = "Remove attachment",
        closeLabel = "X",
        closeWidth = 42,
        statsTitle = "WEAPON DATA"
    },
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
    ammoFont = "FT_ARC9_Venryn_24",
    hintFont = "DermaDefault",
    presentation = "arc9",
    hud = {backgroundMaterial = "ft_base/providers/arc9/hud_bg.png"},
    iconMaterial = "ft_base/providers/arc9/ui/att.png",
    preview = {height = 230, fov = 46, camera = {46, 46, 32}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "arc9",
        background = {5, 12, 16, 236},
        headerBackground = {8, 18, 23, 242},
        headerHeight = 48,
        headerMaterial = "ft_base/providers/arc9/hud_bg.png",
        headerMaterialAlpha = 58,
        titleAlign = "left",
        slotBarHeight = 118,
        detail = {background = {7, 16, 21, 212}, padding = 18, previewHeight = 260, titleFont = "FT_ARC9_Venryn_24", valueFont = "FT_ARC9_Venryn_16", statsTitleFont = "FT_ARC9_Venryn_24", statsFont = "FT_ARC9_Venryn_16"},
        slot = {height = 78, width = 172, marginLeft = 7, marginTop = 12, marginRight = 3},
        slotIcons = {default = "ft_base/providers/arc9/ui/3d_slot_empty.png"},
        button = {background = {12, 30, 38, 232}, hover = {83, 196, 224, 235}, selected = {83, 196, 224, 245}, text = {170, 215, 226, 255}, hoverText = {7, 18, 22, 255}, border = {83, 196, 224, 95}, selectedMaterial = "ft_base/providers/arc9/ui/button_sel.png", selectedMaterialAlpha = 180, corner = 0},
        removeLabel = "UNINSTALL",
        closeLabel = "BACK",
        closeWidth = 70,
        statsTitle = "PERFORMANCE"
    },
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
    ammoFont = "FT_ArcCW_Bahnschrift_24",
    hintFont = "DermaDefault",
    presentation = "arccw",
    hud = {backgroundMaterial = "ft_base/providers/arccw/hud/grad.png"},
    iconMaterial = "ft_base/providers/arccw/hud/default.png",
    preview = {height = 235, fov = 45, camera = {45, 45, 31}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "arccw",
        background = {10, 8, 5, 235},
        headerBackground = {16, 12, 8, 242},
        headerHeight = 42,
        titleAlign = "left",
        detail = {background = {14, 11, 8, 210}, padding = 16, previewHeight = 250, titleFont = "FT_ArcCW_Bahnschrift_24", valueFont = "FT_ArcCW_Bahnschrift_16", statsTitleFont = "FT_ArcCW_Bahnschrift_24", statsFont = "FT_ArcCW_Bahnschrift_16"},
        slot = {height = 54, marginLeft = 8, marginTop = 7},
        slotIcons = {default = "ft_base/providers/arccw/hud/pickx_empty.png"},
        button = {background = {36, 29, 21, 224}, hover = {226, 153, 73, 232}, selected = {226, 153, 73, 242}, text = {235, 205, 162, 255}, hoverText = {20, 14, 8, 255}, border = {226, 153, 73, 90}, selectedMaterial = "ft_base/providers/arccw/hud/pickx_filled.png", selectedMaterialAlpha = 160, corner = 0},
        removeLabel = "UNINSTALL",
        closeLabel = "X",
        closeWidth = 44,
        statsTitle = "WEAPON BALLISTICS"
    },
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
    ammoFont = "FT_TacRP_Myriad_24",
    hintFont = "DermaDefault",
    presentation = "tacrp",
    hud = {backgroundMaterial = "ft_base/providers/tacrp/hud/vignette"},
    iconMaterial = "ft_base/providers/tacrp/hud/news.png",
    preview = {height = 220, fov = 45, camera = {44, 44, 31}, lookAt = {0, 0, 0}},
    shell = {
        mode = "fullscreen",
        layout = "tacrp",
        background = {12, 8, 8, 235},
        headerBackground = {18, 10, 10, 242},
        headerHeight = 44,
        titleAlign = "right",
        headerMaterial = "ft_base/providers/tacrp/hud/news.png",
        headerMaterialAlpha = 38,
        detail = {background = {20, 11, 11, 210}, material = "ft_base/providers/tacrp/hud/vignette", materialAlpha = 30, padding = 18, previewHeight = 248, titleFont = "FT_TacRP_Myriad_24", valueFont = "FT_TacRP_Myriad_16", statsTitleFont = "FT_TacRP_Myriad_24", statsFont = "FT_TacRP_Myriad_16"},
        slot = {height = 52, marginLeft = 8, marginTop = 7},
        slotIcons = {default = "ft_base/providers/tacrp/hud/dot.png"},
        button = {background = {39, 18, 18, 224}, hover = {202, 89, 80, 235}, selected = {202, 89, 80, 245}, text = {243, 184, 178, 255}, hoverText = {22, 9, 9, 255}, border = {202, 89, 80, 90}, corner = 0},
        removeLabel = "REMOVE",
        closeLabel = "X",
        closeWidth = 44,
        statsTitle = "BALLISTICS"
    },
    slotOrder = {optic = 10, barrel = 20, muzzle = 30, stock = 40},
    stats = {{label = "Damage max", path = "damage.base"}, {label = "Damage min", path = "damage.minimum"}, {label = "Armor penetration", path = "ballistics.armor.scale"}, {label = "Free aim", path = "camera.freeAim.radius"}},
    DrawHUD = drawTacRPHUD
})

FTBase.Runtime.Visuals = Visuals
