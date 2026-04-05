function GM:PlayerSpawnProp(ply, mdl)
	//if ply:IsBanned() or ply:IsArrested() or ply:IsFrozen() then return false end
	
	local found = false
	for _, category in pairs(PropWhiteList) do
		if table.HasValue(category, mdl) then
			found = true
			break
		end
	end
	
	if found then return true end
	
	notif(ply, mdl .. " не в вайтлисте!", "fail")
	return ply:IsSuperAdmin()
end