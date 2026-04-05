local PLAYER = FindMetaTable('Player')

rp.Classes = {}

function rp.CreateClass(jobData)
    if not jobData or type(jobData) ~= "table" then return nil end

    local name = jobData.name or jobData.Name
    if not name or type(name) ~= "string" then return nil end

    local color = jobData.color or jobData.Color or Color(255, 255, 255)

    local model = jobData.model or jobData.Model or {}
    if type(model) ~= "table" then model = {model} end

    local weapons = jobData.weapons or jobData.Weapons or {}
    if type(weapons) ~= "table" then weapons = {weapons} end

    local ammo = jobData.ammo or jobData.Ammo or {}
    if type(ammo) ~= "table" then ammo = {ammo} end


    local spawn = jobData.spawn or jobData.Spawn or {}
    if type(spawn) ~= "table" then spawn = {map = {Vector(0, 0, 0)}} end

    local classTable = {
        Name = name,
        Color = color,
        Model = model,
        Weapons = weapons,
        Ammo = ammo,
        Spawn = spawn,
    }

    rp.Classes[name] = classTable
    table.insert(rp.Classes, classTable)
    return classTable
end

function PLAYER:GetPlayerClass()
    local className = self:GetNWString("Jobs", nil)
    if className and rp.Classes[className] then
        return rp.Classes[className]
    end
    return nil
end

function rp.GetClassName(classObj)
    if classObj and classObj.Name then
        return classObj.Name
    else
        return nil
    end
end

function rp.GetClassColor(classObj)
    if classObj and classObj.Color then
        return classObj.Color
    else
        return Color(255, 255, 255)
    end
end