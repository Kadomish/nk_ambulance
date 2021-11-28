local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil


local isBusy, deadPlayers, deadPlayerBlips, isOnDuty = false, {}, {}, false
isInShopMenu = false


local firstSpawn, PlayerLoaded = true, false
local PlayerData = nil
isDead = false

local PlayerData, CurrentActionData, handcuffTimer, dragStatus, blipsCops, currentTask, spawnedVehicles = {}, {}, {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, IsHandcuffed, hasAlreadyJoined, playerInService, isInShopMenu = false, false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged = false
blip = nil
local policeDog = false
local PlayerData = {}
closestDistance, closestEntity = -1, nil
local IsHandcuffed, DragStatus = false, {}
DragStatus.IsDragged          = false
local attente = 0
local currentTask = {}

local function LoadAnimDict(dictname)
	if not HasAnimDictLoaded(dictname) then
		RequestAnimDict(dictname) 
		while not HasAnimDictLoaded(dictname) do 
			Citizen.Wait(1)
		end
	end
end

local societypolicemoney = nil
local societycrucialfixmoney = nil
local societyambulancemoney = nil
local societytacosmoney = nil


Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end
    PlayerLoaded = true
    ESX.PlayerData = ESX.GetPlayerData()
end)
Citizen.CreateThread(function()
    while ESX == nil do
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	Citizen.Wait(0)
    end  
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
    Citizen.Wait(5000)
end)

local societytacosmoney = nil

------------------- TEXTE EN BAS ----------------

