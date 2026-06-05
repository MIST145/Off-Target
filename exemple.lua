RegisterCommand('off-target:example-native', function()
    ContextMenu.Register(function(builder, entity, entityType, worldPos, hit)
        if not hit then return end

        builder:SetHeader('Example', 'fa-solid fa-bolt')

        builder:AddItem(0, 'Hello', function(ent, coords)
            print('clicked hello on entity', ent, coords)
        end, 'fa-solid fa-hand', { color = { 99, 102, 241 } }, 'Prints a message.')

        builder:AddInfo(0, 'Entity', tostring(entity), 'fa-solid fa-hashtag')

        builder:AddSeparator(0)

        builder:AddCheckbox(0, 'Toggle me', false, function(checked, ent, coords)
            print('toggle is now', checked)
        end, 'fa-solid fa-toggle-on')

        local menu = builder:AddSubmenu(0, 'More', 'fa-solid fa-ellipsis', { color = { 234, 179, 8 } }, 'MORE OPTIONS')

        builder:AddItem(menu, 'Sub action', function()
            print('sub action')
        end, 'fa-solid fa-gear')

        if entityType == 2 then
            builder:AddItem(0, 'Lock vehicle', function(ent)
                SetVehicleDoorsLocked(ent, 2)
            end, 'fa-solid fa-lock', { color = { 239, 68, 68 } })
        end
    end)

    print('native example registered, hold the menu key and right-click')
end, false)

CreateThread(function()
    exports["Off-Target"]:addGlobalVehicle({
        {
            name = 'flip_vehicle',
            label = 'Flip Vehicle',
            icon = 'fa-solid fa-rotate',
            distance = 3.0,
            onSelect = function(data)
                SetVehicleOnGroundProperly(data.entity)
            end,
        },
    })

    exports["Off-Target"]:addGlobalPlayer({
        {
            name = 'wave_player',
            label = 'Wave',
            icon = 'fa-solid fa-hand',
            canInteract = function(entity, distance)
                return distance < 2.5
            end,
            onSelect = function()
                TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_CHEERING', 0, true)
            end,
        },
    })

    exports["Off-Target"]:addModel({ 'prop_atm_01', 'prop_atm_02', 'prop_atm_03' }, {
        {
            name = 'use_atm',
            label = 'Use ATM',
            icon = 'fa-solid fa-money-bill',
            distance = 1.5,
            onSelect = function()
                print('open atm ui')
            end,
        },
    })

    exports["Off-Target"]:addSphereZone({
        coords = vector3(195.0, -933.0, 30.0),
        radius = 2.0,
        options = {
            {
                name = 'shop_zone',
                label = 'Open Shop',
                icon = 'fa-solid fa-store',
                onSelect = function()
                    print('open shop')
                end,
            },
        },
    })

    exports["Off-Target"]:addBoxZone({
        coords = vector3(-1037.0, -2738.0, 20.0),
        size = vector3(3.0, 3.0, 2.0),
        options = {
            {
                name = 'box_action',
                label = 'Box Action',
                icon = 'fa-solid fa-cube',
                event = 'off-target:exampleEvent',
            },
        },
    })
end)

RegisterNetEvent('off-target:exampleEvent', function(data)
    print('box action triggered', data.entity, data.coords)
end)

local function spawnVehicleAt(model, coords, heading)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        print(('^1[example] invalid vehicle model: %s^0'):format(tostring(model)))
        return
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end
    if not HasModelLoaded(hash) then
        print('^1[example] vehicle model failed to load^0')
        return
    end

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z + 0.5, heading, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
end

local function requestControl(entity)
    if NetworkGetEntityIsNetworked(entity) then
        NetworkRequestControlOfEntity(entity)
        local timeout = GetGameTimer() + 1000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
            Wait(0)
        end
    end
end

