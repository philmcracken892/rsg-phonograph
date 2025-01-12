local RSGCore = exports['rsg-core']:GetCoreObject()
local xSound = exports.xsound
local isPlaying = false

RegisterNetEvent('rsg_phonograph:server:changeRadius', function(radius, entity)
    local src = source
    if not tonumber(radius) then return end
    xSound:Distance(-1, tostring(entity), radius)
end)

RSGCore.Functions.CreateUseableItem("phonograph", function(source, item)
	local src = source
	local Player = RSGCore.Functions.GetPlayer(src)
	if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent("rsg_phonograph:client:placeDJEquipment", source, item.name)
		TriggerClientEvent("rsg_phonograph:server:pickeupdecks", source, item.name)
	end
end)

RegisterNetEvent('rsg_phonograph:server:playMusic', function(song, entity, coords)
    local src = source
    xSound:PlayUrlPos(-1, tostring(entity), song, Config.DefaultVolume, coords)
    xSound:Distance(-1, tostring(entity), Config.radius)
    isPlaying = true
end)

RegisterNetEvent('rsg_phonograph:server:pickedup', function(entity)
    local src = source
    xSound:Destroy(-1, tostring(entity))
end)

RegisterNetEvent('rsg_phonograph:server:stopMusic', function(data)
    local src = source
    xSound:Destroy(-1, tostring(data.entity))
    TriggerClientEvent('rsg_phonograph:client:playMusic', src)
end)

RegisterNetEvent('rsg_phonograph:server:pauseMusic', function(data)
    local src = source
    xSound:Pause(-1, tostring(data.entity))
end)

RegisterNetEvent('rsg_phonograph:server:resumeMusic', function(data)
    local src = source
    xSound:Resume(-1, tostring(data.entity))
end)

RegisterNetEvent('rsg_phonograph:server:changeVolume', function(volume, entity)
    local src = source
    if not tonumber(volume) then return end
    xSound:setVolume(-1, tostring(entity), volume)
end)

RegisterNetEvent('rsg_phonograph:Server:RemoveItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
end)

RegisterServerEvent('rsg_phonograph:server:pickeupdecks')
AddEventHandler('rsg_phonograph:server:pickeupdecks', function()
	local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
	Player.Functions.AddItem('phonograph', 1)
	TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[phonograph], "add")
	TriggerClientEvent('rNotify:NotifyLeft', source, "PHONOGRAPH", "PICKED UP", "generic_textures", "tick", 4000)
	
end)