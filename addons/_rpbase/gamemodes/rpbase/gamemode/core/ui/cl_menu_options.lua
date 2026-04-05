local PANEL = {}

hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}
function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false }
end

hg.settings:AddOpt("Optimization","hg_potatopc", "Potato PC Mode")
hg.settings:AddOpt("Optimization","hg_anims_draw_distance", "Animations draw distance")
hg.settings:AddOpt("Optimization","hg_anim_fps", "Animations FPS")
hg.settings:AddOpt("Optimization","hg_attachment_draw_distance", "Attachment draw distance")
hg.settings:AddOpt("Optimization","hg_maxsmoketrails", "Maximum smoke trails")
hg.settings:AddOpt("Optimization","hg_tpik_distance", "TPIK Render distance")

hg.settings:AddOpt("Blood","hg_blood_draw_distance", "Blood Draw Distance")
hg.settings:AddOpt("Blood","hg_blood_fps", "Blood FPS")
hg.settings:AddOpt("Blood","hg_blood_sprites", "Blood Sprites (DISABLED FOR EVERYONE)")
hg.settings:AddOpt("Blood","hg_old_blood", "Old blood")

hg.settings:AddOpt("Weapons","hg_weaponshotblur_enable", "Shooting Blur")
hg.settings:AddOpt("Weapons","hg_dynamic_mags", "Dynamic Ammo Inspect")
hg.settings:AddOpt("Weapons","hg_zoomsensitivity", "Scope sensitivity")
hg.settings:AddOpt("Weapons","hg_aiminganim","Aiming anim")

hg.settings:AddOpt("UI","zw_font", "Change custom font", false, true)

hg.settings:AddOpt("View","hg_firstperson_death", "First-Person Death")
hg.settings:AddOpt("View","hg_fov", "Field Of View")
hg.settings:AddOpt("View","hg_newspectate", "Smooth Spectator Camera")
hg.settings:AddOpt("View","hg_cshs_fake", "C'sHS Ragdoll Camera")
hg.settings:AddOpt("View","hg_nofovzoom", "Disable/Enable FOV Zoom")
hg.settings:AddOpt("View","hg_realismcam", "Realism camera (shitty)")
hg.settings:AddOpt("View","hg_newfakecam", "New fake camera")
hg.settings:AddOpt("View","hg_leancam_mul", "Lean camera mul")

hg.settings:AddOpt("Sound","hg_dmusic", "Dynamic Music")

function PANEL:Init()
    self:SetAlpha( 0 )
    self:SetSize( ScrW()*1, ScrH()*1 )
    self:SetY( ScrH() )
    self:SetX( ScrW() / 2 - self:GetWide() / 2 )
    self:SetTitle( "" )
    self:SetBorder( false )
    self:SetColorBG( Color(10,10,25,245) )
    self:SetBlurStrengh( 2 )
    self:SetDraggable( false )
    self:ShowCloseButton( true )
    self.Options = {}

    timer.Simple(0,function()
        self:First()
    end)

    self.fDock = vgui.Create("DScrollPanel",self)
    local fDock = self.fDock
    fDock:Dock( FILL )

    self:CreateCategory( "Settings" )
    
    for k,t in SortedPairs(hg.settings.tbl) do
        for _,tbl in SortedPairs(t) do
            local convar = GetConVar(tbl[2])
            if convar then
                self:CreateOption(tbl[1],convar:GetMax() == 1,convar, tbl[4], tbl[3] or convar:GetName(), nil, tbl[5])
            end
        end
    end
end

function PANEL:First( ply )
    self:MoveTo(self:GetX(), ScrH() / 2 - self:GetTall() / 2, 0.4, 0, 0.2, function() end)
    self:AlphaTo( 255, 0.2, 0.1, nil )
end

function PANEL:CreateCategory( strCategory )
    local fDock = self.fDock
    if not self.Options[strCategory] then
        local category = vgui.Create("DLabel",fDock)
        category:Dock( TOP )
        category:SetSize(0,ScreenScale(20))
        category:SetText(strCategory)
        category:SetFont("ZCity_Small")
        category:DockMargin(15,2,15,5)
    end
    self.Options[strCategory] = self.Options[strCategory] or {}
    return self.Options[strCategory]
end

local color_blacky = Color(39,39,39,220)
local color_reddy = hg.VGUI.MainColor
local color_red = Color(255,0,0)

