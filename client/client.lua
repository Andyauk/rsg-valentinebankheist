local QRCore = exports['qr-core']:GetCoreObject()
local initialCooldownSeconds = 3600 -- cooldown time in seconds
local cooldownSecondsRemaining = 0 -- done to zero cooldown on restart
local lockpicked = false
local dynamiteused = false
local vault1 = false
local vault2 = false
local CurrentLawmen = 0

------------------------------------------------------------------------------------------------------------------------

-- lock vault doors
Citizen.CreateThread(function()
    for k,v in pairs(Config.VaultDoors) do
        Citizen.InvokeNative(0xD99229FE93B46286,v,1,1,0,0,0,0)
        Citizen.InvokeNative(0x6BAB9442830C7F53,v,1)
    end
end)

------------------------------------------------------------------------------------------------------------------------

-- lockpick fist door
Citizen.CreateThread(function()
	while true do
		Wait(0)
		local pos, awayFromObject = GetEntityCoords(PlayerPedId()), true
		local object = Citizen.InvokeNative(0xF7424890E4A094C0, 1340831050, 0)
		if object ~= 0 and cooldownSecondsRemaining == 0 and lockpicked == false then
			local objectPos = GetEntityCoords(object)
			if #(pos - objectPos) < 3.0 then
				awayFromObject = false
				DrawText3Ds(objectPos.x, objectPos.y, objectPos.z + 1.0, "Lockpick [J]")
				if IsControlJustReleased(0, QRCore.Shared.Keybinds['J']) then
					QRCore.Functions.TriggerCallback('police:GetCops', function(result)
						CurrentLawmen = result
						if CurrentLawmen >= Config.MinimumLawmen then
							local hasItem = QRCore.Functions.HasItem('lockpick', 1)
							if hasItem then
								TriggerServerEvent('rsg-valentinebankheist:server:removeItem', 'lockpick', 1)
								TriggerEvent('qr-lockpick:client:openLockpick', LockpickFinish)
							else
								QRCore.Functions.Notify('you need a lockpick', 'error')
							end
						else
							QRCore.Functions.Notify('not enough lawmen on duty!', 'error')
						end
					end)
				end
			end
		end
		if awayFromObject then
			Wait(1000)
		end
	end
end)

function LockpickFinish(success)
    if success then
		QRCore.Functions.Notify('lockpick successful', 'success')
		Citizen.InvokeNative(0x6BAB9442830C7F53, 1340831050, 0)
		lockpicked = true
    else
        QRCore.Functions.Notify('lockpick unsuccessful', 'error')
    end
end

------------------------------------------------------------------------------------------------------------------------

-- vault prompt
Citizen.CreateThread(function()
	while true do
		Wait(0)
		local pos, awayFromObject = GetEntityCoords(PlayerPedId()), true
		local object = Citizen.InvokeNative(0xF7424890E4A094C0, 576950805, 0)
		if object ~= 0 and cooldownSecondsRemaining == 0 and dynamiteused == false then
			local objectPos = GetEntityCoords(object)
			if #(pos - objectPos) < 3.0 then
				awayFromObject = false
				DrawText3Ds(objectPos.x, objectPos.y, objectPos.z + 1.0, "Place Dynamite [J]")
				if IsControlJustReleased(0, QRCore.Shared.Keybinds['J']) then
					TriggerEvent('rsg-valentinebankheist:client:boom')
					dynamiteused = true
				end
			end
		end
		if awayFromObject then
			Wait(1000)
		end
	end
end)

-- blow vault doors
RegisterNetEvent('rsg-valentinebankheist:client:boom')
AddEventHandler('rsg-valentinebankheist:client:boom', function()
	if cooldownSecondsRemaining == 0 then
		local hasItem = QRCore.Functions.HasItem('dynamite', 1)
		if hasItem then
			TriggerServerEvent('rsg-valentinebankheist:server:removeItem', 'dynamite', 1)
			local playerPed = PlayerPedId()
			TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), 5000, true, false, false, false)
			Wait(5000)
			ClearPedTasksImmediately(PlayerPedId())
			local x,y,z = table.unpack(GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.5, 0.0))
			local prop = CreateObject(GetHashKey("p_dynamite01x"), x, y, z, true, false, true)
			SetEntityHeading(prop, GetEntityHeading(PlayerPedId()))
			PlaceObjectOnGroundProperly(prop)
			FreezeEntityPosition(prop,true)
			QRCore.Functions.Notify('explosives set, stand well back', 10000, 'primary')
			Wait(10000)
			AddExplosion(-307.24, 767.2, 118.7, 25 , 5000.0 ,true , false , 27)
			DeleteObject(prop)
			Citizen.InvokeNative(0x6BAB9442830C7F53, 576950805, 0)
			TriggerEvent('rsg-valentinebankheist:client:policenpc')
			local alertcoords = GetEntityCoords(PlayerPedId())
			TriggerServerEvent('police:server:policeAlert', 'Valentine Bank is being robbed')
			handleCooldown()
		else
			QRCore.Functions.Notify('you need dynamite to do that', 'error')
		end
	else
		QRCore.Functions.Notify('you can\'t do that right now', 'error')
	end
