reports = reports or {}
reports.UI = reports.UI or {}

surface.CreateFont("reports.ui.title", {
    font = "Roboto",
    size = 28,
    weight = 700,
    extended = true
})

surface.CreateFont("reports.ui.title.small", {
    font = "Roboto",
    size = 22,
    weight = 700,
    extended = true
})

surface.CreateFont("reports.ui.head", {
    font = "Roboto",
    size = 20,
    weight = 600,
    extended = true
})

surface.CreateFont("reports.ui.text", {
    font = "Roboto",
    size = 18,
    weight = 500,
    extended = true
})

surface.CreateFont("reports.ui.text.small", {
    font = "Roboto",
    size = 16,
    weight = 500,
    extended = true
})

surface.CreateFont("reports.ui.text.tiny", {
    font = "Roboto",
    size = 14,
    weight = 400,
    extended = true
})

surface.CreateFont("reports.ui.text.mini", {
    font = "Roboto",
    size = 13,
    weight = 400,
    extended = true
})

reports.UI.Col = {
    bg              = Color(8, 11, 16, 235),
    bg2             = Color(12, 16, 22, 235),
    bg3             = Color(16, 21, 29, 235),
    bg4             = Color(44, 56, 78, 235),

    header          = Color(10, 14, 20, 220),
    sidebar         = Color(9, 13, 18, 220),
    card            = Color(13, 18, 25, 220),
    entry           = Color(10, 14, 19, 220),

    text            = Color(235, 240, 250),
    text2           = Color(180, 192, 214),
    text3           = Color(120, 132, 154),

    stroke          = Color(90, 110, 140, 95),
    strokeSoft      = Color(120, 150, 190, 28),

    accent          = Color(0, 170, 255),
    accent2         = Color(70, 200, 255),
    accent3         = Color(0, 121, 182),
    green           = Color(80, 210, 130),
    red             = Color(225, 85, 85),
    red2            = Color(225, 0, 0),
    red3            = Color(180, 0, 0),
    orange          = Color(255, 175, 65),
    yellow          = Color(255, 215, 90),
    purple          = Color(180, 120, 255),

    white05         = Color(255, 255, 255, 5),
    white08         = Color(255, 255, 255, 8),
    white12         = Color(255, 255, 255, 12),
    black120        = Color(0, 0, 0, 120),
    black170        = Color(0, 0, 0, 170),

    row             = Color(17, 22, 30, 240),
    rowHover        = Color(35, 46, 63, 220),
    rowSelected     = Color(0, 170, 255, 42)
}

local C = reports.UI.Col

local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local FrameTime = FrameTime
local Lerp = Lerp
local IsValid = IsValid
local ipairs = ipairs
local ScrW = ScrW
local ScrH = ScrH
local CurTime = CurTime
local string_FormattedTime = string.FormattedTime
local math_floor = math.floor

local function Alpha(col, a)
    return Color(col.r, col.g, col.b, a)
end

local function LerpColor(frac, from, to)
    return Color(
        Lerp(frac, from.r, to.r),
        Lerp(frac, from.g, to.g),
        Lerp(frac, from.b, to.b),
        Lerp(frac, from.a or 255, to.a or 255)
    )
end

local function DrawSoftShadow(x, y, w, h, alpha, spread, radius)
    alpha = alpha or 120
    spread = spread or 8
    radius = radius or 14

    for i = 1, spread do
        local a = alpha * (1 - i / spread) * 0.22
        draw_RoundedBox(radius + i, x - i, y - i, w + i * 2, h + i * 2, Color(0, 0, 0, a))
    end
end

local function DrawGlow(x, y, w, h, col, spread, radius)
    spread = spread or 6
    radius = radius or 10

    for i = 1, spread do
        local a = (col.a or 255) * (1 - i / spread) * 0.13
        draw_RoundedBox(radius + i, x - i, y - i, w + i * 2, h + i * 2, Color(col.r, col.g, col.b, a))
    end
end

