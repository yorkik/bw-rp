local PLAYER = FindMetaTable('Player')


timer.Create('HungerTick', cfg.hungerrate, 0, function()
    for _, v in ipairs(player.GetAll()) do
        if v:InSpawnZone() or not v:Alive() then return end


        if v:GetHunger() <= 20 then
            v:EmitSound("zcitysnd/uni/hungry_"..math.random(1,6)..".mp3")
        end

        if v:GetHunger() < 10 then
            local org = v.organism
            org.painadd = org.painadd + 50
            v:EmitSound("zcitysnd/uni/hungry_"..math.random(1,6)..".mp3")
        end

        if v:GetHunger() > 0 then
            v:TakeHunger(cfg.hungertake)
        end

        if v:GetHunger() <= 0 and v:Alive() then
            v:Kill()
        end
    end
end)


function PLAYER:SetHunger(amount)
	self:SetNetVar('Energy', amount)
end

function PLAYER:AddHunger(amount)
	self:SetHunger(self:GetHunger() + amount)
end

function PLAYER:TakeHunger(amount)
	self:AddHunger(-math.abs(amount))
end

hook.Add('PlayerSpawn', 'SetupHunger', function(pl)
	pl:SetHunger(100)
end)