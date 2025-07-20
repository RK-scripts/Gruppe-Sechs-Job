
local ESX = exports['es_extended']:getSharedObject()
local jobActive = false
local jobVehicle = nil
local moneyPeds = {}
local briefcaseObj = nil
local delivered = 0
local totalPickups = #Config.MoneyPickups
local hasBriefcase = false
local currentWaypoint = nil
local returnMarker = false

-- Costanti hardcoded (rimosse dal Config per semplicità)
local ATM_GUARD_PED = 's_m_m_armoured_01'
local BRIEFCASE_PROP = 'prop_security_case_01'
local TABLET_PROP = 'prop_cs_tablet'
local TABLET_ANIM = {dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', anim = 'base'}
local PASS_BRIEF_ANIM = {dict = 'mp_common', anim = 'givetake1_a'}


local function cleanupJob()
   
    if jobVehicle and DoesEntityExist(jobVehicle) then
        exports.ox_target:removeLocalEntity(jobVehicle, {'Deposita valigetta'})
        DeleteEntity(jobVehicle)
        jobVehicle = nil
    end
    
    
    for guard, data in pairs(moneyPeds) do
        if DoesEntityExist(guard) then
            exports.ox_target:removeLocalEntity(guard, {'Recupera denaro'})
            DeleteEntity(guard)
        end
        if data.brief and DoesEntityExist(data.brief) then
            DeleteEntity(data.brief)
        end
    end
    moneyPeds = {}
    
   
    if briefcaseObj and DoesEntityExist(briefcaseObj) then
        DeleteEntity(briefcaseObj)
        briefcaseObj = nil
    end
    
    
    if currentWaypoint then
        RemoveBlip(currentWaypoint)
        currentWaypoint = nil
    end
    
    
    SendNUIMessage({action = 'hideScoreboard'})
    exports.ox_lib:hideTextUI()
    

    jobActive = false
    delivered = 0
    hasBriefcase = false
    returnMarker = false
    totalPickups = #Config.MoneyPickups
end


CreateThread(function()
    
    local blip = AddBlipForCoord(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z)
    SetBlipSprite(blip, 67)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Lavoro Gruppe Sechs')
    EndTextCommandSetBlipName(blip)
    

    local pedHash = GetHashKey(Config.PedModel)
    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do Wait(10) end
    local ped = CreatePed(0, pedHash, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z-1, Config.PedCoords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    
    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Inizia lavoro portavalori',
            icon = 'fa-solid fa-tablet',
            canInteract = function()
                return not jobActive
            end,
            onSelect = function()
                SetNuiFocus(true, true)
                SendNUIMessage({action = 'openTablet'})
            end
        },
        {
            label = 'Termina lavoro anticipato',
            icon = 'fa-solid fa-times',
            canInteract = function()
                return jobActive and not returnMarker
            end,
            onSelect = function()
            
                cleanupJob()
              
                TriggerServerEvent('gruppe_sechs:quitJob')
                exports.ox_lib:notify({type = 'info', description = 'Hai terminato anticipatamente il lavoro.'})
            end
        },
        {
            label = 'Consegna denaro e termina lavoro',
            icon = 'fa-solid fa-hand-holding-dollar',
            canInteract = function()
                return jobActive and returnMarker and hasBriefcase
            end,
            onSelect = function()
             
                local playerPed = PlayerPedId()
                RequestAnimDict(PASS_BRIEF_ANIM.dict)
                while not HasAnimDictLoaded(PASS_BRIEF_ANIM.dict) do Wait(10) end
                TaskPlayAnim(playerPed, PASS_BRIEF_ANIM.dict, PASS_BRIEF_ANIM.anim, 8.0, -8.0, 2000, 49, 0, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
                
               
                if briefcaseObj and DoesEntityExist(briefcaseObj) then
                    DeleteEntity(briefcaseObj)
                    briefcaseObj = nil
                end
                hasBriefcase = false
             
                TriggerServerEvent('gruppe_sechs:finishJob')
                exports.ox_lib:notify({type = 'success', description = 'Hai completato il lavoro! Ricevuto il pagamento.'})
                
             
                cleanupJob()
            end
        }
    })
end)


