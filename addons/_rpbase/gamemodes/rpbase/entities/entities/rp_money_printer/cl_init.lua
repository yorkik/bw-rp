include('shared.lua')

local color_red 	= Color(255,50,50)
local color_yellow 	= Color(255,255,50)
local color_green 	= Color(50,255,50)
local color_grey 	= Color(50,50,50)
local color_black 	= Color(0,0,0)
local color_white 	= Color(245,245,245)

local draw_SimpleText 			= draw.SimpleText
local draw_Box 					= draw.Box
local draw_RoundedBox 			= draw.RoundedBox
local cam_Start3D2D 			= cam.Start3D2D
local cam_End3D2D 				= cam.End3D2D
local math_Clamp 				= math.Clamp
local math_Round 				= math.Round
local CurTime 					= CurTime
local IsValid 					= IsValid

local font 			= '3d2d'
local printdelay 	= cfg.printdelay

local x, y, w, h = -1442, -1024, 2200, 955
local bx1, by1, bh1, bw1 = x + 10, 	y + 200, w - 20, 225
local bx2, by2, bh2, bw2 = bx1, 	y + 445, w - 20, 225
local bx3, by3, bh3, bw3 = bx2, 	y + 690, w - 20, 225
local tx, ty = w * .5 + x, y + 30

local function predict(timeValue, value)
	return math_Clamp(math_Round((CurTime() - timeValue)/value, 2), 0, 1)
end

local function barcolor(perc)
	return ((perc <= .39) and color_red or ((perc <= .75) and color_yellow or color_green))
end

local function drawbar(x, y, w, h, perc, text)
	local s = h

	local bw = (w - 10)
	bw =  math_Clamp((bw * perc), 0, bw)

	draw_RoundedBox(0, x, y, w, h, color_grey)
	if (bw > 0) then
		draw_RoundedBox(0, x + 5, y + 5, bw, h - 10, barcolor(perc))
	end

	draw_SimpleText(text or (perc * 100 .. '%'), font, x + ((w + h) * .5), y + (h * .5), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos()
	local ang = self:GetAngles()
	local dist = LocalPlayer():GetPos():Distance(self:GetPos())
	local inView = dist <= 150000

    if (not inView) then return end

	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	
	cam_Start3D2D(pos + ang:Up() * 16.15, ang, 0.01)
		//draw_Box(x, y, w, h)

		drawbar(bx1, by1, bh1, bw1, self:GetInk()/self:GetMaxInk(), 'Чернил: ' .. self:GetInk() .. '/' .. self:GetMaxInk())
		drawbar(bx2, by2, bh2, bw2, self:GetHP()/100, 'Здоровье: ' .. self:GetHP() .. '%')

		local printperc = predict(self:GetLastPrint(), printdelay)
		drawbar(bx3, by3, bh3, bw3, printperc, 'Процесс печати: ' .. math_Clamp(printperc, 0, 1) * 100 .. '%')

		local pl = self:Getowning_ent()
		if IsValid(pl) then
			local tp, tw = draw_SimpleText(pl:Nick(), font, tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		else
			draw_SimpleText('Unknown', font, tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	cam_End3D2D()
end