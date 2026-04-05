local PLAYER = FindMetaTable("Player")

if not sql.TableExists("rp_money") then
    sql.Query([[
        CREATE TABLE IF NOT EXISTS rp_money (
            steamid VARCHAR(32) PRIMARY KEY,
            money INT NOT NULL DEFAULT 0
        )
    ]])
end

function SavePlayerMoney(ply)
    if not IsValid(ply) or not ply:SteamID() then return end
    local steamid = ply:SteamID()
    local money = ply:GetNWInt("Money", 0)
    sql.Query("REPLACE INTO rp_money (steamid, money) VALUES (" .. sql.SQLStr(steamid) .. ", " .. money .. ")")
end

function LoadPlayerMoney(ply)
    if not IsValid(ply) or not ply:SteamID() then return end
    local steamid = ply:SteamID()
    local data = sql.Query("SELECT money FROM rp_money WHERE steamid = " .. sql.SQLStr(steamid))
    
    local money = cfg.startmoney
    if data and #data > 0 then
        money = tonumber(data[1].money) or 0
    else
        sql.Query("INSERT INTO rp_money (steamid, money) VALUES (" .. sql.SQLStr(steamid) .. ", 1500)")
    end
    
    ply:SetNWInt("Money", money)
end

function PLAYER:AddMoney(amount)
    if not IsValid(self) then return end
    local currentmoney = self:GetNWInt("Money", 0)
    local newmoney = currentmoney + amount
    self:SetNWInt("Money", newmoney)
    SavePlayerMoney(self)
end

function PLAYER:SubtractMoney(amount)
    if not IsValid(self) then return end
    local currentmoney = self:GetNWInt("Money", 0)
    local newmoney = math.max(0, currentmoney - amount)
    self:SetNWInt("Money", newmoney)
    SavePlayerMoney(self)
end

hook.Add("PlayerDisconnected", "savemoney", function(ply)
    SavePlayerMoney(ply)
end)


function PLAYER:CanAfford(amount)
    if self:GetMoney() < amount then
        notif(self, "У вас недостаточно денег!", 'fail')
        return false
    end
    return true
end

function rp.PayPlayer(ply1, ply2, amount)
    ply1:SubtractMoney(amount)
    ply2:AddMoney(amount)
end

function rp.SpawnMoney(pos, amount)
	local moneybag = ents.Create('rp_money')
	moneybag:SetPos(pos)
	moneybag:Setamount(math.Min(amount, 2147483647))
	moneybag:Spawn()
	moneybag:Activate()
	return moneybag
end