function DrawSub(msg, time)
	ClearPrints()
	BeginTextCommandPrint('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandPrint(time, 1)
end

------------------ TEXT 3D ---------------

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end


-------------------- POSITION ----------------

local pos = {
    vestiaire1 = { 
        {x = 365.01068115234, y = -1404.3026123047, z = 32.936199188232}
    },
    stock1 = { 
        {x = 359.82159423828, y = -1389.0850830078, z = 32.429191589355} --Position coffre
    },
    garage1 = { 
        { x = 400.91, y = -1420.58, z = 28.43,} -- Point pour sortir le vehicule
    },
    recoltes1 = { 
        {x = 326.04, y = -1074.34, z = 29.47} 
    },
    boss1 = { 
        {x = 315.31628417969, y = -1397.8205566406, z = 37.911117553711}
    },
    range1 = { 
        {x= 415.85678100586, y = -1432.7882080078, z = 29.435458755493} 
    },
    pharmacie1 = { 
        {x= 362.380859375, y = -1389.2814941406, z = 32.429138183594}
    },
}



---------------------------------------------------------------------------------------------------------
--------------------------------------- AMBULANCE ---------------------------------------------------------
----------------------------------------------------------------------------------------------------


function OpenBillingMenu1()
    ESX.UI.Menu.Open(
        'dialog', GetCurrentResourceName(), 'facture',
        {
            title = 'Donner une facture'
        },
        function(data, menu)

            local amount = tonumber(data.value)

            if amount == nil or amount <= 0 then
                ESX.ShowNotification('Montant invalide')
            else
                menu.close()

                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                if closestPlayer == -1 or closestDistance > 3.0 then
                    ESX.ShowNotification('Pas de joueurs proche')
                else
                    local playerPed        = GetPlayerPed(-1)

                    Citizen.CreateThread(function()
                        TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
                        Citizen.Wait(5000)
                        ClearPedTasks(playerPed)
                        TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_ambulance', 'ambulance', amount)
                        ESX.ShowNotification("~r~Vous avez bien envoyer la facture")
                    end)
                end
            end
        end,
        function(data, menu)
            menu.close()
    end)
end
--------------------- COFFRE ---------------------

function OpenGetStocksambulanceMenu()
	ESX.TriggerServerCallback('ambulance:prendreitem', function(items)
		local elements = {}

		for i=1, #items, 1 do
            table.insert(elements, {
                label = 'x' .. items[i].count .. ' ' .. items[i].label,
                value = items[i].name
            })
        end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
            css      = 'police',
			title    = 'stockage',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
                css      = 'police',
				title = 'quantité'
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification('quantité invalide')
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('ambulance:prendreitems', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksLSPDMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksambulanceMenu()
	ESX.TriggerServerCallback('ambulance:inventairejoueur', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
            css      = 'ambulance',
			title    = 'inventaire',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
                css      = 'ambulance',
				title = 'quantité'
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification('quantité invalide')
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('ambulance:stockitem', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksLSPDMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end


------------------------ REVIVE ---------------


function revivePlayer(closestPlayer)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 3.0 then
      ESX.ShowNotification(_U('no_players'))
    else
                      ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(qtty)
                          if qtty > 0 then
              local closestPlayerPed = GetPlayerPed(closestPlayer)
              local health = GetEntityHealth(closestPlayerPed)
              if health == 0 then
                  local playerPed = GetPlayerPed(-1)
                  Citizen.CreateThread(function()
                    ESX.ShowNotification(_U('revive_inprogress'))
                    TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                    Wait(10000)
                    ClearPedTasks(playerPed)
                    if GetEntityHealth(closestPlayerPed) == 0 then
                        TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
                      TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
                     -- ESX.ShowNotification(_U('revive_complete'))
                    else
                      ESX.ShowNotification(_U('isdead'))
                    end
                  end)
              else
                ESX.ShowNotification(_U('unconscious'))
              end
                          else
                              ESX.ShowNotification(_U('not_enough_medikit'))
                          end
                      end, 'medikit')
    end
  end

--------------- HEAL  -----------------

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(healType, quiet)
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'small' then
		local health = GetEntityHealth(playerPed)
		local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
		SetEntityHealth(playerPed, newHealth)
	elseif healType == 'big' then
		SetEntityHealth(playerPed, maxHealth)
	end

	if not quiet then
		ESX.ShowNotification('Tu as été soigné')
	end
end)

----------------- TENUE -------------
function TenueCivil()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        TriggerEvent('skinchanger:loadSkin', skin)
       end)
    end
    
    function TenueAmbulancier()
        local model = GetEntityModel(GetPlayerPed(-1))
        TriggerEvent('skinchanger:getSkin', function(skin)
            if model == GetHashKey("mp_m_freemode_01") then
                clothesSkin = {
                    ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
                    ['torso_1'] = 78,   ['torso_2'] = 2,
                    ['decals_1'] = 0,   ['decals_2'] = 0,
                    ['arms'] = 85,
                    ['pants_1'] = 58,    ['pants_2'] = 5,
                    ['shoes_1'] = 17,   ['shoes_2'] = 6,
                  }
          end
          TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
      end)
      end

      function TenueAmbulanciere()
      local model = GetEntityModel(GetPlayerPed(-1))
      TriggerEvent('skinchanger:getSkin', function(skin)
   if model == GetHashKey("mp_f_freemode_01") then
    clothesSkin = {
        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
        ['torso_1'] = 78,   ['torso_2'] = 2,
        ['decals_1'] = 0,   ['decals_2'] = 0,
        ['arms'] = 85,
        ['pants_1'] = 58,    ['pants_2'] = 5,
        ['shoes_1'] = 17,   ['shoes_2'] = 6,
      }
end
TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
end)
end



----------------- PED ---------

Citizen.CreateThread(function()
    local hash = GetHashKey("s_m_m_cntrybar_01")
    while not HasModelLoaded(hash) do
    RequestModel(hash)
    Wait(20)
    end
    ped = CreatePed("PED_TYPE_CIVFEMALE", "s_m_m_cntrybar_01", 400.91, -1420.58, 28.43, 237.68, false, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
  end)


--------------------- MENU F6 ------------------

local ambulance = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Ambulance" },
    Data = { currentMenu = "Ambulance :", ""},
    Events = {
    onSelected = function(self, _, btn, PMenu, menuData, result)
		if btn.name == "Réanimer la Personne" then
			revivePlayer(closestPlayer) 
		elseif btn.name == "Soigner une petite blessure" then
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer == -1 or closestDistance > 1.0 then
								ESX.ShowNotification('~r~Aucune Personne à Proximité')
							else
								ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
									if quantity > 0 then
										local closestPlayerPed = GetPlayerPed(closestPlayer)
										local health = GetEntityHealth(closestPlayerPed)
		
										if health > 0 then
											local playerPed = PlayerPedId()
		
											IsBusy = true
											ESX.ShowNotification(_U('heal_inprogress'))
											TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
											Citizen.Wait(10000)
											ClearPedTasks(playerPed)
		
											TriggerServerEvent('esx_ambulancejob:removeItem', 'bandage')
											TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'small')
											ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
											IsBusy = false
										else
											ESX.ShowNotification(_U('player_not_conscious'))
										end
									else
										ESX.ShowNotification(_U('not_enough_bandage'))
									end
								end, 'bandage')
							end
		elseif btn.name == "Soigner une grande blessure" then
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
							if closestPlayer == -1 or closestDistance > 1.0 then
								ESX.ShowNotification('~r~Aucune Personne à Proximité')
							else
								ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
									if quantity > 0 then
										local closestPlayerPed = GetPlayerPed(closestPlayer)
										local health = GetEntityHealth(closestPlayerPed)
		
										if health > 0 then
											local playerPed = PlayerPedId()
		
											IsBusy = true
											ESX.ShowNotification(_U('heal_inprogress'))
											TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
											Citizen.Wait(10000)
											ClearPedTasks(playerPed)
		
											TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
											TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'big')
											ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
											IsBusy = false
										else
											ESX.ShowNotification(_U('player_not_conscious'))
										end
									else
										ESX.ShowNotification(_U('not_enough_medikit'))
									end
								end, 'medikit')
							end
		elseif btn.name == "Facturation" then   
            ExecuteCommand("e notepad")
            Citizen.Wait(1500)
            OpenBillingMenu1()
		elseif btn.name == "~g~Ouvert" then
			TriggerServerEvent("ambulanceouvert")
		elseif btn.name == "~r~Fermer" then
			TriggerServerEvent("ambulancefermer")
		elseif btn.name == "Intéractions" then
			OpenMenu('Intéractions')
		elseif btn.name == "Annonce" then
			OpenMenu('Annonce')
		end 
    end,
},