RegisterCommand('off-target:example-ground', function()
    ContextMenu.Register(function(builder, entity, _, worldPos, hit)
        if not hit then return end
        if entity and entity ~= 0 then return end

        builder:SetHeader('Ground', 'fa-solid fa-location-dot')

        builder:AddInfo(0, 'Position',
            ('%.1f, %.1f, %.1f'):format(worldPos.x, worldPos.y, worldPos.z),
            'fa-solid fa-map-pin')

        builder:AddSeparator(0)

        builder:AddItem(0, 'Spawn vehicle here', function(_, coords)
            local ped = PlayerPedId()
            local heading = GetEntityHeading(ped)
            spawnVehicleAt('adder', coords or worldPos, heading)
        end, 'fa-solid fa-car', { color = { 99, 102, 241 } }, 'Spawns an Adder at this spot.')

        builder:AddItem(0, 'Teleport here', function(_, coords)
            local c = coords or worldPos
            local ped = PlayerPedId()
            SetPedCoordsKeepVehicle(ped, c.x, c.y, c.z + 1.0)
        end, 'fa-solid fa-person-walking-arrow-right', { color = { 16, 185, 129 } }, 'Move to this spot.')
    end)

    print('ground example registered, hold the menu key and point at the floor')
end, false)

ContextMenu.Register(function(builder, entity, _, _, hit)
    if not hit then return end
    local ped = PlayerPedId()
    if entity ~= ped then return end

    builder:SetHeader('Me', 'fa-solid fa-user')

    builder:AddItem(0, 'Hands Up', function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_HANDS_UP', 0, true)
    end, 'fa-solid fa-hands', { color = { 99, 102, 241 } })

    builder:AddItem(0, 'Stop Animation', function()
        ClearPedTasks(PlayerPedId())
    end, 'fa-solid fa-ban', { color = { 239, 68, 68 } })

    builder:AddSeparator(0)

    builder:AddCheckbox(0, 'Toggle Walk Style', false, function(checked)
        SetPedMovementClipset(PlayerPedId(), checked and 'move_m@drunk@verydrunk' or '', 1.0)
        if not checked then ResetPedMovementClipset(PlayerPedId(), 0.0) end
    end, 'fa-solid fa-shoe-prints')

    local emotes = builder:AddSubmenu(0, 'Emotes', 'fa-solid fa-face-smile', { color = { 234, 179, 8 } }, 'EMOTES')

    builder:AddItem(emotes, 'Salute', function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_GUARD_STAND', 0, true)
    end, 'fa-solid fa-hand')

    builder:AddItem(emotes, 'Smoke', function()
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_SMOKING', 0, true)
    end, 'fa-solid fa-smoking')

    builder:AddInfo(0, 'Health', tostring(GetEntityHealth(ped) - 100), 'fa-solid fa-heart-pulse')
end)

ContextMenu.Register(function(builder, entity, entityType, _, hit)
    if not hit or entity == 0 then return end
    if entityType ~= 1 then return end
    if IsPedAPlayer(entity) then return end

    builder:SetHeader('NPC', 'fa-solid fa-person')

    builder:AddItem(0, 'Talk', function(ent)
        requestControl(ent)
        TaskTurnPedToFaceEntity(ent, PlayerPedId(), 2000)
        PlayAmbientSpeech1(ent, 'GENERIC_HI', 'SPEECH_PARAMS_FORCE')
    end, 'fa-solid fa-comments', { color = { 99, 102, 241 } }, 'Make the NPC turn and greet you.')

    builder:AddItem(0, 'Hands Up', function(ent)
        requestControl(ent)
        TaskHandsUp(ent, 10000, PlayerPedId(), -1, true)
    end, 'fa-solid fa-hands', nil, 'Force the NPC to raise their hands.')

    builder:AddItem(0, 'Freeze / Unfreeze', function(ent)
        requestControl(ent)
        FreezeEntityPosition(ent, not IsEntityPositionFrozen(ent))
    end, 'fa-solid fa-snowflake', { color = { 234, 179, 8 } }, 'Lock or unlock the NPC in place.')

    builder:AddItem(0, 'Clear Tasks', function(ent)
        requestControl(ent)
        ClearPedTasksImmediately(ent)
    end, 'fa-solid fa-ban', { color = { 239, 68, 68 } }, 'Stop whatever the NPC is doing.')
end)

