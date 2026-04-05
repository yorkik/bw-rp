-- File: weapons/weapon_police_pda/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Конфигурация
local LICENSE_MIN_PRICE = 500
local LICENSE_MAX_PRICE = 5000
local WANTED_MAX_REASON_LENGTH = 200
local WARRANT_MAX_REASON_LENGTH = 200
local FINE_MAX_REASON_LENGTH = 200 -- Добавлено для штрафов

-- Таблицы данных
local PlayerLicenses = {} -- {steamid = {license_type = true/false}}
local WantedList = {} -- {steamid = {reason = string, issuer = string, time = number}}
local WarrantList = {} -- {steamid = {reason = string, issuer = string, time = number}}
local FineList = {} -- {steamid = {reason = string, issuer = string, amount = number, time = number}} -- Добавлено для штрафов

local function isValidSteamID(steamid)
    return steamid and (string.StartWith(steamid, "STEAM_") or string.StartWith(steamid, "BOT"))
end

-- --- Сетевые сообщения ---
util.AddNetworkString("PolicePDA_SendData")
util.AddNetworkString("PolicePDA_GetData")
util.AddNetworkString("PolicePDA_SetLicense")
util.AddNetworkString("PolicePDA_AddWanted")
util.AddNetworkString("PolicePDA_RemoveWanted")
util.AddNetworkString("PolicePDA_AddWarrant")
util.AddNetworkString("PolicePDA_RemoveWarrant")
util.AddNetworkString("PolicePDA_AddFine") -- Добавлено
util.AddNetworkString("PolicePDA_RemoveFine") -- Добавлено
util.AddNetworkString("PolicePDA_Notification")
util.AddNetworkString("PolicePDA_AddWanted_Response")
util.AddNetworkString("PolicePDA_AddWarrant_Response")
util.AddNetworkString("PolicePDA_AddFine_Response") -- Добавлено
util.AddNetworkString("PolicePDA_RemoveFine_Response") -- Добавлено
util.AddNetworkString("PolicePDA_PayFine") -- Добавлено для оплаты штрафа игроком через телефон
util.AddNetworkString("PolicePDA_GetFineStatus")

-- net.Receive("PolicePDA_GetData") -> Сервер отправляет данные
net.Receive("PolicePDA_GetData", function(len, ply)
    local data = {
        licenses = table.Copy(PlayerLicenses),
        wanted = table.Copy(WantedList),
        warrant = table.Copy(WarrantList),
        fines = table.Copy(FineList), -- Добавлено
        players = {}
    }
    -- Собираем информацию о всех игроках
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            local steamid = p:SteamID()
            local nick = p:GetNWString("PlayerName")
            local job = p:GetPlayerClass() or "Unknown Job"
            local licenseData = PlayerLicenses[steamid] or {}
            local isWanted = WantedList[steamid] ~= nil
            local hasWarrant = WarrantList[steamid] ~= nil
            local hasFine = FineList[steamid] ~= nil -- Добавлено
            local isDarkRPWanted = p:getDarkRPVar('wantedReason') and p:getDarkRPVar('wantedReason') ~= ""
            data.players[steamid] = {
                nick = nick,
                job = job,
                licenses = licenseData,
                isWanted = isWanted,
                hasWarrant = hasWarrant,
                hasFine = hasFine, -- Добавлено
                isDarkRPWanted = isDarkRPWanted
            }
        end
    end
    net.Start("PolicePDA_SendData")
    net.WriteTable(data)
    net.Send(ply)
end)

-- net.Receive("PolicePDA_GetFineStatus") -> Игрок запрашивает статус своего штрафа
net.Receive("PolicePDA_GetFineStatus", function(len, ply)
    local steamid = ply:SteamID()
    -- Предполагаем, что FineList определена в init.lua КПК (как локальная переменная в начале)
    -- Если FineList определена в init.lua КПК, то мы можем к ней обратиться напрямую
    local fineData = FineList[steamid] -- Используем локальную переменную FineList из init.lua КПК
    if fineData then
        net.Start("PolicePDA_GetFineStatus_Response")
        net.WriteBool(true) -- Есть штраф
        net.WriteString(fineData.reason)
        net.WriteInt(fineData.amount, 32)
        net.WriteString(fineData.issuer)
        net.Send(ply)
    else
        net.Start("PolicePDA_GetFineStatus_Response")
        net.WriteBool(false) -- Нет штрафа
        net.Send(ply)
    end
end)

