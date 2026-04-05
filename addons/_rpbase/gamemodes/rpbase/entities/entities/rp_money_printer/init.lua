AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:Initialize()
	self:SetModel('models/props_c17/consolebox01a.mdl')
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:PhysWake()

	self:SetMaxInk(5)
	self:SetInk(5)
	self:SetHP(100)
	self:SetLastPrint(CurTime())

	self:EmitSound("ambient/levels/labs/equipment_printer_loop1.wav", 55, 100, 1)

	timer.Create(self:EntIndex() .. 'Print', cfg.printdelay, 0, function()
		if not IsValid(self) then timer.Destroy(self:EntIndex() .. 'Print') return end
		self:PrintMoney()
	end)
end

function ENT:Use(pl)
	pl:ChatPrint("Скоро")
end

function ENT:OnRemove()
	self:StopSound("ambient/levels/labs/equipment_printer_loop1.wav")
end

function ENT:OnTakeDamage(damageData)
	self:SetHP(self:GetHP() - damageData:GetDamage())

	if (self:GetHP() <= 0) then
		self:Explode()
	end
end

function ENT:Explode()
	timer.Destroy(self:EntIndex() .. 'Print')
	local vPoint = self:GetPos()
	local effectdata = EffectData()
	effectdata:SetStart(vPoint)
	effectdata:SetOrigin(vPoint)
	effectdata:SetScale(1)
	util.Effect('Explosion', effectdata)

	self:Remove()
end

function ENT:PrintMoney()
	if (self:GetInk() <= 0) and (self:GetHP() > 0) then
		self:SetLastPrint(CurTime())
		self:SetHP(math.Clamp(self:GetHP() - 5, 0, 100))
	elseif (self:GetHP() <= 0) then
		self:Explode()
	else
		self:SetLastPrint(CurTime())
		self:SetInk(self:GetInk() - 1)

		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		effectdata:SetMagnitude(1)
		effectdata:SetScale(1)
		effectdata:SetRadius(2)
		util.Effect('Sparks', effectdata)

		local amount = (hook.Call('calcPrintAmount', GAMEMODE, cfg.printamount) or cfg.printamount)
		local money = rp.SpawnMoney(self:GetPos() + ((self:GetAngles():Up() * 15) + (self:GetAngles():Forward() * 20)), amount)
		if IsValid(money) then
			money.PrinterMoney = true
		end
	end
end