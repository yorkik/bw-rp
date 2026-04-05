if SERVER then
	AddCSLuaFile()
end

if SERVER then
	util.AddNetworkString('NotifSystem')

	function notif(ply, message, status)
		net.Start('NotifSystem')
			net.WriteString(message or '')
			net.WriteString(status or 'ok')
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end

	return
end

local notificationStack = {}
local MIN_NOTIF_WIDTH = 200
local MAX_NOTIF_WIDTH = 500
local BASE_NOTIF_HEIGHT = 30
local NOTIF_MARGIN = 10
local NOTIF_SPACING = 5
local TEXT_PADDING = 40
local FONT = 'ui.14'
local cachedFontHeights = {}
local cachedLines = {}

local math_max = math.max
local math_Clamp = math.Clamp
local math_random = math.random
local string_format = string.format
local string_Explode = string.Explode
local string_gsub = string.gsub
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_PlaySound = surface.PlaySound
local draw_SimpleText = draw.SimpleText
local Color = Color
local CurTime = CurTime
local ScrW = ScrW
local ScrH = ScrH
local IsValid = IsValid
local tostring = tostring
local ipairs = ipairs
local LocalPlayer = LocalPlayer

local function getFontHeight(font)
	font = font or FONT
	if cachedFontHeights[font] then
		return cachedFontHeights[font]
	end

	surface_SetFont(font)
	local _, fontHeight = surface_GetTextSize('Ag')
	cachedFontHeights[font] = fontHeight
	return fontHeight
end

local function splitTextToLines(message, maxWidth, font)
	font = font or FONT
	surface_SetFont(font)
	local manualLines = string_Explode('\n', message)
	local finalLines = {}

	for _, line in ipairs(manualLines) do
		if line == '' then
			table.insert(finalLines, '')
		else
			local words = string_Explode(' ', line)
			local currentLine = ''

			for _, word in ipairs(words) do
				local testLine = currentLine == '' and word or (currentLine .. ' ' .. word)
				local testWidth = surface_GetTextSize(testLine)

				if testWidth <= maxWidth then
					currentLine = testLine
				else
					if currentLine ~= '' then
						table.insert(finalLines, currentLine)
						currentLine = word
					else
						table.insert(finalLines, word)
					end
				end
			end

			if currentLine ~= '' then
				table.insert(finalLines, currentLine)
			end
		end
	end

	return finalLines
end

local function calculateNotifWidth(message, font)
	font = font or FONT
	surface_SetFont(font)
	local lines = string_Explode('\n', message)
	local maxWidth = 0

	for _, line in ipairs(lines) do
		local lineWidth = surface_GetTextSize(line)
		maxWidth = math_max(maxWidth, lineWidth)
	end

	local totalWidth = maxWidth + TEXT_PADDING
	return math_Clamp(totalWidth, MIN_NOTIF_WIDTH, MAX_NOTIF_WIDTH)
end

local function calculateNotifHeight(message, width, font)
	font = font or FONT
	local fontHeight = getFontHeight(font)
	local maxTextWidth = width - TEXT_PADDING
	local lines = splitTextToLines(message, maxTextWidth, font)
	local textHeight = #lines * fontHeight
	return math_max(BASE_NOTIF_HEIGHT, textHeight + 30)
end

local function updateNotificationPositions()
	local toRemove = {}

	for i = #notificationStack, 1, -1 do
		local notifData = notificationStack[i]
		if not IsValid(notifData.panel) then
			table.insert(toRemove, i)
		end
	end

	for _, index in ipairs(toRemove) do
		table.remove(notificationStack, index)
	end

	local totalHeight = NOTIF_MARGIN
	for i = #notificationStack, 1, -1 do
		local notifData = notificationStack[i]
		local targetX = ScrW() - notifData.width - NOTIF_MARGIN
		local targetY = totalHeight
		notifData.panel:MoveTo(targetX, targetY, 0.3, 0, -1)
		totalHeight = totalHeight + notifData.height + NOTIF_SPACING
	end
end

local function removeNotificationFromStack(uniqueID)
	for i, notifData in ipairs(notificationStack) do
		if notifData.id == uniqueID then
			if notifData.isRemoving then return end
			notifData.isRemoving = true

			cachedLines[uniqueID] = nil

			if IsValid(notifData.panel) then
				notifData.panel:AlphaTo(0, 0.3, 0, function()
					if IsValid(notifData.panel) then
						notifData.panel:Remove()
					end
				end)
			end

			table.remove(notificationStack, i)
			timer.Simple(0.1, updateNotificationPositions)
			break
		end
	end
end

local function clearAllNotifications()
	for i, notifData in ipairs(notificationStack) do
		if IsValid(notifData.panel) then
			notifData.panel:Remove()
		end
	end

	notificationStack = {}
	cachedLines = {}
end

hook.Add('InitPostEntity', 'NotifLib_ClearNotifications', clearAllNotifications)

