local PLAYER = FindMetaTable("Player")

function PLAYER:GetPlayTime()
    return self:GetNWInt("PlayTime")
end

function PLAYER:GetPlayTimeFormatted()
    local totalSeconds = self:GetPlayTime()
    
    local hours = math.floor(totalSeconds / 3600)
    totalSeconds = totalSeconds % 3600
    
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end