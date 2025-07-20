local ESX = exports['es_extended']:getSharedObject()

CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `rk_gruppe_sechs` (
            `identifier` varchar(60) NOT NULL,
            `active` tinyint(1) NOT NULL DEFAULT 0,
            `pickups` longtext DEFAULT NULL,
            `delivered` int(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    Wait(1000)
    exports.oxmysql:execute('DELETE FROM rk_gruppe_sechs WHERE active = 1 OR active = true', {}, function(result)
        if result and result.affectedRows > 0 then
            print('^3[Gruppe Sechs] Cleanup: Rimossi ' .. result.affectedRows .. ' lavori attivi dal database dopo restart')
        else
            print('^2[Gruppe Sechs] Cleanup: Nessun lavoro attivo da rimuovere')
        end
    end)
end)

RegisterNetEvent('gruppe_sechs:startJob', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local identifier = xPlayer.getIdentifier()

    exports.oxmysql:execute('SELECT active FROM rk_gruppe_sechs WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and (result[1].active == 1 or result[1].active == true) then
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Hai già un lavoro Gruppe Sechs attivo!'})
            return
        end

        local pickupsJson = json.encode(Config.MoneyPickups)
        exports.oxmysql:execute('REPLACE INTO rk_gruppe_sechs (identifier, active, pickups, delivered) VALUES (?, 1, ?, 0)', 
            {identifier, pickupsJson}, function()
            TriggerClientEvent('gruppe_sechs:jobStarted', src, Config.MoneyPickups)
        end)
    end)
end)

RegisterNetEvent('gruppe_sechs:finishJob', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then 
        return 
    end
    local identifier = xPlayer.getIdentifier()

    exports.oxmysql:execute('SELECT active FROM rk_gruppe_sechs WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] and (result[1].active == 1 or result[1].active == true) then

            xPlayer.addMoney(Config.PayAmount)
          
            exports.oxmysql:execute('DELETE FROM rk_gruppe_sechs WHERE identifier = ?', {identifier})
            
            TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Hai ricevuto $' .. Config.PayAmount .. ' per il lavoro completato!'})
        else
            TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Errore: nessun lavoro attivo trovato!'})
        end
    end)
end)

RegisterNetEvent('gruppe_sechs:quitJob', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local identifier = xPlayer.getIdentifier()

    exports.oxmysql:execute('DELETE FROM rk_gruppe_sechs WHERE identifier = ?', {identifier})
end)

RegisterNetEvent('gruppe_sechs:updateProgress', function(delivered)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local identifier = xPlayer.getIdentifier()
    
    exports.oxmysql:execute('UPDATE rk_gruppe_sechs SET delivered = ? WHERE identifier = ?', {delivered, identifier})
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        exports.oxmysql:execute('DELETE FROM rk_gruppe_sechs WHERE identifier = ?', {identifier})
    end
end)

-- Cleanup quando lo script viene fermato
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    print('^3[Gruppe Sechs] Script fermato - Pulizia database in corso...')
    exports.oxmysql:execute('DELETE FROM rk_gruppe_sechs WHERE active = 1 OR active = true', {}, function(result)
        if result and result.affectedRows > 0 then
            print('^3[Gruppe Sechs] Cleanup: Rimossi ' .. result.affectedRows .. ' lavori attivi dal database')
        end
    end)
end)
