local OxTarget = {}

local globalPlayer = {}
local globalPed = {}
local globalVehicle = {}
local globalObject = {}
local models = {}
local localEntities = {}
local networkEntities = {}
local zones = {}

local zoneIdCounter = 0
local targetingDisabled = false

local function tableInsertList(target, options)
    if options.name or options.label or options.onSelect or options.event or options.serverEvent or options.command or options.export then
        target[#target + 1] = options
        return
    end
    for i = 1, #options do
        target[#target + 1] = options[i]
    end
end

local function ensureList(value)
    if type(value) == 'table' then return value end
    return { value }
end

local function removeByNames(list, names)
    if not names then
        for i = #list, 1, -1 do list[i] = nil end
        return
    end
    local lookup = {}
    for _, n in ipairs(ensureList(names)) do lookup[n] = true end
    for i = #list, 1, -1 do
        if list[i].name and lookup[list[i].name] then
            table.remove(list, i)
        end
    end
end

local function resolveModelKey(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    local ok, model = pcall(GetEntityModel, entity)
    if not ok then return nil end
    return model
end

local function canInteract(option, entity, distance, coords, name, bone)
    if option.canInteract then
        local ok, result = pcall(option.canInteract, entity, distance, coords, name, bone)
        if not ok then return false end
        return result ~= false
    end
    return true
end

local function withinDistance(option, distance)
    local max = option.distance or 7.0
    return distance <= max
end

local function triggerOption(option, entity, coords)
    local data = {
        entity = entity,
        coords = coords,
        distance = #(GetEntityCoords(PlayerPedId()) - coords),
    }

    if option.onSelect then
        option.onSelect(data)
    elseif option.export then
        local resource, fn = option.export:match('([^%.]+)%.([^%.]+)')
        if resource and fn then exports[resource][fn](data) end
    elseif option.event then
        TriggerEvent(option.event, data)
    elseif option.serverEvent then
        TriggerServerEvent(option.serverEvent, data)
    elseif option.command then
        ExecuteCommand(option.command)
    end
end

local function collectOptions(out, list, entity, coords, distance)
    for _, option in ipairs(list) do
        if withinDistance(option, distance)
            and canInteract(option, entity, distance, coords, option.name, nil) then
            out[#out + 1] = option
        end
    end
end

ContextMenu.Register(function(builder, entity, entityType, worldPos, hit)
    if targetingDisabled or not hit then return end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - worldPos)
    local matched = {}

    if entity and entity ~= 0 and DoesEntityExist(entity) then
        local model = resolveModelKey(entity)

        if models[model] then
            collectOptions(matched, models[model], entity, worldPos, distance)
        end

        if NetworkGetEntityIsNetworked(entity) then
            local netId = NetworkGetNetworkIdFromEntity(entity)
            if networkEntities[netId] then
                collectOptions(matched, networkEntities[netId], entity, worldPos, distance)
            end
        end

        if localEntities[entity] then
            collectOptions(matched, localEntities[entity], entity, worldPos, distance)
        end

        if entityType == 1 then
            if IsPedAPlayer(entity) then
                collectOptions(matched, globalPlayer, entity, worldPos, distance)
            else
                collectOptions(matched, globalPed, entity, worldPos, distance)
            end
        elseif entityType == 2 then
            collectOptions(matched, globalVehicle, entity, worldPos, distance)
        elseif entityType == 3 then
            collectOptions(matched, globalObject, entity, worldPos, distance)
        end
    end

    for _, zone in pairs(zones) do
        if zone:contains(worldPos) then
            collectOptions(matched, zone.options, entity, worldPos, distance)
        end
    end

    if #matched == 0 then return end

    for _, option in ipairs(matched) do
        local style = option.iconColor and { color = option.iconColor } or nil
        builder:AddItem(0, option.label or option.name or 'Option', function(ent, coords)
            triggerOption(option, ent, coords or worldPos)
        end, option.icon, style, option.description)
    end
end)

function OxTarget.addGlobalPlayer(options) tableInsertList(globalPlayer, options) end
function OxTarget.addGlobalPed(options) tableInsertList(globalPed, options) end
function OxTarget.addGlobalVehicle(options) tableInsertList(globalVehicle, options) end
function OxTarget.addGlobalObject(options) tableInsertList(globalObject, options) end

function OxTarget.removeGlobalPlayer(names) removeByNames(globalPlayer, names) end
function OxTarget.removeGlobalPed(names) removeByNames(globalPed, names) end
function OxTarget.removeGlobalVehicle(names) removeByNames(globalVehicle, names) end
function OxTarget.removeGlobalObject(names) removeByNames(globalObject, names) end

function OxTarget.addModel(input, options)
    for _, m in ipairs(ensureList(input)) do
        local key = type(m) == 'string' and joaat(m) or m
        models[key] = models[key] or {}
        tableInsertList(models[key], options)
    end
end

function OxTarget.removeModel(input, names)
    for _, m in ipairs(ensureList(input)) do
        local key = type(m) == 'string' and joaat(m) or m
        if models[key] then removeByNames(models[key], names) end
    end
end

function OxTarget.addEntity(input, options)
    for _, netId in ipairs(ensureList(input)) do
        networkEntities[netId] = networkEntities[netId] or {}
        tableInsertList(networkEntities[netId], options)
    end
end

function OxTarget.removeEntity(input, names)
    for _, netId in ipairs(ensureList(input)) do
        if networkEntities[netId] then removeByNames(networkEntities[netId], names) end
    end
end

function OxTarget.addLocalEntity(input, options)
    for _, ent in ipairs(ensureList(input)) do
        localEntities[ent] = localEntities[ent] or {}
        tableInsertList(localEntities[ent], options)
    end
end

function OxTarget.removeLocalEntity(input, names)
    for _, ent in ipairs(ensureList(input)) do
        if localEntities[ent] then removeByNames(localEntities[ent], names) end
    end
end

local function registerZone(zone)
    zoneIdCounter = zoneIdCounter + 1
    zone.id = zoneIdCounter
    zone.options = zone.options or {}
    zones[zoneIdCounter] = zone
    return zoneIdCounter
end

function OxTarget.addSphereZone(params)
    local coords = params.coords
    local radius = params.radius or 2.0
    local zone = {
        options = params.options,
        contains = function(_, point) return #(coords - point) <= radius end,
    }
    return registerZone(zone)
end

function OxTarget.addBoxZone(params)
    local coords = params.coords
    local size = params.size or vector3(2.0, 2.0, 2.0)
    local half = size / 2.0
    local zone = {
        options = params.options,
        contains = function(_, point)
            local d = point - coords
            return math.abs(d.x) <= half.x and math.abs(d.y) <= half.y and math.abs(d.z) <= half.z
        end,
    }
    return registerZone(zone)
end

function OxTarget.addPolyZone(params)
    local points = params.points
    local minZ = params.minZ
    local maxZ = params.maxZ
    local zone = {
        options = params.options,
        contains = function(_, point)
            if minZ and point.z < minZ then return false end
            if maxZ and point.z > maxZ then return false end
            local inside = false
            local j = #points
            for i = 1, #points do
                local pi, pj = points[i], points[j]
                if ((pi.y > point.y) ~= (pj.y > point.y))
                    and (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x) then
                    inside = not inside
                end
                j = i
            end
            return inside
        end,
    }
    return registerZone(zone)
end

function OxTarget.removeZone(id)
    zones[id] = nil
end

function OxTarget.disableTargeting(state)
    targetingDisabled = state == true
end

for name, fn in pairs(OxTarget) do
    exports(name, fn)
end
