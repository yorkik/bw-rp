local colbg = Color(0, 0, 0, 250)
local colplrbg = Color(64, 64, 64, 160)

SCOREBOARD_MENU_OPTIONS = {
    {
        text = function(pl)
            return "SteamID: " .. pl:SteamID()
        end,
        callback = function(pl)
            SetClipboardText(pl:SteamID())
            notification.AddLegacy("SteamID скопирован!", "ok")
        end,
        icon = "icon16/user.png"
    },
    {
        text = function(pl)
            return "Ранг: " .. (pl:GetUserGroup() or "user")
        end,
        callback = function(pl)
            SetClipboardText(pl:GetUserGroup())
            notification.AddLegacy("Ранг скопирован!", "ok")
        end,
        icon = "icon16/award_star_gold_3.png"
    },
    {
        text = function(pl)
            return "Организация: " .. (pl:GetOrg() or "Нет")
        end,
        callback = function(pl)
        end,
        icon = "icon16/group.png"
    },
}

hook.Add('ScoreboardShow', 'rp.ScoreBoard', function()
    blurPanel = vgui.Create('DPanel')
    blurPanel:SetSize(ScrW(), ScrH())
    blurPanel:SetPos(0, 0)
    blurPanel:MakePopup()
    blurPanel:SetAlpha(0)
    blurPanel.Paint = function(self, w, h)
        draw.Blur(self)
        surface.SetDrawColor(colbg)
        surface.DrawRect(0, 0, w, h)
    end

    tab = vgui.Create('DPanel')
    tab:SetSize(weight(600), height(800))
    tab:Center()
    tab:MakePopup()
    tab:SetAlpha(0)
    tab.Paint = function(self, w, h) end

    blurPanel:AlphaTo(255, 0.3, 0, function()
        tab:AlphaTo(255, 0.3, 0)
    end)

    local sp = vgui.Create('DScrollPanel', tab)
    sp:Dock(FILL)

    for _, pl in pairs(player.GetAll()) do
        local plrpnl = vgui.Create('DPanel', sp)
        plrpnl:Dock(TOP)
        plrpnl:SetTall(50)
        plrpnl:SetCursor("hand")
        plrpnl.Paint = function(self, w, h)
            draw.BoxCol(0, 0, w, h, colplrbg)
        end

        plrpnl.OnMousePressed = function(self, code)
            if code == MOUSE_LEFT then
                local menu = DermaMenu()
                for _, opt in ipairs(SCOREBOARD_MENU_OPTIONS) do
                    local item = menu:AddOption(opt.text(pl), function()
                        if IsValid(pl) then opt.callback(pl) end
                    end)
                    if opt.icon then item:SetIcon(opt.icon) end
                end
                menu:Open(gui.MouseX(), gui.MouseY())
            end
        end

        local plravt = vgui.Create("AvatarImage", plrpnl)
        plravt:SetSize(40, 40)
        plravt:SetPos(5, 5)
        plravt:SetPlayer(pl, 64)
        plravt:SetCursor("hand")
        plravt.OnMousePressed = function(self, code)
            if code == MOUSE_LEFT then
                pl:ShowProfile()
            end
        end

        local country = pl:GetNWString("country", "none")
        local flagIcon = vgui.Create('DImage', plrpnl)
        flagIcon:SetPos(plrpnl:GetWide() * .82, plrpnl:GetTall() / 2.9)
        flagIcon:SetSize(16, 16)
        flagIcon:SetImage("flags16/" .. string.lower(country) .. ".png")

        local nick = vgui.Create('DLabel', plrpnl)
        nick:SetPos(plrpnl:GetWide() * 1.2, plrpnl:GetTall() / 3.5)
        nick:SetText(pl:GetPlayerName())
        nick:SetFont('ui.20')
        nick:SizeToContents()

        local timeimg = vgui.Create('DImage', plrpnl)
        timeimg:SetPos(plrpnl:GetWide() * 11.5, plrpnl:GetTall() / 3.5)
        timeimg:SetSize(20, 20)
        timeimg:SetImage("icon16/clock.png")
        timeimg:SetMouseInputEnabled(true)
        timeimg:AddHint(function() return 'Онлайн: ' .. pl:GetPlayTimeFormatted() end)

        local pingimg = vgui.Create('DImage', plrpnl)
        pingimg:SetPos(plrpnl:GetWide() * 12, plrpnl:GetTall() / 3.5)
        pingimg:SetSize(20, 20)
        pingimg:SetImage("icon16/cog.png")
        pingimg:SetMouseInputEnabled(true)
        pingimg:AddHint(function() return 'Пинг: ' .. pl:Ping() end)
    end

    return false
end)

hook.Add('ScoreboardHide', 'rp.ScoreBoard', function()
    if IsValid(tab) then
        tab:AlphaTo(0, 0.3, 0, function()
            if IsValid(tab) then
                tab:Remove()
            end
        end)
    end
    
    if IsValid(blurPanel) then
        blurPanel:AlphaTo(0, 0.3, 0, function()
            if IsValid(blurPanel) then
                blurPanel:Remove()
            end
        end)
    end
    
    return false
end)