ContextMenu.Register(function(builder, entity, entityType, _, hit)
    if not hit or entity == 0 then return end
    if entityType ~= 2 then return end

    builder:SetHeader('Vehicle', 'fa-solid fa-car')

    builder:AddInfo(0, 'Plate', GetVehicleNumberPlateText(entity), 'fa-solid fa-id-card', nil, 'License plate of this vehicle.')

    builder:AddItem(0, 'Toggle Engine', function(ent)
        requestControl(ent)
        SetVehicleEngineOn(ent, not GetIsVehicleEngineRunning(ent), false, true)
    end, 'fa-solid fa-power-off', { color = { 99, 102, 241 } }, 'Turn the engine on or off.')

    builder:AddItem(0, 'Lock / Unlock', function(ent)
        requestControl(ent)
        SetVehicleDoorsLocked(ent, GetVehicleDoorLockStatus(ent) == 2 and 1 or 2)
    end, 'fa-solid fa-lock', { color = { 234, 179, 8 } }, 'Toggle the door locks.')

    local doors = builder:AddSubmenu(0, 'Doors', 'fa-solid fa-car-side', nil, 'DOORS')

    builder:AddItem(doors, 'Hood', function(ent)
        requestControl(ent)
        if GetVehicleDoorAngleRatio(ent, 4) > 0.0 then SetVehicleDoorShut(ent, 4, false) else SetVehicleDoorOpen(ent, 4, false, false) end
    end, 'fa-solid fa-car', nil, 'Open or close the hood.')

    builder:AddItem(doors, 'Trunk', function(ent)
        requestControl(ent)
        if GetVehicleDoorAngleRatio(ent, 5) > 0.0 then SetVehicleDoorShut(ent, 5, false) else SetVehicleDoorOpen(ent, 5, false, false) end
    end, 'fa-solid fa-box', nil, 'Open or close the trunk.')

    builder:AddSeparator(0)

    builder:AddItem(0, 'Clean & Repair', function(ent)
        requestControl(ent)
        SetVehicleFixed(ent)
        SetVehicleDirtLevel(ent, 0.0)
    end, 'fa-solid fa-wrench', { color = { 16, 185, 129 } }, 'Fully repair and clean the vehicle.')
end)

ContextMenu.Register(function(builder, entity, entityType, _, hit)
    if not hit or entity == 0 then return end
    if entityType ~= 3 then return end

    builder:SetHeader('Object', 'fa-solid fa-cube')

    builder:AddInfo(0, 'Model', tostring(GetEntityModel(entity)), 'fa-solid fa-hashtag', nil, 'Model hash of this object.')

    builder:AddItem(0, 'Pick Up', function(ent)
        requestControl(ent)
        AttachEntityToEntity(ent, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end, 'fa-solid fa-hand', { color = { 99, 102, 241 } }, 'Hold the object in your hand.')

    builder:AddItem(0, 'Drop', function(ent)
        requestControl(ent)
        DetachEntity(ent, true, true)
    end, 'fa-solid fa-hand-point-down', { color = { 234, 179, 8 } }, 'Detach and drop the object.')

    builder:AddItem(0, 'Delete', function(ent)
        requestControl(ent)
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end, 'fa-solid fa-trash', { color = { 239, 68, 68 } }, 'Remove the object from the world.')
end)

ContextMenu.Register(function(builder, entity, _, worldPos, hit)
    if not hit then return end
    if entity and entity ~= 0 then return end

    builder:SetHeader('World', 'fa-solid fa-location-dot')

    builder:AddInfo(0, 'Position',
        ('%.1f, %.1f, %.1f'):format(worldPos.x, worldPos.y, worldPos.z),
        'fa-solid fa-map-pin', nil, 'Coordinates you are pointing at.')

    builder:AddSeparator(0)

    builder:AddItem(0, 'Teleport here', function(_, coords)
        local c = coords or worldPos
        SetPedCoordsKeepVehicle(PlayerPedId(), c.x, c.y, c.z + 1.0)
    end, 'fa-solid fa-person-walking-arrow-right', { color = { 16, 185, 129 } }, 'Move yourself to this spot.')

    builder:AddItem(0, 'Set Waypoint', function(_, coords)
        local c = coords or worldPos
        SetNewWaypoint(c.x, c.y)
    end, 'fa-solid fa-flag', { color = { 99, 102, 241 } }, 'Place a GPS waypoint here.')

    builder:AddItem(0, 'Spawn Vehicle', function(_, coords)
        spawnVehicleAt('adder', coords or worldPos, GetEntityHeading(PlayerPedId()))
    end, 'fa-solid fa-car', nil, 'Spawn an Adder facing your direction.')
end)
