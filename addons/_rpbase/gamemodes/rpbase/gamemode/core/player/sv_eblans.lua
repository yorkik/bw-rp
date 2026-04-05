-- Авто бан ебланов
local huisosi = {
    ["STEAM_0:1:889727219"] = true,
    ["STEAM_1:1:790429765"] = true,
    -- [""] = true,
}

hook.Add("CheckPassword", "AutoKickBlacklisted", function(steamID64, ipAddress, svPass, clPass)
    local steamID = util.SteamIDFrom64(steamID64)
    if huisosi[steamID] then
        return false, "ХАЙ! Вы поплаи в список хуесосов."
    end
end)