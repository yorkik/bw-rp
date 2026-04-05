AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:Initialize()
	self:SetModel('models/props_lab/reciever01d.mdl')
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	self:PhysWake()

	self:SetTrigger(true)
end

function ENT:StartTouch(ent)
	if (not self.Used) and IsValid(ent) and (ent:GetClass() == 'rp_money_printer') then
		if ent:GetMaxInk() >= 5 then return end
		self.Used = true
		self:Remove()
		//ent:SetMaxInk(ent:GetMaxInk() + 1)
		ent:SetInk(ent:GetMaxInk() + 1)
		ent:EmitSound('ambient/energy/weld2.wav')
	end
end