function PANEL:CreateOption( strCategory, bType, cConVar, bDecimals, strTitle, strDesc, bString )
    local fDock = self.fDock
    local Category = self:CreateCategory( strCategory )
    Category[cConVar:GetName()] = vgui.Create("DPanel",fDock)
    local opt = Category[cConVar:GetName()]
    opt:Dock( TOP )
    opt:SetSize(0,ScreenScale(25))
    opt:DockMargin(10,2,10,2)
    function opt:Paint(w,h)
        draw.Box( 0, 0, w, h, color_blacky )
        --hg.DrawBlur(self, 0.1)
    end

    opt.NLabel = vgui.Create("DLabel",opt)
    local NLbl = opt.NLabel
    NLbl:SetText( strTitle.."\n"..(strDesc or string.NiceName( cConVar:GetHelpText() ) ) )
    NLbl:SetFont("ZCity_Tiny")
    NLbl:SizeToContents()
    NLbl:Dock(LEFT)
    NLbl:DockMargin(10,0,0,0)

    if bString then
        opt.TextInput = vgui.Create("DTextEntry",opt)
        local TextInput = opt.TextInput
        TextInput:DockMargin( 10,ScreenScale(5),10,ScreenScale(5) )
        TextInput:DockPadding(ScreenScale(5),ScreenScale(5),ScreenScale(5),ScreenScale(5))
        TextInput:SetSize( ScreenScale(90),0 )
        TextInput:Dock( RIGHT )

        TextInput:SetValue(cConVar:GetString())
        TextInput:SetPlaceholderText("")
        TextInput:SetFont("ZCity_Tiny")
        function TextInput:OnLoseFocus()
            cConVar:SetString(self:GetValue())
        end
    elseif bType then
        opt.Button = vgui.Create("DButton",opt)
        local btn = opt.Button
        btn:SetText( "" )
        btn:DockMargin( 10,ScreenScale(5),10,ScreenScale(5) )
        btn:SetSize( ScreenScale(40),0 )
        btn:Dock( RIGHT )

        btn.On = cConVar:GetBool()

        function btn:Paint(w, h)
            self.Lerp = LerpFT(0.2, self.Lerp or (btn.On and 1 or 0), btn.On and 1 or 0)
            
            local baseClr = Color(45, 45, 45):Lerp(Color(65, 65, 65), self.Lerp * 0.3)
            draw.RoundedBox(4, 0, 0, w, h, baseClr)
            
            draw.RoundedBox(2, 2, 2, w-4, h-4, ColorAlpha(Color(30, 30, 30), 180))

            local stateWidth = (w * 0.8) * (self.Lerp * 0.8 + 0.2)
            local stateX = (w - stateWidth) * 0.5
            local stateClr = Color(200, 50, 50):Lerp(Color(50, 200, 50), self.Lerp)
            
            draw.RoundedBox(3, stateX, h * 0.2, stateWidth, h * 0.6, stateClr)

            if self.Hovered then
                surface.SetDrawColor(stateClr.r, stateClr.g, stateClr.b, 100)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
                
                local glowSize = math.min(w, h) * 0.1 * self.Lerp
                draw.RoundedBox(0, -glowSize, -glowSize, w + glowSize*2, h + glowSize*2, ColorAlpha(stateClr, 30))
            else
                surface.SetDrawColor(20, 20, 20, 220)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
        end
        
        function btn:DoClick()
            cConVar:SetBool(not cConVar:GetBool())
            btn.On = cConVar:GetBool()
        end
    else
        local Slid = vgui.Create( "DNumSlider", opt )
        Slid:DockMargin( 10,15,10,15 )
        Slid:SetSize( 500, 0 )
        Slid:Dock( RIGHT )
        Slid:SetMin( cConVar:GetMin() )
        Slid:SetMax( cConVar:GetMax() )
        Slid:SetDecimals( bDecimals and 2 or 0)
        Slid:SetConVar( cConVar:GetName() )
        Slid.TextArea:SetFont("ZCity_Tiny")
    end
end

vgui.Register( "ZOptions", PANEL, "ZFrame")
 
concommand.Add("hg_settings",function()
    if hg_options and IsValid(hg_options) then
        hg_options:Close()
        hg_options = nil
    end
    local s = vgui.Create("ZOptions") 
    s:MakePopup()
    hg_options = s
end)