local function StyleButton(btn, baseCol, hoverCol, textCol, radius)
    btn:SetText("")
    btn:SetCursor("hand")
    btn.HoverLerp = 0
    btn.DownLerp = 0
    btn.Label = btn.Label or ""
    btn.BaseCol = baseCol or C.bg4
    btn.HoverCol = hoverCol or C.accent
    btn.TextCol = textCol or C.text
    btn.Radius = radius or 8

    btn.Paint = function(self, w, h)
        self.HoverLerp = Lerp(FrameTime() * 10, self.HoverLerp, self:IsHovered() and 1 or 0)
        self.DownLerp = Lerp(FrameTime() * 16, self.DownLerp, self:IsDown() and 1 or 0)

        local col = LerpColor(self.HoverLerp, self.BaseCol, self.HoverCol)
        local offset = self.DownLerp * 1

        DrawSoftShadow(0, 0, w, h, 80 + self.HoverLerp * 30, 4, self.Radius)

        if self.HoverLerp > 0.02 then
            DrawGlow(0, 0, w, h, Alpha(self.HoverCol, 35 * self.HoverLerp), 4, self.Radius)
        end

        draw_RoundedBox(self.Radius, 0, offset, w, h - offset, col)
        draw_SimpleText(self.Label, "reports.ui.text.small", w / 2, h / 2 + offset / 2, self.TextCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function StyleScrollBar(bar)
    if not IsValid(bar) then return end

    bar:SetHideButtons(true)

    function bar:Paint(w, h)
        draw_RoundedBox(6, 4, 0, w - 8, h, C.white05)
    end

    function bar.btnGrip:Paint(w, h)
        self.HoverLerp = Lerp(FrameTime() * 10, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
        local col = LerpColor(self.HoverLerp, Color(110, 125, 150, 110), Alpha(C.accent, 180))
        draw_RoundedBox(6, 3, 0, w - 6, h, col)
    end
end

local function CreateWindow(titleText, w, h, posX, posY, closable)
    local fr = vgui.Create("DFrame")
    fr:SetSize(w, h)
    fr:SetTitle("")
    fr:ShowCloseButton(false)
	fr:SetDraggable(true)
    fr:SetAlpha(0)
    fr.StartTime = SysTime()

    if posX and posY then
        fr:SetPos(posX, posY)
    else
        fr:Center()
    end

    fr.OpenFrac = 0
    fr.Closing = false

    if closable then
        fr.CloseBtn = vgui.Create("DButton", fr)
        fr.CloseBtn:SetSize(34, 34)
        fr.CloseBtn:SetText("")
        fr.CloseBtn.HoverLerp = 0
        fr.CloseBtn.DoClick = function()
            fr:Close()
        end
        fr.CloseBtn.Paint = function(self, ww, hh)
            self.HoverLerp = Lerp(FrameTime() * 12, self.HoverLerp, self:IsHovered() and 1 or 0)
            local col = LerpColor(self.HoverLerp, C.red3, C.red2)
            draw_RoundedBox(6, 0, 0, ww, hh, col)
            draw_SimpleText("✕", "reports.ui.text", ww / 2, hh / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        fr.PerformLayout = function(self, ww, hh)
            self.CloseBtn:SetPos(ww - 46, 10)
        end
    end

    fr.Think = function(self)
        local speed = FrameTime() * 10

        if self.Closing then
            self.OpenFrac = Lerp(speed, self.OpenFrac, 0)
            self:SetAlpha(Lerp(speed, self:GetAlpha(), 0))
            if self:GetAlpha() <= 3 then
                self:Remove()
            end
        else
            self.OpenFrac = Lerp(speed, self.OpenFrac, 1)
            self:SetAlpha(Lerp(speed, self:GetAlpha(), 255))
        end
    end

    fr.Paint = function(self, ww, hh)
        local open = self.OpenFrac
        local offsetY = (1 - open) * 20

        draw.Blur(self)
        DrawSoftShadow(0, offsetY, ww, hh - offsetY, 140, 10, 8)
        draw_RoundedBox(8, 0, offsetY, ww, hh - offsetY, C.bg)
        draw.RoundedBoxEx(8, 0, offsetY, ww, 58, C.header, true, true, false, false)
        draw_RoundedBox(0, 0, offsetY + 57, ww, 1, C.stroke)
        DrawGlow(0, offsetY, ww, 58, Alpha(C.accent, 26), 5, 8)
        draw_SimpleText(titleText, "reports.ui.title", 18, offsetY + 27, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    return fr
end

local function CreateCard(parent)
    local pnl = vgui.Create("DPanel", parent)
    pnl.Paint = function(self, w, h)
        draw_RoundedBox(8, 0, 0, w, h, C.card)
        surface_SetDrawColor(C.stroke)
        surface_DrawOutlinedRect(0, 0, w, h, 1)
    end
    return pnl
end

local function CreateRichWrap(parent)
    local wrap = CreateCard(parent)

    local chat = vgui.Create("RichText", wrap)
    chat:Dock(FILL)
    chat:DockMargin(8, 8, 8, 8)
    chat:SetBGColor(C.entry)

    function chat:PerformLayout()
        self:SetFontInternal("reports.ui.text.small")
    end

    return wrap, chat
end

function reports.OpenAdminMenu(data)
    if IsValid(reports.adminPanel) then reports.adminPanel:Remove() end

    local reporter = data.reporter
    if not IsValid(reporter) then return end

    local w = ScrW() * 0.29
    local h = ScrH() * 0.25

    reports.adminPanel = CreateWindow(reporter:GetPlayerName(), w, h, 2, 2, false)

    local body = vgui.Create("DPanel", reports.adminPanel)
    body:SetPos(14, 70)
    body:SetSize(w - 28, h - 84)
    body.Paint = function(self, ww, hh)
        draw_RoundedBox(14, 0, 0, ww, hh, C.bg)
    end

    local footer = vgui.Create("DPanel", body)
    footer:Dock(BOTTOM)
    footer:SetTall(34)
    footer.Paint = nil

    local left = CreateCard(body)
    left:Dock(LEFT)
    left:SetWide(math_floor(body:GetWide() * 0.35))

    local scroll = vgui.Create("DScrollPanel", left)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 8, 8, 8)
    StyleScrollBar(scroll:GetVBar())

    local function addButton(text, callback, hoverCol)
        local btn = vgui.Create("DButton", scroll)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 8)
        btn:SetTall(30)
        btn.Label = text
        StyleButton(btn, C.bg4, hoverCol or C.accent)
        btn.DoClick = callback
    end

    addButton("Скопировать SteamID", function()
        SetClipboardText(reporter:SteamID())
    end, C.green)

    addButton("ТП игрока к себе", function()
        LocalPlayer():ConCommand("sam bring " .. reporter:EntIndex())
    end, C.accent)

    addButton("ТП к игроку", function()
        LocalPlayer():ConCommand("sam goto " .. reporter:EntIndex())
    end, C.orange)

    addButton("Вернуть", function()
        LocalPlayer():ConCommand("sam return " .. reporter:EntIndex())
    end, C.purple)

    local right = vgui.Create("DPanel", body)
    right:Dock(FILL)
    right:DockMargin(12, 0, 0, 0)
    right.Paint = nil

    local msgBtn = vgui.Create("DButton", right)
    msgBtn:Dock(BOTTOM)
    msgBtn:SetTall(32)
    msgBtn:DockMargin(0, 8, 0, 0)
    msgBtn.Label = "Написать сообщение"
    StyleButton(msgBtn, C.bg4, C.accent)

    local chatWrap, chatBox = CreateRichWrap(right)
    chatWrap:Dock(FILL)

    reports.adminPanel.Chat = function(msg)
        local ply, text = msg[1], msg[2]
        if not IsValid(ply) then return end

        local col = ply:GetPlayerColor():ToColor() or Color(255, 255, 255)
        chatBox:InsertColorChange(col.r, col.g, col.b, 255)
        chatBox:AppendText(ply:GetPlayerName())
        chatBox:InsertColorChange(255, 255, 255, 255)
        chatBox:AppendText(": " .. text .. "\n")
    end

    msgBtn.DoClick = function()
        Derma_StringRequest(
            "Сообщение в репорт",
            "Введите сообщение:",
            "",
            function(txt)
                net.Start("reports.message")
                net.WriteString(txt)
                net.SendToServer()
            end
        )
    end

    for _, msg in ipairs(data.report_chat or {}) do
        reports.adminPanel.Chat(msg)
    end

    local closeBtn = vgui.Create("DButton", footer)
    closeBtn:Dock(FILL)
	msgBtn:SetTall(32)
    closeBtn.Label = "Закрыть жалобу"
    StyleButton(closeBtn, C.red3, C.red2)
    closeBtn.DoClick = function()
        net.Start("reports.close")
        net.SendToServer()
    end
end

function reports.CreateMainPanel()
    reports.mainPanel = vgui.Create("DPanel")
    reports.mainPanel:SetSize(ScrW() * 0.15 + 22, ScrH() * 0.3)
    reports.mainPanel:SetPos(ScrW() - reports.mainPanel:GetWide(), ScrH() * 0.5 - reports.mainPanel:GetTall() * 0.5)
    reports.mainPanel.reports = {}
    reports.mainPanel.total = 0
    reports.mainPanel.hidden = false

    reports.mainPanel.Paint = function(s, w, h)
        DrawSoftShadow(0, 0, w, h, 120, 8, 8)
        draw_RoundedBox(8, 0, 0, w, h, C.bg)
        draw.RoundedBoxEx(8, 0, 0, w, 28, C.header, true, true, false, false)
        surface_SetDrawColor(C.stroke)
        surface_DrawRect(0, 27, w, 1)
    end

    local info = vgui.Create("DPanel", reports.mainPanel)
    info:SetSize(reports.mainPanel:GetWide(), 28)
    info.Paint = function(s, w, h)
        draw_SimpleText(reports.mainPanel.hidden and tostring(reports.mainPanel.total) or "Жалоб: " .. reports.mainPanel.total,
            "reports.ui.text.small", reports.mainPanel.hidden and w / 2 or 12, h / 2, C.text, reports.mainPanel.hidden and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local toggle = vgui.Create("DButton", reports.mainPanel)
    toggle:SetPos(3, 30)
    toggle:SetSize(15, reports.mainPanel:GetTall() - 34)
    toggle:SetText("")
    toggle.HoverLerp = 0
    toggle.DoClick = function()
        if reports.mainPanel.hidden then
            reports.mainPanel:MoveTo(ScrW() - reports.mainPanel:GetWide(), ScrH() * 0.5 - reports.mainPanel:GetTall() * 0.5, 0.3)
            reports.mainPanel.hidden = false
        else
            reports.mainPanel:MoveTo(ScrW() - 21, ScrH() * 0.5 - reports.mainPanel:GetTall() * 0.5, 0.3)
            reports.mainPanel.hidden = true
        end
    end
    toggle.Paint = function(s, w, h)
        s.HoverLerp = Lerp(FrameTime() * 10, s.HoverLerp, s:IsHovered() and 1 or 0)
        local col = LerpColor(s.HoverLerp, C.bg4, C.accent)
        draw.RoundedBox(6, 0, 0, w, h, col)
        if s.HoverLerp > 0.02 then
            DrawGlow(0, 0, w, h, Alpha(C.accent, 22 * s.HoverLerp), 3, 6)
        end
        draw_SimpleText(reports.mainPanel.hidden and "<" or ">", "reports.ui.text", w / 2, h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", reports.mainPanel)
    scroll:SetPos(22, 30)
    scroll:SetSize(reports.mainPanel:GetWide() - 22, reports.mainPanel:GetTall() - 30)
    StyleScrollBar(scroll:GetVBar())

    reports.mainPanel.AddReport = function(data)
        reports.mainPanel:Show()

        local btn = vgui.Create("DButton", scroll)
        btn:SetText("")
        btn:Dock(TOP)
        btn:DockMargin(6, 6, 6, 0)
        btn:SetTall(46)
        btn.data = data
        btn.HoverLerp = 0

        reports.mainPanel.reports[data.reporter] = btn

        btn.Paint = function(s, w, h)
            if not IsValid(data.reporter) then
                s:Remove()
                return
            end

            s.HoverLerp = Lerp(FrameTime() * 10, s.HoverLerp, s:IsHovered() and 1 or 0)

            local age = CurTime() - (data.start or 0)
            local border = C.stroke
            if age > 180 then border = C.orange end
            if age > 300 then border = C.red end

            local base = LerpColor(s.HoverLerp, C.row, C.rowHover)
            if s.Depressed or s.m_bSelected then
                base = Alpha(C.bg4, 255)
            end

            DrawSoftShadow(0, 0, w, h, 60, 4, 0)
            draw_RoundedBox(0, 0, 0, w, h, base)
            surface_SetDrawColor(border)
            surface_DrawOutlinedRect(0, 0, w, h, 1)

            local nick = data.reporter:GetPlayerName()
            local timeStr = string_FormattedTime(age, "%02i:%02i")

            draw_SimpleText(nick, "reports.ui.text.small", 48, 12, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw_SimpleText(timeStr, "reports.ui.text.tiny", 48, h - 12, C.text2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            if LocalPlayer():GetNWBool("report_claimed", false) then return end
			if LocalPlayer() == data.reporter then
				notif('Вы не можете принять свою жалабу', 'fail')
				return
			end
            net.Start("reports.accept")
            net.WriteEntity(data.reporter)
            net.SendToServer()
        end

        btn.OnRemove = function()
            reports.mainPanel.reports[data.reporter] = nil
            reports.mainPanel.total = reports.mainPanel.total - 1
            if reports.mainPanel.total <= 0 then
                reports.mainPanel:Hide()
            end
        end

        local avatar = vgui.Create("AvatarImage", btn)
        avatar:SetPos(5, 5)
        avatar:SetSize(36, 36)
        avatar:SetPlayer(data.reporter, 184)

        reports.mainPanel.total = reports.mainPanel.total + 1
    end
end

net.Receive("reports.send", function()
    local data = net.ReadTable()
    local reporter = data.reporter

    if reporter == LocalPlayer() then
        if IsValid(reports.playerPanel) then reports.playerPanel:Remove() end

        local w = ScrW() * 0.25
        local h = ScrH() * 0.12 + 100

        reports.playerPanel = CreateWindow("★ Жалоба", w, h, 2, 2, true)
        reports.playerPanel.data = data

        reports.playerPanel.OnClose = function()
            net.Start("reports.close")
            net.SendToServer()
        end

        local body = vgui.Create("DPanel", reports.playerPanel)
        body:SetPos(14, 70)
        body:SetSize(w - 28, h - 84)
        body.Paint = function(self, ww, hh)
            draw_RoundedBox(14, 0, 0, ww, hh, C.bg)
        end

        local status = CreateCard(body)
        status:Dock(BOTTOM)
        status:SetTall(28)
        status:DockMargin(0, 8, 0, 0)
        status.Paint = function(s, ww, hh)
            draw_RoundedBox(8, 0, 0, ww, hh, C.card)
            surface_SetDrawColor(C.stroke)
            surface_DrawOutlinedRect(0, 0, ww, hh, 1)
            local admin = data.admin
            local txt = admin and admin:GetPlayerName() or "Ожидаем админа..."
            local col = admin and admin:GetPlayerColor():ToColor() or C.text2
            draw_SimpleText(txt, "reports.ui.text.small", ww / 2, hh / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local msgBtn = vgui.Create("DButton", body)
        msgBtn:Dock(BOTTOM)
        msgBtn:SetTall(32)
        msgBtn:DockMargin(0, 8, 0, 0)
        msgBtn.Label = "Написать сообщение"
        StyleButton(msgBtn, C.bg4, C.accent)

        local chatWrap, chat = CreateRichWrap(body)
        chatWrap:Dock(FILL)

        reports.playerPanel.Chat = function(msg)
            local ply, text = msg[1], msg[2]
            if not IsValid(ply) then return end

            local col = ply:GetPlayerColor():ToColor() or Color(255, 255, 255)
            chat:InsertColorChange(col.r, col.g, col.b, 255)
            chat:AppendText(ply:GetPlayerName())
            chat:InsertColorChange(255, 255, 255, 255)
            chat:AppendText(": " .. text .. "\n")
        end

        msgBtn.DoClick = function()
            Derma_StringRequest(
                "Сообщение в репорт",
                "Введите сообщение:",
                "",
                function(txt)
                    net.Start("reports.message")
                    net.WriteString(txt)
                    net.SendToServer()
                end
            )
        end

        for _, msg in ipairs(data.report_chat or {}) do
            reports.playerPanel.Chat(msg)
        end
    end

    if LocalPlayer():IsAdmin() then
        if not IsValid(reporter) then return end
        if not IsValid(reports.mainPanel) then reports.CreateMainPanel() end
        if not reports.mainPanel.hidden then surface.PlaySound("report/reportsound.wav") end
        reports.mainPanel.AddReport(data)
    end
end)

net.Receive("reports.accept", function()
    local reporter = net.ReadEntity()
    local admin = net.ReadEntity()

    if admin == LocalPlayer() then
        reports.OpenAdminMenu(net.ReadTable())
    end

    if IsValid(reports.playerPanel) then
        reports.playerPanel.data.admin = admin
        surface.PlaySound("buttons/blip1.wav")
    end

    if IsValid(reports.mainPanel) and reports.mainPanel.reports[reporter] then
        reports.mainPanel.reports[reporter]:Remove()
    end
end)

net.Receive("reports.close", function()
    if IsValid(reports.playerPanel) then reports.playerPanel:Remove() end
    if IsValid(reports.adminPanel) then reports.adminPanel:Remove() end
	if IsValid(reports.mainPanel) then reports.mainPanel:Remove() end
end)

net.Receive("reports.message", function()
    local msg = net.ReadTable()
    if IsValid(reports.playerPanel) then reports.playerPanel.Chat(msg) end
    if IsValid(reports.adminPanel) then reports.adminPanel.Chat(msg) end
    surface.PlaySound("buttons/bugle.wav")
end)