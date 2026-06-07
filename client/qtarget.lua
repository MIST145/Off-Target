local resourceName = GetCurrentResourceName()
local target = exports[resourceName]

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qtarget_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

---@param options table
---@return table
local function convert(options)
    local distance = options.distance
    options = options.options

    for k, v in pairs(options) do
        if type(k) ~= 'number' then
            table.insert(options, v)
        end
    end

    for id, v in pairs(options) do
        if type(id) ~= 'number' then
            options[id] = nil
            goto continue
        end

        v.onSelect = v.action
        v.distance = v.distance or distance
        v.name = v.name or v.label
        v.groups = v.job
        v.items = v.item or v.required_item

        if v.event and v.type and v.type ~= 'client' then
            if v.type == 'server' then
                v.serverEvent = v.event
            elseif v.type == 'command' then
                v.command = v.event
            end

            v.event = nil
            v.type = nil
        end

        v.action = nil
        v.job = nil
        v.item = nil
        v.required_item = nil
        v.qtarget = true

        ::continue::
    end

    return options
end

exportHandler('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local z = center.z

    if not options.minZ then
        options.minZ = -100
    end

    if not options.maxZ then
        options.maxZ = 800
    end

    if not options.useZ then
        z = z + math.abs(options.maxZ - options.minZ) / 2
        center = vec3(center.x, center.y, z)
    end

    return target:addBoxZone({
        name = name,
        coords = center,
        size = vec3(width, length, (options.useZ or not options.maxZ) and center.z or math.abs(options.maxZ - options.minZ)),
        debug = options.debugPoly,
        rotation = options.heading,
        options = convert(targetoptions),
    })
end)

exportHandler('AddPolyZone', function(name, points, options, targetoptions)
    local newPoints = table.create(#points, 0)
    local thickness = math.abs(options.maxZ - options.minZ)

    for i = 1, #points do
        local point = points[i]
        newPoints[i] = vec3(point.x, point.y, options.maxZ - (thickness / 2))
    end

    return target:addPolyZone({
        name = name,
        points = newPoints,
        thickness = thickness,
        minZ = options.minZ,
        maxZ = options.maxZ,
        debug = options.debugPoly,
        options = convert(targetoptions),
    })
end)

exportHandler('AddCircleZone', function(name, center, radius, options, targetoptions)
    return target:addSphereZone({
        name = name,
        coords = center,
        radius = radius,
        debug = options.debugPoly,
        options = convert(targetoptions),
    })
end)

exportHandler('RemoveZone', function(id)
    target:removeZone(id)
end)

exportHandler('AddTargetBone', function(bones, options)
    if type(bones) ~= 'table' then bones = { bones } end
    options = convert(options)

    for _, v in pairs(options) do
        v.bones = bones
    end

    target:addGlobalVehicle(options)
end)

exportHandler('AddTargetEntity', function(entities, options)
    if type(entities) ~= 'table' then entities = { entities } end
    options = convert(options)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            target:addEntity(NetworkGetNetworkIdFromEntity(entity), options)
        else
            target:addLocalEntity(entity, options)
        end
    end
end)

exportHandler('RemoveTargetEntity', function(entities, labels)
    if type(entities) ~= 'table' then entities = { entities } end

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            target:removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
        else
            target:removeLocalEntity(entity, labels)
        end
    end
end)

exportHandler('AddTargetModel', function(models, options)
    target:addModel(models, convert(options))
end)

exportHandler('RemoveTargetModel', function(models, labels)
    target:removeModel(models, labels)
end)

exportHandler('Ped', function(options)
    target:addGlobalPed(convert(options))
end)

exportHandler('RemovePed', function(labels)
    target:removeGlobalPed(labels)
end)

exportHandler('Vehicle', function(options)
    target:addGlobalVehicle(convert(options))
end)

exportHandler('RemoveVehicle', function(labels)
    target:removeGlobalVehicle(labels)
end)

exportHandler('Object', function(options)
    target:addGlobalObject(convert(options))
end)

exportHandler('RemoveObject', function(labels)
    target:removeGlobalObject(labels)
end)

exportHandler('Player', function(options)
    local playerType = options.type

    if playerType == 'self' then
        target:addGlobalSelfPlayer(convert(options))
    elseif playerType == 'other' then
        target:addGlobalOtherPlayer(convert(options))
    else
        target:addGlobalPlayer(convert(options))
    end
end)

exportHandler('RemovePlayer', function(labels)
    target:removeGlobalPlayer(labels)
end)

exportHandler('Globals', function(options)
    target:addGlobalOption(convert(options))
end)

exportHandler('RemoveGlobals', function(labels)
    target:removeGlobalOption(labels)
end)
