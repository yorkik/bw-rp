include("shared.lua")

local color_white = Color(255, 255, 255)
local color_black = Color(0, 0, 0)
local complex_off = Vector(0, 0, 9)

function ENT:CalculateRenderPos()
    local vec = self:GetAngles():Forward() + self:GetAngles():Right() * -1 + self:GetAngles():Up() * -.5
    local pos = self:GetPos() + vec
    return pos
end

function ENT:CalculateRenderAng()
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 180)
    ang:RotateAroundAxis(ang:Forward(), 90)
    return ang
end

function ENT:Draw()
    self:DrawModel()
    
    local pos, ang = self:CalculateRenderPos(), self:CalculateRenderAng()
    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    local inView = dist <= 500
    if not inView then return end

    local alpha = 255 - (dist / 2)
    color_white.a = alpha
    color_black.a = alpha

    local x = math.sin(CurTime() * math.pi) * 0

    cam.Start3D2D(pos, ang, 0.03)
        draw.SimpleTextOutlined(self.NpcName, '3d2d', 0, x, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
    cam.End3D2D()
end

local selectedClass = nil

local function StartPoliceQuiz(selectedClass)
    local quizFrame = vgui.Create("DFrame")
    quizFrame:SetSize(500, 400)
    quizFrame:Center()
    quizFrame:SetTitle("Тест на вступление в полицию")
    quizFrame:SetVisible(true)
    quizFrame:MakePopup()
    quizFrame:SetDraggable(true)

    local questions = {
        {
            text = "Когда офицер может применить смертоносную силу?",
            options = {
                "При любом подозрении в преступлении",
                "Когда угроза смерти или вреда жизни",
                "Только после трех предупреждений",
                "Когда подозреваемый убегает",
            },
            correct = 2
        },
        {
            text = "Что должны содержать права при аресте?",
            options = {
                "Право на адвоката и хранить молчание",
                "Право на звонок родственникам",
                "Право отказаться от ареста",
                "Право требовать судью на месте"
            },
            correct = 1
        },
        {
            text = "Когда требуется ордер для обыска жилого помещения?",
            options = {
                "Всегда, без исключений",
                "Только для поиска нелегала",
                "Когда нет добровольного согласия или экстренных обстоятельств",
                "Только в дневное время"
            },
            correct = 3
        },
        {
            text = "Какое действие является приоритетным при остановке ТС?",
            options = {
                "Немедленный обыск автомобиля",
                "Обеспечение безопасности и идентификация водителя",
                "Требование покинуть автомобиль",
                "Проверка багажника первым делом"
            },
            correct = 2
        }
    }

    local currentQuestion = 1

    local questionLabel = vgui.Create("DLabel", quizFrame)
    questionLabel:SetPos(20, 50)
    questionLabel:SetSize(460, 100)
    questionLabel:SetWrap(true)
    questionLabel:SetContentAlignment(7)
    questionLabel:SetAutoStretchVertical(true)

    local answerPanel = vgui.Create("DScrollPanel", quizFrame)
    answerPanel:SetPos(20, 160)
    answerPanel:SetSize(460, 200)
    answerPanel.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
    end

    local function ShowQuestion(index)
        local q = questions[index]
        questionLabel:SetText(q.text)
        questionLabel:SetFont('ui.20')
        answerPanel:Clear()

        local btnWidth = answerPanel:GetWide() - 20
        local btnHeight = 40
        local spacing = 10
        local startY = 10

        for i, option in ipairs(q.options) do
            local btn = vgui.Create("DButton", answerPanel)
            btn:SetText(option)
            btn:Dock(TOP)
            btn:DockMargin(5,5,5,5)
            btn:SetSize(btnWidth, btnHeight)
            btn.DoClick = function()
                if i == q.correct then
                    if index == #questions then
                        quizFrame:Close()
                        net.Start("PlayerSelectJob")
                            net.WriteString(selectedClass.Name)
                        net.SendToServer()
                        chat.AddText(Color(0, 255, 0), "Поздравляем! Вы прошли тест и приняты на службу!")
                    else
                        currentQuestion = index + 1
                        ShowQuestion(currentQuestion)
                    end
                else
                    chat.AddText(Color(255, 0, 0), "Неверный ответ! Попробуйте ещё раз.")
                    quizFrame:Close()
                end
            end
        end
    end

    if #questions > 0 then
        ShowQuestion(1)
    else
        chat.AddText(Color(255, 0, 0), "Ошибка: тест недоступен.")
        quizFrame:Close()
    end
end

net.Receive("OpenJob.PoliceMenu", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 250)
    frame:Center()
    frame:SetTitle("Полиция")
    frame:SetVisible(true)
    frame:MakePopup()

    local combo = vgui.Create("DComboBox", frame)
    combo:SetPos(50, 50)
    combo:SetSize(300, 20)
    combo:SetText("Выберите профессию")

    for _, rpclass in ipairs(rp.Classes) do
        if rpclass and table.HasValue(joballowed, rpclass) then
            combo:AddChoice(rpclass.Name)
        end
    end

    if not table.HasValue(joballowed, LocalPlayer():GetPlayerClass()) then
        local button = vgui.Create("DButton", frame)
        button:SetPos(150, 190)
        button:SetSize(100, 30)
        button:SetText("Устроиться")
        button.DoClick = function()
            local selectedName = combo:GetValue()
            if selectedName == "Выберите профессию" or selectedName == "" then
                chat.AddText(Color(255, 0, 0), "Выберите профессию!")
                return
            end
    
            for _, cls in ipairs(rp.Classes) do
                if cls.Name == selectedName then
                    selectedClass = cls
                    break
                end
            end
    
            frame:Close()

            if not table.HasValue(joballowed, LocalPlayer():GetPlayerClass()) then StartPoliceQuiz(selectedClass) end
        end
    else
        local buttondem = vgui.Create("DButton", frame)
        buttondem:SetPos(150, 190)
        buttondem:SetSize(100, 30)
        buttondem:SetText("Уволится")
        buttondem.DoClick = function()
            frame:Close()
            net.Start("PlayerSelectJob")
                net.WriteString('Гражданин')
            net.SendToServer()
        end
    end
end)