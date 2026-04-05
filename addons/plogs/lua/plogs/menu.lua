surface.CreateFont("plogs.ui.title", {
    font = "Roboto",
    size = 28,
    weight = 700,
    extended = true
})

surface.CreateFont("plogs.ui.title.small", {
    font = "Roboto",
    size = 22,
    weight = 700,
    extended = true
})

surface.CreateFont("plogs.ui.head", {
    font = "Roboto",
    size = 20,
    weight = 600,
    extended = true
})

surface.CreateFont("plogs.ui.text", {
    font = "Roboto",
    size = 18,
    weight = 500,
    extended = true
})

surface.CreateFont("plogs.ui.text.small", {
    font = "Roboto",
    size = 16,
    weight = 500,
    extended = true
})

surface.CreateFont("plogs.ui.text.tiny", {
    font = "Roboto",
    size = 14,
    weight = 400,
    extended = true
})

surface.CreateFont("plogs.ui.text.mini", {
    font = "Roboto",
    size = 13,
    weight = 400,
    extended = true
})

local UI = plogs.ui

UI.Col = {
    bg              = Color(8, 11, 16, 160),
    bg2             = Color(12, 16, 22, 160),
    bg3             = Color(16, 21, 29, 160),
    bg4             = Color(44, 56, 78, 160),

    header          = Color(10, 14, 20, 100),
    sidebar         = Color(9, 13, 18, 100),
    card            = Color(13, 18, 25, 100),
    entry           = Color(10, 14, 19, 100),

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

    row             = Color(17, 22, 30),
    rowHover        = Color(35, 46, 63, 100),
    rowSelected     = Color(0, 170, 255, 42),

    skeletonA       = Color(255, 255, 255, 8),
    skeletonB       = Color(255, 255, 255, 18)
}

local C = UI.Col

local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawLine = surface.DrawLine
local Derma_DrawBackgroundBlur = Derma_DrawBackgroundBlur
local math_Clamp = math.Clamp
local FrameTime = FrameTime
local Lerp = Lerp
local IsValid = IsValid
local ipairs = ipairs
local SortedPairs = SortedPairs
local os_date = os.date
local string_find = string.find
local string_lower = string.lower
local string_Trim = string.Trim
local ScrW = ScrW
local ScrH = ScrH

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

local function GetLogType(logText)
    local txt = string_lower(logText or "")

    if string_find(txt, "say", 1, true) or string_find(txt, "chat", 1, true) or string_find(txt, " написал ", 1, true) then
        return "chat", C.accent
    end

    if string_find(txt, "killed", 1, true) or string_find(txt, "убил", 1, true) or string_find(txt, "slain", 1, true) then
        return "kill", C.red
    end

    if string_find(txt, "command", 1, true) or string_find(txt, "ran", 1, true) or string_find(txt, "executed", 1, true) or string_find(txt, "команд", 1, true) then
        return "command", C.orange
    end

    if string_find(txt, "connected", 1, true) or string_find(txt, "join", 1, true) or string_find(txt, "подключ", 1, true) then
        return "connect", C.green
    end

    if string_find(txt, "disconnected", 1, true) or string_find(txt, "leave", 1, true) or string_find(txt, "disconnect", 1, true) or string_find(txt, "отключ", 1, true) then
        return "disconnect", C.yellow
    end

    if string_find(txt, "admin", 1, true) or string_find(txt, "ban", 1, true) or string_find(txt, "kick", 1, true) or string_find(txt, "mute", 1, true) then
        return "admin", C.purple
    end

    return "log", C.text3
end

local function OpenCopyMenu(log, copyTable)
    local menu = DermaMenu()

    menu:AddOption("Копировать строку", function()
        SetClipboardText(log or "")
    end)

    for name, value in SortedPairs(copyTable or {}) do
        menu:AddOption("Копировать " .. name, function()
            SetClipboardText(value or "ERROR")
        end)
    end

    menu:Open()
end

