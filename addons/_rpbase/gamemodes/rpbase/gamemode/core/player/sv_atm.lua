BraxBank = {}

if not sql.TableExists("rp_atm") then
	sql.Query([[
		CREATE TABLE IF NOT EXISTS rp_atm (
			steamid VARCHAR(32) PRIMARY KEY,
			money INT NOT NULL DEFAULT 0
		)
	]])
end

function BraxBank.CreateAccount(ply)
	if not IsValid(ply) or not ply:SteamID() then return end
	local steamid = ply:SteamID()
	local data = sql.Query("SELECT money FROM rp_atm WHERE steamid = " .. sql.SQLStr(steamid))
	
	if not data or #data == 0 then
		sql.Query("INSERT INTO rp_atm (steamid, money) VALUES (" .. sql.SQLStr(steamid) .. ", 0)")
	end
end

function BraxBank.PlayerMoney(ply)
	if not IsValid(ply) or not ply:SteamID() then return 0 end
	local steamid = ply:SteamID()
	local data = sql.Query("SELECT money FROM rp_atm WHERE steamid = " .. sql.SQLStr(steamid))
	
	if data and #data > 0 then
		return tonumber(data[1].money) or 0
	else
		print("Could not find bank for " .. ply:Nick())
		BraxBank.CreateAccount(ply)
		return BraxBank.PlayerMoney(ply)
	end
end

function BraxBank.UpdateMoney(ply, amount)
	if not IsValid(ply) or not ply:SteamID() then return end
	local steamid = ply:SteamID()
	local data = sql.Query("SELECT money FROM rp_atm WHERE steamid = " .. sql.SQLStr(steamid))
	
	if data and #data > 0 then
		sql.Query("UPDATE rp_atm SET money = " .. tonumber(amount) .. " WHERE steamid = " .. sql.SQLStr(steamid))
	else
		print("Could not find bank for " .. ply:Nick())
		BraxBank.CreateAccount(ply)
		BraxBank.UpdateMoney(ply, amount)
	end
end


function BraxBank.TakeAction(ply)
	MsgC(Color(255,0,0), ply:Name().." tried to exploit an ATM!\n")
end

--[[
	Return codes!!
	1 = NULL
	2 = Deposit, bank does not have money
	3 = Deposit, ok
	4 = Insert, User does not have enough money
	5 = Insert, ok
]]--

util.AddNetworkString( "BraxAtmWithdraw" )
net.Receive( "BraxAtmWithdraw", function( length, client )
	
	local WithdrawValue = net.ReadInt(32)
	local UserMoney = BraxBank.PlayerMoney(client)
	
	local atmcheck = false
	for _,v in pairs(ents.FindByClass("rp_atm")) do
		if IsValid(v) and v:GetClass() == "rp_atm" and v:GetPos():Distance(client:GetShootPos()) < 256 then atmcheck = true end
	end
	if atmcheck == false then BraxBank.TakeAction(client) return end
	if WithdrawValue <= 0 then BraxBank.TakeAction(client) return end
	
	
	if WithdrawValue > UserMoney then
		BraxBankAtmReturnCode(2, client)
		return
	end
	
	local NewVal = UserMoney-WithdrawValue
	
	BraxBank.UpdateMoney(client, NewVal)
	client:AddMoney(WithdrawValue)
	BraxBankAtmReturnCode(3, client)
end )

util.AddNetworkString( "BraxAtmDeposit" )
net.Receive( "BraxAtmDeposit", function( length, client )
	
	local DepositValue = net.ReadInt(32)
	local UserMoney = BraxBank.PlayerMoney(client)
	
	local atmcheck = false
	for _,v in pairs(ents.FindByClass("rp_atm")) do
		if IsValid(v) and v:GetClass() == "rp_atm" and v:GetPos():Distance(client:GetShootPos()) < 256 then atmcheck = true end
	end
	if atmcheck == false then BraxBank.TakeAction(client) return end
	if DepositValue <= 0 then BraxBank.TakeAction(client) return end

	if DepositValue > client:GetMoney() then
		BraxBankAtmReturnCode(2, client)
		return
	end
	
	
	local NewVal = UserMoney + DepositValue
	
	BraxBank.UpdateMoney(client, NewVal)	
	client:SubtractMoney(DepositValue)
	BraxBankAtmReturnCode(5, client)
end )

function BraxBankAtmUpdate(client)
	BraxBank.CreateAccount(client)
	local m = BraxBank.PlayerMoney(client)

	net.Start( "BraxAtmFetch" )
		net.WriteInt(m, 32)
	net.Send(client)
end

util.AddNetworkString( "BraxAtmReturnCode" )
function BraxBankAtmReturnCode(code, client)
	net.Start( "BraxAtmReturnCode" )
		net.WriteInt(code, 32)
	net.Send(client)
end

util.AddNetworkString( "BraxAtmFetch" )

concommand.Add("brax_atm_update", function(p, c, a)
	BraxBankAtmUpdate(p)
end)

hook.Add("playerGetSalary","BraxAtmSalary", function(ply, amount)
	local money = BraxBank.PlayerMoney(ply)
	BraxBank.UpdateMoney(ply, money+amount)
	return false
end)