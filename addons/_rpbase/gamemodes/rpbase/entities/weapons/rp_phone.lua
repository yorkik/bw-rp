if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_tpik1_base"
SWEP.PrintName = "Телефон"
SWEP.Instructions = ""
SWEP.Category = "RP"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 0

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.WorldModel = "models/ivancorn/gtaiv/electrical/phones/cellphone_badger_crappy.mdl"
SWEP.ViewModel = ""
SWEP.HoldType = "normal"

SWEP.setrhik = true
SWEP.setlhik = false

SWEP.LHPos = Vector(0,0,0)
SWEP.LHAng = Angle(0,0,0)

SWEP.RHPosOffset = Vector(1,-1,-4)
SWEP.RHAngOffset = Angle(0,45,-90)

SWEP.LHPosOffset = Vector(0,0,0)
SWEP.LHAngOffset = Angle(0,0,0)

SWEP.handPos = Vector(0,0,0)
SWEP.handAng = Angle(0,0,0)

SWEP.UsePistolHold = false

SWEP.offsetVec = Vector(5,-2,-2)
SWEP.offsetAng = Angle(0,90,120)   

SWEP.HeadPosOffset = Vector(12,3,-5)
SWEP.HeadAngOffset = Angle(-90,0,-90)

SWEP.BaseBone = "ValveBiped.Bip01_Head1"

SWEP.HoldLH = "normal"
SWEP.HoldRH = "normal"

SWEP.HoldClampMax = 35
SWEP.HoldClampMin = 35

SWEP.Skin = 2

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

if SERVER then return end

hook.Add("GUIMousePressed", "HideCursorOnRightClick", function(mouseCode)
    if mouseCode == MOUSE_RIGHT then
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == "rp_phone" then
                if IsValid(wep.menu) then
                    wep.menu:Close()
                    gui.EnableScreenClicker(false)
                    wep.MouseHasControl = false
                    wep.menu:SetMouseInputEnabled(false)
                end
            end
        end
    end
end)

local numbat = math.random(20, 100)

local color_black = Color(0,0,0)
local col_bg = Color(0,75,0)
local col_pnl = Color(0,75,0, 50)
local col_btn = Color(0,100,0)
local col_btnout = Color(0,160,0)

