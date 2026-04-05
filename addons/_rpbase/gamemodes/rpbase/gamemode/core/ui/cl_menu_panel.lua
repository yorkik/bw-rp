local PANEL = {}

local red_select = Color(0, 146, 231)

local Selects = {
    {Title = "Продолжить",      Func = function(luaMenu) luaMenu:Close() end},
    {Title = "Одежда",  Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_appearance_menu") end},
    {Title = "Discord",     Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/475EmEdTgH") end},
    {Title = "Настройки",    Func = function(luaMenu) luaMenu:Close() RunConsoleCommand("hg_settings") end},
    {Title = "Главное меню",   Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Отключится", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
}

function PANEL:InitializeMarkup()
    local text = "<font=ZC_MM_Title><colour=0,146,231,255>BRENT</colour>WOOD</font>"

    return markup.Parse(text)
end

local clr_gray     = Color(255, 255, 255, 25)
local clr_verygray = Color(10, 10, 19, 235)

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:ShowCloseButton(false)

    self.Title = self:InitializeMarkup()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.CenterBox = vgui.Create("DPanel", self)
    self.CenterBox.Paint = function() end

    self.TitlePanel = vgui.Create("DPanel", self.CenterBox)
    self.TitlePanel.Paint = function(_, w, h)
        if not self.Title then return end
        self.Title:Draw(w * 0.5, h * 0.5, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 255)
    end

    self.ButtonList = vgui.Create("DPanel", self.CenterBox)
    self.ButtonList.Paint = function() end

    self.Buttons = {}
    for _, v in ipairs(Selects) do
        self:AddSelect(self.ButtonList, v.Title, v)
    end

    self.Authors = vgui.Create("DLabel", self)
    self.Authors:Dock(BOTTOM)
    self.Authors:SetFont("ui.20")
    self.Authors:SetTextColor(clr_gray)
    self.Authors:SetText("Authors: uzelezz, Sadsalat, Mr.Point, Zac90, Deka, Mannytko")
    self.Authors:SetContentAlignment(5)
    self.Authors:DockMargin(0, 0, 0, 0)

    self:InvalidateLayout(true)
end

function PANEL:First()
    self:AlphaTo(255, 0.1, 0, nil)
end

local gradient_l = surface.GetTextureID("vgui/gradient-l")

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
    hg.DrawBlur(self, 5)

    surface.SetDrawColor(self.ColorBG)
    surface.SetTexture(gradient_l)
    surface.DrawTexturedRect(0, 0, w, h)
end

function PANEL:PerformLayout(w, h)
    w, h = w or ScrW(), h or ScrH()

    local btnH = math.max(ScreenScaleH(24), 28)
    local spacing = ScreenScaleH(6)

    local titleH = ScreenScaleH(80)
    local listPadding = ScreenScaleH(10)

    local count = #(self.Buttons or {})
    local listH = (count * btnH) + (math.max(0, count - 1) * spacing) + (listPadding * 2)

    local boxW = math.min(w * 0.38, ScreenScale(320))
    local boxH = titleH + listH

    boxH = math.min(boxH, h * 0.8)

    if IsValid(self.CenterBox) then
        self.CenterBox:SetSize(boxW, boxH)
        self.CenterBox:Center()

        self.TitlePanel:SetTall(titleH)
        self.TitlePanel:Dock(TOP)

        self.ButtonList:Dock(FILL)
        self.ButtonList:DockMargin(0, 0, 0, 0)
        self.ButtonList:InvalidateLayout(true)
    end
end

function PANEL:AddSelect(pParent, strTitle, tbl)
    local id = #self.Buttons + 1

    local btn = vgui.Create("DButton", pParent)
    self.Buttons[id] = btn

    btn:SetText(strTitle)
    btn:SetFont("ZCity_Small")
    btn:SetTall(math.max(ScreenScaleH(24), 28))
    btn:SetTextColor(Color(225, 225, 225))
    btn:SetContentAlignment(5)
    btn:Dock(TOP)
    btn:DockMargin(0, (id == 1) and ScreenScaleH(10) or ScreenScaleH(6), 0, 0)

    btn:DockPadding(0, 0, 0, 0)

    local luaMenu = self

    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end

    function btn:DoClick()
        if btn.Func then btn.Func(luaMenu) surface.PlaySound('garrysmod/ui_click.wav') end
    end

    local normal = Color(225, 225, 225)
    local hover = false
    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        local v = self.HoverLerp
        self:SetTextColor(normal:Lerp(red_select, v))

        if self:IsHovered() then
            if !hover then
                hover = true
                surface.PlaySound('garrysmod/ui_hover.wav')
            end
        else
            hover = false
        end
    end

    btn.Paint = function(selfBtn, w, h) end

    return btn
end

function PANEL:Close()
    self:AlphaTo(0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("MainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
    local run = hook.Run("OnShowZCityPause")
    if run then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("MainMenu")
    MainMenu:MakePopup()
    return false
end)