local QBCore = exports['qb-core']:GetCoreObject()
local showNames = true 
local playerTags = {}

RegisterCommand("friends", function()
    QBCore.Functions.TriggerCallback('j0w1_headfriends:getFriends', function(friends)
        local menu = {
            { header = "Sistema de Amigos", isMenuHeader = true },
            {
                header = "📋 Lista de Amigos (" .. #friends .. ")",
                txt = "Ver y gestionar tus amigos",
                params = {
                    event = "j0w1_headfriends:showFriendsList",
                    args = friends
                }
            },
            {
                header = "➕ Agregar Amigo",
                txt = "Seleccionar alguien cercano",
                params = { event = "j0w1_headfriends:addFriend" }
            },
            { header = "❌ Cerrar", params = { event = "qb-menu:closeMenu" } }
        }
        exports['qb-menu']:openMenu(menu)
    end)
end)

RegisterNetEvent('j0w1_headfriends:showFriendsList', function(friends)
    local menu = {
        { header = "Lista de Amigos", isMenuHeader = true }
    }

    if #friends == 0 then
        table.insert(menu, {
            header = "Sin amigos",
            txt = "¡Agrega algunos amigos!",
            disabled = true
        })
    else
        for _, v in pairs(friends) do
            table.insert(menu, {
                header = v.name .. (v.online and " | #" .. v.id or ""),
                txt = "Gestionar amistad",
                params = {
                    event = "j0w1_headfriends:manageFriend",
                    args = {
                        id = v.id,
                        name = v.name
                    }
                }
            })
        end
    end

    table.insert(menu, { header = "❌ Cerrar", params = { event = "qb-menu:closeMenu" } })
    
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('j0w1_headfriends:addFriendByID', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Añadir Amigo",
        submitText = "Confirmar",
        inputs = {
            {
                text = "Discord ID", 
                name = "discordid", 
                type = "text", 
                isRequired = true
            }
        }
    })
    
    if dialog then
        TriggerServerEvent('j0w1_headfriends:addSQLFriend', dialog.discordid)
    end
end)

RegisterNetEvent('j0w1_headfriends:addFriend', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local players = GetActivePlayers()
    local nearbyPlayers = {}
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= 3.0 then
                table.insert(nearbyPlayers, player)
            end
        end
    end
    
    if #nearbyPlayers == 0 then
        QBCore.Functions.Notify("No hay jugadores cerca para agregar", "error")
        return
    end
end)

local function IsPedWearingMask(ped)
    local mask = GetPedDrawableVariation(ped, 1)
    return mask ~= 0
end

CreateThread(function()
    while true do
        local sleep = 1000
        
        if showNames then
            local players = GetActivePlayers()
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            
            QBCore.Functions.TriggerCallback('j0w1_headfriends:getFriends', function(friends)
                local friendIds = {}
                for _, f in pairs(friends) do
                    friendIds[f.id] = f.name
                end
                
                for _, player in ipairs(players) do
                    if player ~= PlayerId() then
                        local targetPed = GetPlayerPed(player)
                        local targetPos = GetEntityCoords(targetPed)
                        local distance = #(playerPos - targetPos)
                        local serverId = GetPlayerServerId(player)
                        
                        if distance <= 10.0 then
                            sleep = 0
                            local targetBone = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                            local playerBone = GetPedBoneCoords(playerPed, 31086, 0.0, 0.0, 0.0)
                            
                            local _, hit = GetShapeTestResult(StartShapeTestRay(
                                playerBone.x, playerBone.y, playerBone.z,
                                targetBone.x, targetBone.y, targetBone.z,
                                -1, playerPed, 4
                            ))
                            
                            local shouldShow = distance <= 2.0 or not hit
                            
                            if shouldShow then
                                local isMasked = IsPedWearingMask(targetPed)
                                local displayName = isMasked and "Desconocido | #" .. serverId or 
                                                  (friendIds[serverId] and (friendIds[serverId] .. " | #" .. serverId) or 
                                                  ("Desconocido | #" .. serverId))
                                
                                if not playerTags[serverId] then
                                    playerTags[serverId] = CreateFakeMpGamerTag(targetPed, displayName, false, false, "", 0)
                                    SetMpGamerTagVisibility(playerTags[serverId], 0, true)
                                    SetMpGamerTagAlpha(playerTags[serverId], 0, 255)
                                else
                                    SetMpGamerTagName(playerTags[serverId], displayName)
                                end
                            else
                                if playerTags[serverId] then
                                    RemoveMpGamerTag(playerTags[serverId])
                                    playerTags[serverId] = nil
                                end
                            end
                        else
                            if playerTags[serverId] then
                                RemoveMpGamerTag(playerTags[serverId])
                                playerTags[serverId] = nil
                            end
                        end
                    end
                end
            end)
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('j0w1_headfriends:receiveRequest', function(sourceId, senderName)
    if lib == nil then
        QBCore.Functions.Notify("Error al mostrar el menú", "error")
        return
    end

    lib.registerContext({
        id = 'friend_request_menu',
        title = '📨 Nueva Solicitud de Amistad',
        options = {
            {
                title = '👤 ' .. senderName,
                description = 'ID: ' .. sourceId,
                disabled = true,
                metadata = {
                    {label = 'Estado', value = 'Pendiente'},
                    {label = 'ID', value = '#' .. sourceId}
                }
            },
            {
                title = 'Aceptar Solicitud',
                description = '¿Quieres ser amigo de ' .. senderName .. '?',
                icon = 'check',
                onSelect = function()
                    TriggerServerEvent('j0w1_headfriends:acceptRequest', sourceId)
                end
            },
            {
                title = 'Rechazar Solicitud',
                description = 'Ignorar solicitud de amistad',
                icon = 'xmark',
                onSelect = function()
                    TriggerServerEvent('j0w1_headfriends:rejectRequest', sourceId)
                end
            }
        }
    })

    lib.showContext('friend_request_menu')
end)

RegisterNetEvent('j0w1_headfriends:sendRequest', function(targetId)
    print('DEBUG: Intentando enviar solicitud a ID:', targetId)
    TriggerServerEvent('j0w1_headfriends:sendRequest', targetId)
end)

RegisterNetEvent('j0w1_headfriends:manageFriend', function(data)
    local menu = {
        { header = "Gestionar Amistad", isMenuHeader = true },
        {
            header = "🗑️ Eliminar Amigo",
            txt = "Eliminar a " .. data.name,
            params = {
                isServer = true,
                event = "j0w1_headfriends:removeFriend",
                args = data.id
            }
        },
        { header = "❌ Cerrar", params = { event = "qb-menu:closeMenu" } }
    }
    
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('j0w1_headfriends:back', function()
    TriggerEvent('j0w1_headfriends:showMenu')
end)

RegisterNetEvent('j0w1_headfriends:refreshNames', function()
    if playerTags then
        for k, v in pairs(playerTags) do
            if v and DoesEntityExist(v) then
                RemoveMpGamerTag(v)
            end
            playerTags[k] = nil
        end
    end
    playerTags = {}
end)
