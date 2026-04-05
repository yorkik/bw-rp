DarkRP = DarkRP or {}
DarkRP.Orgs = DarkRP.Orgs or {}
DarkRP.Orgs.BaseData = DarkRP.Orgs.BaseData or {}

DarkRP.Orgs.BaseData['Owner'] = DarkRP.Orgs.BaseData['Owner'] or {
    Perms = {
        Weight = 100,
        Owner = true,
        Invite = true,
        Kick = true,
        Rank = true,
        MoTD = true,
        ChangeColor = true
    }
}

local PLAYER = FindMetaTable("Player")
local ENTITY = FindMetaTable("Entity")

function PLAYER:GetOrg()
	return self:GetNetVar('Org') or nil
end

function PLAYER:GetOrgData()
	return self:GetNetVar('OrgData')
end

function PLAYER:GetOrgColor()
	local c = self:GetNetVar('OrgColor')
	return (c and Color(c.r, c.g, c.b) or Color(255, 255, 255))
end


function ENTITY:GetOrg()
	return self:GetNetVar('Org') or nil
end

function ENTITY:GetOrgData()
	return self:GetNetVar('OrgData')
end

function ENTITY:GetOrgColor()
	local c = self:GetNetVar('OrgColor')
	return (c and Color(c.r, c.g, c.b) or Color(255, 255, 255))
end



function DarkRP.FindPlayer(info)
	if not info or (info == '') then return end
	info = tostring(info)

	for _, pl in ipairs(player.GetAll()) do
		if (info == pl:SteamID()) then
			return pl
		elseif (info == pl:SteamID64()) then
			return pl
		elseif string.find(string.lower(pl:Name()), string.lower(info), 1, true) ~= nil then
			return pl
		end
	end
end

function DarkRP.Orgs.GetOnlineMembers(org)
	return table.Filter(player.GetAll(), function(pl)
		return (pl:GetOrg() == org)
	end)
end

function DarkRP.Orgs.Join(pl, org_name)
    if pl:GetOrg() then
        return false, "Вы уже состоите в организации!"
    end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data then
        return false, "Организация не найдена!"
    end

    org_data.Members[pl:SteamID()] = { Rank = "Member", Perms = org_data.Ranks["Member"].Perms }

    pl:SetNetVar('Org', org_name)
    pl:SetNetVar('OrgData', org_data.Members[pl:SteamID()])
    pl:SetNetVar('OrgColor', org_data.Color)

    return true
end

function DarkRP.Orgs.Create(org_name, owner_steamid, color)
    if DarkRP.Orgs[org_name] then
        return false, "Организация с таким названием уже существует!"
    end

    DarkRP.Orgs[org_name] = {
        Name = org_name,
        Owner = owner_steamid,
        Color = color,
        Members = {
            [owner_steamid] = {
                Rank = 'Owner',
                Perms = DarkRP.Orgs.BaseData['Owner'].Perms
            }
        },
        MoTD = "Добро пожаловать в " .. org_name .. "!",
        Created = os.time(),
        Ranks = {
            ["Member"] = {
                Weight = 1,
                Perms = { Weight = 1, Owner = false, Invite = false, Kick = false, Rank = false, MoTD = false, ChangeColor = false }
            },
            ["Admin"] = {
                Weight = 50,
                Perms = { Weight = 50, Owner = false, Invite = true, Kick = true, Rank = true, MoTD = true, ChangeColor = false }
            }
        }
    }

    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint("Организация '" .. org_name .. "' была создана игроком " .. (DarkRP.FindPlayer(owner_steamid) and DarkRP.FindPlayer(owner_steamid):Name() or "Unknown") .. "!")
    end

    return true
end

function DarkRP.Orgs.Disband(owner)
    local org_name = owner:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if org_data.Owner ~= owner:SteamID() then return false, "Только владелец может распустить организацию." end

    for sid, _ in pairs(org_data.Members) do
        local pl = DarkRP.FindPlayer(sid)
        if pl then
            pl:SetNetVar('Org', nil)
            pl:SetNetVar('OrgData', nil)
            pl:SetNetVar('OrgColor', nil)
            pl:ChatPrint("Организация '" .. org_name .. "' была распущена владельцем.")
        end
    end

    DarkRP.Orgs[org_name] = nil

    for _, pl in ipairs(player.GetAll()) do
        pl:ChatPrint("Организация '" .. org_name .. "' была распущена.")
    end

    return true
end

function DarkRP.Orgs.Leave(pl)
    local org_name = pl:GetOrg()
    if not org_name then
        return false, "Вы не состоите ни в одной организации!"
    end

    local org_data = DarkRP.Orgs[org_name]
    org_data.Members[pl:SteamID()] = nil

    pl:SetNetVar('Org', nil)
    pl:SetNetVar('OrgData', nil)
    pl:SetNetVar('OrgColor', nil)

    return true
