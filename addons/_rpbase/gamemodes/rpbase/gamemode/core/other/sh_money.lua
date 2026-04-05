local PLAYER = FindMetaTable('Player')
local string_comma = string.Comma

function PLAYER:GetMoney()
    return self:GetNWInt("Money", 0)
end

function FormatMoney(a)
    return string_comma(a) .. "$"
end