-- net.Receive("PolicePDA_SetLicense", targetSteamID, licenseType, status) -> Установить лицензию
net.Receive("PolicePDA_SetLicense", function(len, ply)
    if not IsValid(ply) or not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to set license without being CP!")
        return
    end
    local targetSteamID = net.ReadString()
    local licenseType = net.ReadString()
    local status = net.ReadBool()
    if not isValidSteamID(targetSteamID) or not licenseType or licenseType == "" then
        print("[PolicePDA] Invalid data for license setting.")
        return
    end
    -- Находим игрока по SteamID
    local targetPlayer = player.GetBySteamID(targetSteamID)
    if not IsValid(targetPlayer) then
        print("[PolicePDA] Target player not found: " .. targetSteamID)
        return
    end
    -- Устанавливаем лицензию через DarkRP переменную
    -- В данном случае, мы поддерживаем только лицензию на оружие
    if licenseType == "weapon" then
        -- Устанавливаем лицензию через DarkRP переменную
        targetPlayer:setDarkRPVar('HasGunlicense', status)
        -- Если лицензия отозвана, также удаляем её из инвентаря
        if not status and targetPlayer:hasLicense() then
            targetPlayer:removeLicense()
        end
    end
    if not PlayerLicenses[targetSteamID] then
        PlayerLicenses[targetSteamID] = {}
    end
    PlayerLicenses[targetSteamID][licenseType] = status
    -- Уведомление
    local targetNick = targetPlayer:GetNWString("PlayerName")
    local action = status and "ВЫДАНА" or "ОТЗВАНА"
    local notificationData = {
        type = "license_change",
        targetNick = targetNick,
        licenseType = licenseType,
        status = status,
        issuer = ply:GetNWString("PlayerName"),
        action = action
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    print("[PolicePDA] License '" .. licenseType .. "' " .. (status and "GRANTED" or "REVOKED") .. " for " .. targetNick .. " by " .. ply:GetNWString("PlayerName"))
end)

-- net.Receive("PolicePDA_AddWanted", targetSteamID, reason, issuer) -> Добавить в розыск
net.Receive("PolicePDA_AddWanted", function(len, ply)
    if not IsValid(ply) then
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Игрок не найден")
        net.Send(ply)
        return
    end
    if not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to add wanted without being CP!")
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Вы не являетесь полицейским")
        net.Send(ply)
        return
    end
    local targetSteamID = net.ReadString()
    local reason = net.ReadString()
    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for wanted.")
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Неверный SteamID")
        net.Send(ply)
        return
    end
    if not reason or reason == "" then
        print("[PolicePDA] Empty reason for wanted.")
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Причина не указана")
        net.Send(ply)
        return
    end
    if #reason > WANTED_MAX_REASON_LENGTH then
        print("[PolicePDA] Reason too long for wanted.")
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Причина слишком длинная (макс 200 символов)")
        net.Send(ply)
        return
    end
    local targetPlayer = player.GetBySteamID(targetSteamID)
    if not IsValid(targetPlayer) then
        print("[PolicePDA] Target player not found: " .. targetSteamID)
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Целевой игрок не найден")
        net.Send(ply)
        return
    end
    if targetPlayer:getDarkRPVar('wantedReason') and targetPlayer:getDarkRPVar('wantedReason') ~= "" then
        print("[PolicePDA] Player " .. targetPlayer:GetNWString("PlayerName") .. " is already wanted.")
        net.Start("PolicePDA_AddWanted_Response")
        net.WriteBool(false)
        net.WriteString("Игрок уже в розыске")
        net.Send(ply)
        return
    end
    targetPlayer:wanted(ply, reason)
    WantedList[targetSteamID] = {
        reason = reason,
        time = os.time()
    }
    local targetNick = targetPlayer:GetNWString("PlayerName")
    local notificationData = {
        type = "wanted_added",
        targetNick = targetNick,
        reason = reason
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    net.Broadcast()
    net.Start("PolicePDA_AddWanted_Response")
    net.WriteBool(true)
    net.WriteString(targetNick)
    net.Send(ply)
    print("[PolicePDA] Added " .. targetNick .. " to wanted list (Reason: " .. reason .. ") by " .. ply:GetNWString("PlayerName"))
end)

-- net.Receive("PolicePDA_RemoveWanted", targetSteamID) -> Удалить из розыск
net.Receive("PolicePDA_RemoveWanted", function(len, ply)
    if not IsValid(ply) or not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to remove wanted without being CP!")
        return
    end
    local targetSteamID = net.ReadString()
    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for removing wanted.")
        return
    end
    if not WantedList[targetSteamID] then
        print("[PolicePDA] Player " .. targetSteamID .. " is not on wanted list.")
        return
    end
    local oldData = WantedList[targetSteamID]
    WantedList[targetSteamID] = nil
    -- Уведомление
    local targetPlayer = player.GetBySteamID(targetSteamID)
    local targetNick = targetPlayer and targetPlayer:GetNWString("PlayerName") or targetSteamID
    local notificationData = {
        type = "wanted_removed",
        targetNick = targetNick,
        issuer = ply:GetNWString("PlayerName")
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    net.Broadcast() -- Отправляем всем игрокам
    print("[PolicePDA] Removed " .. targetNick .. " from wanted list by " .. ply:GetNWString("PlayerName"))
end)

-- net.Receive("PolicePDA_AddWarrant", targetSteamID, reason, issuer) -> Добавить ордер
net.Receive("PolicePDA_AddWarrant", function(len, ply)
    if not IsValid(ply) then
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("Игрок не найден")
        net.Send(ply)
        return
    end
    if not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to add warrant without being CP!")
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("Вы не являетесь полицейским")
        net.Send(ply)
        return
    end
    local targetSteamID = net.ReadString()
    local reason = net.ReadString()
    local issuer = net.ReadString() -- Имя полицейского, который выдает ордер
    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for warrant.")
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("Неверный SteamID")
        net.Send(ply)
        return
    end
    if not reason or reason == "" then
        print("[PolicePDA] Empty reason for warrant.")
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("Причина не указана")
        net.Send(ply)
        return
    end
    if #reason > WARRANT_MAX_REASON_LENGTH then
        print("[PolicePDA] Reason too long for warrant.")
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("Причина слишком длинная (макс 200 символов)")
        net.Send(ply)
        return
    end
    -- Проверяем, нет ли уже ордера
    if WarrantList[targetSteamID] then
        print("[PolicePDA] Player " .. targetSteamID .. " already has a warrant.")
        net.Start("PolicePDA_AddWarrant_Response")
        net.WriteBool(false)
        net.WriteString("У игрока уже есть ордер")
        net.Send(ply)
        return
    end
    WarrantList[targetSteamID] = {
        reason = reason,
        issuer = issuer,
        time = os.time()
    }
    -- Уведомление
    local targetPlayer = player.GetBySteamID(targetSteamID)
    local targetNick = targetPlayer and targetPlayer:GetNWString("PlayerName") or targetSteamID
    local notificationData = {
        type = "warrant_added",
        targetNick = targetNick,
        reason = reason,
        issuer = issuer
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    net.Start("PolicePDA_AddWarrant_Response")
    net.WriteBool(true)
    net.WriteString(targetNick)
    net.Send(ply)
    print("[PolicePDA] Added warrant for " .. targetNick .. " (Reason: " .. reason .. ") by " .. issuer)
end)

-- net.Receive("PolicePDA_RemoveWarrant", targetSteamID) -> Удалить ордер
net.Receive("PolicePDA_RemoveWarrant", function(len, ply)
    if not IsValid(ply) or not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to remove warrant without being CP!")
        return
    end
    local targetSteamID = net.ReadString()
    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for removing warrant.")
        return
    end
    if not WarrantList[targetSteamID] then
        print("[PolicePDA] Player " .. targetSteamID .. " has no warrant.")
        return
    end
    local oldData = WarrantList[targetSteamID]
    WarrantList[targetSteamID] = nil
    -- Уведомление
    local targetPlayer = player.GetBySteamID(targetSteamID)
    local targetNick = targetPlayer and targetPlayer:GetNWString("PlayerName") or targetSteamID
    local notificationData = {
        type = "warrant_removed",
        targetNick = targetNick,
        issuer = ply:GetNWString("PlayerName")
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    print("[PolicePDA] Removed warrant for " .. targetNick .. " by " .. ply:GetNWString("PlayerName"))
end)

-- net.Receive("PolicePDA_AddFine", targetSteamID, reason, amount, issuer) -> Добавить штраф
net.Receive("PolicePDA_AddFine", function(len, ply)
    if not IsValid(ply) then
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Игрок не найден")
        net.Send(ply)
        return
    end
    if not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to add fine without being CP!")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Вы не являетесь полицейским")
        net.Send(ply)
        return
    end
    local targetSteamID = net.ReadString()
    local reason = net.ReadString()
    local amount = net.ReadInt(32) -- Читаем целое число
    local issuer = net.ReadString()

    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for fine.")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Неверный SteamID")
        net.Send(ply)
        return
    end
    if not reason or reason == "" then
        print("[PolicePDA] Empty reason for fine.")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Причина не указана")
        net.Send(ply)
        return
    end
    if #reason > FINE_MAX_REASON_LENGTH then
        print("[PolicePDA] Reason too long for fine.")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Причина слишком длинная (макс 200 символов)")
        net.Send(ply)
        return
    end
    if amount <= 0 then
        print("[PolicePDA] Invalid amount for fine.")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("Неверная сумма штрафа")
        net.Send(ply)
        return
    end

    -- Проверяем, нет ли уже штрафа
    if FineList[targetSteamID] then
        print("[PolicePDA] Player " .. targetSteamID .. " already has a fine.")
        net.Start("PolicePDA_AddFine_Response")
        net.WriteBool(false)
        net.WriteString("У игрока уже есть штраф")
        net.Send(ply)
        return
    end

    FineList[targetSteamID] = {
        reason = reason,
        issuer = issuer,
        amount = amount,
        time = os.time()
    }

    -- Уведомление
    local targetPlayer = player.GetBySteamID(targetSteamID)
    local targetNick = targetPlayer and targetPlayer:GetNWString("PlayerName") or targetSteamID
    local notificationData = {
        type = "fine_added",
        targetNick = targetNick,
        reason = reason,
        amount = amount,
        issuer = issuer
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    -- Уведомление самому игроку
    if IsValid(targetPlayer) then
        net.Start("PolicePDA_Notification")
        net.WriteTable(notificationData)
        net.Send(targetPlayer)
    end

    net.Start("PolicePDA_AddFine_Response")
    net.WriteBool(true)
    net.WriteString(targetNick)
    net.Send(ply)
    print("[PolicePDA] Added fine for " .. targetNick .. " (Reason: " .. reason .. ", Amount: " .. amount .. ") by " .. issuer)
end)

-- net.Receive("PolicePDA_RemoveFine", targetSteamID) -> Удалить штраф
net.Receive("PolicePDA_RemoveFine", function(len, ply)
    if not IsValid(ply) or not ply:isCP() then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to remove fine without being CP!")
        net.Start("PolicePDA_RemoveFine_Response")
        net.WriteBool(false)
        net.WriteString("Вы не являетесь полицейским")
        net.Send(ply)
        return
    end
    local targetSteamID = net.ReadString()
    if not isValidSteamID(targetSteamID) then
        print("[PolicePDA] Invalid SteamID for removing fine.")
        net.Start("PolicePDA_RemoveFine_Response")
        net.WriteBool(false)
        net.WriteString("Неверный SteamID")
        net.Send(ply)
        return
    end
    if not FineList[targetSteamID] then
        print("[PolicePDA] Player " .. targetSteamID .. " has no fine.")
        net.Start("PolicePDA_RemoveFine_Response")
        net.WriteBool(false)
        net.WriteString("У игрока нет штрафа")
        net.Send(ply)
        return
    end
    local oldData = FineList[targetSteamID]
    FineList[targetSteamID] = nil
    -- Уведомление
    local targetPlayer = player.GetBySteamID(targetSteamID)
    local targetNick = targetPlayer and targetPlayer:GetNWString("PlayerName") or targetSteamID
    local notificationData = {
        type = "fine_removed",
        targetNick = targetNick,
        issuer = ply:GetNWString("PlayerName")
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    -- Уведомление самому игроку
    if IsValid(targetPlayer) then
        net.Start("PolicePDA_Notification")
        net.WriteTable(notificationData)
        net.Send(targetPlayer)
    end

    net.Start("PolicePDA_RemoveFine_Response")
    net.WriteBool(true)
    net.WriteString(targetNick)
    net.Send(ply)
    print("[PolicePDA] Removed fine for " .. targetNick .. " by " .. ply:GetNWString("PlayerName"))
end)

-- net.Receive("PolicePDA_PayFine") -> Игрок оплачивает штраф
net.Receive("PolicePDA_PayFine", function(len, ply)
    local steamid = ply:SteamID()
    if not FineList[steamid] then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to pay fine, but has no fine.")
        return
    end
    local fineData = FineList[steamid]
    local fineAmount = fineData.amount

    if ply:GetMoney() < fineAmount then
        print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " tried to pay fine, but has insufficient funds.")
        ply:ChatPrint("У вас недостаточно денег для оплаты штрафа в " .. fineAmount .. "$.")
        return
    end

    -- Снимаем деньги
    ply:addMoney(-fineAmount)

    -- Удаляем штраф
    FineList[steamid] = nil

    -- Уведомления
    local notificationData = {
        type = "fine_paid",
        targetNick = ply:GetNWString("PlayerName"),
        amount = fineAmount
    }
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    -- Отправляем всем полицейским
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:isCP() then
            net.Send(p)
        end
    end
    -- Уведомление самому игроку
    net.Start("PolicePDA_Notification")
    net.WriteTable(notificationData)
    net.Send(ply)

    print("[PolicePDA] Player " .. ply:GetNWString("PlayerName") .. " paid fine of " .. fineAmount .. "$.")
end)

-- Хук для автоматического снятия розыска при смерти полицейского
hook.Add("PlayerDeath", "PolicePDA_ClearWantedOnDeath", function(victim, inflictor, attacker)
    local victimSteamID = victim:SteamID()
    -- Если игрок в розыске - снимаем розыск
    if WantedList[victimSteamID] then
        local oldData = WantedList[victimSteamID]
        WantedList[victimSteamID] = nil
        local notificationData = {
            type = "wanted_removed",
            targetNick = victim:GetNWString("PlayerName"),
            reason = "Цель убита",
            issuer = "Система"
        }
        net.Start("PolicePDA_Notification")
        net.WriteTable(notificationData)
        net.Broadcast()
        print("[PolicePDA] Wanted removed for " .. victim:GetNWString("PlayerName") .. " (Target killed)")
    end
end)

-- Хук для удаления ордера при аресте (если используется система ареста)
hook.Add("playerArrested", "PolicePDA_ClearWarrantOnArrest", function(ply, time, arrester)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    if WarrantList[steamid] then
        local oldData = WarrantList[steamid]
        WarrantList[steamid] = nil
        local notificationData = {
            type = "warrant_removed",
            targetNick = ply:GetNWString("PlayerName"),
            reason = "Арестован",
            issuer = arrester and arrester:GetNWString("PlayerName") or "Система"
        }
        net.Start("PolicePDA_Notification")
        net.WriteTable(notificationData)
        -- Отправляем всем полицейским
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p:isCP() then
                net.Send(p)
            end
        end
        print("[PolicePDA] Warrant removed for " .. ply:GetNWString("PlayerName") .. " (Player arrested)")
    end
end)