end

function DarkRP.Orgs.Invite(inviter, target_steamid)
    local org_name = inviter:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[inviter:SteamID()] or not org_data.Members[inviter:SteamID()].Perms.Invite then return false, "Нет прав." end

    local target_pl = DarkRP.FindPlayer(target_steamid)
    if not target_pl then return false, "Игрок не найден." end
    if target_pl:GetOrg() then return false, "Игрок уже состоит в организации." end

    target_pl.org_invite_pending = org_name
    inviter:ChatPrint("Приглашение отправлено " .. target_pl:Name())
    target_pl:ChatPrint("Вас пригласили присоединиться к организации " .. org_name .. ". Используйте /acceptorg для принятия.")

    return true
end

function DarkRP.Orgs.Kick(kicker, target_steamid)
    local org_name = kicker:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[kicker:SteamID()] or not org_data.Members[kicker:SteamID()].Perms.Kick then return false, "Нет прав." end

    if not org_data.Members[target_steamid] then return false, "Игрок не состоит в организации." end

    local target_pl = DarkRP.FindPlayer(target_steamid)
    if target_pl then
        target_pl:SetNetVar('Org', nil)
        target_pl:SetNetVar('OrgData', nil)
        target_pl:SetNetVar('OrgColor', nil)
        target_pl:ChatPrint("Вас исключили из организации " .. org_name)
    end

    org_data.Members[target_steamid] = nil
    return true
end

function DarkRP.Orgs.SetRank(changer, target_steamid, new_rank)
    local org_name = changer:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[changer:SteamID()] or not org_data.Members[changer:SteamID()].Perms.Rank then return false, "Нет прав." end

    if not org_data.Members[target_steamid] then return false, "Игрок не состоит в организации." end

    if not org_data.Ranks or not org_data.Ranks[new_rank] then return false, "Роль не существует." end

    org_data.Members[target_steamid].Rank = new_rank
    org_data.Members[target_steamid].Perms = org_data.Ranks[new_rank].Perms

    local target_pl = DarkRP.FindPlayer(target_steamid)
    if target_pl and target_pl:GetOrg() == org_name then
        target_pl:SetNetVar('OrgData', org_data.Members[target_steamid])
    end

    return true
end

function DarkRP.Orgs.AddRank(owner, rank_name, weight, perms)
    local org_name = owner:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[owner:SteamID()] or not org_data.Members[owner:SteamID()].Perms.Owner then return false, "Нет прав." end

    if not org_data.Ranks then org_data.Ranks = {} end
    if org_data.Ranks[rank_name] then return false, "Роль уже существует." end

    org_data.Ranks[rank_name] = {
        Weight = weight,
        Perms = perms
    }

    return true
end

function DarkRP.Orgs.RemoveRank(owner, rank_name)
    local org_name = owner:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[owner:SteamID()] or not org_data.Members[owner:SteamID()].Perms.Owner then return false, "Нет прав." end

    if not org_data.Ranks or not org_data.Ranks[rank_name] then return false, "Роль не существует." end

    if rank_name == "Owner" then return false, "Нельзя удалить роль владельца." end

    for sid, data in pairs(org_data.Members) do
        if data.Rank == rank_name then
            data.Rank = "Member"
            data.Perms = { Weight = 1, Owner = false, Invite = false, Kick = false, Rank = false, MoTD = false, ChangeColor = false }
            local pl = DarkRP.FindPlayer(sid)
            if pl and pl:GetOrg() == org_name then
                pl:SetNetVar('OrgData', data)
            end
        end
    end

    org_data.Ranks[rank_name] = nil
    return true
end

function DarkRP.Orgs.UpdateMotD(updater, new_motd)
    local org_name = updater:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[updater:SteamID()] or not org_data.Members[updater:SteamID()].Perms.MoTD then return false, "Нет прав." end

    org_data.MoTD = new_motd

    net.Start("SendUpdatedMotD")
        net.WriteString(org_name)
        net.WriteString(new_motd)
    net.Send(player.GetAll())

    return true
end

function DarkRP.Orgs.UpdateColor(updater, new_color)
    local org_name = updater:GetOrg()
    if not org_name then return false, "Вы не состоите в организации." end

    local org_data = DarkRP.Orgs[org_name]
    if not org_data.Members[updater:SteamID()] or not org_data.Members[updater:SteamID()].Perms.ChangeColor then return false, "Нет прав." end

    org_data.Color = new_color

    for sid, data in pairs(org_data.Members) do
        local pl = DarkRP.FindPlayer(sid)
        if pl and pl:GetOrg() == org_name then
            pl:SetNetVar('OrgColor', new_color)
        end
    end

    net.Start("SendUpdatedColor")
        net.WriteString(org_name)
        net.WriteColor(new_color)
    net.Send(player.GetAll())

    return true
end