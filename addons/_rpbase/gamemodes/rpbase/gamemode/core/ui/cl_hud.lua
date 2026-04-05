local scrw, scrh = ScrW(), ScrH()
local voice_mat = Material('hud/voice.png', 'smooth')
local baseWidth = 1920
local baseHeight = 1080
local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = true,
    ["CHudDamageIndicator"] = true,
    ["CHudWeaponSelection"] = true,
}


local function scaleWidth(width)
    return (width / baseWidth) * scrw
end

local function scaleHeight(height)
    return (height / baseHeight) * scrh
end

hook.Add("HUDShouldDraw", "donthud", function(name) if hide[name] then return false end end)

hook.Add("HUDPaint","Identifier",function()
	if !lply:Alive() then return end
	
	local trace = hg.eyeTrace(lply)
	
	if not trace then return end

	local Size = math.max(math.min(1 - trace.Fraction, 1), 0.1)
	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y

	if trace.Hit and (trace.Entity:IsRagdoll() or trace.Entity:IsPlayer()) then
		
		draw.NoTexture()
		
		local col = trace.Entity:GetPlayerColor():ToColor()
		col.a = 255 * Size * 1.5

		draw.SimpleTextOutlined(trace.Entity:GetPlayerName() or "", "HomigradFontLarge", x, y + 50, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, .6, color_black)

		if trace.Entity:GetOrg() then
			local org = trace.Entity:GetOrg() or ''
			local orgcol = trace.Entity:GetOrgColor() or color_white
            draw.SimpleTextOutlined(org, "HomigradFontLarge", x, y + 100, orgcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, .6, color_black)
		end
	end
end)

function GM:Voice()
    local colorvoice = Color(255,255,255)

    surface.SetDrawColor(colorvoice)
	surface.SetMaterial(voice_mat)
	surface.DrawTexturedRect(scrw / 2.05, scrh / 1.15, 90, 96)
end

function GM:ArrestHud()
    if lply.organism and lply.organism.otrub then return end
    if not lply:Alive() then return end
    if not lply:GetNWBool("is_arrested") then return end

    local arrestEndTime = lply:GetNWInt("arrest_end_time")
    if arrestEndTime <= CurTime() then return end

    local remainingTime = math.max(0, arrestEndTime - CurTime())
    local minutes = math.floor(remainingTime / 60)
    local seconds = math.floor(remainingTime % 60)
    local timeText = string.format("%02d:%02d", minutes, seconds)

    local x = scrw / 2
    local y = scrh / 2 + scaleHeight(200)
    local width = scaleWidth(200)
    local height = scaleHeight(120)

    draw.RoundedBoxEx(6, x - width / 2, y - height / 2, width, height, Color(10, 0, 0, 160), true, true, true, true)
    draw.DrawText("ВЫ АРЕСТОВАНЫ", "ui.24", x, y - scaleHeight(35), Color(255, 50, 50), TEXT_ALIGN_CENTER)
    draw.DrawText("Осталось: " .. timeText, "ui.18", x, y - scaleHeight(5), Color(255, 255, 100), TEXT_ALIGN_CENTER)
    draw.DrawText("Причина: " .. (lply:GetNWString("arrest_reason") or "Не указано"), "ui.18", x, y + scaleHeight(20), Color(255, 255, 255), TEXT_ALIGN_CENTER)
end



function GM:HUDPaint()
    if lply:Alive() then
		if lply:IsArrested() then self:ArrestHud() end
        if lply:IsSpeaking() then
            self:Voice()
        end
    end
end