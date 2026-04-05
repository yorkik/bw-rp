--- [[ RP ACTS ]] ---


rp.AddChatCommand("ds", function(ply, text, team)
    ply:SendLua([[gui.OpenURL("https://discord.com/invite/cSmhecewkY")]])
end)

local function dropmoney(ply, text, team)
    local amount = tonumber(string.match(text, "%d+"))
    if not amount or amount <= 0 then
        ply:ChatPrint("Используйте: /dropmoney [сумма]")
        return
    end

    if not ply:CanAfford(amount) then return end

    ply:SubtractMoney(amount)

    hook.Run("playerDropMoney", ply, tonumber(string.match(text, "%d+")))
    notif(ply, "-" .. FormatMoney(amount), 'fail')


    local trace = {}
	trace.start = ply:EyePos()
	trace.endpos = trace.start + ply:GetAimVector() * 85
	trace.filter = ply

	local tr = util.TraceLine(trace)
    rp.SpawnMoney(tr.HitPos, amount)
end
rp.AddChatCommand("dropmoney", dropmoney)

local function givemoney(ply, text, team)
	local trace = hg.eyeTrace(ply)

	if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.Entity:GetPos():DistToSqr(ply:GetPos()) < 22500 then
		local amount = tonumber(string.match(text, "%d+"))
        if not amount or amount <= 0 then
            ply:ChatPrint("Используйте: /give [сумма]")
            return
        end

		if not ply:CanAfford(amount) then return end
		
        ply:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_GIVE)

        rp.PayPlayer(ply, trace.Entity, amount)

		hook.Run('playerGiveMoney', ply, trace.Entity, amount)

        notif(ply, "Вы дали " .. trace.Entity:GetNWString("PlayerName") .. ' ' .. FormatMoney(amount), 'ok')
        notif(trace.Entity, ply:GetNWString("PlayerName") .. ' дал вам ' .. FormatMoney(amount), 'ok')
	else
		notif(ply, "Вы должны смотреть на игрока!", 'fail')
	end
end
rp.AddChatCommand("give", givemoney)


--- [[ RP CHAT ]] ---

local looccol = Color(128,0,0)
local ooccol = Color(100,255,150)
local rollcol = Color(245,120,120)
local colred = Color(245,0,0)
local colw = Color(0,140,255)

local function localrp(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[LOOC] " .. pl:NameID() .. ": " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist then
                sendMessageCustom(target, looccol, "[LOOC] ", color, playerName, Color(255,255,255), ": " .. message)
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("looc", localrp)
rp.AddChatCommandd("//", localrp)

local function ooc(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[OOC] " .. pl:NameID() .. ": " .. message
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            sendMessageCustom(target, ooccol, "[OOC] ", pl:GetNWVector("PlayerColor"):ToColor(), playerName, Color(255,255,255), ": " .. message)
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("ooc", ooc)
rp.AddChatCommandd("a", ooc)
rp.AddChatCommandd("/", ooc)

local function rpact(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[ME] " .. pl:NameID() .. " " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist then
                sendMessageCustom(target, color, playerName .. " " .. message)
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("me", rpact)

local function advertrp(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[Реклама] " .. pl:NameID() .. ": " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        if not pl:CanAfford(cfg.advertcost) then return end
        pl:SubtractMoney(cfg.advertcost)
        notif(pl, 'Вы купили рекламу за ' .. FormatMoney(cfg.advertcost), 'ok')
        for _, target in pairs(player.GetAll()) do
            sendMessageCustom(target, colred, "[Реклама] ", color, playerName, Color(255,255,255), ": " .. message)
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("advert", advertrp)
rp.AddChatCommandd("ad", advertrp)

local function rproll(pl, args)
    local max = 100
    if args and args[1] and tonumber(args[1]) then
        local num = math.floor(tonumber(args[1]))
        if num > 1 then
            max = num
        end
    end
    
    local result = math.random(1, max)
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[ROLL] " .. pl:NameID() .. " кинул и выпало " .. result .. " из " .. max
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist then
                sendMessageCustom(target, colred, '[', rollcol, 'ROLL', colred, '] ', color, playerName .. " ", color_white, "кинул и выпало ", rollcol, result, color_white, " из " .. max .. ".")
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("roll", rproll)

local function tryrp(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local result = table.Random({"УСПЕШНО", "НЕУСПЕШНО"})
    local fullMessage = "[Попытка] " .. pl:NameID() .. ": " .. result .. " " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist then
                sendMessageCustom(target, colred, '[', rollcol, 'Попытка', colred, '] ', color, playerName, color_white, ':', rollcol, ' ' .. result, color_white, " " .. message)
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("try", tryrp)

local function wrp(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[Шёпот] " .. pl:NameID() .. ": " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist - 150 then
                sendMessageCustom(target, colw, "[Шёпот] ", color, playerName, Color(255,255,255), ": " .. message)
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("w", wrp)

local function yrp(pl, args)
    local message = table.concat(args, " ")
    local playerName = pl:GetNWString("PlayerName")
    local fullMessage = "[Крик] " .. pl:NameID() .. ": " .. message
    local color = pl:GetNWVector("PlayerColor"):ToColor()
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            if target:GetPos():Distance(pl:GetPos()) <= cfg.chatdist + 150 then
                sendMessageCustom(target, colw, "[Крик] ", color, playerName, Color(255,255,255), ": " .. message)
            end
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("y", yrp)

local function darkwebrp(pl, args)
    local message = table.concat(args, " ")
    local fullMessage = "[DarkWeb] " .. pl:NameID() .. ": " .. message
    if SERVER then
        for _, target in pairs(player.GetAll()) do
            sendMessageCustom(target, looccol, "[DarkWeb] ", pl:GetNWVector("PlayerColor"):ToColor(), 'Аноним', Color(255,255,255), ": " .. message)
        end
        plogs.PlayerLog(pl, 'Чат', fullMessage, {
            ['Name']    = pl:Name(),
            ['SteamID'] = pl:SteamID()
        })
    end
end
rp.AddChatCommandd("darkweb", darkwebrp)
rp.AddChatCommandd("dark", darkwebrp)