function notif(message, status)
	local uniqueID = 'notif_' .. string_gsub(tostring(CurTime()), '%.', '_') .. '_' .. math_random(10000, 99999) .. '_' .. LocalPlayer():EntIndex()
	local duration = 5
	status = status or 'ok'

	if not message or message == '' then
		message = 'Text not specified!'
		status = 'fail'
	end

	local startTime = CurTime()
	local notifWidth = calculateNotifWidth(message, FONT)
	local notifHeight = calculateNotifHeight(message, notifWidth, FONT)

	local notifPanel = vgui.Create('DPanel')
	notifPanel:SetSize(notifWidth, notifHeight)
	notifPanel:SetPos(ScrW() - notifWidth - NOTIF_MARGIN, -notifHeight)
	notifPanel:SetDrawOnTop(true)
	notifPanel:SetZPos(32767)
	notifPanel:SetKeyboardInputEnabled(false)
	notifPanel:SetMouseInputEnabled(false)

	local maxTextWidth = notifWidth - TEXT_PADDING
	cachedLines[uniqueID] = splitTextToLines(message, maxTextWidth, FONT)
	local cachedFontHeight = getFontHeight(FONT)

	local bgColor = status == 'ok' and Color(46, 125, 50, 200) or Color(183, 28, 28, 200)
	local progressColor = status == 'ok' and Color(76, 175, 80) or Color(244, 67, 54)

	notifPanel.Think = function(self)
		if CurTime() - startTime >= duration then
			removeNotificationFromStack(uniqueID)
		end
	end

	notifPanel.Paint = function(self, w, h)
		local currentTime = CurTime()
		local elapsed = currentTime - startTime
		local progress = math_Clamp(elapsed / duration, 0, 1)

		draw.BoxCol(0, 0, w, h, Color(bgColor.r, bgColor.g, bgColor.b, bgColor.a))

		local lines = cachedLines[uniqueID]
		if lines then
			local totalTextHeight = #lines * cachedFontHeight
			local textStartY = (h - totalTextHeight - 10) / 2

			for i, line in ipairs(lines) do
				local yPos = textStartY + (i - 1) * cachedFontHeight
				draw_SimpleText(line, FONT, w / 2, yPos, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end

		surface_SetDrawColor(0, 0, 0, 150)
		surface_DrawRect(10, h - 15, w - 20, 6)

		local progressWidth = (w - 20) * progress
		surface_SetDrawColor(progressColor.r, progressColor.g, progressColor.b, 255)
		surface_DrawRect(10, h - 15, progressWidth, 6)

		local timeLeft = math_max(0, duration - elapsed)
		local timeText = string_format('%.1fs', timeLeft)
		//draw_SimpleText(timeText, 'DermaDefault', w - 15, h - 20, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	table.insert(notificationStack, {
		id = uniqueID,
		panel = notifPanel,
		startTime = startTime,
		duration = duration,
		width = notifWidth,
		height = notifHeight,
		isRemoving = false
	})

	updateNotificationPositions()
	surface_PlaySound('ambient/water/drip4.wav')

	return notifPanel
end

function notification.AddLegacy(message, status)
	local uniqueID = 'notif_' .. string_gsub(tostring(CurTime()), '%.', '_') .. '_' .. math_random(10000, 99999) .. '_' .. LocalPlayer():EntIndex()
	local duration = 5
	status = status or 'ok'

	if not message or message == '' then
		message = 'Text not specified!'
		status = 'fail'
	end

	local startTime = CurTime()
	local notifWidth = calculateNotifWidth(message, FONT)
	local notifHeight = calculateNotifHeight(message, notifWidth, FONT)

	local notifPanel = vgui.Create('DPanel')
	notifPanel:SetSize(notifWidth, notifHeight)
	notifPanel:SetPos(ScrW() - notifWidth - NOTIF_MARGIN, -notifHeight)
	notifPanel:SetDrawOnTop(true)
	notifPanel:SetZPos(32767)
	notifPanel:SetKeyboardInputEnabled(false)
	notifPanel:SetMouseInputEnabled(false)

	local maxTextWidth = notifWidth - TEXT_PADDING
	cachedLines[uniqueID] = splitTextToLines(message, maxTextWidth, FONT)
	local cachedFontHeight = getFontHeight(FONT)

	local bgColor = status == 'ok' and Color(46, 125, 50, 200) or Color(183, 28, 28, 200)
	local progressColor = status == 'ok' and Color(76, 175, 80) or Color(244, 67, 54)

	notifPanel.Think = function(self)
		if CurTime() - startTime >= duration then
			removeNotificationFromStack(uniqueID)
		end
	end

	notifPanel.Paint = function(self, w, h)
		local currentTime = CurTime()
		local elapsed = currentTime - startTime
		local progress = math_Clamp(elapsed / duration, 0, 1)

		draw.BoxCol(0, 0, w, h, Color(bgColor.r, bgColor.g, bgColor.b, bgColor.a))

		local lines = cachedLines[uniqueID]
		if lines then
			local totalTextHeight = #lines * cachedFontHeight
			local textStartY = (h - totalTextHeight - 10) / 2

			for i, line in ipairs(lines) do
				local yPos = textStartY + (i - 1) * cachedFontHeight
				draw_SimpleText(line, FONT, w / 2, yPos, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
		end

		surface_SetDrawColor(0, 0, 0, 150)
		surface_DrawRect(10, h - 15, w - 20, 6)

		local progressWidth = (w - 20) * progress
		surface_SetDrawColor(progressColor.r, progressColor.g, progressColor.b, 255)
		surface_DrawRect(10, h - 15, progressWidth, 6)

		local timeLeft = math_max(0, duration - elapsed)
		local timeText = string_format('%.1fs', timeLeft)
		//draw_SimpleText(timeText, 'DermaDefault', w - 15, h - 20, Color(200, 200, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	table.insert(notificationStack, {
		id = uniqueID,
		panel = notifPanel,
		startTime = startTime,
		duration = duration,
		width = notifWidth,
		height = notifHeight,
		isRemoving = false
	})

	updateNotificationPositions()
	surface_PlaySound('ambient/water/drip4.wav')

	return notifPanel
end

net.Receive('NotifSystem', function()
	local message = net.ReadString()
	local status = net.ReadString()

	notif(message, status)
end)

hook.Add('ShutDown', 'NotifLib_ClearCache', function()
	cachedLines = {}
	cachedFontHeights = {}
end)