Menu = {
	["Ambulance :"] = {
		b = {
			{name = "Annonce", ask = '>', askX = true},
			{name = "Intéractions", ask = '>', askX = true},
			{name = "Facturation", ask = '>', askX = true},
		}
	},
	["Annonce"] = {
		b = {
			{name = "~g~Ouvert", ask = '>', askX = true},
			{name = "~r~Fermer", ask = '>', askX = true},
		}
	},
	["Intéractions"] = {
		b = {
			{name = "Réanimer la Personne", ask = '>', askX = true},
			{name = "Soigner une petite blessure", ask = '>', askX = true},
			{name = "Soigner une grande blessure", ask = '>', askX = true},
		}
	}
}
} 

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then 
		if IsControlJustReleased(0 ,167) then
            CreateMenu(ambulance)	
		end
	end
	end
end)
		
-------------------------------- BOSS ---------------



Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.boss1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 1.5 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' and ESX.PlayerData.job.grade_name == 'boss' then
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 204, 200)
                Draw3DText(v.x,v.y,v.z, "Appuyez sur ~g~E ~w~pour ouvrir l'ordinateur !")
                if IsControlJustPressed(1,38) then 
                    ExecuteCommand('e type3')
                    DrawSub("~r~Code Coffre~s~ : #5500", 2000)
                    Citizen.Wait(1500)	
                    ExecuteCommand('e damn')	
                    DrawSub("~r~[Vous]~w~ : #5500 ! Yes ça fonctionnee", 500)
                    Citizen.Wait(500)
                    TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
                        menu.close()
                    end, {wash = true})
                end
            end
        end
    end
end)



-------------------------- VESTIAIRE --------------

local tenue1 = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Vestiaire" },
    Data = { currentMenu = "Tenue :", "Test"},
    Events = {
        onSelected = function(self, _, btn, PMenu, menuData, result)
         
            if btn.name == "Tenue Civil" then   
                ExecuteCommand("e adjusttie")
                Citizen.Wait(5000)
                TenueCivil()
            elseif btn.name == "Tenue Ambulancier" then
                ExecuteCommand("e adjusttie")
                Citizen.Wait(5000)
                TenueAmbulancier()
            elseif btn.name == "Tenue Ambulancière" then
                ExecuteCommand("e adjusttie")
                Citizen.Wait(5000)
                TenueAmbulanciere()
            end 
    end,
},
    Menu = {
        ["Tenue :"] = {
            b = {
                {name = "Tenue Civil", ask = '', askX = true},
                {name = "Tenue Ambulancier", ask = '', askX = true},
                {name = "Tenue Ambulancière", ask = '', askX = true},
            }
        }
    }
} 


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.vestiaire1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 2 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 0, 200)
                Draw3DText(v.x,v.y,v.z, "~h~~w~Appuyez sur ~g~E ~w~pour se ~g~Changer")
                if IsControlJustPressed(1,38) then 
                   CreateMenu(tenue1)
                end
            end
        end
    end
