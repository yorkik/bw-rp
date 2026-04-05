AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString('OpenJob.PoliceMenu')
util.AddNetworkString("PlayerSelectJob")

function ENT:Initialize()
    self:SetModel( self.NpcModel )
	self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:AcceptInput(name, ply)
    if name == "Use" && ply:IsPlayer() then
        net.Start("OpenJob.PoliceMenu")
        net.Send(ply)
    end
end

net.Receive("PlayerSelectJob", function(len, ply)
    local jobName = net.ReadString()

    local targetClass = nil
    for _, cls in ipairs(rp.Classes) do
        if cls.Name == jobName then
            targetClass = cls
            break
        end
    end

    if table.HasValue(joballowed, ply) then return end

    rp.SetPlayerClass(ply, targetClass)
end)