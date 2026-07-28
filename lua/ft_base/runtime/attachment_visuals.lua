FTBase = FTBase or {}
FTBase.Runtime = FTBase.Runtime or {}

local AttachmentVisuals = FTBase.Module.Define("AttachmentVisuals", {})

local Table = FTBase.Util.Table
local Types = FTBase.Util.Types

local function firstTable(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "table" then
            return value
        end
    end

    return nil
end

local function firstString(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "string" and value ~= "" then
            return value
        end
    end

    return nil
end

local function visualForRealm(definition, realm)
    local visuals = firstTable(definition.visuals, definition.visual) or {}
    local realmVisual = nil

    if realm == "view" then
        realmVisual = firstTable(
            visuals.view,
            visuals.viewmodel,
            visuals.viewModel,
            definition.viewVisual,
            definition.viewModelVisual
        )
    else
        realmVisual = firstTable(
            visuals.world,
            visuals.worldmodel,
            visuals.worldModel,
            definition.worldVisual,
            definition.worldModelVisual
        )
    end

    realmVisual = realmVisual or visuals

    local model = nil

    if realm == "view" then
        model = firstString(
            realmVisual.model,
            definition.viewModel,
            definition.viewmodel,
            definition.model
        )
    else
        model = firstString(
            realmVisual.model,
            definition.worldModel,
            definition.worldmodel,
            definition.model
        )
    end

    if not model then
        return nil
    end

    return {
        model = model,
        bone = firstString(realmVisual.bone, definition.bone),
        attachment = firstString(realmVisual.attachment, definition.attachment),
        pos = Types.Vector(realmVisual.pos or realmVisual.position or definition.pos or definition.position),
        ang = Types.Angle(realmVisual.ang or realmVisual.angle or definition.ang or definition.angle),
        scale = realmVisual.scale or definition.scale,
        skin = realmVisual.skin ~= nil and realmVisual.skin or definition.skin,
        material = firstString(realmVisual.material, definition.material),
        materials = firstTable(realmVisual.materials, realmVisual.subMaterials, definition.materials),
        bodygroups = firstTable(realmVisual.bodygroups, definition.bodygroups),
        elements = firstTable(realmVisual.elements, definition.elements),
        color = realmVisual.color or definition.color,
        icon = firstString(realmVisual.icon, definition.icon, definition.iconMaterial)
    }
end

function AttachmentVisuals.GetDescriptors(runtime, realm)
    local descriptors = {}
    realm = realm == "world" and "world" or "view"

    if not runtime or not runtime.ir or not runtime.attachments then
        return descriptors
    end

    local definitions = runtime.ir.attachments and runtime.ir.attachments.definitions or {}

    for _, slot in ipairs(runtime.attachments.slots or {}) do
        local attachmentId = runtime.attachments.installed and runtime.attachments.installed[slot.id]
        local definition = attachmentId and definitions[attachmentId]
        local descriptor = type(definition) == "table" and visualForRealm(definition, realm) or nil

        if descriptor then
            descriptor.slotId = slot.id
            descriptor.attachmentId = attachmentId
            descriptors[#descriptors + 1] = descriptor
        end
    end

    return descriptors
end

local function removeModel(model)
    if model and (not IsValid or IsValid(model)) and model.Remove then
        model:Remove()
    end
end

function AttachmentVisuals.Cleanup(runtime)
    if not runtime or not runtime.attachmentVisualModels then
        return
    end

    for _, realmModels in pairs(runtime.attachmentVisualModels) do
        for _, model in pairs(realmModels) do
            removeModel(model)
        end
    end

    runtime.attachmentVisualModels = nil
end

function AttachmentVisuals.Refresh(runtime)
    if not runtime then
        return
    end

    AttachmentVisuals.Cleanup(runtime)
    runtime.attachmentVisualRevision = (runtime.attachmentVisualRevision or 0) + 1
end

local function validEntity(entity)
    return entity and (not IsValid or IsValid(entity))
end

local function ensureModel(runtime, realm, descriptor)
    if not CLIENT or not ClientsideModel then
        return nil
    end

    runtime.attachmentVisualModels = runtime.attachmentVisualModels or {view = {}, world = {}}
    local models = runtime.attachmentVisualModels[realm]
    local model = models[descriptor.slotId]

    if validEntity(model) and model.GetModel and model:GetModel() == descriptor.model then
        return model
    end

    removeModel(model)
    model = ClientsideModel(descriptor.model, RENDER_GROUP_VIEW_MODEL_OPAQUE or RENDERGROUP_OPAQUE)

    if not validEntity(model) then
        models[descriptor.slotId] = nil
        return nil
    end

    if model.SetNoDraw then
        model:SetNoDraw(true)
    end

    models[descriptor.slotId] = model
    return model
end

local function baseTransform(entity, descriptor)
    if not validEntity(entity) then
        return nil, nil
    end

    if descriptor.attachment and entity.LookupAttachment and entity.GetAttachment then
        local attachmentIndex = entity:LookupAttachment(descriptor.attachment)
        local attachment = attachmentIndex and attachmentIndex > 0 and entity:GetAttachment(attachmentIndex)

        if attachment then
            return attachment.Pos or attachment.pos, attachment.Ang or attachment.ang
        end
    end

    if descriptor.bone and entity.LookupBone and entity.GetBoneMatrix then
        local boneIndex = entity:LookupBone(descriptor.bone)
        local matrix = boneIndex and entity:GetBoneMatrix(boneIndex)

        if matrix and matrix.GetTranslation and matrix.GetAngles then
            return matrix:GetTranslation(), matrix:GetAngles()
        end
    end

    local position = entity.GetPos and entity:GetPos() or nil
    local angle = entity.GetAngles and entity:GetAngles() or nil
    return position, angle
end

local function transformed(entity, descriptor)
    local position, angle = baseTransform(entity, descriptor)

    if not position or not angle then
        return nil, nil
    end

    local localPosition = descriptor.pos or (Vector and Vector(0, 0, 0))
    local localAngle = descriptor.ang or (Angle and Angle(0, 0, 0))

    if LocalToWorld and localPosition and localAngle then
        return LocalToWorld(localPosition, localAngle, position, angle)
    end

    return position, angle
end

local function applyAppearance(model, descriptor)
    if descriptor.skin ~= nil and model.SetSkin then
        model:SetSkin(tonumber(descriptor.skin) or 0)
    end

    if descriptor.material and model.SetMaterial then
        model:SetMaterial(descriptor.material)
    end

    if type(descriptor.materials) == "table" and model.SetSubMaterial then
        for _, key in ipairs(Table.Keys(descriptor.materials)) do
            local index = tonumber(key)

            if index and index >= 0 then
                model:SetSubMaterial(index, tostring(descriptor.materials[key] or ""))
            end
        end
    end

    if type(descriptor.bodygroups) == "table" and model.SetBodygroup then
        for _, key in ipairs(Table.Keys(descriptor.bodygroups)) do
            local index = tonumber(key)

            if not index and model.FindBodygroupByName then
                index = model:FindBodygroupByName(tostring(key))
            end

            if index and index >= 0 then
                model:SetBodygroup(index, tonumber(descriptor.bodygroups[key]) or 0)
            end
        end
    end

    if type(descriptor.elements) == "table" then
        if descriptor.elements.bodygroups and model.SetBodygroup then
            for _, key in ipairs(Table.Keys(descriptor.elements.bodygroups)) do
                local index = tonumber(key)

                if not index and model.FindBodygroupByName then
                    index = model:FindBodygroupByName(tostring(key))
                end

                if index and index >= 0 then
                    model:SetBodygroup(index, tonumber(descriptor.elements.bodygroups[key]) or 0)
                end
            end
        end

        if descriptor.elements.skin ~= nil and model.SetSkin then
            model:SetSkin(tonumber(descriptor.elements.skin) or 0)
        end

        if descriptor.elements.material and model.SetMaterial then
            model:SetMaterial(tostring(descriptor.elements.material))
        end
    end

    if descriptor.color and model.SetColor and Color then
        local value = descriptor.color
        model:SetColor(Color(value.r or value[1] or 255, value.g or value[2] or 255, value.b or value[3] or 255, value.a or value[4] or 255))
    end

    if type(descriptor.scale) == "number" and model.SetModelScale then
        model:SetModelScale(descriptor.scale, 0)
    end
end

local function drawRealm(swep, entity, realm)
    local runtime = swep and swep.FTRuntime

    if not CLIENT or not runtime then
        return
    end

    for _, descriptor in ipairs(AttachmentVisuals.GetDescriptors(runtime, realm)) do
        local model = ensureModel(runtime, realm, descriptor)
        local position, angle = transformed(entity, descriptor)

        if model and position and angle then
            if model.SetPos then
                model:SetPos(position)
            end

            if model.SetAngles then
                model:SetAngles(angle)
            end

            applyAppearance(model, descriptor)

            if model.SetupBones then
                model:SetupBones()
            end

            if model.DrawModel then
                model:DrawModel()
            end
        end
    end
end

function AttachmentVisuals.DrawViewModel(swep, viewModel)
    drawRealm(swep, viewModel, "view")
end

function AttachmentVisuals.DrawWorldModel(swep)
    drawRealm(swep, swep, "world")
end

FTBase.Runtime.AttachmentVisuals = AttachmentVisuals
