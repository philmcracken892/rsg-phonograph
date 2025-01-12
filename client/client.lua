-- Variables

local RSGCore = exports['rsg-core']:GetCoreObject()
local deployeddecks = nil
local deployedOwner = nil


-- Functions

local function loadAnimDict(dict)
  while (not HasAnimDictLoaded(dict)) do
      RequestAnimDict(dict)
      Wait(5)
  end
end

local function helpText(text)
	SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- target
Citizen.CreateThread(function()
    local djdecksprop = {
        `P_PHONOGRAPH01X`,
    }
    exports['rsg-target']:AddTargetModel(djdecksprop, {
        options = {
            {
                type = "client",
                event = "rsg_phonograph:client:playMusic",
                icon = "fas fa-record-vinyl",
                label = "Music Menu",
                canInteract = function(entity)
                    local playerId = GetPlayerServerId(PlayerId())
                    local networkId = NetworkGetNetworkIdFromEntity(entity)
                    return networkId == deployeddecks and deployedOwner == playerId
                end
            },
            {
                type = "client",
                event = "rsg_phonograph:client:pickupDJEquipment",
                icon = "fas fa-undo",
                label = "Pickup Equipment",
                canInteract = function(entity)
                    local playerId = GetPlayerServerId(PlayerId())
                    local networkId = NetworkGetNetworkIdFromEntity(entity)
                    return networkId == deployeddecks and deployedOwner == playerId
                end
            }
        },
        distance = 3.0
    })
end)


-- Events

-- place dj equipment
RegisterNetEvent('rsg_phonograph:client:placeDJEquipment', function()
    local playerId = GetPlayerServerId(PlayerId())
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    local x, y, z = table.unpack(coords + forward * 0.5)
    local object = CreateObject(GetHashKey('P_PHONOGRAPH01X'), x, y, z, true, false, false)
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), -1, true, "StartScenario", 0, false)
    PlaceObjectOnGroundProperly(object)
    SetEntityHeading(object, heading)
    FreezeEntityPosition(object, true)
    Wait(500)
    ClearPedTasks(PlayerPedId())
    deployeddecks = NetworkGetNetworkIdFromEntity(object)
    deployedOwner = playerId -- Store the owner's ID
end)


RegisterNetEvent('rsg_phonograph:client:playMusic', function(data)
    lib.registerContext({
        id = 'music_menu',
        title = '💿 Music Box',
        options = {
            {
                title = '🎶 Play a song',
                description = 'Enter a youtube URL',
                onSelect = function()
                    TriggerEvent('rsg_phonograph:client:musicMenu', {
                        entity = deployeddecks
                    })
                end
            },
            {
                title = '⏸️ Pause Music',
                description = 'Pause currently playing music',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:pauseMusic', {
                        entity = deployeddecks
                    })
                end
            },
            {
                title = '▶️ Resume Music',
                description = 'Resume playing paused music',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:resumeMusic', {
                        entity = deployeddecks
                    })
                end
            },
            {
                title = '🔈 Change Volume',
                description = 'Adjust the music volume',
                onSelect = function()
                    TriggerEvent('rsg_phonograph:client:changeVolume')
                end
            },
            {
                title = '📍 Change Range',
                description = 'Adjust how far the music can be heard',
                onSelect = function()
                    TriggerEvent('rsg_phonograph:client:changeRadius')
                end
            },
            {
                title = '❌ Turn off music',
                description = 'Stop the music & choose a new song',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:stopMusic', {
                        entity = deployeddecks
                    })
                end
            }
        }
    })

    lib.showContext('music_menu')
end)

