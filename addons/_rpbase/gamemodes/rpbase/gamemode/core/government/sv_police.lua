local PLAYER = FindMetaTable('Player')

--- [[ АРЕСТ ]] ---

local function JailPos()
    local map = game.GetMap()
    local spawns = cfg.arrestpos[map]
    
    if spawns and #spawns > 0 then
        return spawns[math.random(1, #spawns)]
    end
    
    return Vector(0, 0, 0)
end

function PLAYER:Arrest(time, reason, arrester)
    if not self:IsValid() then return end

    local actualTime = time or cfg.arresttime
    local endTime = CurTime() + actualTime

    self:SetNWInt("arrest_end_time", endTime)
    self:SetNWString("arrest_reason", reason or "Не указано")

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self)
    end

    self:StripWeapons()
    self:Give("weapon_hands_sh")
    timer.Simple(0.2, function()
        if self:IsValid() then
            self:SetPos(JailPos())
        end
    end)

    if self:IsWanted() then
        self:UnWanted()
    end

    if self:IsHandcuffed() then
        local org = self.organism
        if org then
            org.handcuffed = false
        end
        self:SetNetVar("handcuffed", false)
    end

    self:SetNWBool("is_arrested", true)
    hook.Run("playerArrested", self, time, reason, arrester)
    //self:ChatPrint(string.format("Вы арестованы! Причина: %s. Время: %d секунд.", reason or "Не указано", actualTime))


    timer.Create("arrest_release_" .. self:SteamID(), actualTime, 1, function()
        if self:IsValid() then
            self:UnArrest()
        end
    end)
end

function PLAYER:UnArrest()
    if not self:IsValid() then return end

    timer.Remove("arrest_release_" .. self:SteamID())
    self:SetNWBool("is_arrested", false)
    self:SetNWInt("arrest_end_time", 0)
    self:SetNWString("arrest_reason", "")
    self:Spawn()
    hook.Run("playerUnArrested", self)
    //self:ChatPrint("Вы освобождены из ареста!")
end

hook.Add("PlayerInitialSpawn", "RestoreArrestTime", function(ply)
    if not ply:IsValid() or not ply:GetNWBool("is_arrested") then return end

    local endTime = ply:GetNWInt("arrest_end_time")
    local remaining = math.max(0, endTime - CurTime())

    if remaining > 0 then
        ply:Arrest(remaining, ply:GetNWString("arrest_reason"))
    else
        ply:UnArrest()
    end
end)

hook.Add("PlayerSpawn", "RestoreArrestPos", function(pl)
    if OverrideSpawn then return false end
    if pl:GetNWBool("is_arrested") then
        timer.Simple(.1, function()
            pl:StripWeapons()
            pl:Give("weapon_hands_sh")
            pl:SetPos(JailPos())    
        end)
    end
end)


--- [[ РОЗЫСК ]] ---
function PLAYER:Wanted(reason, officer)
    if not self:IsValid() then return end

    self:SetNWInt("wanted_time", time or cfg.wantedtime)
    self:SetNWString("wanted_reason", reason or "Не указано")
    
    self:SetNWBool("is_wanted", true)
    
    self:ChatPrint("Вы находитесь под розыском! Причина: " .. reason)
    hook.Run("playerWanted", self, reason, officer)
    
    timer.Simple(0, function()
        if not self:IsValid() then return end
        
        local remaining = self:GetNWInt("wanted_time")
        if remaining > 0 then
            timer.Create("wanted_timer_" .. self:SteamID(), 1, 0, function()
                if not self:IsValid() then timer.Remove("wanted_timer_" .. self:SteamID()) return end
                
                remaining = self:GetNWInt("wanted_time")
                if remaining <= 0 then
                    timer.Remove("wanted_timer_" .. self:SteamID())
                    self:UnWanted()
                    return
                end
                
                self:SetNWInt("wanted_time", remaining - 1)
            end)
        end
    end)
end

function PLAYER:UnWanted(officer)
    if not self:IsValid() then return end

    self:SetNWBool("is_wanted", false)
    self:SetNWInt("wanted_time", 0)
    self:SetNWString("wanted_reason", "")

    self:ChatPrint("Розыск снят!")
    hook.Run("playerUnWanted", self)
end

hook.Add("PlayerInitialSpawn", "RestoreWantedTime", function(ply)
    if not ply:IsValid() then return end
    
    if ply:IsWanted() then
        local remaining = ply:GetNWInt("wanted_time")
        if remaining > 0 then
            ply:Wanted(remaining, ply:GetNWString("wanted_reason"))
        else
            ply:UnWanted()
        end
    end
end)