end)


--------------------------------- COFFRE 



local coffre1 = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Caisse Ambulance" },
    Data = { currentMenu = "Caisse :", "Test"},
    Events = {
        onSelected = function(self, _, btn, PMenu, menuData, result)
            if btn.name == "Retirer Objets" then
                self:CloseMenu()
                OpenGetStocksambulanceMenu()
            elseif btn.name == "Déposer Objets" then
                self:CloseMenu()
                OpenPutStocksambulanceMenu()
            end 
    end,
},
    Menu = {
        ["Caisse :"] = {
            b = {
                {name = "Retirer Objets", ask = '>>', askX = true},
                {name = "Déposer Objets", ask = '>>', askX = true},
            }
        }
    }
} 

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.stock1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 2 then
                Draw3DText(v.x,v.y,v.z, "Appuyez sur ~g~E ~w~pour ouvrir le ~g~Coffre !")
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 0, 200)
                if IsControlJustPressed(1,38) then 
                    ExecuteCommand('e type3')
                    DrawSub("~r~Code Coffre~s~ : 49836", 2000)
                    Citizen.Wait(1500)	
                    ExecuteCommand('e damn')	
                    DrawSub("~r~[Vous]~w~ : 49836 ! Yes ça marche", 500)
                    Citizen.Wait(500)	
                   CreateMenu(coffre1)
                end
            end
        end
    end
end)
 

----------------------------- Voiture 


local voiture1 = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Garage Ambulance" },
    Data = { currentMenu = "Liste des véhicules :", ""},
    Events = {
        onSelected = function(self, _, btn, PMenu, menuData, result)
            if btn.name == "Camion - Ambulancier" then  
                spawnCar2("ambulance")           
            end 
    end,
},
    Menu = {
        ["Liste des véhicules :"] = {
            b = {
                {name = "Camion - Ambulancier", ask = '', askX = true},
            }
        }
    }
} 

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.garage1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 2 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 0, 200)
                Draw3DText(400.91,-1420.58, 30.43, "~h~Appuyez sur ~r~E ~w~pour ouvrir le menu des ~r~Véhicules")
                if IsControlJustPressed(1,38) then
                    DrawSub("~b~[Garagiste]~w~ : Bonjour ~g~Monsieur/Madame ~s~voici le garage de l'Ambulance ! ", 2000)
                    Citizen.Wait(1500)
                    DrawSub("~b~[Vous]~w~ : Merci Mr le ~r~Garagiste~w~ de me faire voir le garage de l'Ambulance !", 2000)
                    Citizen.Wait(1500)	
                   CreateMenu(voiture1)
                end
            end
        end
    end
end)

------------------------------ SPAWN CAR ---------------------

function spawnCar2(car)
    local car = GetHashKey(car)
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(50)   
    end
    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), false))
    local vehicle = CreateVehicle(car, 401.54428100586,-1426.1448974609,29.450204849243, 230.04, true, false)   ---- spawn du vehicule (position)
    TriggerEvent("notify", 1, "Ambulance", "Vous avez sorti votre véhicule, il se trouve sur une place de parking. Faites y attention !", 2500)
    TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate)
end

-----------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.range1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 3.5 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 0, 200)
                Draw3DText(v.x,v.y,v.z, "~h~Appuyez sur ~g~E ~w~pour ranger votre ~g~Véhicule")
                if IsControlJustPressed(1,38) then 
                    TriggerEvent('esx:deleteVehicle')
                    TriggerEvent("notify", 2, "Garage Ambulance", "Vous avez bien rangé votre vehicule", 2500)
                end                
            end
        end
    end
end)

------------------------ PHARMACIE ---------------