RegisterNetEvent('rsg_phonograph:client:changeRadius', function()
    lib.registerContext({
        id = 'radius_menu',
        title = '📍 Sound Range Control',
        options = {
            {
                title = '🏠 Small Range (5m)',
                description = 'Intimate setting, just around the phonograph',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeRadius', 5.0, deployeddecks)
                end
            },
            {
                title = '🏘️ Medium Range (10m)',
                description = 'Good for small gatherings',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeRadius', 10.0, deployeddecks)
                end
            },
            {
                title = '🏰 Large Range (15m)',
                description = 'Perfect for larger events',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeRadius', 15.0, deployeddecks)
                end
            },
            {
                title = '⚙️ Custom Range',
                description = 'Set a custom range (1-20m)',
                onSelect = function()
                    local input = lib.inputDialog('Custom Range', {
                        {
                            type = 'number',
                            label = 'Range in meters',
                            description = 'Enter a value between 1 and 20 meters',
                            required = true,
                            min = 1,
                            max = 20,
                            step = 1,
                            default = 10
                        }
                    })
                    
                    if input then
                        local radius = input[1]
                        if radius then
                            TriggerServerEvent('rsg_phonograph:server:changeRadius', radius, deployeddecks)
                        end
                    end
                end
            }
        }
    })

    lib.showContext('radius_menu')
end)
-- Music Selection Menu
RegisterNetEvent('rsg_phonograph:client:musicMenu', function()
    local input = lib.inputDialog('Song Selection', {
        {
            type = 'input',
            label = 'YouTube URL',
            description = 'Enter the URL of the song you want to play',
            required = true,
            placeholder = 'https://youtube.com/...'
        }
    })
    
    if input then
        local song = input[1]
        if song then
            TriggerServerEvent('rsg_phonograph:server:playMusic', song, deployeddecks, GetEntityCoords(NetworkGetEntityFromNetworkId(deployeddecks)))
        end
    end
end)

RegisterNetEvent('rsg_phonograph:client:changeVolume', function()
    lib.registerContext({
        id = 'volume_menu',
        title = '🔊 Volume Control',
        options = {
            {
                title = '🔈 Whisper Volume (5%)',
                description = 'Set volume to 0.05',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 0.05, deployeddecks)
                end
            },
            {
                title = '🔈 Very Low Volume (10%)',
                description = 'Set volume to 0.10',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 0.10, deployeddecks)
                end
            },
            {
                title = '🔈 Low Volume (25%)',
                description = 'Set volume to 0.25',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 0.25, deployeddecks)
                end
            },
            {
                title = '🔉 Medium Volume (50%)',
                description = 'Set volume to 0.50',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 0.50, deployeddecks)
                end
            },
            {
                title = '🔊 High Volume (75%)',
                description = 'Set volume to 0.75',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 0.75, deployeddecks)
                end
            },
            {
                title = '📢 Maximum Volume (100%)',
                description = 'Set volume to 1.00',
                onSelect = function()
                    TriggerServerEvent('rsg_phonograph:server:changeVolume', 1.00, deployeddecks)
                end
            },
            {
                title = '⚙️ Custom Volume',
                description = 'Enter a custom volume (0.01-1.00)',
                onSelect = function()
                    local input = lib.inputDialog('Custom Volume', {
                        {
                            type = 'number',
                            label = 'Volume Level',
                            description = 'Enter a value between 0.01 and 1.00',
                            required = true,
                            min = 0.01,
                            max = 1.00,
                            step = 0.01,
                            default = 0.50
                        }
                    })
                    
                    if input then
                        local volume = input[1]
                        if volume then
                            TriggerServerEvent('rsg_phonograph:server:changeVolume', volume, deployeddecks)
                        end
                    end
                end
            }
        }
    })

    lib.showContext('volume_menu')
end)

RegisterNetEvent('rsg_phonograph:client:pickupDJEquipment', function()
    local playerId = GetPlayerServerId(PlayerId())
    if not deployeddecks or deployedOwner ~= playerId then
        TriggerEvent('lib:notify', {title = 'Error', description = 'You do not own this equipment!', type = 'error'})
        return
    end

    local obj = NetworkGetEntityFromNetworkId(deployeddecks)
    if not DoesEntityExist(obj) then
        TriggerEvent('lib:notify', {title = 'Error', description = 'Equipment not found!', type = 'error'})
        return
    end

    NetworkRequestControlOfEntity(obj)
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_CROUCH_INSPECT"), -1, true, "StartScenario", 0, false)
    Wait(500)
    DeleteEntity(obj)
    if not DoesEntityExist(obj) then
        TriggerServerEvent('rsg_phonograph:server:pickedup', deployeddecks)
        TriggerServerEvent('rsg_phonograph:server:pickeupdecks')
        deployeddecks = nil
        deployedOwner = nil -- Clear the owner
    else
        TriggerEvent('lib:notify', {title = 'Error', description = 'Failed to remove equipment.', type = 'error'})
    end
    Wait(500)
    ClearPedTasks(PlayerPedId())
end)

