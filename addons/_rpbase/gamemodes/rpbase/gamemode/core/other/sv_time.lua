if not sql.TableExists("rp_playtime") then
    sql.Query([[
        CREATE TABLE IF NOT EXISTS rp_playtime (
            steamid VARCHAR(32) PRIMARY KEY,
            playtime INT NOT NULL DEFAULT 0
        )
    ]])
end

local PLAYER = FindMetaTable("Player")

function PLAYER:SetPlayTime(time)
    self:SetNWInt("PlayTime", time)
end

function PLAYER:AddPlayTime(time)
    local current = self:GetPlayTime()
    self:SetPlayTime(current + time)
end

function SavePlayerPlayTime(ply)
    if not IsValid(ply) or not ply:SteamID() then return end
    local steamid = ply:SteamID()
    local playtime = ply:GetPlayTime()
    sql.Query("REPLACE INTO rp_playtime (steamid, playtime) VALUES (" .. sql.SQLStr(steamid) .. ", " .. playtime .. ")")
end

function LoadPlayerPlayTime(ply)
    if not IsValid(ply) or not ply:SteamID() then return end
    local steamid = ply:SteamID()
    local data = sql.Query("SELECT playtime FROM rp_playtime WHERE steamid = " .. sql.SQLStr(steamid))
    
    local playtime = 0
    if data and #data > 0 then
        playtime = tonumber(data[1].playtime) or 0
    else
        sql.Query("INSERT INTO rp_playtime (steamid, playtime) VALUES (" .. sql.SQLStr(steamid) .. ", 0)")
    end
    
    ply:SetPlayTime(playtime)
end

hook.Add("PlayerInitialSpawn", "LoadPlayTime", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            LoadPlayerPlayTime(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "SavePlayTimeOnDisconnect", function(ply)
    SavePlayerPlayTime(ply)
end)

hook.Add("ShutDown", "SaveAllPlayTimes", function()
    for _, ply in ipairs(player.GetAll()) do
        SavePlayerPlayTime(ply)
    end
end)

timer.Create("SavePlayTimes", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        SavePlayerPlayTime(ply)
    end
end)

hook.Add("PlayerAuthed", "StartPlayTimeCounter", function(ply)
    if not IsValid(ply) then return end

    if ply.playtimeTimerName then
        timer.Remove(ply.playtimeTimerName)
    end

    local steamID = ply:SteamID()
    local timerName = "PlayTimeCounter_" .. steamID
    ply.playtimeTimerName = timerName

    timer.Create(timerName, 1, 0, function()
        if IsValid(ply) then
            ply:AddPlayTime(1)
        else
            timer.Remove(timerName)
        end
    end)
end)

hook.Add("PlayerDisconnected", "StopPlayTimeCounter", function(ply)
    if not IsValid(ply) or not ply.playtimeTimerName then return end
    timer.Remove(ply.playtimeTimerName)
    ply.playtimeTimerName = nil
end)