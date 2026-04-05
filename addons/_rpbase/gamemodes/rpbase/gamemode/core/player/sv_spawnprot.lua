local PLAYER = FindMetaTable("Player")

function PLAYER:InSpawnZone()
    local zones = cfg.spawnzone[game.GetMap()]
    
    if not zones then return false end
    
    if self.IsInSpawnZone and (self.IsInSpawnZone >= CurTime()) then return true end
    
    local pos = self:GetPos()
    
    for i = 1, #zones, 2 do
        if pos:WithinAABox(zones[i], zones[i + 1]) then
            self.IsInSpawnZone = CurTime() + 0.1
            return true
        end
    end
    
    return false
end

hook.Add("PlayerSpawnProp", "SpawnZonePropBlock", function(ply, model)
    if ply:InSpawnZone() then
        notif(ply, "Вы не можете спавнить пропы на спавне!", 'fail')
        return false
    end
end)

hook.Add("PlayerButtonDown", "SpawnZoneBlockButtons", function(ply, button)
    if ply:InSpawnZone() then
        if button == IN_ATTACK or button == IN_ATTACK2 then
            return false
        end
    end
end)

hook.Add("PlayerButtonUp", "SpawnZoneBlockButtonsUp", function(ply, button)
    if ply:InSpawnZone() then
        if button == IN_ATTACK or button == IN_ATTACK2 then
            return false
        end
    end
end)