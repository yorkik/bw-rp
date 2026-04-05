if not sql.TableExists("rp_orgs") then
    sql.Query([[
        CREATE TABLE IF NOT EXISTS rp_orgs (
            name VARCHAR(64) PRIMARY KEY,
            owner_steamid VARCHAR(32) NOT NULL,
            color_r TINYINT NOT NULL DEFAULT 128,
            color_g TINYINT NOT NULL DEFAULT 128,
            color_b TINYINT NOT NULL DEFAULT 128,
            motd TEXT NOT NULL DEFAULT '',
            created INT NOT NULL,
            members TEXT NOT NULL,
            ranks TEXT NOT NULL
        )
    ]])
end

function SaveOrg(org_name)
    local org = DarkRP.Orgs[org_name]
    if not org then return end

    local members_json = util.TableToJSON(org.Members)
    local ranks_json = util.TableToJSON(org.Ranks)

    sql.Query("REPLACE INTO rp_orgs (name, owner_steamid, color_r, color_g, color_b, motd, created, members, ranks) VALUES (" ..
        sql.SQLStr(org.Name) .. ", " ..
        sql.SQLStr(org.Owner) .. ", " ..
        org.Color.r .. ", " ..
        org.Color.g .. ", " ..
        org.Color.b .. ", " ..
        sql.SQLStr(org.MoTD or "") .. ", " ..
        (org.Created or os.time()) .. ", " ..
        sql.SQLStr(members_json) .. ", " ..
        sql.SQLStr(ranks_json) ..
    ")")
end

function LoadAllOrgs()
    local data = sql.Query("SELECT * FROM rp_orgs")
    if not data or #data == 0 then return end

    for _, row in ipairs(data) do
        local members = util.JSONToTable(row.members) or {}
        local ranks = util.JSONToTable(row.ranks) or {}

        local color = Color(
            math.Clamp(tonumber(row.color_r) or 128, 0, 255),
            math.Clamp(tonumber(row.color_g) or 128, 0, 255),
            math.Clamp(tonumber(row.color_b) or 128, 0, 255)
        )

        DarkRP.Orgs[row.name] = {
            Name = row.name,
            Owner = row.owner_steamid,
            Color = color,
            MoTD = row.motd,
            Created = tonumber(row.created) or os.time(),
            Members = members,
            Ranks = ranks
        }
    end
end

hook.Add("Initialize", "LoadOrganizations", LoadAllOrgs)

util.AddNetworkString("RequestCreateOrg")
util.AddNetworkString("ConfirmCreateOrg")
util.AddNetworkString("RequestOrgMembers")
util.AddNetworkString("SendOrgMembers")
util.AddNetworkString("InviteToOrg")
util.AddNetworkString("KickFromOrg")
util.AddNetworkString("RequestOrgRanks")
util.AddNetworkString("SendOrgRanks")
util.AddNetworkString("SetPlayerRank")
util.AddNetworkString("AddOrgRank")
util.AddNetworkString("RemoveOrgRank")
util.AddNetworkString("UpdateOrgMotD")
util.AddNetworkString("SendUpdatedMotD")
util.AddNetworkString("UpdateOrgColor")
util.AddNetworkString("SendUpdatedColor")
util.AddNetworkString("DisbandOrg")

net.Receive("RequestCreateOrg", function(len, pl)
    local org_name = net.ReadString()
    local can_afford = pl:GetMoney() >= cfg.orgcost

    net.Start("RequestCreateOrg")
        net.WriteString(org_name)
        net.WriteBool(can_afford)
        net.WriteInt(pl:GetMoney(), 32)
    net.Send(pl)
end)

net.Receive("ConfirmCreateOrg", function(len, pl)
    local org_name = net.ReadString()

    if pl:GetOrg() then
        pl:ChatPrint("Вы уже состоите в организации!")
        return
    end

    if not pl:CanAfford(cfg.orgcost) then return end

    pl:SubtractMoney(cfg.orgcost)

    local success, err = DarkRP.Orgs.Create(org_name, pl:SteamID(), Color(128, 128, 128))
    if not success then
        pl:AddMoney(cfg.orgcost)
        pl:ChatPrint(err)
    else
        pl:SetNetVar('Org', org_name)
        pl:SetNetVar('OrgData', DarkRP.Orgs[org_name].Members[pl:SteamID()])
        pl:SetNetVar('OrgColor', DarkRP.Orgs[org_name].Color)
        pl:ChatPrint("Организация '" .. org_name .. "' успешно создана за " .. FormatMoney(cfg.orgcost) .. "!")
        SaveOrg(org_name)
    end
end)

net.Receive("RequestOrgMembers", function(len, pl)
    local org_name = pl:GetOrg()
    if not org_name then return end
    local org_data = DarkRP.Orgs[org_name]

    net.Start("SendOrgMembers")
        local count = 0
        for _ in pairs(org_data.Members) do count = count + 1 end
        net.WriteUInt(count, 8)
        for sid, data in pairs(org_data.Members) do
            local p = DarkRP.FindPlayer(sid)
            net.WriteString(p and p:Name() or "Offline Player")
            net.WriteString(data.Rank)
        end
    net.Send(pl)
end)