local function createWaypoint(coords, label)
    if currentWaypoint then
        RemoveBlip(currentWaypoint)
    end
    currentWaypoint = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(currentWaypoint, 1)
    SetBlipColour(currentWaypoint, 2)
    SetBlipScale(currentWaypoint, 1.0)
    SetBlipRoute(currentWaypoint, true)
    SetBlipRouteColour(currentWaypoint, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Punto raccolta denaro')
    EndTextCommandSetBlipName(currentWaypoint)
end


local function createReturnWaypoint()
    if currentWaypoint then
        RemoveBlip(currentWaypoint)
    end
    currentWaypoint = AddBlipForCoord(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z)
    SetBlipSprite(currentWaypoint, 1)
    SetBlipColour(currentWaypoint, 3) 
    SetBlipScale(currentWaypoint, 1.2)
    SetBlipRoute(currentWaypoint, true)
    SetBlipRouteColour(currentWaypoint, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Torna al capo per consegnare')
    EndTextCommandSetBlipName(currentWaypoint)
end



RegisterNUICallback('startJob', function(_, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('gruppe_sechs:startJob')
    cb('ok')
end)


RegisterNetEvent('gruppe_sechs:jobStarted', function(pickups)
    jobActive = true
    delivered = 0
    totalPickups = #pickups
    hasBriefcase = false

    local vehHash = GetHashKey(Config.VehicleModel)
    RequestModel(vehHash)
    while not HasModelLoaded(vehHash) do Wait(10) end
    if jobVehicle and DoesEntityExist(jobVehicle) then DeleteEntity(jobVehicle) end
    jobVehicle = CreateVehicle(vehHash, Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, Config.VehicleSpawn.w, true, false)
    SetVehicleNumberPlateText(jobVehicle, 'GRUPPE')
    SetEntityAsMissionEntity(jobVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), jobVehicle, -1)


    for i,coords in ipairs(pickups) do

        local guardHash = GetHashKey(ATM_GUARD_PED)
        RequestModel(guardHash)
        while not HasModelLoaded(guardHash) do Wait(10) end
        local guard = CreatePed(0, guardHash, coords.x, coords.y, coords.z-1, coords.w, false, true)
        SetEntityInvincible(guard, true)
        SetBlockingOfNonTemporaryEvents(guard, true)
        FreezeEntityPosition(guard, true)
        SetEntityAsMissionEntity(guard, true, true)
        
        Wait(500)

        local propHash = GetHashKey(BRIEFCASE_PROP)
        if not IsModelValid(propHash) then
            propHash = GetHashKey('prop_security_case_01')
        end
        
        RequestModel(propHash)
        local attempts = 0
        while not HasModelLoaded(propHash) and attempts < 100 do
            Wait(10)
            attempts = attempts + 1
        end
        
        if HasModelLoaded(propHash) then
            local brief = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
            SetEntityAsMissionEntity(brief, true, true)
            
       
            Wait(100)
            
            local boneIndex = GetPedBoneIndex(guard, 57005)
            if boneIndex ~= -1 then
                AttachEntityToEntity(brief, guard, boneIndex, 0.10, 0.02, 0.0, 0.0, 270.0, 60.0, true, true, false, true, 1, true)
            end
            
            moneyPeds[guard] = {brief = brief, taken = false}
        else
            moneyPeds[guard] = {brief = nil, taken = false}
        end
    
        Wait(200)
        
        local success = pcall(function()
            exports.ox_target:addLocalEntity(guard, {
                {
                    label = 'Recupera denaro',
                    icon = 'fa-solid fa-sack-dollar',
                    distance = 2.5,
                    canInteract = function()
                        local guardData = moneyPeds[guard]
                        if not guardData then return false end
                        return not guardData.taken and not hasBriefcase and jobActive
                    end,
                    onSelect = function()
                   
                        local playerPed = PlayerPedId()

                        local tabletHash = GetHashKey(TABLET_PROP)
                        RequestModel(tabletHash)
                        while not HasModelLoaded(tabletHash) do Wait(10) end
                        local tablet = CreateObject(tabletHash, 0, 0, 0, true, true, false)
                        local tabletBone = GetPedBoneIndex(playerPed, 28422) 
                        AttachEntityToEntity(tablet, playerPed, tabletBone, 0.0, 0.0, 0.03, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                        
                        RequestAnimDict(TABLET_ANIM.dict)
                        while not HasAnimDictLoaded(TABLET_ANIM.dict) do Wait(10) end
                        TaskPlayAnim(playerPed, TABLET_ANIM.dict, TABLET_ANIM.anim, 8.0, -8.0, 2000, 49, 0, false, false, false)
                        Wait(2000)
                        ClearPedTasks(playerPed)
                        
                  
                        if DoesEntityExist(tablet) then
                            DeleteEntity(tablet)
                        end
                        
                    
                        RequestAnimDict(PASS_BRIEF_ANIM.dict)
                        while not HasAnimDictLoaded(PASS_BRIEF_ANIM.dict) do Wait(10) end
                        TaskPlayAnim(guard, PASS_BRIEF_ANIM.dict, PASS_BRIEF_ANIM.anim, 8.0, -8.0, 1500, 49, 0, false, false, false)
                        Wait(1500)
                        ClearPedTasks(guard)
                        
                    
                        if moneyPeds[guard].brief and DoesEntityExist(moneyPeds[guard].brief) then
                            DetachEntity(moneyPeds[guard].brief, true, true)
                            local playerBoneIndex = GetPedBoneIndex(playerPed, 57005)
                            AttachEntityToEntity(moneyPeds[guard].brief, playerPed, playerBoneIndex, 0.10, 0.02, 0.0, 0.0, 270.0, 60.0, true, true, false, true, 1, true)
                            briefcaseObj = moneyPeds[guard].brief
                            hasBriefcase = true
                            moneyPeds[guard].taken = true
                            
                            exports.ox_lib:notify({type = 'info', description = 'Hai recuperato il denaro! Porta la valigetta al furgone.'})
                            
                       
                            if currentWaypoint then
                                RemoveBlip(currentWaypoint)
                                currentWaypoint = nil
                            end

                            local nextPickup = nil
                            for nextGuard, nextData in pairs(moneyPeds) do
                                if not nextData.taken and nextGuard ~= guard then
                              
                                    for i, coords in ipairs(Config.MoneyPickups) do
                                        local guardPos = GetEntityCoords(nextGuard)
                                        local distance = #(vector3(coords.x, coords.y, coords.z) - guardPos)
                                        if distance < 5.0 then
                                            nextPickup = coords
                                            break
                                        end
                                    end
                                    if nextPickup then break end
                                end
                            end
                            
                            if nextPickup then
                                createWaypoint(nextPickup, 'Recupera denaro ATM')
                            end

                            CreateThread(function()
                                Wait(2000)
                                if DoesEntityExist(guard) then
                                    exports.ox_target:removeLocalEntity(guard, {'Recupera denaro'})
                                    DeleteEntity(guard)
                                end
                            end)
                        else
                            exports.ox_lib:notify({type = 'error', description = 'Errore nel recupero della valigetta!'})
                        end
                    end
                }
            })
        end)
    end

    exports.ox_target:addLocalEntity(jobVehicle, {
        {
            label = 'Deposita valigetta',
            icon = 'fa-solid fa-box',
            canInteract = function()
                return hasBriefcase and jobActive and not returnMarker
            end,
            onSelect = function()
              
                SetVehicleDoorOpen(jobVehicle, 2, false, false)
                SetVehicleDoorOpen(jobVehicle, 3, false, false)
                Wait(500)
                
                local playerPed = PlayerPedId()
                RequestAnimDict("pickup_object")
                while not HasAnimDictLoaded("pickup_object") do Wait(10) end
                TaskPlayAnim(playerPed, "pickup_object", "putdown_low", 8.0, -8.0, 1500, 49, 0, false, false, false)
                Wait(1500)
                ClearPedTasks(playerPed)

                if briefcaseObj and DoesEntityExist(briefcaseObj) then
                    DeleteEntity(briefcaseObj)
                    briefcaseObj = nil
                end
                hasBriefcase = false
                delivered = delivered + 1

                TriggerServerEvent('gruppe_sechs:updateProgress', delivered)
                
                exports.ox_lib:notify({type = 'success', description = 'Valigetta depositata!'} )
                Wait(1200)
                SetVehicleDoorShut(jobVehicle, 2, false)
                SetVehicleDoorShut(jobVehicle, 3, false)
                SendNUIMessage({action = 'updateScoreboard', consegnati = delivered, totali = totalPickups})
                if delivered >= totalPickups then
                    returnMarker = true
                    createReturnWaypoint()
                    exports.ox_lib:notify({type = 'info', description = 'Hai raccolto tutto! Torna dal capo per consegnare.'})
                    SendNUIMessage({action = 'showDelivery'})
                end
            end
        },
        {
            label = 'Prendi valigetta',
            icon = 'fa-solid fa-hand-holding',
            canInteract = function()
                return not hasBriefcase and jobActive and returnMarker and delivered >= totalPickups
            end,
            onSelect = function()
                SetVehicleDoorOpen(jobVehicle, 2, false, false)
                SetVehicleDoorOpen(jobVehicle, 3, false, false)
                Wait(500)
                
                local playerPed = PlayerPedId()
                RequestAnimDict("pickup_object")
                while not HasAnimDictLoaded("pickup_object") do Wait(10) end
                TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, -8.0, 1500, 49, 0, false, false, false)
                Wait(1500)
                ClearPedTasks(playerPed)

                local propHash = GetHashKey(BRIEFCASE_PROP)
                if not IsModelValid(propHash) then
                    propHash = GetHashKey('prop_security_case_01')
                end
                RequestModel(propHash)
                while not HasModelLoaded(propHash) do Wait(10) end
                
                briefcaseObj = CreateObject(propHash, 0, 0, 0, true, true, false)
                SetEntityAsMissionEntity(briefcaseObj, true, true)
                local playerBoneIndex = GetPedBoneIndex(playerPed, 57005)
                AttachEntityToEntity(briefcaseObj, playerPed, playerBoneIndex, 0.10, 0.02, 0.0, 0.0, 270.0, 60.0, true, true, false, true, 1, true)
                hasBriefcase = true
                
                exports.ox_lib:notify({type = 'info', description = 'Hai preso la valigetta! Consegnala al capo.'})

                Wait(1200)
                SetVehicleDoorShut(jobVehicle, 2, false)
                SetVehicleDoorShut(jobVehicle, 3, false)
            end
        }
    })

    SendNUIMessage({action = 'showScoreboard', consegnati = delivered, totali = totalPickups})

    local firstAvailablePickup = nil
    for i, coords in ipairs(pickups) do
        local hasGuard = false
        for guard, data in pairs(moneyPeds) do
            if not data.taken then
                hasGuard = true
                break
            end
        end
        if hasGuard then
            firstAvailablePickup = coords
            break
        end
    end
    
    if firstAvailablePickup then
        createWaypoint(firstAvailablePickup, 'Recupera denaro ATM')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    cleanupJob()
end)

RegisterNUICallback('closeTablet', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
