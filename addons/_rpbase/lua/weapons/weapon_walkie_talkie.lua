if SERVER then 
	AddCSLuaFile() 
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Рация"
SWEP.Instructions = "Use the walkie-talkie to communicate with other people in the 4km radius. Must be on the same frequency."
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/sirgibs/ragdoll/css/terror_arctic_radio.mdl"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_walkietalkie")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_walkietalkie.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 5
SWEP.SlotPos = 5
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(6, 5.5, -41)
SWEP.offsetAng = Angle(180, 160, 180)

SWEP.Frequency = 1
SWEP.Frequencies = {
	"Полиция",
	"SWAT",
}

function SWEP:BippSound(ent, pitch)
	ent:EmitSound("radio/voip_end_transmit_beep_0" .. math.random(1,8) .. ".wav", 35, pitch)
end

if SERVER then

	function SWEP:CanCommunicate(listener, speaker)
		if not IsValid(listener) or not IsValid(speaker) then return false end
		if not listener:Alive() or not speaker:Alive() then return false end
		if listener.organism.otrub or speaker.organism.otrub then return false end
		if not speaker:HasWeapon("weapon_walkie_talkie") then return false end
		if IsValid(listener:GetActiveWeapon()) and listener:GetActiveWeapon():GetClass() ~= "weapon_walkie_talkie" then return false end

		local listenerWep = listener:GetWeapon("weapon_walkie_talkie")
		local speakerWep = speaker:GetWeapon("weapon_walkie_talkie")

		if not IsValid(listenerWep) or not IsValid(speakerWep) then return false end

		return listenerWep.Frequency == speakerWep.Frequency or listener:Team() == 1002
	end

	function SWEP:IsInRange(listener, speaker)
		return listener:GetPos():DistToSqr(speaker:GetPos()) <= 16000000 -- 4000^2
	end

	-- Voice communication
	hook.Add("PlayerCanHearPlayersVoice", "WalkieTalkie_Voice", function(listener, speaker)
		local wep = speaker:GetWeapon("weapon_walkie_talkie")
		if not IsValid(wep) then return end

		if wep:CanCommunicate(listener, speaker) and wep:IsInRange(listener, speaker) then
			wep:BippSound(speaker, 100)
			if listener ~= speaker then
				wep:BippSound(listener, 100)
			end
			return true, false
		end
	end)

	-- Chat communication
	hook.Add("PlayerCanSeePlayersChat", "WalkieTalkie_Chat", function(listener, speaker, text, isTeam, isDead)
		if isTeam or isDead then return end

		local wep = speaker:GetWeapon("weapon_walkie_talkie")
		if not IsValid(wep) then return end

		if wep:CanCommunicate(listener, speaker) then
			if wep:IsInRange(listener, speaker) then
				wep:BippSound(speaker, 100)
				if listener ~= speaker then
					wep:BippSound(listener, 100)
				end
				return true
			else
				speaker:ChatPrint("Рация: " .. text)
				return false
			end
		end
	end)

	function SWEP:OnRemove()
	end

end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModel2()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local WorldModel = self.model
	local owner = hg.GetCurrentCharacter(self:GetOwner())

	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale or 1)

	if IsValid(owner) then
		local offsetVec = self.offsetVec
		local offsetAng = self.offsetAng
		local boneid = owner:LookupBone("ValveBiped.Bip01_L_Hand")

		if not boneid then return end

		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end

		local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
	end

	WorldModel:DrawModel()
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:Think()
	self:SetHold(self.HoldType)
end

function SWEP:PrimaryAttack()
	if SERVER then
		self.Frequency = ((self.Frequency <= #self.Frequencies - 1) and self.Frequency + 1 or 1)
		self:GetOwner():ChatPrint('Канал: ' .. self.Frequencies[self.Frequency])
	end
end

if CLIENT then
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		if LocalPlayer():InVehicle() then return end
	end
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
end

function SWEP:SecondaryAttack()
	if SERVER then
		self.Frequency = ((self.Frequency > 1) and self.Frequency - 1 or #self.Frequencies)
		self:GetOwner():ChatPrint('Канал: ' .. self.Frequencies[self.Frequency])
	end
end

function SWEP:Reload()
end

if SERVER then
	function SWEP:SetFakeGun(ent)
		self:SetNWEntity("fakeGun", ent)
		self.fakeGun = ent
	end

	function SWEP:RemoveFake()
		if not IsValid(self.fakeGun) then return end
		self.fakeGun:Remove()
		self:SetFakeGun()
	end

	SWEP.RHandPos = Vector(0, 0, 0)

	function SWEP:CreateFake(ragdoll)
		if IsValid(self:GetNWEntity("fakeGun")) then return end

		local ent = ents.Create("prop_physics")
		local lh = ragdoll:GetPhysicsObjectNum(5)
		local rh = ragdoll:GetPhysicsObjectNum(7)

		rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
		rh:SetAngles(self:GetOwner():EyeAngles() + Angle(0, 0, -90))
		lh:SetPos(rh:GetPos())

		ent:SetModel(self.WorldModel)
		ent:SetPos(rh:GetPos())
		ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
		ent:Spawn()

		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetOwner(ragdoll)
		ent:GetPhysicsObject():SetMass(0)
		ent:SetNoDraw(true)
		ent.dontPickup = true
		ent.fakeOwner = self

		ragdoll:DeleteOnRemove(ent)
		ragdoll.fakeGun = ent

		if IsValid(ragdoll.ConsRH) then ragdoll.ConsRH:Remove() end

		self:SetFakeGun(ent)
		ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)

		local vec = Vector(0, 0, 0)
		vec:Set(-self.RHandPos or vector_origin)
		vec:Rotate(ent:GetAngles())

		rh:SetPos(ent:GetPos() + vec)
	end

	function SWEP:RagdollFunc(pos, angles, ragdoll)
		shadowControl = shadowControl or hg.ShadowControl
		local fakeGun = ragdoll.fakeGun
		shadowControl(ragdoll, 5, 0.001, angles, 500, 30, pos, 500, 50)
	end
end