local QBCore = exports['qb-core']:GetCoreObject()
local lastUse = 0

local function showBadgeWithProgress(ped, callback)
    RequestAnimDict("paper_1_rcm_alt1-9")
    while not HasAnimDictLoaded("paper_1_rcm_alt1-9") do 
        Wait(10) 
    end

    ClearPedTasks(ped)
    TaskPlayAnim(ped, "paper_1_rcm_alt1-9", "player_one_dual-9", 8.0, -8.0, 3000, 49, 0, false, false, false)

    QBCore.Functions.Progressbar("showing_badge", "Showing Police Badge...", 3000, false, true, {}, {}, {}, {}, function()
        ClearPedTasks(ped)
        if callback then 
            callback() 
        end
    end)
end

Citizen.CreateThread(function()
    exports['qb-target']:AddGlobalVehicle({
        options = {
            {
                icon = "fas fa-car",
                label = "Borrow Vehicle (Police)",
                action = function(entity)
                    local playerPed = PlayerPedId()
                    local veh = entity
                    local driver = GetPedInVehicleSeat(veh, -1)

                    if not DoesEntityExist(driver) or IsPedAPlayer(driver) then
                        QBCore.Functions.Notify("No NPC driver in the vehicle.", "error")
                        return
                    end

                    if GetGameTimer() - lastUse < Config.Cooldown * 1000 then
                        QBCore.Functions.Notify("You must wait before trying again.", "error")
                        return
                    end

                    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
                        if not hasItem then
                            QBCore.Functions.Notify("You don't have your police badge.", "error")
                            return
                        end

                        lastUse = GetGameTimer()

                        showBadgeWithProgress(playerPed, function()

                            SetBlockingOfNonTemporaryEvents(driver, true)
                            SetPedFleeAttributes(driver, 0, false)
                            SetPedCanRagdoll(driver, false)
                            SetPedKeepTask(driver, true)
                            SetEntityAsMissionEntity(driver, true, true)


                            TaskLeaveVehicle(driver, veh, 0)
                            
                            local exitTimeout = 5000
                            while IsPedInAnyVehicle(driver, false) and exitTimeout > 0 do
                                Wait(100)
                                exitTimeout = exitTimeout - 100
                            end


                            ClearPedTasksImmediately(driver)
                            DetachEntity(driver, true, true)
                            ClearPedTasksImmediately(driver)


                            RequestAnimDict("anim@mp_player_intincarsalutestd@ds@")
                            while not HasAnimDictLoaded("anim@mp_player_intincarsalutestd@ds@") do 
                                Wait(10) 
                            end
                            TaskPlayAnim(driver, "anim@mp_player_intincarsalutestd@ds@", "idle_a", 8.0, -8.0, 1500, 49, 0, false, false, false)
                            Wait(1600)
                            ClearPedTasks(driver)


                            local approachTimeout = 10000
                            while approachTimeout > 0 and #(GetEntityCoords(driver) - GetEntityCoords(playerPed)) > 1.5 do
                                TaskGoToEntity(driver, playerPed, -1, 1.2, 2.0, 0.0, 0)
                                Wait(500)
                                approachTimeout = approachTimeout - 500
                            end


                            TaskTurnPedToFaceEntity(driver, playerPed, 1500)
                            Wait(1500)


                            RequestAnimDict("mp_common")
                            while not HasAnimDictLoaded("mp_common") do 
                                Wait(10) 
                            end

                            TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 49, 0, false, false, false)
                            TaskPlayAnim(driver, "mp_common", "givetake1_b", 8.0, -8.0, 2000, 49, 0, false, false, false)
                            Wait(2000)


                            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
                            SetVehicleDoorsLocked(veh, false) 
                            SetVehicleNeedsToBeHotwired(veh, false)
                            QBCore.Functions.Notify("You received the vehicle keys.", "success")


                            ClearPedTasks(driver)
                            SetBlockingOfNonTemporaryEvents(driver, false)
                            SetPedAsNoLongerNeeded(driver)
                            TaskWanderStandard(driver, 10.0, 10)
                            

                            ClearPedTasks(playerPed)
                        end)
                    end, Config.PoliceBadgeItem)
                end,
                canInteract = function(entity)
                    local job = QBCore.Functions.GetPlayerData().job
                    return job and job.name == "police"
                end
            }
        },
        distance = 2.5
    })
end)