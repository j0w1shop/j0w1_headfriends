local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('j0w1_headfriends:getFriends', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end

    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT pf.*, p.charinfo FROM player_friends pf LEFT JOIN players p ON p.citizenid = CASE WHEN pf.player1 = ? THEN pf.player2 ELSE pf.player1 END WHERE pf.player1 = ? OR pf.player2 = ?', 
    {citizenid, citizenid, citizenid})
    
    local friends = {}
    for _, v in pairs(result) do
        local charinfo = json.decode(v.charinfo)
        local friendId = v.player1 == citizenid and v.player2 or v.player1
        local friendPlayer = QBCore.Functions.GetPlayerByCitizenId(friendId)
        local serverId = friendPlayer and friendPlayer.PlayerData.source or 0
        
        table.insert(friends, {
            id = serverId,
            name = charinfo.firstname .. " " .. charinfo.lastname,
            online = serverId > 0
        })
    end
    cb(friends)
end)

RegisterNetEvent('j0w1_headfriends:sendRequest', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    if not Player or not Target then return end

    local senderName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    TriggerClientEvent('j0w1_headfriends:receiveRequest', targetId, src, senderName)
end)

RegisterNetEvent('j0w1_headfriends:acceptRequest', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    if not Player or not Target then return end

    MySQL.insert('INSERT INTO player_friends (player1, player2) VALUES (?, ?)', {
        Player.PlayerData.citizenid, Target.PlayerData.citizenid
    })

    TriggerClientEvent('QBCore:Notify', src, "Has aceptado a " .. Target.PlayerData.charinfo.firstname .. " como amigo", "success")
    TriggerClientEvent('QBCore:Notify', targetId, Player.PlayerData.charinfo.firstname .. " te ha aceptado como amigo", "success")

    TriggerClientEvent('j0w1_headfriends:refreshNames', src)
    TriggerClientEvent('j0w1_headfriends:refreshNames', targetId)
end)

RegisterNetEvent('j0w1_headfriends:rejectRequest', function(targetId)
    local src = source
    TriggerClientEvent('QBCore:Notify', targetId, "La ID " .. src .. " ha rechazado tu solicitud de amistad", "error")
end)

RegisterNetEvent('j0w1_headfriends:removeFriend', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    if not Player or not Target then return end

    MySQL.query.await('DELETE FROM player_friends WHERE (player1 = ? AND player2 = ?) OR (player1 = ? AND player2 = ?)', {
        Player.PlayerData.citizenid, Target.PlayerData.citizenid, Target.PlayerData.citizenid, Player.PlayerData.citizenid
    })

    TriggerClientEvent('QBCore:Notify', src, "Has eliminado a " .. Target.PlayerData.charinfo.firstname .. " de tu lista de amigos", "error")
    TriggerClientEvent('QBCore:Notify', targetId, Player.PlayerData.charinfo.firstname .. " te ha eliminado de su lista de amigos", "error")

    TriggerClientEvent('j0w1_headfriends:refreshNames', src)
    TriggerClientEvent('j0w1_headfriends:refreshNames', targetId)
end)
