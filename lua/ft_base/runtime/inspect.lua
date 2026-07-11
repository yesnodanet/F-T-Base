FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local Inspect = FTBase.Module.Define("Inspect", {
    Active = nil
})

local function validWeapon(swep)
    if not swep or not swep.FTRuntime then
        return false
    end

    return not IsValid or IsValid(swep)
end

local function formatStat(label, value)
    return label .. ": " .. tostring(FTBase.Util.Math.Round(value or 0, 3))
end

local function createLabel(parent, text, font)
    local label = parent:Add("DLabel")
    label:SetText(text)
    label:SetFont(font or "DermaDefault")
    label:SetTextColor(Color(225, 230, 236))
    label:Dock(TOP)
    label:DockMargin(12, 6, 12, 0)
    label:SizeToContentsY()
    return label
end

local function buildDetail(frame, slot)
    local detail = frame.FTDetail
    detail:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider
    local ir = FTBase.Runtime.Customization.GetEffectiveIR(runtime)
    local installed = runtime.attachments.installed[slot.id]
    local definition = installed and runtime.ir.attachments.definitions[installed]

    local model = detail:Add("DModelPanel")
    model:Dock(TOP)
    model:SetTall(220)
    model:SetModel(ir.rendering.viewModel or "models/weapons/c_pistol.mdl")
    model:SetFOV(45)
    model:SetCamPos(Vector(45, 45, 32))
    model:SetLookAt(Vector(0, 0, 0))

    createLabel(detail, provider:GetSlotLabel(slot), "DermaLarge")
    createLabel(detail, definition and ("Installed: " .. provider:GetInstalledLabel(definition, installed)) or provider:GetInstalledLabel(nil), "DermaDefaultBold")

    if provider.id == "mixed" then
        createLabel(detail, "Source: " .. tostring(ir.ui.customization.source or "mixed"))
    end

    local clear = detail:Add("DButton")
    clear:Dock(TOP)
    clear:DockMargin(12, 10, 12, 0)
    clear:SetTall(28)
    clear:SetText(provider.id == "mw" and "Remove from gunsmith" or "Remove attachment")
    clear:SetEnabled(installed ~= nil)
    clear.DoClick = function()
        local request = provider:BuildRequest(slot.id, "")
        FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
    end

    for _, option in ipairs(provider:GetOptions(runtime, slot.id)) do
        local button = detail:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(12, 6, 12, 0)
        button:SetTall(32)
        button:SetText(provider:GetOptionLabel(option))
        button:SetTooltip(provider:GetOptionDescription(option))
        button.DoClick = function()
            local request = provider:BuildRequest(slot.id, option.id)
            FTBase.Runtime.Networking.RequestAttachment(frame.FTWeapon, request.slotId, request.attachmentId)
        end
    end

    createLabel(detail, "Weapon statistics", "DermaLarge")
    createLabel(detail, formatStat("Damage", ir.damage.base))
    createLabel(detail, formatStat("RPM", ir.fire.rpm))
    createLabel(detail, formatStat("Hip spread", ir.spread.hip))
    createLabel(detail, formatStat("ADS spread", ir.spread.ads))

    if provider.id == "mw" then
        createLabel(detail, "Gunsmith preview uses the selected attachment modifier before installation.", "DermaDefaultBold")
    end
end

local function buildSlots(frame)
    local list = frame.FTSlots
    list:Clear()

    local runtime = frame.FTWeapon.FTRuntime
    local provider = frame.FTProvider

    for _, slot in ipairs(provider:GetSlots(runtime)) do
        local installed = runtime.attachments.installed[slot.id]
        local definition = installed and runtime.ir.attachments.definitions[installed]
        local button = list:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(8, 6, 8, 0)
        button:SetTall(42)
        button:SetText(provider:GetSlotLabel(slot) .. "\n" .. provider:GetInstalledLabel(definition, installed))
        button.DoClick = function()
            frame.FTSelectedSlot = slot.id
            buildDetail(frame, slot)
        end
    end
end

function Inspect.Open(swep, providerId)
    if not CLIENT or not vgui or not validWeapon(swep) then
        return false
    end

    Inspect.Close()

    local runtime = swep.FTRuntime
    local provider = FTBase.Runtime.Customization.GetProvider(runtime)

    if providerId and provider.id ~= providerId then
        provider = FTBase.Runtime.Customization.GetProvider({
            ir = {
                ui = {
                    customization = {
                        provider = providerId
                    }
                }
            }
        })
    end

    local ir = FTBase.Runtime.Customization.GetEffectiveIR(runtime)
    local frame = vgui.Create("DFrame")
    frame:SetSize(provider.frame.width, provider.frame.height)
    frame:Center()
    frame:SetTitle(provider.title .. " - " .. (ir.meta.printName or swep.PrintName or "Weapon"))
    frame:MakePopup()
    frame.FTWeapon = swep
    frame.FTProvider = provider
    frame.OnClose = function()
        if Inspect.Active == frame then
            Inspect.Active = nil
        end
    end

    local slots = vgui.Create("DScrollPanel", frame)
    slots:Dock(LEFT)
    slots:SetWide(270)
    frame.FTSlots = slots

    local detail = vgui.Create("DScrollPanel", frame)
    detail:Dock(FILL)
    frame.FTDetail = detail

    Inspect.Active = frame
    buildSlots(frame)

    local firstSlot = provider:GetSlots(runtime)[1]

    if firstSlot then
        frame.FTSelectedSlot = firstSlot.id
        buildDetail(frame, firstSlot)
    else
        createLabel(detail, "This weapon has no attachment slots.", "DermaLarge")
    end

    return true
end

function Inspect.Close(swep)
    local frame = Inspect.Active

    if not frame or not IsValid(frame) then
        Inspect.Active = nil
        return
    end

    if swep and frame.FTWeapon ~= swep then
        return
    end

    frame:Close()
end

function Inspect.Toggle(swep)
    if Inspect.Active and IsValid(Inspect.Active) and Inspect.Active.FTWeapon == swep then
        Inspect.Close(swep)
        return false
    end

    return Inspect.Open(swep)
end

function Inspect.Refresh(swep)
    local frame = Inspect.Active

    if not frame or not IsValid(frame) or frame.FTWeapon ~= swep then
        return
    end

    buildSlots(frame)

    local slot = FTBase.Runtime.Attachments.GetSlot(swep.FTRuntime, frame.FTSelectedSlot)

    if slot then
        buildDetail(frame, slot)
    end
end

local function activeWeapon()
    local player = LocalPlayer and LocalPlayer()

    if not player or not player.GetActiveWeapon then
        return nil
    end

    return player:GetActiveWeapon()
end

function Inspect.ToggleActiveWeapon()
    local swep = activeWeapon()

    if validWeapon(swep) then
        return FTBase.Runtime.Customization.Open(swep)
    end

    return false
end

if CLIENT and concommand then
    concommand.Add("ft_customize", function()
        Inspect.ToggleActiveWeapon()
    end)

    concommand.Add("ft_customice", function()
        Inspect.ToggleActiveWeapon()
    end)
end

FTBase.Runtime.Inspect = Inspect
