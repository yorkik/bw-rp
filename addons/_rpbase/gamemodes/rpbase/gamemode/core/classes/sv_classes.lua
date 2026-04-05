function rp.SetPlayerClass(ply, classObj)
    if not ply:IsValid() then return end
    if not classObj or not classObj.Name then return end

    if not rp.Classes[classObj.Name] then return end

    local oldClass = ply:GetNWString("Jobs", "")

    ply:SetNWString("Jobs", classObj.Name)
    ply:KillSilent()
    
    timer.Simple(0.1, function()
        hook.Run("OnPlayerChangedClass", ply, oldClass, classObj.Name)
    end)
end