function SWEP:CreateMenu()
    if IsValid(self.menu) then self.menu:Remove() end
    
    local baseW, baseH = 1920, 1080
    local baseMenuW, baseMenuH = 110, 103
    local currentW, currentH = ScrW(), ScrH()
    local scaleX = currentW / baseW
    local scaleY = currentH / baseH
    local scale = math.min(scaleX, scaleY)
    local menuW = math.floor(baseMenuW * scale)
    local menuH = math.floor(baseMenuH * scale)
    
    self.menu = vgui.Create( "DFrame" )
    self.menu:SetSize( menuW, menuH )
    self.menu:Center()
    self.menu:SetY(ScrH() - math.floor(462 * scale))
    self.menu:SetTitle("")
    self.menu:ShowCloseButton(false)
    self.menu:SetDraggable(false)
    local tablet = self
    self.menu.Paint = function(s, w, h)
        local time = os.date("%H:%M") 
        draw.RoundedBox(4, 0, 0, w, h, col_bg)
        draw.SimpleText(time, 'ui.12', 3, 0, color_black)
    end
    function self.menu:Think()
        local wep = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon() or false
        if not wep or wep:GetClass() ~= "rp_phone" then
            if tablet.MouseHasControl then
                gui.EnableScreenClicker(false)
                tablet.MouseHasControl = false
            end
        end
        if not IsValid(tablet) then
            gui.EnableScreenClicker(false)
            self:Remove()
        end
    end

    local wifi = vgui.Create('DLabel', self.menu)
    wifi:SetPos(self.menu:GetWide() / 1.43, -4)
    wifi:SetFont('SVG_25_3D')
    wifi:SetText('s')
    wifi:SetTextColor(color_black)

    local batary = vgui.Create('DLabel', self.menu)
    batary:SetPos(self.menu:GetWide() / 1.23, -2)
    batary:SetFont('ui.12')
    batary:SetText('99' .. '%')
    batary:SetTextColor(color_black)

    self.panel = vgui.Create('DScrollPanel', self.menu)
    self.panel:Dock(FILL)
    self.panel:DockMargin(0, -14, 0, 0)
    self.panel.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, color_black)
        draw.RoundedBox(0, 0, 0, w, h, col_pnl)
    end

    self.call = vgui.Create('DButton', self.panel)
    self.call:Dock(TOP)
    self.call:DockMargin(3,3,3,3)
    self.call:SetText('Контакты')

    self.call.Paint = function(s, w, h)
        if s.Hovered then
            col_btn = Color(0,75,0)
        else
            col_btn = Color(0,100,0)
        end

        surface.SetDrawColor(col_btn)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_btnout)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    self.call.DoClick = function()
        surface.PlaySound('garrysmod/ui_click.wav')
        self:callmenu()
        self.call:Remove()
    end

    self.news = vgui.Create('DButton', self.panel)
    self.news:Dock(TOP)
    self.news:DockMargin(3,3,3,3)
    self.news:SetText('Новости')

    self.news.Paint = function(s, w, h)
        if s.Hovered then
            col_btn = Color(0,75,0)
        else
            col_btn = Color(0,100,0)
        end

        surface.SetDrawColor(col_btn)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_btnout)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    self.news.DoClick = function()
        surface.PlaySound('garrysmod/ui_click.wav')
        self:opennews()
    end

    self.house = vgui.Create('DButton', self.panel)
    self.house:Dock(TOP)
    self.house:DockMargin(3,3,3,3)
    self.house:SetText('Недвижимость')

    self.house.Paint = function(s, w, h)
        if s.Hovered then
            col_btn = Color(0,75,0)
        else
            col_btn = Color(0,100,0)
        end

        surface.SetDrawColor(col_btn)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_btnout)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    self.house.DoClick = function()
        surface.PlaySound('garrysmod/ui_click.wav')
        self:openhouse()
    end
end

function SWEP:opennews()
    local panelnews = vgui.Create('DScrollPanel', self.menu)
    panelnews:Dock(FILL)
    panelnews:DockMargin(0, -14, 0, 0)
    panelnews.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, color_black)
        draw.RoundedBox(0, 0, 0, w, h, col_pnl)
    end
end

function SWEP:openhouse()
    local panelhouse = vgui.Create('DScrollPanel', self.menu)
    panelhouse:Dock(FILL)
    panelhouse:DockMargin(0, -14, 0, 0)
    panelhouse.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, color_black)
        draw.RoundedBox(0, 0, 0, w, h, col_pnl)
    end

    for _, dom in ipairs(cfg.doors) do
        if dom.Teams and #dom.Teams > 0 then continue end
        
        local ply = LocalPlayer()
        
        local house = vgui.Create('DButton', panelhouse)
        house:Dock(TOP)
        house:DockMargin(3, 3, 3, 3)
        house:SetText(dom.Name .. ' - ' .. (dom.Price or cfg.defaultprice) .. ' $')

        house.Paint = function(s, w, h)
            local col_btn
            if s.Hovered then
                col_btn = Color(0, 75, 0)
            else
                col_btn = Color(0, 100, 0)
            end

            surface.SetDrawColor(col_btn)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(col_btnout)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        house.DoClick = function()
            surface.PlaySound('garrysmod/ui_click.wav')
            
            local targetDoor = nil
            for _, ent in ipairs(ents.GetAll()) do
                if ent:IsManagedDoor() then
                    local cfg = ent:GetDoorCfg()
                    if cfg and cfg.Name == dom.Name then
                        targetDoor = ent
                        break
                    end
                end
            end

            self.menu:Close()
            gui.EnableScreenClicker(false)
            self.MouseHasControl = false
            self.menu:SetMouseInputEnabled(false)
            
            if IsValid(targetDoor) then
                net.Start("DoorSys.Action")
                    net.WriteEntity(targetDoor)
                    net.WriteString("buy")
                net.SendToServer()
            end
        end
    end