end)

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	exports['qr-core']:createPrompt('valvault1', vector3(-308.26, 762.72, 118.7), 0xF3830D8E, 'Loot Vault', {
		type = 'client',
		event = 'rsg-valentinebankheist:client:checkvault1',
		args = {},
	})
end)

-- loot vault1
RegisterNetEvent('rsg-valentinebankheist:client:checkvault1', function()
	local player = PlayerPedId()
	SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
	if vault1 == false then
		local animDict = "script_ca@cachr@ig@ig4_vaultloot"
		local anim = "ig13_14_grab_money_front01_player_zero"
		RequestAnimDict(animDict)
		while ( not HasAnimDictLoaded(animDict) ) do
			Wait(100)
		end
		TaskPlayAnim(player, animDict, anim, 8.0, -8.0, 10000, 1, 0, true, 0, false, 0, false)
		Wait(10000)
		ClearPedTasks(player)
		SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
		TriggerServerEvent('rsg-valentinebankheist:server:reward')
		vault1 = true
	else
		QRCore.Functions.Notify('already looted this vault', 'error')
	end
end)

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	exports['qr-core']:createPrompt('valvault2', vector3(-308.7, 765.22, 118.7), 0xF3830D8E, 'Loot Vault', {
		type = 'client',
		event = 'rsg-valentinebankheist:client:checkvault2',
		args = {},
	})
end)

-- loot vault2
RegisterNetEvent('rsg-valentinebankheist:client:checkvault2', function()
	local player = PlayerPedId()
	SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
	if vault2 == false then
			local animDict = "script_ca@cachr@ig@ig4_vaultloot"
			local anim = "ig13_14_grab_money_front01_player_zero"
			RequestAnimDict(animDict)
            while ( not HasAnimDictLoaded(animDict) ) do
				Wait(100)
            end
            TaskPlayAnim(player, animDict, anim, 8.0, -8.0, 10000, 1, 0, true, 0, false, 0, false)
			Wait(10000)
			ClearPedTasks(player)
			SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
			TriggerServerEvent('rsg-valentinebankheist:server:reward')
			vault2 = true
	else
		QRCore.Functions.Notify('already looted this vault', 'error')
	end
end)

------------------------------------------------------------------------------------------------------------------------

function modelrequest( model )
    Citizen.CreateThread(function()
        RequestModel( model )
    end)
end

-- start mission npcs
RegisterNetEvent('rsg-valentinebankheist:client:policenpc')
AddEventHandler('rsg-valentinebankheist:client:policenpc', function()
	for z, x in pairs(Config.HeistNpcs) do
	while not HasModelLoaded( GetHashKey(Config.HeistNpcs[z]["Model"]) ) do
		Wait(500)
		modelrequest( GetHashKey(Config.HeistNpcs[z]["Model"]) )
	end
	local npc = CreatePed(GetHashKey(Config.HeistNpcs[z]["Model"]), Config.HeistNpcs[z]["Pos"].x, Config.HeistNpcs[z]["Pos"].y, Config.HeistNpcs[z]["Pos"].z, Config.HeistNpcs[z]["Heading"], true, false, 0, 0)
	while not DoesEntityExist(npc) do
		Wait(300)
	end
	if not NetworkGetEntityIsNetworked(npc) then
		NetworkRegisterEntityAsNetworked(npc)
	end
	Citizen.InvokeNative(0x283978A15512B2FE, npc, true) -- SetRandomOutfitVariation
	GiveWeaponToPed_2(npc, 0x64356159, 500, true, 1, false, 0.0)
	TaskCombatPed(npc, PlayerPedId())
	end
end)

------------------------------------------------------------------------------------------------------------------------

-- cooldown
function handleCooldown()
    cooldownSecondsRemaining = initialCooldownSeconds
    Citizen.CreateThread(function()
        while cooldownSecondsRemaining > 0 do
            Wait(1000)
            cooldownSecondsRemaining = cooldownSecondsRemaining - 1
        end
    end)
end

------------------------------------------------------------------------------------------------------------------------

function DrawText3Ds(x, y, z, text)
    local onScreen,_x,_y=GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    SetTextColor(255, 255, 255, 215)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    SetTextCentre(1)
    DisplayText(str,_x,_y)
end