local function StyleButton(btn, baseCol, hoverCol, textCol)
    btn:SetText("")
    btn:SetCursor("hand")
    btn.HoverLerp = 0
    btn.DownLerp = 0
    btn.Label = btn.Label or ""
    btn.BaseCol = baseCol or C.bg4
    btn.HoverCol = hoverCol or C.accent
    btn.TextCol = textCol or C.text

    btn.Paint = function(self, w, h)
        self.HoverLerp = Lerp(FrameTime() * 10, self.HoverLerp, self:IsHovered() and 1 or 0)
        self.DownLerp = Lerp(FrameTime() * 16, self.DownLerp, self:IsDown() and 1 or 0)

        local col = LerpColor(self.HoverLerp, self.BaseCol, self.HoverCol)
        local offset = self.DownLerp * 1

        DrawSoftShadow(0, 0, w, h, 80 + self.HoverLerp * 30, 4, 8)

        if self.HoverLerp > 0.02 then
            DrawGlow(0, 0, w, h, Alpha(self.HoverCol, 35 * self.HoverLerp), 4, 8)
        end

        draw_RoundedBox(8, 0, offset, w, h - offset, col)
        draw_SimpleText(self.Label, "plogs.ui.text.small", w / 2, h / 2 + offset / 2, self.TextCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function StyleEntry(entry)
    entry:SetPaintBackground(false)
    entry:SetFont("plogs.ui.text.small")
    entry:SetTextColor(C.text)
    entry:SetCursorColor(C.text)
    entry:SetHighlightColor(Alpha(C.accent, 70))
    entry.HoverLerp = 0
    entry.FocusLerp = 0

    entry.Paint = function(self, w, h)
        self.HoverLerp = Lerp(FrameTime() * 10, self.HoverLerp, self:IsHovered() and 1 or 0)
        self.FocusLerp = Lerp(FrameTime() * 12, self.FocusLerp, self:HasFocus() and 1 or 0)

        local borderCol = LerpColor(self.FocusLerp, LerpColor(self.HoverLerp, C.stroke, C.strokeSoft), Alpha(C.accent, 210))

        draw_RoundedBox(0, 0, 0, w, h, C.entry)
        if self.FocusLerp > 0.02 then
            DrawGlow(0, 0, w, h, Alpha(C.accent, 26 * self.FocusLerp), 4, 0)
        end
        surface_SetDrawColor(borderCol)
        surface_DrawOutlinedRect(0, 0, w, h, 1)

        self:DrawTextEntryText(C.text, C.accent, C.text)
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

local function CreateFrame(titleText, w, h)
    local fr = vgui.Create("DFrame")
    fr:SetSize(w, h)
    fr:Center()
    fr:SetTitle("")
    fr:ShowCloseButton(false)
    fr:MakePopup()
    fr:SetAlpha(0)

    fr.OpenFrac = 0
    fr.Closing = false
    fr.CloseBtn = vgui.Create("DButton", fr)
    fr.CloseBtn:SetSize(34, 34)
    fr.CloseBtn:SetText("")
    fr.CloseBtn.HoverLerp = 0
    fr.CloseBtn.DoClick = function()
        fr.Closing = true
    end
    fr.CloseBtn.Paint = function(self, ww, hh)
        self.HoverLerp = Lerp(FrameTime() * 12, self.HoverLerp, self:IsHovered() and 1 or 0)
        local col = LerpColor(self.HoverLerp, C.red3, C.red2)
        draw_RoundedBox(6, 0, 0, ww, hh, col)
        draw_SimpleText("✕", "plogs.ui.text", ww / 2, hh / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    fr.PerformLayout = function(self, ww, hh)
        self.CloseBtn:SetPos(ww - 46, 10)
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

		draw.Blur(self, 5)

        DrawSoftShadow(0, offsetY, ww, hh - offsetY, 140, 10, 8)
        draw_RoundedBox(8, 0, offsetY, ww, hh - offsetY, C.bg)
        draw.RoundedBoxEx(8, 0, offsetY, ww, 58, C.header, true, true, false, false)
        draw_RoundedBox(0, 0, offsetY + 57, ww, 1, C.stroke)

        DrawGlow(0, offsetY, ww, 58, Alpha(C.accent, 26), 5, 8)

        draw_SimpleText(titleText, "plogs.ui.title", 18, offsetY + 27, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    return fr
end

local function CreateSkeleton(parent)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetVisible(false)
    pnl.Shine = 0
    pnl.Paint = function(self, w, h)
        self.Shine = (self.Shine + FrameTime() * 1.3) % 1

        draw_RoundedBox(6, 0, 0, w, h, C.bg2)

        local function Bone(x, y, ww, hh, delay)
            local phase = (self.Shine + delay) % 1
            local lerp = math.abs(phase - 0.5) * 2
            local col = LerpColor(1 - lerp, C.skeletonA, C.skeletonB)
            draw_RoundedBox(8, x, y, ww, hh, col)
        end

        Bone(16, 18, w * 0.26, 18, 0.00)
        Bone(16, 52, w - 32, 24, 0.15)
        Bone(16, 86, w - 110, 20, 0.25)
        Bone(16, 126, w - 32, 34, 0.35)
        Bone(16, 170, w - 32, 34, 0.45)
        Bone(16, 214, w - 32, 34, 0.55)
        Bone(16, 258, w - 32, 34, 0.65)
        Bone(16, 302, w * 0.4, 24, 0.75)
    end
    return pnl
end

local function CreateSidebar(parent)
    local sidebar = vgui.Create("DPanel", parent)
    sidebar:Dock(LEFT)
    sidebar:SetWide(196)
    sidebar.Categories = {}
    sidebar.ActiveKey = nil

    sidebar.Paint = function(self, w, h)
        draw_RoundedBox(0, 0, 0, w, h, C.sidebar)
        surface_SetDrawColor(C.stroke)
        surface_DrawOutlinedRect(0, 0, w, h, 1)

        draw_SimpleText("Категории", "plogs.ui.head", w / 4, 18, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    sidebar.List = vgui.Create("DScrollPanel", sidebar)
    sidebar.List:SetPos(8, 72)
    sidebar.List:SetSize(180, parent:GetTall() - 80)
    StyleScrollBar(sidebar.List:GetVBar())

    function sidebar:AddCategory(key, text, callback, specialColor)
        local btn = vgui.Create("DButton", self.List)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 8)
        btn:SetTall(42)
        btn:SetText("")
        btn.Key = key
        btn.Label = text
        btn.ActiveLerp = 0
        btn.HoverLerp = 0
        btn.SpecialColor = specialColor or C.accent

        btn.Paint = function(selfBtn, w, h)
            local active = sidebar.ActiveKey == selfBtn.Key
            selfBtn.HoverLerp = Lerp(FrameTime() * 10, selfBtn.HoverLerp, selfBtn:IsHovered() and 1 or 0)
            selfBtn.ActiveLerp = Lerp(FrameTime() * 10, selfBtn.ActiveLerp, active and 1 or 0)

            local base = LerpColor(selfBtn.HoverLerp, C.white05, C.white08)
            local col = LerpColor(selfBtn.ActiveLerp, base, Alpha(selfBtn.SpecialColor, 42))

            draw.RoundedBoxEx(8, 0, 0, w, h, col, false, true, false, true)

            if selfBtn.ActiveLerp > 0.02 then
                draw_RoundedBox(0, 0, 0, 3, h, Alpha(selfBtn.SpecialColor, 220 * selfBtn.ActiveLerp))
                DrawGlow(0, 0, w, h, Alpha(selfBtn.SpecialColor, 24 * selfBtn.ActiveLerp), 4, 0)
            end

            local txtCol = LerpColor(selfBtn.ActiveLerp, LerpColor(selfBtn.HoverLerp, C.text2, C.text), C.text)
            draw_SimpleText(selfBtn.Label, "plogs.ui.text.small", 14, h / 2, txtCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            sidebar.ActiveKey = key
            if callback then
                callback()
            end
        end

        self.Categories[key] = btn
        return btn
    end

    return sidebar
end

local function CreateDetailCard(parent)
    local card = vgui.Create("DPanel", parent)
    card:Dock(RIGHT)
    card:SetWide(315)
    card.LogData = nil

    card.Paint = function(self, w, h)
        draw_RoundedBox(0, 0, 0, w, h, C.card)
        surface_SetDrawColor(C.stroke)
        surface_DrawOutlinedRect(0, 0, w, h, 1)

        local bottomY = 17
        local btnCopy = self.CopyBtn
        if IsValid(btnCopy) then
            btnCopy:SetPos(16, bottomY)
        end

        local btnMenu = self.MenuBtn
        if IsValid(btnMenu) then
            btnMenu:SetPos(16, bottomY + 40)
        end
    end

    card.CopyBtn = vgui.Create("DButton", card)
    card.CopyBtn:SetSize(283, 32)
    card.CopyBtn.Label = "Копировать строку"
    StyleButton(card.CopyBtn, C.bg4, C.green)
    card.CopyBtn.DoClick = function()
        if not card.LogData then return end
        SetClipboardText(card.LogData.Data or "")
    end

    card.MenuBtn = vgui.Create("DButton", card)
    card.MenuBtn:SetSize(283, 32)
    card.MenuBtn.Label = "Открыть меню копирования"
    StyleButton(card.MenuBtn, C.bg4, C.accent)
    card.MenuBtn.DoClick = function()
        if not card.LogData then return end
        OpenCopyMenu(card.LogData.Data, card.LogData.Copy)
    end

    function card:SetLog(log)
        self.LogData = log
    end

    return card
end

local function CreateAnimatedList(parent, detailCard)
    local wrap = vgui.Create("DPanel", parent)
    wrap:Dock(FILL)
    wrap:DockMargin(12, 0, 12, 0)
    wrap.Paint = function(self, w, h)
        draw_RoundedBox(0, 0, 0, w, h, C.bg2)
        surface_SetDrawColor(C.stroke)
        surface_DrawOutlinedRect(0, 0, w, h, 1)
    end

    local topBar = vgui.Create("DPanel", wrap)
    topBar:Dock(TOP)
    topBar:SetTall(52)
    topBar.Paint = function(self, w, h)
        draw_RoundedBox(0, 0, 0, w, h, C.header)
        surface_SetDrawColor(C.stroke)
        surface_DrawRect(0, h - 1, w, 1)
    end

    local searchEntry = vgui.Create("DTextEntry", topBar)
    searchEntry:SetPos(14, 10)
    searchEntry:SetSize(260, 32)
    StyleEntry(searchEntry)

    local sortBtn = vgui.Create("DButton", topBar)
    sortBtn:SetPos(284, 10)
    sortBtn:SetSize(140, 32)
    sortBtn.Label = "Сорт: новые сверху"
    StyleButton(sortBtn, C.bg4, C.accent)

    local saveBtn = vgui.Create("DButton", topBar)
    saveBtn:SetPos(434, 10)
    saveBtn:SetSize(110, 32)
    saveBtn.Label = "Сохранить"
    StyleButton(saveBtn, C.bg4, C.green)

    local listHost = vgui.Create("DScrollPanel", wrap)
    listHost:Dock(FILL)
    listHost:DockMargin(0, 0, 0, 0)
    StyleScrollBar(listHost:GetVBar())

    wrap.Rows = {}
    wrap.Data = {}
    wrap.Filtered = {}
    wrap.SortNewestFirst = true
    wrap.Search = searchEntry
    wrap.SaveBtn = saveBtn
    wrap.SortBtn = sortBtn
    wrap.DetailCard = detailCard
    wrap.Loading = false

    local function ClearRows()
        for _, row in ipairs(wrap.Rows) do
            if IsValid(row) then
                row:Remove()
            end
        end
        wrap.Rows = {}
    end

    local function CreateRow(log)
        local row = vgui.Create("DButton", listHost)
        row:Dock(TOP)
        row:DockMargin(10, 10, 10, 0)
        row:SetTall(66)
        row:SetText("")
        row.LogData = log
        row.HoverLerp = 0
        row.SelectLerp = 0
        row.Appear = 0

        local tag, tagCol = GetLogType(log.Data)

        row.Paint = function(self, w, h)
            self.HoverLerp = Lerp(FrameTime() * 10, self.HoverLerp, self:IsHovered() and 1 or 0)
            local selected = wrap.DetailCard.LogData == self.LogData
            self.SelectLerp = Lerp(FrameTime() * 12, self.SelectLerp, selected and 1 or 0)
            self.Appear = Lerp(FrameTime() * 9, self.Appear, 1)

            local yOff = (1 - self.Appear) * 12
            local alphaMul = self.Appear

            local base = LerpColor(self.HoverLerp, C.row, C.rowHover)
            local final = LerpColor(self.SelectLerp, base, Alpha(C.bg4, 38))

            DrawSoftShadow(0, yOff, w, h - yOff, 75 * alphaMul, 4, 0)
            draw_RoundedBox(0, 0, yOff, w, h - yOff, Alpha(final, 255 * alphaMul))
            surface_SetDrawColor(Alpha(LerpColor(self.SelectLerp, C.stroke, Alpha(C.accent, 180)), 255 * alphaMul))
            surface_DrawOutlinedRect(0, yOff, w, h - yOff, 1)

			/*
            draw_RoundedBox(0, 12, 12 + yOff, 76, 20, Alpha(tagCol, 38 * alphaMul))
            surface_SetDrawColor(Alpha(tagCol, 160 * alphaMul))
            surface_DrawOutlinedRect(12, 12 + yOff, 76, 20, 1)
            draw_SimpleText(string.upper(tag), "plogs.ui.text.mini", 50, 22 + yOff, Alpha(C.text, 255 * alphaMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			*/

            draw_SimpleText(log.DateText or "-", "plogs.ui.text.tiny", 10, 14 + yOff, Alpha(C.text3, 255 * alphaMul), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw_SimpleText(tostring(log.Data or ""), "plogs.ui.text.small", 10, 32 + yOff, Alpha(C.text, 255 * alphaMul), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        row.DoClick = function()
            wrap.DetailCard:SetLog(log)
        end

        row.DoRightClick = function()
            OpenCopyMenu(log.Data, log.Copy)
        end

        return row
    end

    function wrap:SetLoading(state)
        self.Loading = state
        if IsValid(self.Skeleton) then
            self.Skeleton:SetVisible(state)
        end
        listHost:SetVisible(not state)
    end

    wrap.Skeleton = CreateSkeleton(wrap)
    wrap.Skeleton:Dock(FILL)
    wrap.Skeleton:DockMargin(0, 0, 0, 0)

    function wrap:SetData(data)
        self.Data = data or {}
        self:Rebuild()
    end

    function wrap:GetVisibleData()
        local query = string_lower(string_Trim(self.Search:GetValue() or ""))
        local out = {}

        for _, log in ipairs(self.Data or {}) do
            local txt = string_lower(tostring(log.Data or ""))
            if query == "" or string_find(txt, query, 1, true) then
                out[#out + 1] = log
            end
        end

        table.sort(out, function(a, b)
            local ad = tonumber(a.SortTime or 0) or 0
            local bd = tonumber(b.SortTime or 0) or 0

            if self.SortNewestFirst then
                return ad > bd
            else
                return ad < bd
            end
        end)

        return out
    end

    function wrap:Rebuild()
        ClearRows()

        self.Filtered = self:GetVisibleData()
        listHost:InvalidateLayout(true)

        for _, log in ipairs(self.Filtered) do
            local row = CreateRow(log)
            self.Rows[#self.Rows + 1] = row
        end

        if #self.Filtered == 0 then
            local empty = vgui.Create("DPanel", listHost)
            empty:Dock(TOP)
            empty:DockMargin(10, 10, 10, 0)
            empty:SetTall(70)
            empty.Paint = function(selfPnl, w, h)
                draw_RoundedBox(0, 0, 0, w, h, C.row)
                surface_SetDrawColor(C.stroke)
                surface_DrawOutlinedRect(0, 0, w, h, 1)
                draw_SimpleText("Ничего не найдено", "plogs.ui.text", 16, 18, C.text2, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw_SimpleText("Попробуй изменить поиск или открыть другую категорию.", "plogs.ui.text.tiny", 16, 42, C.text3, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            self.Rows[#self.Rows + 1] = empty
        end
    end

    searchEntry.OnValueChange = function()
        wrap:Rebuild()
    end

    sortBtn.DoClick = function()
        wrap.SortNewestFirst = not wrap.SortNewestFirst
        sortBtn.Label = wrap.SortNewestFirst and "Сорт: новые сверху" or "Сорт: старые сверху"
        wrap:Rebuild()
    end

    saveBtn.DoClick = function()
        local dataToSave = wrap.Filtered or {}
        Derma_StringRequest(
            "Сохранение лога",
            "Как назвать сохранение?",
            "",
            function(saveName)
                if #dataToSave == 0 then
                    return
                end

                plogs.SaveLog(saveName, dataToSave)

                if IsValid(plogs.Menu) and IsValid(plogs.Menu.SaveList) and plogs.Menu.SaveList.AddSaves then
                    plogs.Menu.SaveList:AddSaves()
                end
            end,
            function()
            end
        )
    end

    return wrap
end

local function NormalizeLogs(rawData)
    local out = {}

    for _, v in ipairs(rawData or {}) do
        local sortTime = tonumber(v.Date) or 0
        local dateText = isstring(v.Date) and v.Date or os_date("%X - %d/%m/%Y", sortTime)

        out[#out + 1] = {
            Date = v.Date,
            DateText = dateText,
            Data = v.Data or "",
            Copy = v.Copy or {},
            SortTime = sortTime
        }
    end

    return out
end

local function OpenSearch(command)
    local w, h = math.max(ScrW() * 0.30, 460), 182
    local fr = CreateFrame("Поиск", w, h)

    plogs.SearchMenu = fr

    local lbl = vgui.Create("DLabel", fr)
    lbl:SetPos(16, 70)
    lbl:SetText("Введите SteamID / SteamID64")
    lbl:SetFont("plogs.ui.text.small")
    lbl:SetTextColor(C.text2)
    lbl:SizeToContents()

    local txt = vgui.Create("DTextEntry", fr)
    txt:SetPos(16, 96)
    txt:SetSize(w - 32, 34)
    StyleEntry(txt)

    local btn = vgui.Create("DButton", fr)
    btn:SetPos(16, 138)
    btn:SetSize(w - 32, 28)
    btn.Label = "Найти"
    StyleButton(btn, C.bg4, C.accent)

    btn.DoClick = function()
        LocalPlayer():ConCommand('plogs "' .. command .. '" "' .. txt:GetValue() .. '"')
        fr.Closing = true
    end
end

local function OpenSingleLogMenu(title, data)
    if IsValid(plogs.Menu) then
        plogs.Menu:SetVisible(false)
    end

    if IsValid(plogs.LogMenu) then
        plogs.LogMenu:Remove()
    end

    local w, h = math.floor(ScrW() * 0.75), math.floor(ScrH() * 0.76)
    local fr = CreateFrame(title, w, h)
    plogs.LogMenu = fr

    fr.OnRemove = function()
        if IsValid(plogs.Menu) then
            plogs.Menu:SetVisible(true)
        end
    end

    local body = vgui.Create("DPanel", fr)
    body:SetPos(14, 70)
    body:SetSize(w - 28, h - 84)
    body.Paint = function(self, ww, hh)
        draw_RoundedBox(14, 0, 0, ww, hh, C.bg)
    end

    local detail = CreateDetailCard(body)
    local list = CreateAnimatedList(body, detail)
    list:SetData(NormalizeLogs(data))
end

local function OpenMainMenu()
    if IsValid(plogs.Menu) then
        plogs.Menu:Remove()
    end

    local w = math.floor(ScrW() * 0.88)
    local h = math.floor(ScrH() * 0.84)

    local fr = CreateFrame("Логи", w, h)
    plogs.Menu = fr

    fr.OnRemove = function()
        if IsValid(plogs.SearchMenu) then
            plogs.SearchMenu:Remove()
        end
    end

    fr.ProgressLerp = 0
    fr.ExpectedCount = 1
    fr.LoadedCount = 0

    local content = vgui.Create("DPanel", fr)
    content:SetPos(14, 70)
    content:SetSize(w - 28, h - 84)
    content.Paint = function(self, ww, hh)
        draw_RoundedBox(14, 0, 0, ww, hh, C.bg)
    end

    local sidebar = CreateSidebar(content)
    local detail = CreateDetailCard(content)
    local list = CreateAnimatedList(content, detail)

    fr.Sidebar = sidebar
    fr.Detail = detail
    fr.List = list

    sidebar:AddCategory("saves", "Сохранения", function()
        local saves = {}

        for _, saveName in ipairs(plogs.GetSaves() or {}) do
            saves[#saves + 1] = {
                Date = 0,
                DateText = "Локальное сохранение",
                Data = tostring(saveName),
                Copy = {["save"] = tostring(saveName)},
                SortTime = 0,
                SaveName = tostring(saveName),
                IsSave = true
            }
        end

        list:SetData(saves)
        detail:SetLog(nil)
        list.SaveBtn:SetVisible(false)
        list.SortBtn:SetVisible(false)

        if IsValid(fr.SaveActionPanel) then
            fr.SaveActionPanel:Remove()
        end

        local pnl = vgui.Create("DPanel", content)
        pnl:SetPos(208, content:GetTall() - 110)
        pnl:SetSize(content:GetWide() - 208 - 327, 98)
        pnl.Paint = function(self, ww, hh)
            draw_RoundedBox(0, 0, 0, ww, hh, C.bg2)
            surface_SetDrawColor(C.stroke)
            surface_DrawOutlinedRect(0, 0, ww, hh, 1)
            draw_SimpleText("Работа с сохранениями", "plogs.ui.text.small", 14, 12, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw_SimpleText("Выбери строку со списком сохранений и открой или удали её.", "plogs.ui.text.tiny", 14, 34, C.text3, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        fr.SaveActionPanel = pnl

        local selectedSave = nil

        local oldSetLog = detail.SetLog
        detail.SetLog = function(self, log)
            oldSetLog(self, log)
            selectedSave = log and log.Data or nil
        end

        local openBtn = vgui.Create("DButton", pnl)
        openBtn:SetPos(14, 58)
        openBtn:SetSize(130, 28)
        openBtn.Label = "Открыть"
        StyleButton(openBtn, C.bg4, C.accent)
        openBtn.DoClick = function()
            if not selectedSave then
                return
            end

            local opened = NormalizeLogs(plogs.OpenSave(selectedSave) or {})
            list:SetData(opened)
            detail:SetLog(nil)
            list.SaveBtn:SetVisible(true)
            list.SortBtn:SetVisible(true)
        end

        local delBtn = vgui.Create("DButton", pnl)
        delBtn:SetPos(152, 58)
        delBtn:SetSize(130, 28)
        delBtn.Label = "Удалить"
        StyleButton(delBtn, C.bg4, C.red)
        delBtn.DoClick = function()
            if not selectedSave then
                return
            end

            plogs.DeleteSave(selectedSave)
            sidebar.Categories["saves"]:DoClick()
        end

        fr.SaveList = {
            AddSaves = function()
                if IsValid(sidebar.Categories["saves"]) then
                    sidebar.Categories["saves"]:DoClick()
                end
            end
        }
    end, C.green)

    if plogs.cfg.EnableMySQL then
        sidebar:AddCategory("playerevents", "События игроков", function()
            if IsValid(fr.SaveActionPanel) then
                fr.SaveActionPanel:Remove()
            end
            list.SaveBtn:SetVisible(true)
            list.SortBtn:SetVisible(true)
            OpenSearch("playerevents")
        end, C.accent)

        if plogs.cfg.IPUserGroups[string.lower(LocalPlayer():GetUserGroup())] then
            sidebar:AddCategory("ipsearch", "Логи IP", function()
                if IsValid(fr.SaveActionPanel) then
                    fr.SaveActionPanel:Remove()
                end
                list.SaveBtn:SetVisible(true)
                list.SortBtn:SetVisible(true)
                OpenSearch("ipsearch")
            end, C.orange)
        end
    end

    sidebar:AddCategory("overview", "Обзор", function()
        if IsValid(fr.SaveActionPanel) then
            fr.SaveActionPanel:Remove()
        end
        list.SaveBtn:SetVisible(true)
        list.SortBtn:SetVisible(true)

        local merged = {}
        for name, logs in pairs(plogs.data or {}) do
            for _, log in ipairs(logs or {}) do
                merged[#merged + 1] = {
                    Date = log.Date,
                    DateText = isstring(log.Date) and log.Date or os_date("%X - %d/%m/%y", tonumber(log.Date) or 0),
                    Data = "[" .. tostring(name) .. "] " .. tostring(log.Data or ""),
                    Copy = log.Copy or {},
                    SortTime = tonumber(log.Date) or 0
                }
            end
        end

        list:SetData(merged)
        detail:SetLog(nil)
    end, C.purple)

    sidebar.Categories["overview"]:DoClick()

    list:SetLoading(true)
    timer.Simple(0.45, function()
        if not IsValid(list) then return end
        list:SetLoading(false)
    end)
end

net.Receive("plogs.OpenMenu", function()
    if not IsValid(plogs.Menu) then
        OpenMainMenu()
    end

    local name = net.ReadString()
    local size = net.ReadUInt(16)
    local data = plogs.Decode(net.ReadData(size))
    local normalized = NormalizeLogs(data)

    plogs.data[name] = normalized

    local fr = plogs.Menu
    if not IsValid(fr) then return end

    fr.LoadedCount = (fr.LoadedCount or 0) + 1
    fr.ExpectedCount = math.max(fr.ExpectedCount or 1, table.Count(plogs.data))

    local sidebar = fr.Sidebar
    local list = fr.List
    local detail = fr.Detail

    if not IsValid(sidebar) or not IsValid(list) then return end

    if not sidebar.Categories[name] then
        sidebar:AddCategory(name, tostring(name), function()
            if IsValid(fr.SaveActionPanel) then
                fr.SaveActionPanel:Remove()
            end
            list.SaveBtn:SetVisible(true)
            list.SortBtn:SetVisible(true)
            list:SetLoading(true)

            timer.Simple(0.35, function()
                if not IsValid(list) then return end
                list:SetLoading(false)
                list:SetData(plogs.data[name] or {})
                detail:SetLog(nil)
            end)
        end, C.accent2)
    end

    if sidebar.ActiveKey == "overview" then
        sidebar.Categories["overview"]:DoClick()
    end
end)

net.Receive("plogs.LogData", function()
    local title = net.ReadString()
    local size = net.ReadUInt(16)
    local data = plogs.Decode(net.ReadData(size))
    OpenSingleLogMenu(title, data)
end)