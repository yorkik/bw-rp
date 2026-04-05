-- File: weapons/rp_police_pda/cl_init.lua
include("shared.lua")
if CLIENT then
    -----------------------------------------------------------------------
    -- Шрифты и цвета
    -----------------------------------------------------------------------
    surface.CreateFont("PolicePDA_Title",   {font = "Arial", size = 24, weight = 900, extended = true})
    surface.CreateFont("PolicePDA_Header",  {font = "Arial", size = 18, weight = 700, extended = true})
    surface.CreateFont("PolicePDA_Normal",  {font = "Arial", size = 14, weight = 500, extended = true})
    surface.CreateFont("PolicePDA_Small",   {font = "Arial", size = 12, weight = 400, extended = true})
    surface.CreateFont("PolicePDA_Tiny",    {font = "Arial", size = 10, weight = 400, extended = true})

    local COLORS = {
        BG      = Color(15, 15, 20),
        HEADER  = Color(20, 40, 80),
        ACCENT  = Color(0, 100, 200),
        RED     = Color(200, 50, 50),
        GREEN   = Color(50, 200, 50),
        BLUE    = Color(50, 100, 200),
        ORANGE  = Color(200, 150, 50),
        YELLOW  = Color(255, 255, 0), -- Добавлено для штрафов
        TEXT    = Color(255, 255, 255),
        TEXT_DIM= Color(200, 200, 200),
        BORDER  = Color(40, 40, 50),
        PANEL   = Color(25, 25, 30),
        ROW_BG  = Color(30, 30, 40),
        ROW_HOVER = Color(50, 50, 60)
    }

    -----------------------------------------------------------------------
    -- Функции для кастомных таблиц
    -----------------------------------------------------------------------
    local function CreateCustomTable(parent, columns)
        local scroll = vgui.Create("DScrollPanel", parent)
        scroll:Dock(FILL)
        scroll:SetPaintBackground(false)

        local tableData = {
            scroll = scroll,
            rows = {},
            columns = columns
        }

        -- Заголовок таблицы
        local header = vgui.Create("DPanel", scroll)
        header:Dock(TOP)
        header:SetTall(30)
        header:SetPaintBackground(false)
        header:SetMouseInputEnabled(false)
        header.Paint = function(s, w, h)
            draw.RoundedBoxEx(4, 0, 0, w, h, COLORS.HEADER, true, true, false, false)
            draw.RoundedBox(0, 0, h-2, w, 2, COLORS.ACCENT)
        end

        local x = 0
        for i, col in ipairs(columns) do
            local label = vgui.Create("DLabel", header)
            label:SetText(col.name)
            label:SetFont("PolicePDA_Normal")
            label:SetTextColor(COLORS.TEXT)
            label:SetMouseInputEnabled(false)
            label:SetPos(x + 5, 6)
            label:SetSize((col.width or 100) - 10, 18)
            x = x + (col.width or 100)
        end

        function tableData:Clear()
            for _, row in ipairs(self.rows) do
                if IsValid(row.panel) then
                    row.panel:Remove()
                end
            end
            self.rows = {}
        end

        function tableData:AddRow(data, onRightClick, onDeleteButton, fullData)
            local row = vgui.Create("DPanel", self.scroll)
            row:Dock(TOP)
            row:SetTall(35)
            row:SetPaintBackground(false)
            row.data = data
            row.fullData = fullData -- Сохраняем полные данные для tooltip

            local isHovered = false
            local hoverTime = 0
            local tooltip = nil

            row.Paint = function(s, w, h)
                local bgColor = isHovered and COLORS.ROW_HOVER or COLORS.ROW_BG
                draw.RoundedBox(0, 0, 0, w, h, bgColor)
                if isHovered then
                    draw.RoundedBox(0, 0, h-1, w, 1, COLORS.ACCENT)
                end
            end

            row.OnCursorEntered = function()
                isHovered = true
                hoverTime = CurTime()
                -- Находим главный фрейм и сохраняем ссылку на строку для tooltip
                local parentFrame = row:GetParent()
                while IsValid(parentFrame) and not parentFrame.GetSize do
                    parentFrame = parentFrame:GetParent()
                end
                if IsValid(parentFrame) then
                    local frame = parentFrame
                    while IsValid(frame:GetParent()) and frame:GetParent().GetSize do
                        frame = frame:GetParent()
                    end
                    if IsValid(frame) then
                        frame.hoveredRow = row
                        frame.hoverStartTime = CurTime()
                    end
                end
            end

            row.OnCursorExited = function()
                isHovered = false
                hoverTime = 0
                -- Удаляем ссылку на строку из фрейма
                local parentFrame = row:GetParent()
                while IsValid(parentFrame) and not parentFrame.GetSize do
                    parentFrame = parentFrame:GetParent()
                end
                if IsValid(parentFrame) then
                    local frame = parentFrame
                    while IsValid(frame:GetParent()) and frame:GetParent().GetSize do
                        frame = frame:GetParent()
                    end
                    if IsValid(frame) and frame.hoveredRow == row then
                        frame.hoveredRow = nil
                        frame.hoverStartTime = nil
                    end
                end
            end

            -- Вычисляем общую ширину столбцов для позиционирования кнопки
            local totalColWidth = 0
            for _, col in ipairs(columns) do
                totalColWidth = totalColWidth + (col.width or 100)
            end

            local x = 0
            for i, col in ipairs(columns) do
                local label = vgui.Create("DLabel", row)
                label:SetText(data[i] or "")
                label:SetFont("PolicePDA_Small")
                label:SetTextColor(COLORS.TEXT)
                label:SetMouseInputEnabled(false)
                label:SetPos(x + 5, 8)
                label:SetSize((col.width or 100) - 10, 19)
                x = x + (col.width or 100)
            end

            table.insert(self.rows, {panel = row, data = data})
            return row
        end

        return tableData
    end

    -----------------------------------------------------------------------
    -- Сетевые хуки
    -----------------------------------------------------------------------
    net.Receive("PolicePDA_SendData", function(len)
        local data = net.ReadTable()
        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "rp_police_pda" then
            wep.LicensesData = data.licenses or {}
            wep.WantedData = data.wanted or {}
            wep.WarrantData = data.warrant or {}
            wep.FineData = data.fines or {} -- Добавлено
            wep.PlayersData = data.players or {}
            if IsValid(wep.menu) then wep:UpdateMenu() end
        end
    end)

    net.Receive("PolicePDA_Notification", function(len)
        local data = net.ReadTable()
        local wep = LocalPlayer():GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "rp_police_pda" then
            local notificationType = data.type
            local notificationColor = COLORS.ORANGE -- По умолчанию
            if notificationType == "wanted_added" or notificationType == "warrant_added" then
                notificationColor = COLORS.RED
            elseif notificationType == "wanted_removed" or notificationType == "warrant_removed" then
                notificationColor = COLORS.GREEN
            elseif notificationType == "fine_added" or notificationType == "fine_paid" then -- Добавлено
                notificationColor = COLORS.YELLOW
            elseif notificationType == "license_change" then
                notificationColor = COLORS.BLUE
            end
            table.insert(wep.Notifications, {
                type = notificationType,
                targetNick = data.targetNick or "Неизвестно",
                reason = data.reason or "",
                issuer = data.issuer or "Система",
                amount = data.amount or 0, -- Добавлено
                action = data.action or "",
                time = CurTime() + 8, -- Показываем 8 секунд
                color = notificationColor -- Добавлено
            })
            -- Ограничиваем количество уведомлений
            while #wep.Notifications > 5 do
                table.remove(wep.Notifications, 1)
            end
            if IsValid(wep.menu) then wep:UpdateMenu() end
        end
    end)

    net.Receive("PolicePDA_AddWanted_Response", function(len)
        local success = net.ReadBool()
        if success then
            local targetNick = net.ReadString()
            chat.AddText(COLORS.GREEN, "Розыск выдан на " .. targetNick .. "!")
        else
            local errorMsg = net.ReadString()
            chat.AddText(COLORS.RED, "Ошибка: " .. errorMsg)
        end
    end)

    net.Receive("PolicePDA_AddWarrant_Response", function(len)
        local success = net.ReadBool()
        if success then
            local targetNick = net.ReadString()
            chat.AddText(COLORS.GREEN, "Ордер выдан на " .. targetNick .. "!")
        else
            local errorMsg = net.ReadString()
            chat.AddText(COLORS.RED, "Ошибка: " .. errorMsg)
        end
    end)

    net.Receive("PolicePDA_AddFine_Response", function(len) -- Добавлено
        local success = net.ReadBool()
        if success then
            local targetNick = net.ReadString()
            chat.AddText(COLORS.GREEN, "Штраф выписан игроку " .. targetNick .. "!")
        else
            local errorMsg = net.ReadString()
            chat.AddText(COLORS.RED, "Ошибка: " .. errorMsg)
        end
    end)

    net.Receive("PolicePDA_RemoveFine_Response", function(len) -- Добавлено
        local success = net.ReadBool()
        if success then
            local targetNick = net.ReadString()
            chat.AddText(COLORS.GREEN, "Штраф снят с игрока " .. targetNick .. "!")
        else
            local errorMsg = net.ReadString()
            chat.AddText(COLORS.RED, "Ошибка: " .. errorMsg)
        end
    end)

    -----------------------------------------------------------------------
    -- SWEP
    -----------------------------------------------------------------------
    SWEP.LicensesData = {}
    SWEP.WantedData = {}
    SWEP.WarrantData = {}
    SWEP.FineData = {} -- Добавлено
    SWEP.PlayersData = {}
    SWEP.Notifications = {}
    SWEP.MouseHasControl = false

    -- Глобальный хук для закрытия планшета при ПКМ
    hook.Add("PlayerButtonDown", "PolicePDA_CloseOnRightClick", function(ply, button)
        if IsValid(ply) and ply == LocalPlayer() then
            if button == 108 or button == MOUSE_RIGHT then
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and wep:GetClass() == "rp_police_pda" then
                    wep:CloseTablet()
                end
            end
        end
    end)

    -- Дополнительный хук через Think
    local lastRightClickCheck = 0
    hook.Add("Think", "PolicePDA_CloseOnRightClickThink", function()
        local currentTime = CurTime()
        if (currentTime - lastRightClickCheck) < 0.1 then return end
        lastRightClickCheck = currentTime
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "rp_police_pda" then return end
        if input.IsMouseDown(MOUSE_RIGHT) and wep.MouseHasControl then
            wep:CloseTablet()
        end
    end)

    SWEP.LastPrimaryClick = 0
    SWEP.PrimaryClickCooldown = 0.2

    function SWEP:PrimaryAttack()
        local currentTime = CurTime()
        if (currentTime - self.LastPrimaryClick) < self.PrimaryClickCooldown then
            return
        end
        self.LastPrimaryClick = currentTime
        if not IsValid(self.menu) then self:CreateMenu() end
        if IsValid(self.menu) then
            self.menu:SetMouseInputEnabled( true )
            self.menu:MakePopup(  )
            self.MouseHasControl = true
            gui.EnableScreenClicker(true)
        end
        self:SetNextPrimaryFire(CurTime() + 0.5)
    end

    function SWEP:SecondaryAttack()
        self:CloseTablet()
        self:SetNextSecondaryFire(CurTime() + 0.3)
    end

    function SWEP:CloseTablet()
        if self.MouseHasControl then
            gui.EnableScreenClicker(false)
            self.MouseHasControl = false
            if IsValid(self.menu) then
                self.menu:SetMouseInputEnabled(false)
                self.menu:SetKeyboardInputEnabled(false)
            end
        end
    end

    -----------------------------------------------------------------------
    -- 3D2D меню
    -----------------------------------------------------------------------
    function SWEP:CreateMenu()
        if IsValid(self.menu) then self.menu:Remove() end
        local baseW, baseH = 1920, 1080
        local baseMenuW, baseMenuH = 600, 450
        local currentW, currentH = ScrW(), ScrH()
        local scaleX = currentW / baseW
        local scaleY = currentH / baseH
        local scale = math.min(scaleX, scaleY)
        local menuW = math.floor(baseMenuW * scale)
        local menuH = math.floor(baseMenuH * scale)

        self.menu = vgui.Create("DFrame")
        self.menu:SetSize(menuW, menuH)
        self.menu:Center()
        self.menu:SetY(ScrH() - menuH - 20)
        self.menu:SetTitle("")
        self.menu:SetDraggable(false)
        self.menu:ShowCloseButton(false)

        local tablet = self

        local notifPanel = vgui.Create("DPanel", self.menu)
        notifPanel:SetSize(menuW, menuH)
        notifPanel:SetPos(0, 0)
        notifPanel:SetZPos(99999)
        notifPanel:SetMouseInputEnabled(false)
        notifPanel:SetKeyboardInputEnabled(false)
        notifPanel:SetPaintBackground(false)

        function notifPanel:Paint(w, h)
            if not tablet.Notifications or #tablet.Notifications == 0 then return end
            local notifX = 10
            local notifY = 10
            local notifWidth = 220
            local notifHeight = 50
            local notifSpacing = 10
            local currentTime = CurTime()
            for i = #tablet.Notifications, 1, -1 do
                local notif = tablet.Notifications[i]
                if notif.time > currentTime then
                    local remaining = notif.time - currentTime
                    local alpha = math.min(255, remaining * 32)
                    local notifColor = notif.color or COLORS.ORANGE -- Используем цвет из уведомления
                    local title
                    if notif.type == "wanted_added" or notif.type == "warrant_added" then
                        title = "РОЗЫСК/ОРДЕР"
                    elseif notif.type == "wanted_removed" or notif.type == "warrant_removed" then
                        title = "РОЗЫСК/ОРДЕР СНЯТ"
                    elseif notif.type == "fine_added" then -- Добавлено
                        title = "ШТРАФ ВЫПИСАН"
                    elseif notif.type == "fine_paid" then -- Добавлено
                        title = "ШТРАФ ОПЛАЧЕН"
                    elseif notif.type == "license_change" then
                        title = "ЛИЦЕНЗИЯ"
                    else
                        title = "ИНФО"
                    end
                    local text = title .. " | " .. (notif.targetNick or "Неизвестно")
                    if notif.reason and notif.reason ~= "" then
                        text = text .. " | " .. (notif.reason or "")
                    end
                    if notif.amount and notif.amount > 0 then -- Добавлено
                        text = text .. " | $" .. notif.amount
                    end
                    text = text .. " | " .. (notif.issuer or "Система")
                    local textWidth = w - notifX - 10
                    draw.RoundedBox(4, notifX, notifY, textWidth, notifHeight, Color(notifColor.r, notifColor.g, notifColor.b, alpha))
                    draw.RoundedBox(4, notifX, notifY, textWidth, 3, Color(notifColor.r * 0.7, notifColor.g * 0.7, notifColor.b * 0.7, alpha))
                    draw.SimpleTextOutlined(text, "PolicePDA_Normal", notifX + 10, notifY + notifHeight/2, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
                    notifY = notifY + notifHeight + notifSpacing
                else
                    table.remove(tablet.Notifications, i)
                end
            end
        end

        self.menu.notifPanel = notifPanel

        function self.menu:Think()
            local wep = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon() or false
            if not wep or wep:GetClass() ~= "rp_police_pda" then
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

        hook.Add("OnShowZCityPause","CloseDerma_PolicePDA",function()
            if tablet.MouseHasControl then
                gui.EnableScreenClicker(false)
                tablet.menu:SetMouseInputEnabled( false )
                tablet.menu:SetKeyboardInputEnabled( false )
                tablet.MouseHasControl = false
                return false
            end
        end)

        self.menu.bNoBackgroundBlur = true
        self.menu.NoBlur = true

        local frame = self.menu
        function frame:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, COLORS.BG)
            draw.RoundedBoxEx(8, 0, 0, w, 50, COLORS.HEADER, true, true, false, false)
            draw.RoundedBox(0, 0, 50, w, 3, COLORS.ACCENT)
            draw.SimpleText("POLICE", "PolicePDA_Title", 15, 25, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("BWPD", "PolicePDA_Tiny", w-15, 12, COLORS.TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.SimpleText(os.date("%H:%M:%S"), "PolicePDA_Small", w-15, 28, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.RoundedBoxEx(8, 0, h-40, w, 40, Color(20,20,25,200), false, false, true, true)
            draw.SimpleText("Статус: Активен | Офицер: "..(LocalPlayer():GetNWString("PlayerName") or "Неизвестно"), "PolicePDA_Tiny", 15, h-22, COLORS.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        function frame:PaintOver(w, h)
            if IsValid(self.hoveredRow) and self.hoveredRow.fullData then
                local rowX, rowY = self.hoveredRow:GetPos()
                local parent = self.hoveredRow:GetParent()
                local totalY = rowY
                while IsValid(parent) and parent ~= self do
                    local py = parent:GetPos()
                    totalY = totalY + (py or 0)
                    parent = parent:GetParent()
                    if not IsValid(parent) or parent == self then break end
                end
                local padding = 15
                local lineHeight = 18
                local headerHeight = 30
                local description = self.hoveredRow.fullData.description or "Нет описания"
                local maxWidth = 450
                local maxCharsPerLine = 55
                local descLines = {}
                if #description > maxCharsPerLine then
                    local i = 1
                    while i <= #description do
                        local line = string.sub(description, i, i + maxCharsPerLine - 1)
                        local lastSpace = string.find(line:reverse(), " ")
                        if lastSpace and i + maxCharsPerLine <= #description then
                            line = string.sub(description, i, i + maxCharsPerLine - lastSpace)
                            i = i + maxCharsPerLine - lastSpace + 1
                        else
                            i = i + maxCharsPerLine
                        end
                        table.insert(descLines, line)
                    end
                else
                    table.insert(descLines, description)
                end
                local tooltipW = maxWidth
                local infoLines = 0
                if self.hoveredRow.fullData.price then infoLines = infoLines + 1 end
                if self.hoveredRow.fullData.time then infoLines = infoLines + 1 end
                if self.hoveredRow.fullData.npc then infoLines = infoLines + 1 end
                if self.hoveredRow.fullData.amount then infoLines = infoLines + 1 end -- Добавлено
                local contentHeight = headerHeight + 10 + 20 + (#descLines * lineHeight) + 10 + (infoLines * 18) + 10
                local tooltipH = contentHeight

                local tooltipX = rowX + 10
                local tooltipY = totalY - tooltipH - 10

                if tooltipX + tooltipW > w - 10 then
                    tooltipX = w - tooltipW - 10
                end
                if tooltipX < 10 then
                    tooltipX = 10
                end
                if tooltipY < 60 then
                    tooltipY = totalY + 40
                end
                if tooltipY + tooltipH > h - 50 then
                    tooltipY = h - tooltipH - 50
                end

                draw.RoundedBox(6, tooltipX + 3, tooltipY + 3, tooltipW, tooltipH, Color(0, 0, 0, 120))
                draw.RoundedBox(6, tooltipX, tooltipY, tooltipW, tooltipH, COLORS.BG)
                draw.RoundedBoxEx(6, tooltipX, tooltipY, tooltipW, headerHeight, COLORS.HEADER, true, true, false, false)
                draw.RoundedBox(0, tooltipX, tooltipY + headerHeight - 2, tooltipW, 2, COLORS.ACCENT)

                local titleText = "ИНФОРМАЦИЯ"
                draw.SimpleText(titleText .. " - Подробная информация", "PolicePDA_Header", tooltipX + padding, tooltipY + headerHeight/2, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                local bodyY = tooltipY + headerHeight
                local currentY = bodyY + 10

                draw.SimpleText("Описание:", "PolicePDA_Normal", tooltipX + padding, currentY, COLORS.ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                currentY = currentY + 20
                for _, line in ipairs(descLines) do
                    draw.SimpleText(line, "PolicePDA_Small", tooltipX + padding, currentY, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    currentY = currentY + lineHeight
                end

                draw.RoundedBox(0, tooltipX + padding, currentY + 5, tooltipW - padding * 2, 1, COLORS.BORDER)
                currentY = currentY + 15

                if self.hoveredRow.fullData.price then
                    draw.SimpleText("Цена: ", "PolicePDA_Small", tooltipX + padding, currentY, COLORS.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("$" .. self.hoveredRow.fullData.price, "PolicePDA_Small", tooltipX + padding + 60, currentY, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    currentY = currentY + 18
                end
                if self.hoveredRow.fullData.time then
                    local timeStr = os.date("%d.%m.%Y %H:%M:%S", self.hoveredRow.fullData.time)
                    draw.SimpleText("Время: ", "PolicePDA_Small", tooltipX + padding, currentY, COLORS.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(timeStr, "PolicePDA_Small", tooltipX + padding + 60, currentY, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    currentY = currentY + 18
                end
                if self.hoveredRow.fullData.npc then
                    draw.SimpleText("NPC: ", "PolicePDA_Small", tooltipX + padding, currentY, COLORS.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(self.hoveredRow.fullData.npc, "PolicePDA_Small", tooltipX + padding + 60, currentY, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                if self.hoveredRow.fullData.amount then -- Добавлено
                    draw.SimpleText("Сумма: ", "PolicePDA_Small", tooltipX + padding, currentY, COLORS.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("$" .. self.hoveredRow.fullData.amount, "PolicePDA_Small", tooltipX + padding + 60, currentY, COLORS.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
        end

        function frame:OnMousePressed(code)
            if code == MOUSE_RIGHT then
                if IsValid(self.modal) then
                    self.modal:Remove()
                end
                if IsValid(tablet) then
                    tablet:CloseTablet()
                end
            end
        end

        -------------------------------------------------------------------
        -- Вкладки
        -------------------------------------------------------------------
        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)
        sheet:DockMargin(5, 55, 5, 45)
        function sheet:Paint(w,h) draw.RoundedBox(0,0,0,w,h,COLORS.PANEL) end

        -------------------------------------------------------------------
        -- 1. Лицензии
        -------------------------------------------------------------------
        local licTab = vgui.Create("DPanel", sheet)
        licTab:SetPaintBackground(false)
        licTab:DockPadding(10,10,10,10)

        local licTitle = vgui.Create("DLabel", licTab)
        licTitle:SetText("СПИСОК ЛИЦЕНЗИЙ")
        licTitle:SetFont("PolicePDA_Header")
        licTitle:SetTextColor(COLORS.ACCENT)
        licTitle:SizeToContents()
        licTitle:Dock(TOP)
        licTitle:DockMargin(0,0,0,15)

        local licListContainer = vgui.Create("DPanel", licTab)
        licListContainer:Dock(FILL)
        licListContainer:SetPaintBackground(false)
        licListContainer.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.BG)
        end

        local licList = CreateCustomTable(licListContainer, {
            {name = "Имя", width = 150},
            {name = "Лицензия", width = 100},
        })

        sheet:AddSheet("Лицензии", licTab, "icon16/shield.png")

        -------------------------------------------------------------------
        -- 2. Розыск
        -------------------------------------------------------------------
        local wantedTab = vgui.Create("DPanel", sheet)
        wantedTab:SetPaintBackground(false)
        wantedTab:DockPadding(10,10,10,10)

        local wantedTitle = vgui.Create("DLabel", wantedTab)
        wantedTitle:SetText("СПИСОК РОЗЫСКА")
        wantedTitle:SetFont("PolicePDA_Header")
        wantedTitle:SetTextColor(COLORS.ACCENT)
        wantedTitle:SizeToContents()
        wantedTitle:Dock(TOP)
        wantedTitle:DockMargin(0,0,0,15)

        local wantedListContainer = vgui.Create("DPanel", wantedTab)
        wantedListContainer:Dock(FILL)
        wantedListContainer:SetPaintBackground(false)
        wantedListContainer.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.BG)
        end

        local wantedList = CreateCustomTable(wantedListContainer, {
            {name = "Имя", width = 150},
            {name = "Причина", width = 250},
            {name = "Выдал", width = 120}
        })

        -- Кнопка "Повесить в розыск"
        local addWantedBtn = vgui.Create("DButton", wantedTab)
        addWantedBtn:SetText("ПОВЕСИТЬ В РОЗЫСК")
        addWantedBtn:SetFont("PolicePDA_Small")
        addWantedBtn:SetTextColor(COLORS.TEXT)
        addWantedBtn:Dock(BOTTOM)
        addWantedBtn:SetTall(30)
        addWantedBtn:SetZPos(1000)
        function addWantedBtn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.RED)
        end
        addWantedBtn.DoClick = function()
            -- Создаем модальное окно для выбора данных
            local modal = vgui.Create("DFrame")
            modal:SetSize(400, 400)
            modal:Center()
            modal:SetTitle("Повесить в розыск")
            modal:SetDraggable(true)
            modal:ShowCloseButton(true)
            modal:MakePopup()

            local playerLabel = vgui.Create("DLabel", modal)
            playerLabel:SetText("Выберите игрока:")
            playerLabel:SetPos(20, 30)
            playerLabel:SetSize(300, 20)

            local playerList = vgui.Create("DListView", modal)
            playerList:SetPos(20, 50)
            playerList:SetSize(360, 100)
            playerList:AddColumn("Имя")
            playerList:AddColumn("Работа")
            -- Заполняем список игроков
            for steamid, data in pairs(tablet.PlayersData) do
                if not data.isWanted and not data.isDarkRPWanted and steamid ~= LocalPlayer():SteamID() then
                    local line = playerList:AddLine(data.nick, data.job or "Unknown")
                    line.SteamID = steamid
                end
            end

            local reasonLabel = vgui.Create("DLabel", modal)
            reasonLabel:SetText("Причина:")
            reasonLabel:SetPos(20, 160)
            reasonLabel:SetSize(300, 20)

            local reasonEntry = vgui.Create("DTextEntry", modal)
            reasonEntry:SetPos(20, 180)
            reasonEntry:SetSize(360, 60)
            reasonEntry:SetMultiline(true)
            reasonEntry:RequestFocus()

            local submitBtn = vgui.Create("DButton", modal)
            submitBtn:SetText("ПОВЕСИТЬ РОЗЫСК")
            submitBtn:SetPos(20, 250)
            submitBtn:SetSize(360, 30)
            function submitBtn:Paint(w, h)
                draw.RoundedBox(4, 0, 0, w, h, COLORS.RED)
            end
            submitBtn.DoClick = function()
                local selected = playerList:GetSelectedLine()
                local reason = string.Trim(reasonEntry:GetValue())
                if not selected or not reason or reason == "" then
                    chat.AddText(COLORS.RED, "Ошибка: Выберите игрока и введите причину!")
                    return
                end
                local line = playerList:GetLine(selected)
                local targetSteamID = line.SteamID
                net.Start("PolicePDA_AddWanted")
                net.WriteString(targetSteamID)
                net.WriteString(reason)
                net.SendToServer()
                modal:Close()
            end
        end

        sheet:AddSheet("Розыск", wantedTab, "icon16/exclamation.png")

        -------------------------------------------------------------------
        -- 3. Ордер
        -------------------------------------------------------------------
        local warrantTab = vgui.Create("DPanel", sheet)
        warrantTab:SetPaintBackground(false)
        warrantTab:DockPadding(10,10,10,10)

        local warrantTitle = vgui.Create("DLabel", warrantTab)
        warrantTitle:SetText("СПИСОК ОРДЕРОВ")
        warrantTitle:SetFont("PolicePDA_Header")
        warrantTitle:SetTextColor(COLORS.ACCENT)
        warrantTitle:SizeToContents()
        warrantTitle:Dock(TOP)
        warrantTitle:DockMargin(0,0,0,15)

        local warrantListContainer = vgui.Create("DPanel", warrantTab)
        warrantListContainer:Dock(FILL)
        warrantListContainer:SetPaintBackground(false)
        warrantListContainer.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.BG)
        end

        local warrantList = CreateCustomTable(warrantListContainer, {
            {name = "Имя", width = 150},
            {name = "Причина", width = 250},
            {name = "Выдал", width = 120}
        })

        -- Кнопка "Выдать ордер"
        local addWarrantBtn = vgui.Create("DButton", warrantTab)
        addWarrantBtn:SetText("ВЫДАТЬ ОРДЕР")
        addWarrantBtn:SetFont("PolicePDA_Small")
        addWarrantBtn:SetTextColor(COLORS.TEXT)
        addWarrantBtn:Dock(BOTTOM)
        addWarrantBtn:SetTall(30)
        addWarrantBtn:SetZPos(1000)
        function addWarrantBtn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.ORANGE)
        end
        addWarrantBtn.DoClick = function()
            -- Создаем модальное окно для ввода данных
            local modal = vgui.Create("DFrame")
            modal:SetSize(400, 400)
            modal:Center()
            modal:SetTitle("Выдать ордер")
            modal:SetDraggable(true)
            modal:ShowCloseButton(true)
            modal:MakePopup()

            local playerLabel = vgui.Create("DLabel", modal)
            playerLabel:SetText("Выберите игрока:")
            playerLabel:SetPos(20, 30)
            playerLabel:SetSize(300, 20)

            local playerList = vgui.Create("DListView", modal)
            playerList:SetPos(20, 50)
            playerList:SetSize(360, 100)
            playerList:AddColumn("Имя")
            playerList:AddColumn("Работа")
            -- Заполняем список игроков
            for steamid, data in pairs(tablet.PlayersData) do
                if not data.hasWarrant and steamid ~= LocalPlayer():SteamID() then
                    local line = playerList:AddLine(data.nick, data.job or "Unknown")
                    line.SteamID = steamid
                end
            end

            local reasonLabel = vgui.Create("DLabel", modal)
            reasonLabel:SetText("Причина:")
            reasonLabel:SetPos(20, 160)
            reasonLabel:SetSize(300, 20)

            local reasonEntry = vgui.Create("DTextEntry", modal)
            reasonEntry:SetPos(20, 180)
            reasonEntry:SetSize(360, 60)
            reasonEntry:SetMultiline(true)
            reasonEntry:RequestFocus()

            local submitBtn = vgui.Create("DButton", modal)
            submitBtn:SetText("ВЫДАТЬ ОРДЕР")
            submitBtn:SetPos(20, 250)
            submitBtn:SetSize(360, 30)
            function submitBtn:Paint(w, h)
                draw.RoundedBox(4, 0, 0, w, h, COLORS.ORANGE)
            end
            submitBtn.DoClick = function()
                local selected = playerList:GetSelectedLine()
                local reason = string.Trim(reasonEntry:GetValue())
                if not selected or not reason or reason == "" then
                    chat.AddText(COLORS.RED, "Ошибка: Выберите игрока и введите причину!")
                    return
                end
                local line = playerList:GetLine(selected)
                local targetSteamID = line.SteamID
                net.Start("PolicePDA_AddWarrant")
                net.WriteString(targetSteamID)
                net.WriteString(reason)
                net.WriteString(LocalPlayer():GetNWString("PlayerName"))
                net.SendToServer()
                modal:Close()
            end
        end

        sheet:AddSheet("Ордер", warrantTab, "icon16/book.png")

        -------------------------------------------------------------------
        -- 4. Штрафы (Новая вкладка)
        -------------------------------------------------------------------
        local fineTab = vgui.Create("DPanel", sheet)
        fineTab:SetPaintBackground(false)
        fineTab:DockPadding(10,10,10,10)

        local fineTitle = vgui.Create("DLabel", fineTab)
        fineTitle:SetText("СПИСОК ШТРАФОВ")
        fineTitle:SetFont("PolicePDA_Header")
        fineTitle:SetTextColor(COLORS.ACCENT)
        fineTitle:SizeToContents()
        fineTitle:Dock(TOP)
        fineTitle:DockMargin(0,0,0,15)

        local fineListContainer = vgui.Create("DPanel", fineTab)
        fineListContainer:Dock(FILL)
        fineListContainer:SetPaintBackground(false)
        fineListContainer.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.BG)
        end

        local fineList = CreateCustomTable(fineListContainer, {
            {name = "Имя", width = 150},
            {name = "Причина", width = 150},
            {name = "Сумма", width = 70},
            {name = "Выдал", width = 120}
        })

        -- Кнопка "Выписать штраф"
        local addFineBtn = vgui.Create("DButton", fineTab)
        addFineBtn:SetText("ВЫПИСАТЬ ШТРАФ")
        addFineBtn:SetFont("PolicePDA_Small")
        addFineBtn:SetTextColor(COLORS.TEXT)
        addFineBtn:Dock(BOTTOM)
        addFineBtn:SetTall(30)
        addFineBtn:SetZPos(1000)
        function addFineBtn:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, COLORS.YELLOW)
        end
        addFineBtn.DoClick = function()
			local modal = vgui.Create("DFrame")
            modal:SetSize(400, 450)
            modal:Center()
            modal:SetTitle("Выписать штраф")
            modal:SetDraggable(true)
            modal:ShowCloseButton(true)
            modal:MakePopup()

            local playerLabel = vgui.Create("DLabel", modal)
            playerLabel:SetText("Выберите игрока:")
            playerLabel:SetPos(20, 30)
            playerLabel:SetSize(300, 20)

            local playerList = vgui.Create("DListView", modal)
            playerList:SetPos(20, 50)
            playerList:SetSize(360, 100)
            playerList:AddColumn("Имя")
            playerList:AddColumn("Работа")
            -- Заполняем список игроков
            for steamid, data in pairs(tablet.PlayersData) do
                if not data.hasFine and steamid ~= LocalPlayer():SteamID() then -- Проверяем, что у игрока нет штрафа
                    local ply = player.GetBySteamID(steamid)
                    if ply and not ply:isCP() then -- Проверяем, что игрок не является полицейским
                        local line = playerList:AddLine(data.nick, data.job or "Unknown")
                        line.SteamID = steamid
                    end
                end
            end

            local reasonLabel = vgui.Create("DLabel", modal)
            reasonLabel:SetText("Причина:")
            reasonLabel:SetPos(20, 160)
            reasonLabel:SetSize(300, 20)

            local reasonEntry = vgui.Create("DTextEntry", modal)
            reasonEntry:SetPos(20, 180)
            reasonEntry:SetSize(360, 60)
            reasonEntry:SetMultiline(true)
            reasonEntry:RequestFocus()

            local amountLabel = vgui.Create("DLabel", modal)
            amountLabel:SetText("Сумма штрафа:")
            amountLabel:SetPos(20, 250)
            amountLabel:SetSize(300, 20)

            local amountEntry = vgui.Create("DNumberWang", modal) -- Используем DNumberWang для чисел
            amountEntry:SetPos(20, 270)
            amountEntry:SetSize(360, 25)
            amountEntry:SetMin(1000)
            amountEntry:SetMax(25000) -- Установите лимит по желанию
            amountEntry:SetValue(1000) -- Значение по умолчанию

            local submitBtn = vgui.Create("DButton", modal)
            submitBtn:SetText("ВЫПИСАТЬ ШТРАФ")
            submitBtn:SetPos(20, 310)
            submitBtn:SetSize(360, 30)
            function submitBtn:Paint(w, h)
                draw.RoundedBox(4, 0, 0, w, h, COLORS.YELLOW)
            end
            submitBtn.DoClick = function()
                local selected = playerList:GetSelectedLine()
                local reason = string.Trim(reasonEntry:GetValue())
                local amount = math.floor(tonumber(amountEntry:GetValue()) or 0)
                
                if not selected or not reason or reason == "" or amount <= 0 then
                    chat.AddText(COLORS.RED, "Ошибка: Выберите игрока, введите причину и сумму штрафа!")
                    return
                end
                
                local line = playerList:GetLine(selected)
                local targetSteamID = line.SteamID
                local targetPly = player.GetBySteamID(targetSteamID)
                
                if targetPly and targetPly:isCP() then
                    chat.AddText(COLORS.RED, "Ошибка: Нельзя выписать штраф полицейскому!")
                    return
                end
                
                net.Start("PolicePDA_AddFine")
                net.WriteString(targetSteamID)
                net.WriteString(reason)
                net.WriteInt(amount, 32) -- Отправляем как целое число
                net.WriteString(LocalPlayer():GetNWString("PlayerName"))
                net.SendToServer()
                modal:Close()
            end
        end

        sheet:AddSheet("Штрафы", fineTab, "icon16/money.png") -- Иконка для штрафов

        -------------------------------------------------------------------
        -- Сохраняем ссылки
        -------------------------------------------------------------------
        frame.licensesList = licList
        frame.wantedList = wantedList
        frame.warrantList = warrantList
        frame.fineList = fineList -- Добавлено

        net.Start("PolicePDA_GetData") net.SendToServer()

        timer.Simple(0.1, function()
            if IsValid(tablet) and IsValid(tablet.menu) then
                tablet:UpdateMenu()
            end
        end)

        -- Автообновление
        timer.Create("PolicePDA_Update_"..self:EntIndex(), 5, 0, function()
            if not IsValid(self) or not IsValid(self.menu) then timer.Remove("PolicePDA_Update_"..self:EntIndex()) return end
            net.Start("PolicePDA_GetData") net.SendToServer()
        end)
    end

    -----------------------------------------------------------------------
    -- Обновление списков
    -----------------------------------------------------------------------
    function SWEP:UpdateMenu()
        if not IsValid(self.menu) then return end
        local m = self.menu
        -- Лицензии
        if m.licensesList then
            m.licensesList:Clear()
            local hasPlayers = false
            for steamid, playerData in pairs(self.PlayersData) do
                local nick = playerData.nick or "Неизвестно"
                local job = playerData.job or "Unknown Job"
                -- Находим игрока по SteamID и проверяем его лицензию
                local targetPlayer = player.GetBySteamID(steamid)
                local weaponLic = "Нету"
                if IsValid(targetPlayer) then
                    local hasLicense = targetPlayer:getDarkRPVar('HasGunlicense')
                    weaponLic = (hasLicense and hasLicense ~= false and hasLicense ~= 0) and "Есть" or "Нету"
                end
                m.licensesList:AddRow({nick, weaponLic})
                hasPlayers = true
            end
            if not hasPlayers then
                m.licensesList:AddRow({"Нет игроков", ""})
            end
        end
        -- Розыск
        if m.wantedList then
            m.wantedList:Clear()
            local hasWanted = false
            for steamid, data in pairs(self.WantedData) do
                local playerData = self.PlayersData[steamid]
                local targetPlayer = player.GetBySteamID(steamid)
                local nick = (playerData and playerData.nick) or steamid
                local reason = data.reason or "Неизвестно"
                local issuer = data.issuer or "Система"
                m.wantedList:AddRow({nick, reason, issuer})
                hasWanted = true
            end
            if not hasWanted then
                m.wantedList:AddRow({"Нет розыска", "", ""})
            end
        end
        -- Ордер
        if m.warrantList then
            m.warrantList:Clear()
            local hasWarrants = false
            for steamid, data in pairs(self.WarrantData) do
                local playerData = self.PlayersData[steamid]
                local nick = (playerData and playerData.nick) or steamid
                local reason = data.reason or "Неизвестно"
                local issuer = data.issuer or "Система"
                m.warrantList:AddRow({nick, reason, issuer})
                hasWarrants = true
            end
            if not hasWarrants then
                m.warrantList:AddRow({"Нет ордеров", "", ""})
            end
        end
        -- Штрафы
        if m.fineList then
            m.fineList:Clear()
            local hasFines = false
            for steamid, data in pairs(self.FineData) do
                local playerData = self.PlayersData[steamid]
                local nick = (playerData and playerData.nick) or steamid
                local reason = data.reason or "Неизвестно"
                local amount = data.amount or 0
                local issuer = data.issuer or "Система"
                m.fineList:AddRow({nick, reason, "$" .. amount, issuer}) -- Отображаем сумму с $
                hasFines = true
            end
            if not hasFines then
                m.fineList:AddRow({"Нет штрафов", "", "", ""})
            end
        end
    end

    -----------------------------------------------------------------------
    -- 3D2D отрисовка планшета
    -----------------------------------------------------------------------
    function SWEP:AddDrawModel(ent)
        if not IsValid(self:GetOwner()) or self:GetOwner() ~= LocalPlayer() then return end
        if not IsValid(self.menu) then self:CreateMenu() end
        if not IsValid(self.menu) then return end
        local pos, ang = ent:GetRenderOrigin(), ent:GetRenderAngles()
        local basePos = pos + ang:Up() * 1.2 + ang:Forward() * -14.82 + ang:Right() * -12.7
        local baseH = 1080
        local currentH = ScrH()
        local baseScale = 0.0151
        local scale3d = baseScale * (baseH / currentH)
        local menuW, menuH = self.menu:GetSize()
        local menuHeight = menuH
        local heightDiff = menuHeight * (baseScale - scale3d)
        local posOffset = heightDiff / 12
        pos = basePos + ang:Up() * posOffset
        vgui.Start3D2D(pos,ang,scale3d)
            self.menu:Paint3D2D()
        vgui.End3D2D()
    end

    -----------------------------------------------------------------------
    -- Очистка
    -----------------------------------------------------------------------
    function SWEP:Holster()
        self:CloseTablet()
        if IsValid(self.menu) then
            hook.Remove("OnShowZCityPause","CloseDerma_PolicePDA")
            self.menu:Remove()
        end
        return true
    end

    function SWEP:OnRemove()
        self:CloseTablet()
        if IsValid(self.menu) then
            hook.Remove("OnShowZCityPause","CloseDerma_PolicePDA")
            self.menu:Remove()
        end
        timer.Remove("PolicePDA_Update_"..self:EntIndex())
    end
end