local pharmacie1 = {
    Base = { Header = {"commonmenu", "interaction_bgd"}, Color = {color_black}, HeaderColor = {255, 255, 255}, Title = "Pharmacie" },
    Data = { currentMenu = "Pharmacie", ""},
    Events = {
        onSelected = function(self, _, btn, PMenu, menuData, result)
            if btn.name == "Medikit" then  
                TriggerServerEvent('buyMedikit') 
            elseif btn.name == "Bandage" then  
                TriggerServerEvent('buyBandage')                  
            end 
    end,
},
    Menu = {
        ["Pharmacie"] = {
            b = {
                {name = "Medikit", ask = '', askX = true},
                {name = "Bandage", ask = '', askX = true},
            }
        }
    }
} 


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for k,v in pairs(pos.pharmacie1) do
            if Vdist2(GetEntityCoords(PlayerPedId(), false), v.x,v.y,v.z ) <= 2 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
                DrawMarker(6, v.x, v.y, v.z-0.99, nil, nil, nil, -90, nil, nil, 1.0, 1.0, 1.0, 0, 102, 0, 200)
                Draw3DText(v.x, v.y, v.z, "~h~Appuyez sur ~r~E ~w~pour ouvrir le menu des ~r~Pharmacie")
                if IsControlJustPressed(1,38) then
                   CreateMenu(pharmacie1)
                end
            end
        end
    end
end)


------------------------- BLIPS ---------------



 Citizen.CreateThread(function()

	local nkambulance = AddBlipForCoord(348.71, -1412.41, 76.17)
	SetBlipSprite(nkambulance, 621)
	SetBlipColour(nkambulance, 41)
	SetBlipScale(nkambulance, 0.7)
	SetBlipAsShortRange(nkambulance, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString("~r~Hopital")
	EndTextCommandSetBlipName(nkambulance)


end)        
         

----------------- PRIS APPEL EMS 

AddEventHandler("onClientMapStart", function()
	exports.spawnmanager:spawnPlayer()
	Citizen.Wait(5000)
	exports.spawnmanager:setAutoSpawn(false)
end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerLoaded = true
	PlayerData = ESX.GetPlayerData()
end)
----------------------------------------------------------
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	PlayerLoaded = true
end)
---------------------------------------------------------
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

AddEventHandler('esx:onPlayerSpawn', function()
	isDead = false

	if firstSpawn then
		firstSpawn = false

		if Config.AntiCombatLog then
			while not PlayerLoaded do
				Citizen.Wait(1000)
			end

			ESX.TriggerServerCallback('esx_ambulancejob:getDeathStatus', function(shouldDie)
				if shouldDie then
					ESX.ShowNotification(_U('combatlog_message'))
					RemoveItemsAfterRPDeath()
				end
			end)
		end
	end
end)

print ('^6(https://dsc.gg/nkdev)')

-- Disable most inputs when dead
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isDead then
			DisableAllControlActions(0)
			EnableControlAction(0, 47, true)
			EnableControlAction(0, 245, true)
			EnableControlAction(0, 38, true)
		else
			Citizen.Wait(500)
		end
	end
end)

function OnPlayerDeath()
	isDead = true
	ESX.UI.Menu.CloseAll()
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', true)

	StartDeathTimer()
	StartDistressSignal()

	StartScreenEffect('DeathFailOut', 0, false)
end



function StartDistressSignal()
	Citizen.CreateThread(function()
		local timer = Config.BleedoutTimer

		while timer > 0 and isDead do
			Citizen.Wait(0)
			timer = timer - 30

			SetTextFont(4)
			SetTextScale(0.45, 0.45)
			SetTextColour(185, 185, 185, 255)
			SetTextDropshadow(0, 0, 0, 0, 255)
			SetTextDropShadow()
			SetTextOutline()
			BeginTextCommandDisplayText('STRING')
			AddTextComponentSubstringPlayerName("Appuyer sur [G] pour envoyer su signal aux EMS")
			EndTextCommandDisplayText(0.175, 0.805)

			if IsControlJustReleased(0, 47) then
				SendDistressSignal()
				break
			end
		end
	end)
end

function SendDistressSignal()
	local playerPed = PlayerPedId()
	PedPosition		= GetEntityCoords(playerPed)
	
	local PlayerCoords = { x = PedPosition.x, y = PedPosition.y, z = PedPosition.z }

	ESX.ShowNotification('Message envoyer aux ambulanciers en service')

    TriggerServerEvent('esx_addons_gcphone:startCall', 'ambulance', "Une personne est blessé !", PlayerCoords, {

		PlayerCoords = { x = PedPosition.x, y = PedPosition.y, z = PedPosition.z },
	})
	TriggerServerEvent('esx_ambulancejob:onPlayerDistress')
end

function DrawGenericTextThisFrame()
	SetTextFont(4)
	SetTextScale(0.0, 0.5)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
end

