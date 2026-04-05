local PLAYER = FindMetaTable('Player')

function PLAYER:GiveSalary(num)
    if num <= 0 then return end

    local tax = math.Round(num * cfg.tax)
    local netSalary = num - tax

    if netSalary <= 0 then return end

    hook.Run("playerGetSalary", self, netSalary)
    notif(self, "Зарплата! Вы получили " .. FormatMoney(netSalary), 'ok')
end