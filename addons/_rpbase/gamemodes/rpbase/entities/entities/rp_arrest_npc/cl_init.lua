include("shared.lua")

ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()
end

local color_white = Color(255, 255, 255)
local color_black = Color(0, 0, 0)
local complex_off = Vector(0, 0, 9)
local ang = Angle(0, 90, 90)

function ENT:Draw()
    self:DrawModel()

    local bone = self:LookupBone('ValveBiped.Bip01_Head1')
    if not bone then return end
    
    local pos = self:GetBonePosition(bone) + complex_off
    ang.y = (LocalPlayer():EyeAngles().y - 90)

    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    local inView = dist <= 150000

    if (not inView) then return end

    local alpha = 255 - (dist/590)
    color_white.a = alpha
    color_black.a = alpha

    local x = math.sin(CurTime() * math.pi) * 30

    cam.Start3D2D(pos, ang, 0.03)
        draw.SimpleTextOutlined('Тюремщик', '3d2d', 0, x, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
    cam.End3D2D()
end

net.Receive("OpenArrestMenu", function()
    local npc = net.ReadEntity()
    local players = net.ReadTable()

    if not IsValid(npc) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 350)
    frame:Center()
    frame:SetTitle("Арестовать игрока")
    frame:SetVisible(true)
    frame:MakePopup()

    local combo = vgui.Create("DComboBox", frame)
    combo:SetPos(50, 50)
    combo:SetSize(300, 20)
    combo:SetText("Выберите игрока")

    for _, plyData in ipairs(players) do
        local ply = Player(plyData.id)
        if ply and IsValid(ply) then
            combo:AddChoice(plyData.name, plyData.id)
        end
    end

    local slider = vgui.Create("DNumSlider", frame)
    slider:SetPos(50, 90)
    slider:SetSize(300, 30)
    slider:SetText("Время ареста (сек)")
    slider:SetMin(120)
    slider:SetMax(900)
    slider:SetDecimals(0)
    slider:SetValue(120)

    local textEntry = vgui.Create("DTextEntry", frame)
    textEntry:SetPos(50, 140)
    textEntry:SetSize(300, 25)
    textEntry:SetText("Причина ареста")
    textEntry:SetTooltip("Введите причину ареста")

    local button = vgui.Create("DButton", frame)
    button:SetPos(150, 190)
    button:SetSize(100, 30)
    button:SetText("Арестовать")
    button.DoClick = function()
        local _, userID = combo:GetSelected()
        local time = math.Round(slider:GetValue())
        local reason = textEntry:GetValue()

        if userID == nil then
            chat.AddText(Color(255, 0, 0), "Выберите игрока!")
            return
        end

        if not reason or reason == "" or reason == "Причина ареста" then
            chat.AddText(Color(255, 0, 0), "Напишите причину!")
            return 
        end

        net.Start("RequestArrestPlayer")
            net.WriteEntity(npc)
            net.WriteUInt(userID, 16)
            net.WriteUInt(time, 16)
            net.WriteString(reason)
        net.SendToServer()
        frame:Close()
    end
end)