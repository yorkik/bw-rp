DoorSys = DoorSys or {}

local function sendAction(ent, action)
    net.Start("DoorSys.Action")
        net.WriteEntity(ent)
        net.WriteString(action)
    net.SendToServer()
end

net.Receive("DoorSys.OpenMenu", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    if not ent.IsManagedDoor or not ent:IsManagedDoor() then return end

    local name = ent:GetDoorDisplayName()
    local price = ent:GetDoorPrice()
    local owner = ent:GetDoorOwnerSID64()
    local locked = ent:GetNWBool("DoorSys.Locked", false)

    local fr = vgui.Create("DFrame")
    fr:SetSize(380, 180)
    fr:Center()
    fr:SetTitle("Опции")
    fr:MakePopup()

    if owner == "" then
    /*
        local buy = vgui.Create("DButton", fr)
        buy:SetSize(350, 30)
        buy:Dock(TOP)
        buy:DockMargin(3,3,3,3)
        buy:SetText("Купить")
        buy.DoClick = function()
            sendAction(ent, "buy")
            fr:Close()
        end
    */
    else
        local sid64 = LocalPlayer():SteamID64()
        if owner == sid64 then
            local sell = vgui.Create("DButton", fr)
            sell:SetSize(350, 30)
            sell:Dock(TOP)
            sell:DockMargin(3,3,3,3)
            sell:SetText("Продать")
            sell.DoClick = function()
                sendAction(ent, "sell")
                fr:Close()
            end
        else
            local lbl = vgui.Create("DLabel", fr)
            lbl:SetPos(15, 95)
            lbl:SetSize(350, 60)
            lbl:SetText("Эта дверь принадлежит другому игроку.")
        end
    end
end)