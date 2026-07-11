FTBase = FTBase or {}

local Validator = {}

local function isNumber(value)
    return type(value) == "number"
end

function Validator.Validate(ir, report)
    report = report or FTBase.Report.New("validation")

    if not isNumber(ir.damage.base) or ir.damage.base < 0 then
        report:AddWarning("damage.base should be a non-negative number")
    end

    if not isNumber(ir.fire.rpm) or ir.fire.rpm <= 0 then
        report:AddWarning("fire.rpm should be greater than zero")
    end

    if not isNumber(ir.ammo.clipSize) or ir.ammo.clipSize < 0 then
        report:AddWarning("ammo.clipSize should be a non-negative number")
    end

    if not ir.sounds.fire.layers or #ir.sounds.fire.layers == 0 then
        report:AddMissingSound("sounds.fire.layers")
    end

    if not ir.animations.base or not ir.animations.base.reload then
        report:AddMissingAnimation("animations.base.reload")
    end

    for index, slot in ipairs(ir.attachments.slots or {}) do
        if type(slot) ~= "table" or not slot.id then
            report:AddInvalidAttachment("attachments.slots[" .. tostring(index) .. "] is missing id", slot)
        end
    end

    for _, plugin in ipairs(FTBase.Plugin and FTBase.Plugin.GetAll() or {}) do
        if plugin.Validate then
            plugin.Validate(ir, report)
        end
    end

    return report
end

FTBase.Validator = Validator
