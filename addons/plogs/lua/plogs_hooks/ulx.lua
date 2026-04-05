--[[
addons/lgos/lua/plogs_hooks/ulx.lua
--]]
plogs.Register('Админка', false)

plogs.AddHook('SAM.RanCommand', function(pl, cmd, args)
	if pl:IsPlayer() then 
		plogs.PlayerLog(pl, 'Админка', pl:NameID() .. ' выполнил "' .. cmd .. '" аргумент "' .. table.concat(args, ' ') .. '"', {
			['Name']	= pl:Name(),
			['SteamID']	= pl:SteamID(),
		})
	end
end)


