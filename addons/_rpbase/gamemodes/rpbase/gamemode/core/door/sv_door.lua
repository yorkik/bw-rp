DoorSys = DoorSys or {}

util.AddNetworkString("DoorSys.OpenMenu")
util.AddNetworkString("DoorSys.Action")

local function setDoorLocked(ent, locked)
    if not IsValid(ent) then return end
    if locked then
        ent:Fire("Lock", "", 0)
        ent:Fire("Close", "", 0)
    else
        ent:Fire("Unlock", "", 0)
    end
    ent:SetNWBool("DoorSys.Locked", locked and true or false)
end

local function setOwner(ent, sid64)
    ent:SetNWString("DoorSys.Owner", sid64 or "")
end

hook.Add("InitPostEntity", "DoorSys.InitDoors", function()
    for _, ent in ipairs(ents.GetAll()) do
        if ent.IsManagedDoor and ent:IsManagedDoor() then
            local d = ent:GetDoorCfg()
            if d and d.Locked ~= nil then
                setDoorLocked(ent, d.Locked)
            end
        end
    end
end)

hook.Add("PlayerButtonDown", "DoorSys.PlayerF2", function(ply, button)
    if button ~= KEY_F2 then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    if not IsValid(ent) or not ent:IsManagedDoor() then return end

    local d = ent:GetDoorCfg()
    if not d then return end

    if ent:IsDoorForTeamsOnly() then
        if ent:TeamHasAccess(ply:GetPlayerClass()) then
            return
        end
        return
    end


    if ent:IsManagedDoor() and ply:OwnsAnyHouseDoor() then
        net.Start("DoorSys.OpenMenu")
            net.WriteEntity(ent)
        net.Send(ply)
        return 
    end
end)

net.Receive("DoorSys.Action", function(_, ply)
    local ent = net.ReadEntity()
    local action = net.ReadString()

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ent) or not ent.IsManagedDoor or not ent:IsManagedDoor() then return end

    local d = ent:GetDoorCfg()
    if not d then return end

    if ent:IsDoorForTeamsOnly() then return end

    local price = ent:GetDoorPrice()
    local owner = ent:GetDoorOwnerSID64()
    local sid64 = ply:SteamID64()

    if action == "buy" then
        if owner ~= "" then return end
        if price <= 0 then return end
        if not ply:CanAfford(price) then return end
        if ply:OwnsAnyHouseDoor() then notif('У вас уже есть купленный дом!', 'fail') return end

        local doorCfg = ent:GetDoorCfg()
        
        local doorsToBuy = {}
        for _, e in ipairs(ents.GetAll()) do
            if e:IsManagedDoor() then
                local cfg = e:GetDoorCfg()
                if cfg and cfg.Name == doorCfg.Name and not e:HasDoorOwner() then
                    table.insert(doorsToBuy, e)
                end
            end
        end
        
        if #doorsToBuy == 0 then return end
        
        for _, door in ipairs(doorsToBuy) do
            setOwner(door, sid64)
            setDoorLocked(door, false)
        end

        ply:SubtractMoney(price)

        for _, wep in ipairs(cfg.dootitems) do
            ply:Give(wep)
        end

        notif(ply, "Вы купили " .. ent:GetDoorDisplayName() .. " за " .. FormatMoney(price) .. ".")
        hook.Run("playerBoughtDoor", ply, ent, price)
        return
    end

    if action == "sell" then
        if owner == "" then return end
        if owner ~= sid64 then return end

        local doorCfg = ent:GetDoorCfg()
        
        local doorsToSell = {}
        for _, e in ipairs(ents.GetAll()) do
            if e:IsManagedDoor() and e:GetDoorOwnerSID64() == sid64 then
                local cfg = e:GetDoorCfg()
                if cfg and cfg.Name == doorCfg.Name then
                    table.insert(doorsToSell, e)
                end
            end
        end

        for _, door in ipairs(doorsToSell) do
            setOwner(door, "")
            local d = door:GetDoorCfg()
            if d and d.Locked ~= nil then
                setDoorLocked(door, d.Locked)
            end
        end

        local refund = math.floor((ent:GetDoorPrice() > 0 and ent:GetDoorPrice() or cfg.defaultprice) * 0.5)

        ply:AddMoney(refund)

        for _, wep in ipairs(cfg.dootitems) do
            ply:StripWeapon(wep)
        end

        notif(ply, "Вы продали " .. ent:GetDoorDisplayName() .. " за " .. FormatMoney(refund) .. ".")
        hook.Run("playerSellDoor", ply, ent)
        return
    end
end)