function secondsToClock(seconds)
	local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0

	if seconds <= 0 then
		return 0, 0
	else
		local hours = string.format('%02.f', math.floor(seconds / 3600))
		local mins = string.format('%02.f', math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format('%02.f', math.floor(seconds - hours * 3600 - mins * 60))

		return mins, secs
	end
end

function StartDeathTimer()
	local canPayFine = false

	if Config.EarlyRespawnFine then
		ESX.TriggerServerCallback('esx_ambulancejob:checkBalance', function(canPay)
			canPayFine = canPay
		end)
	end

	local earlySpawnTimer = ESX.Math.Round(Config.EarlyRespawnTimer / 1000)
	local bleedoutTimer = ESX.Math.Round(Config.BleedoutTimer / 1000)

	Citizen.CreateThread(function()
		-- early respawn timer
		while earlySpawnTimer > 0 and isDead do
			Citizen.Wait(1000)

			if earlySpawnTimer > 0 then
				earlySpawnTimer = earlySpawnTimer - 1
			end
		end

		-- bleedout timer
		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(1000)

			if bleedoutTimer > 0 then
				bleedoutTimer = bleedoutTimer - 1
			end
		end
	end)

	Citizen.CreateThread(function()
		local text, timeHeld

		-- early respawn timer
		while earlySpawnTimer > 0 and isDead do
			Citizen.Wait(0)
			text = _U('respawn_available_in', secondsToClock(earlySpawnTimer))

			DrawGenericTextThisFrame()

			SetTextEntry('STRING')
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end

		-- bleedout timer
		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(0)
			text = _U('respawn_bleedout_in', secondsToClock(bleedoutTimer))

			if not Config.EarlyRespawnFine then
				text = text .. _U('respawn_bleedout_prompt')

				if IsControlPressed(0, 38) and timeHeld > 60 then
					RemoveItemsAfterRPDeath()
					break
				end
			elseif Config.EarlyRespawnFine and canPayFine then
				text = text .. _U('respawn_bleedout_fine', ESX.Math.GroupDigits(Config.EarlyRespawnFineAmount))

				if IsControlPressed(0, 38) and timeHeld > 60 then
					TriggerServerEvent('esx_ambulancejob:payFine')
					RemoveItemsAfterRPDeath()
					break
				end
			end

			if IsControlPressed(0, 38) then
				timeHeld = timeHeld + 1
			else
				timeHeld = 0
			end

			DrawGenericTextThisFrame()

			SetTextEntry('STRING')
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end

		if bleedoutTimer < 1 and isDead then
			RemoveItemsAfterRPDeath()
		end
	end)
end

function RemoveItemsAfterRPDeath()
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(10)
		end

		ESX.TriggerServerCallback('esx_ambulancejob:removeItemsAfterRPDeath', function()
			local formattedCoords = {
				x = Config.RespawnPoint.coords.x,
				y = Config.RespawnPoint.coords.y,
				z = Config.RespawnPoint.coords.z
			}

			ESX.SetPlayerData('loadout', {})
			RespawnPed(PlayerPedId(), formattedCoords, Config.RespawnPoint.heading)

			StopScreenEffect('DeathFailOut')
			DoScreenFadeIn(800)
		end)
	end)
end

function RespawnPed(ped, coords, heading)
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
	SetPlayerInvincible(ped, false)
	ClearPedBloodDamage(ped)

	TriggerServerEvent('esx:onPlayerSpawn')
	TriggerEvent('esx:onPlayerSpawn')
	TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
end

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = 'Ambulance',
		number     = 'ambulance',
		base64Icon = 'data:image/png;base64,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'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	OnPlayerDeath()
end)

RegisterNetEvent('esx_ambulancejob:revive')
AddEventHandler('esx_ambulancejob:revive', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Citizen.Wait(50)
	end

	local formattedCoords = {
		x = ESX.Math.Round(coords.x, 1),
		y = ESX.Math.Round(coords.y, 1),
		z = ESX.Math.Round(coords.z, 1)
	}

	RespawnPed(playerPed, formattedCoords, 0.0)

	StopScreenEffect('DeathFailOut')
	DoScreenFadeIn(800)
end)

-- Load unloaded IPLs
-- if Config.LoadIpl then
-- 	RequestIpl('Coroner_Int_on') -- Morgue
-- end





print ('^6(Crée par ^2Kadomish^6)')