net.Receive("InviteToOrg", function(len, pl)
    local target_steamid = net.ReadString()
    local success, err = DarkRP.Orgs.Invite(pl, target_steamid)
    if not success then pl:ChatPrint(err) end
end)

net.Receive("KickFromOrg", function(len, pl)
    local target_steamid = net.ReadString()
    local success, err = DarkRP.Orgs.Kick(pl, target_steamid)
    if success then
        SaveOrg(pl:GetOrg())
    end
    if not success then pl:ChatPrint(err) end
end)

net.Receive("RequestOrgRanks", function(len, pl)
    local org_name = pl:GetOrg()
    if not org_name then return end
    local org_data = DarkRP.Orgs[org_name]

    net.Start("SendOrgRanks")
        local count = 0
        if org_data.Ranks then
            for _ in pairs(org_data.Ranks) do count = count + 1 end
            net.WriteUInt(count, 4)
            for name, data in pairs(org_data.Ranks) do
                net.WriteString(name)
                net.WriteUInt(data.Weight, 7)
            end
        else
            net.WriteUInt(0, 4)
        end
    net.Send(pl)
end)

net.Receive("SetPlayerRank", function(len, pl)
    local target_steamid = net.ReadString()
    local rank_name = net.ReadString()
    local success, err = DarkRP.Orgs.SetRank(pl, target_steamid, rank_name)
    if success then
        SaveOrg(pl:GetOrg())
    end
    if not success then pl:ChatPrint(err) end
end)

net.Receive("AddOrgRank", function(len, pl)
    local rank_name = net.ReadString()
    local weight = net.ReadUInt(7)
    local perms = {
        Weight = weight,
        Owner = net.ReadBool(),
        Invite = net.ReadBool(),
        Kick = net.ReadBool(),
        Rank = net.ReadBool(),
        MoTD = net.ReadBool(),
        ChangeColor = net.ReadBool()
    }

    local success, err = DarkRP.Orgs.AddRank(pl, rank_name, weight, perms)
    if not success then
        pl:ChatPrint(err)
    else
        pl:ChatPrint("Роль '" .. rank_name .. "' успешно добавлена.")
        SaveOrg(pl:GetOrg())
    end
end)

net.Receive("RemoveOrgRank", function(len, pl)
    local rank_name = net.ReadString()
    local success, err = DarkRP.Orgs.RemoveRank(pl, rank_name)
    if success then
        SaveOrg(pl:GetOrg())
    end
    if not success then pl:ChatPrint(err) end
end)

net.Receive("UpdateOrgMotD", function(len, pl)
    local new_motd = net.ReadString()
    local success, err = DarkRP.Orgs.UpdateMotD(pl, new_motd)
    if success then
        SaveOrg(pl:GetOrg())
    end
    if not success then pl:ChatPrint(err) end
end)

net.Receive("UpdateOrgColor", function(len, pl)
    local r = net.ReadUInt(8)
    local g = net.ReadUInt(8)
    local b = net.ReadUInt(8)
    local new_color = Color(r, g, b)
    local success, err = DarkRP.Orgs.UpdateColor(pl, new_color)
    if success then
        SaveOrg(pl:GetOrg())
    end
    if not success then pl:ChatPrint(err) end
end)

net.Receive("DisbandOrg", function(len, pl)
    local org_name = pl:GetOrg()
    if not org_name then
        pl:ChatPrint("Вы не состоите в организации.")
        return
    end

    local success, err = DarkRP.Orgs.Disband(pl)
    if not success then
        pl:ChatPrint(err)
    else
        pl:ChatPrint("Вы распустили свою организацию.")
        sql.Query("DELETE FROM rp_orgs WHERE name = " .. sql.SQLStr(org_name))
    end
end)

rp.AddChatCommand("joinorg", function(pl, orgName, team)
    if pl:GetOrg() then
        pl:ChatPrint("Вы уже состоите в организации!")
        return
    end

    orgName = string.Trim(orgName)
    if orgName == "" then
        pl:ChatPrint("Использование: /joinorg Название")
        return
    end

    local success, err = DarkRP.Orgs.Join(pl, orgName)
    if not success then
        pl:ChatPrint(err or "Не удалось присоединиться к организации.")
    else
        pl:ChatPrint("Вы присоединились к организации '" .. orgName .. "'.")
        SaveOrg(orgName)
    end
end)

rp.AddChatCommand("leaveorg", function(pl, args, team)
    local org_name = pl:GetOrg()
    if not org_name then
        pl:ChatPrint("Вы не состоите ни в одной организации!")
        return
    end

    local success, err = DarkRP.Orgs.Leave(pl)
    if not success then
        pl:ChatPrint(err or "Не удалось покинуть организацию.")
    else
        pl:ChatPrint("Вы покинули организацию.")
        SaveOrg(org_name)
    end
end)

rp.AddChatCommand("acceptorg", function(pl, args, team)
    if pl.org_invite_pending then
        local orgName = pl.org_invite_pending
        pl.org_invite_pending = nil
        local success, err = DarkRP.Orgs.Join(pl, orgName)
        if not success then
            pl:ChatPrint(err or "Не удалось принять приглашение.")
        else
            pl:ChatPrint("Вы присоединились к организации '" .. orgName .. "'.")
            SaveOrg(orgName)
        end
    else
        pl:ChatPrint("У вас нет активных приглашений.")
    end
end)