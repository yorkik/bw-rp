local PLAYER = FindMetaTable("Player")

function IsCop(classObj)
    if not classObj or not classObj.Name or not cfg or not cfg.civilprotection then
        return false
    end
    return cfg.civilprotection[classObj.Name] == true
end

function IsSWAT(classObj)
    if not classObj or not classObj.Name or not cfg or not cfg.swat then
        return false
    end
    return cfg.swat[classObj.Name] == true
end

function PLAYER:IsArrested()
    return self:GetNWBool("is_arrested", false)
end

function PLAYER:IsWanted()
    return self:GetNWBool("is_wanted", false)
end