end

function SWEP:callmenu()
    local panelcall = vgui.Create('DScrollPanel', self.menu)
    panelcall:Dock(FILL)
    panelcall:DockMargin(0, -14, 0, 0)
    panelcall.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, color_black)
        draw.RoundedBox(0, 0, 0, w, h, col_pnl)
    end

    local call911 = vgui.Create('DButton', panelcall)
    call911:Dock(TOP)
    call911:DockMargin(3,3,3,3)
    call911:SetText('911')

    call911.Paint = function(s, w, h)
        if s.Hovered then
            col_btn = Color(0,75,0)
        else
            col_btn = Color(0,100,0)
        end

        surface.SetDrawColor(col_btn)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_btnout)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    call911.DoClick = function()
        surface.PlaySound('garrysmod/ui_click.wav')
        LocalPlayer():EmitSound('phone/gudok.wav', 60)

        timer.Simple(3, function()
            LocalPlayer():EmitSound('phone/911.wav', 60)
        end)
        timer.Simple(5, function()
            self:open911()
        end)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply == LocalPlayer() then continue end
        local callbtn = vgui.Create('DButton', panelcall)
        callbtn:Dock(TOP)
        callbtn:DockMargin(3,3,3,3)
        callbtn:SetText(ply:GetPlayerName())

        callbtn.Paint = function(s, w, h)
            if s.Hovered then
                col_btn = Color(0,75,0)
            else
                col_btn = Color(0,100,0)
            end

            surface.SetDrawColor(col_btn)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(col_btnout)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        callbtn.DoClick = function()
            surface.PlaySound('garrysmod/ui_click.wav')
            if IsValid(ply) then
                Phone.StartCall(ply)
            end
        end
    end
end

function SWEP:open911()
    local panel911 = vgui.Create('DScrollPanel', self.menu)
    panel911:Dock(FILL)
    panel911:DockMargin(0, -14, 0, 0)
    panel911.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, color_black)
        draw.RoundedBox(0, 0, 0, w, h, col_pnl)
    end

    local callpolice = vgui.Create('DButton', panel911)
    callpolice:Dock(TOP)
    callpolice:DockMargin(3,3,3,3)
    callpolice:SetText('Полиция')

    callpolice.Paint = function(s, w, h)
        if s.Hovered then
            col_btn = Color(0,75,0)
        else
            col_btn = Color(0,100,0)
        end

        surface.SetDrawColor(col_btn)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col_btnout)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    callpolice.DoClick = function()
        surface.PlaySound('garrysmod/ui_click.wav')
        Derma_StringRequest("Вызов полиции", "Сообщение для полиции?", "", function(text)
            net.Start("rp.GovernmentRequare")
                net.WriteString(text)
            net.SendToServer()
        end)
        self.menu:Close()
    end
end



function SWEP:PrimaryAttack()
    if IsValid(self.menu) then
        self.menu:SetMouseInputEnabled( true )
        self.menu:MakePopup()
        self.MouseHasControl = true
        gui.EnableScreenClicker(true)
    end
end

function SWEP:AddDrawModel(ent)
    if not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() then return end
    if not IsValid(self.menu) then self:CreateMenu() end
    if not IsValid(self.menu) then return end

    local pos, ang = ent:GetRenderOrigin(), ent:GetRenderAngles()
    local basePos = pos + ang:Up() * 11.3 + ang:Forward() * -14.5 + ang:Right() * .55
    local baseH = 1080
    local currentH = ScrH()
    local baseScale = 0.0151
    local scale3d = baseScale * (baseH / currentH)
    local menuW, menuH = self.menu:GetSize()
    local menuHeight = menuH
    local heightDiff = menuHeight * (baseScale - scale3d)
    local posOffset = heightDiff / 12
    pos = basePos + ang:Up() * posOffset
    ang = Angle(ang.p - 0, ang.y + 0, ang.r + 90)
    
    vgui.Start3D2D(pos, ang, scale3d)
        self.menu:Paint3D2D()
    vgui.End3D2D()
end