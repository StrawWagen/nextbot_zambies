AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS(ENT.Base)
ENT.PrintName = "Zombie Spirit"
ENT.Author = "Octantis Addons"
ENT.Category = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

list.Set("NPC", "terminator_nextbot_zambiespirit", {
	Name = "Zombie Spirit",
	Class = "terminator_nextbot_zambiespirit",
	Category = "Nextbot Zambies",
})

if CLIENT then
	language.Add("terminator_nextbot_zambiespirit", ENT.PrintName)
end

local ZOMBIE_COLOR = Color(100, 180, 100)
local ZAMBIE_PREFIX = "terminator_nextbot_zambie"
local ZAMBIE_PREFIX_LEN = #ZAMBIE_PREFIX

local function PackSquadVectors(center, count, radius)
	local results = {}
	local attempts = count * 6
	local angleStep = (math.pi * 2) / attempts

	for i = 0, attempts - 1 do
		if #results >= count then break end

		local angle = i * angleStep
		local pos = center + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		local area = navmesh.GetNearestNavArea(pos, false, 128)

		if area then
			local snapped = area:GetClosestPointOnArea(pos)
			local tooClose = false

			for _, v in ipairs(results) do
				if v:DistToSqr(snapped) < (radius * 0.4) ^ 2 then
					tooClose = true
					break
				end
			end

			if not tooClose then
				table.insert(results, snapped)
			end
		end
	end

	return results, #results >= count
end

local function NPC_GetRowdy(ent)
	if ent.SetSchedule then
		ent:SetSchedule(SCHED_PATROL_RUN)
	end
end

local function GetFPSEstimate()
	local ft = FrameTime()
	if ft <= 0 then return 60 end
	return 1 / ft
end

local function SafeGoto(bot, pos)
	if not isvector(pos) then return end
	local area = navmesh.GetNearestNavArea(pos, false, 512)
	if not area then return end
	local snapped = area:GetClosestPointOnArea(pos)
	if not isvector(snapped) then return end
	pcall(bot.GotoPosSimple, bot, snapped)
end

function ENT:SetupDataTables()
	if BaseClass.SetupDataTables then
		BaseClass.SetupDataTables(self)
	end
	self:NetworkVar("Bool", 10, "IsDying")
	self:NetworkVar("Float", 10, "DeathTime")
	self:NetworkVar("Int", 10, "CarriedNPCCount")
end

if SERVER then
	function ENT:AdditionalInitialize()
		BaseClass.AdditionalInitialize(self)
		self:SetBodygroup(1, 0)
	end
end

ENT.GiveShieldAmount = 25
ENT.GiveShieldRegen = 7
ENT.GiveShieldRegenDelay = 3
ENT.DeployDistance = 1000
ENT.GrabDistance = 666
ENT.GiveShieldDistance = 666
ENT.MinGrabDist = 1500

ENT.GrabBlacklist = {
	["terminator_nextbot_zambietank"] = true,
	["terminator_nextbot_zambietankelite"] = true,
	["terminator_nextbot_zambienecro"] = true,
	["terminator_nextbot_zambienecroelite"] = true,
	["terminator_nextbot_zambiecop"] = true,
	["terminator_nextbot_zambiebigheadcrab"] = true,
	["terminator_nextbot_zambiebiggerheadcrab"] = true,
	["terminator_nextbot_zambieglasstitan"] = true,
	["terminator_nextbot_zambiereanimator"] = true,
	["terminator_nextbot_zambiereanimatorelite"] = true,
}

ENT.MyClassTask = {
	OnCreated = function(self, data)
		data.npcCarryGoal = math.random(3, 5)
		data.wantToCarry = true
		data.carryCooldown = 0
		data.nextMove = 0
	end,

	OnDamaged = function(self, data, dmg)
		if self:GetIsDying() then return true end

		local melee = bit.band(dmg:GetDamageType(), bit.bor(DMG_SLASH, DMG_CLUB)) > 0
		local damage = dmg:GetDamage()

		if melee then
			damage = damage * 2.2
		elseif damage < 25 then
			damage = damage * 0.2
		end

		self:SetHealth(self:Health() - damage)

		if self:Health() <= 0 then
			self:SetHealth(1)
			local v = dmg:GetDamageForce()
			local len = v:Length()
			if len > 0 then
				v:Div(len)
				v:Mul(120)
			end
			self:SpiritDeath(dmg:GetAttacker(), dmg:GetInflictor(), v)
		else
			local v = self:GetVelocity()
			v.z = v.z + 2
			v:Mul(2.5)
			self:SetVelocity(v)
		end

		return true
	end,

	OnKilled = function(self, data, attacker, inflictor, ragdoll)
		if IsValid(ragdoll) then
			ragdoll:Remove()
		end
	end,

	PreventBecomeRagdollOnKilled = function(self, data, dmg)
		return true, true
	end,

	DisableBehaviour = function(self, data)
		return self:GetIsDying()
	end,

	BehaveUpdatePriority = function(self, data)
		if self:GetIsDying() then return end

		if data.wantToCarry and self:GetCarriedNPCCount() > 0 then
			local enemy = self:GetEnemy()
			if IsValid(enemy) then
				local enemyPos = enemy:GetPos()
				if isvector(enemyPos) and enemyPos:DistToSqr(self:GetPos()) < self.GrabDistance ^ 2 then
					data.wantToCarry = false
				end
			end
		end

		local enemy = self:GetEnemy()
		if IsValid(enemy) then
			local selfPos = self:GetPos()
			local enemyPos = enemy:GetPos()

			if not isvector(selfPos) or not isvector(enemyPos) then return end

			local dist2 = enemyPos:DistToSqr(selfPos)

			if dist2 < (self.DeployDistance / 2) ^ 2 then
				local diff = selfPos - enemyPos
				local diffLen = diff:Length()
				if diffLen > 1 then
					diff:Div(diffLen)
					diff:Mul(512)
					local fleeTarget = selfPos + diff
					local fleeArea = navmesh.GetNearestNavArea(fleeTarget, false, 512)
					if fleeArea then
						SafeGoto(self, fleeArea:GetClosestPointOnArea(fleeTarget))
					end
				end
				return
			end

			if self:GetCarriedNPCCount() > 0 then
				local viscon = self:Visible(enemy) and dist2 < self.DeployDistance ^ 2
				if viscon and (not data.carryCooldown or CurTime() > data.carryCooldown) then
					self:DeployNPCs(enemyPos)
					data.carryCooldown = CurTime() + 5
					data.wantToCarry = true
				end
			end
		end

		if not data.carryCooldown or CurTime() > data.carryCooldown then
			if data.wantToCarry then
				for _, npc in ipairs(ents.FindInSphere(self:WorldSpaceCenter(), self.GrabDistance)) do
					if self:IsGoodGrabTarget(npc) and self:Visible(npc) then
						local npcEnemy = npc:GetEnemy()
						if not IsValid(npcEnemy) or npcEnemy:GetPos():DistToSqr(npc:GetPos()) > self.MinGrabDist ^ 2 then
							self:CarryNPC(npc)
							data.carryCooldown = CurTime() + 0.25
							break
						end
					end
				end

				if self:GetCarriedNPCCount() >= data.npcCarryGoal then
					data.wantToCarry = false
					data.carryCooldown = CurTime() + 1
				end
			end
		end
	end,

	BehaveUpdateMotion = function(self, data)
		if self:GetIsDying() then return end

		local enemy = self:GetEnemy()
		if not IsValid(enemy) then
			data.wantToCarry = true
			return
		end

		local enemyPos = enemy:GetPos()
		local selfPos = self:GetPos()

		if not isvector(enemyPos) or not isvector(selfPos) then return end

		if selfPos:DistToSqr(enemyPos) < (self.DeployDistance / 2) ^ 2 then return end

		if not data.wantToCarry then
			if self:GetCarriedNPCCount() <= 0 then
				data.wantToCarry = true
			end
			return
		end

		local canMove = CurTime() > (data.nextMove or 0)
		local bestDist2 = self.MinGrabDist ^ 2
		local furthest
		local furthestPos

		for _, npc in ipairs(ents.FindByClass("terminator_nextbot_zambie*")) do
			if not self:IsGoodGrabTarget_optimised(npc) then continue end
			local npcPos = npc:GetPos()
			if not isvector(npcPos) then continue end
			local dist2 = npcPos:DistToSqr(enemyPos)
			if dist2 > bestDist2 then
				furthest = npc
				furthestPos = npcPos
				bestDist2 = dist2
			end
		end

		if IsValid(furthest) and isvector(furthestPos) then
			if canMove or furthestPos:DistToSqr(selfPos) >= (self.GrabDistance / 2) ^ 2 then
				local gotoPos = furthest:GetPos()
				if isvector(gotoPos) then
					SafeGoto(self, gotoPos)
					data.nextMove = CurTime() + 5
				end
			end
		else
			data.wantToCarry = false
		end
	end,
}

function ENT:IsValidZambieClass(class)
	return string.sub(class, 1, ZAMBIE_PREFIX_LEN) == ZAMBIE_PREFIX and not self.GrabBlacklist[class]
end

function ENT:IsGoodGrabTarget(target)
	return IsValid(target)
		and self:IsValidZambieClass(target:GetClass())
		and target ~= self
		and target:Health() > 0
		and not IsValid(target:GetParent())
		and target:GetMoveType() > MOVETYPE_NONE
end

function ENT:IsGoodGrabTarget_optimised(target)
	return IsValid(target)
		and self:IsValidZambieClass(target:GetClass())
		and target:Health() > 0
		and not IsValid(target:GetParent())
end

function ENT:SpiritDeath(attacker, inflictor, forceVec)
	if self:GetIsDying() then return end

	self:SetIsDying(true)
	self:SetDeathTime(CurTime())

	self:DeployNPCs()

	local valids = {}
	for _, npc in ipairs(ents.FindInSphere(self:WorldSpaceCenter(), self.GiveShieldDistance)) do
		if IsValid(npc) and npc:Health() > 0 and (npc:IsPlayer() or npc:IsNPC()) then
			table.insert(valids, npc)
		end
	end

	table.Shuffle(valids)
	for i = 1, math.min(#valids, 5) do
		local npc = valids[i]

		if npc:IsPlayer() then
			npc:SetMaxArmor(npc:GetMaxArmor() + self.GiveShieldAmount)
			npc:SetArmor(npc:GetMaxArmor())
		elseif npc:GetClass() ~= "terminator_nextbot_zambiespirit" then
			local newMax = npc:GetNWInt("sweeper_shield_max", 0) + self.GiveShieldAmount
			npc:SetNWInt("sweeper_shield_max", newMax)
			npc:SetNWInt("sweeper_shield", newMax)
			npc:SetNWFloat("sweeper_shield_regen", self.GiveShieldRegen)
			npc:SetNWFloat("sweeper_shield_regen_delay", self.GiveShieldRegenDelay)
		end

		local ed = EffectData()
		ed:SetFlags(2)
		ed:SetEntity(npc)
		ed:SetOrigin(self:WorldSpaceCenter())
		util.Effect("eff_zambspirit_rays", ed)
	end

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:SetMoveType(MOVETYPE_FLY)
	self:SetVelocity(Vector(0, 0, 0))
	self:SetNoDraw(true)

	if isvector(forceVec) then
		self:SetVelocity(forceVec)
	end

	local ed = EffectData()
	ed:SetMagnitude(1.5)
	ed:SetOrigin(self:WorldSpaceCenter())
	ed:SetRadius(78)
	ed:SetNormal(self:GetAngles():Up())
	ed:SetFlags(2)
	util.Effect("eff_zambspirit_blast", ed)

	self:EmitSound("npc/advisor/advisor_scream.wav", 100, 170, 1)
	hook.Call("OnNPCKilled", GAMEMODE, self, attacker, inflictor)

	local ent = self
	timer.Simple(0.1, function()
		if IsValid(ent) then
			ent:Remove()
		end
	end)
end

function ENT:CarryNPC(npc)
	local ed = EffectData()
	ed:SetFlags(2)
	ed:SetEntity(self)
	ed:SetOrigin(npc:WorldSpaceCenter())
	util.Effect("eff_zambspirit_rays", ed)
	npc:SetParent(self)
	npc:SetPos(self:GetPos())
	npc:SetNoDraw(true)
	self:SetCarriedNPCCount(self:GetCarriedNPCCount() + 1)
	self:EmitSound("npc/advisor/advisor_blast1.wav", 100, 100, 1)
end

function ENT:DeployNPCs(pos)
	local toDeploy = {}
	for _, ent in ipairs(self:GetChildren()) do
		if IsValid(ent) and ent:Health() > 0 then
			table.insert(toDeploy, ent)
		end
	end

	if #toDeploy == 0 then return end

	local mostVectors

	if isvector(pos) then
		for i = 1, 4 do
			local vectors, fully = PackSquadVectors(LerpVector(math.Remap(i, 1, 4, 0.5, 0.2), self:WorldSpaceCenter(), pos), #toDeploy, math.random(75, 125))
			if fully or not mostVectors or #vectors > #mostVectors then
				mostVectors = vectors
				if fully then break end
			end
		end
	else
		local vectors = PackSquadVectors(self:WorldSpaceCenter(), #toDeploy, math.random(150, 200))
		mostVectors = vectors
	end

	if not mostVectors or #mostVectors == 0 then return end

	local upVec = Vector(0, 0, 10)
	local deployed = 0

	for i, v in ipairs(mostVectors) do
		deployed = deployed + 1
		local ent = toDeploy[i]
		ent:SetParent()
		ent:SetPos(v + upVec)
		ent:SetNoDraw(false)

		local foe = self:GetEnemy()
		if IsValid(foe) then
			local foePos = foe:GetPos()

			if ent.SetEnemy then ent:SetEnemy(foe) end
			if ent.UpdateEnemyMemory then ent:UpdateEnemyMemory(foe, foePos) end
			if ent.NavSetGoalPos then ent:NavSetGoalPos(ent:GetPos()) end

			local faceAngle = (foePos - v):Angle()
			faceAngle.p = 0
			faceAngle.r = 0
			ent:SetAngles(faceAngle)
		else
			NPC_GetRowdy(ent)
		end

		local filter = RecipientFilter()
		filter:AddPVS(self:WorldSpaceCenter())
		filter:AddPVS(ent:WorldSpaceCenter())

		local ed = EffectData()
		ed:SetFlags(2)
		ed:SetEntity(self)
		ed:SetOrigin(ent:WorldSpaceCenter())
		util.Effect("eff_zambspirit_rays", ed, true, filter)
	end

	self:EmitSound("npc/advisor/advisor_blast6.wav", 100, 100, 1)
	local remaining = #toDeploy - deployed
	self:SetCarriedNPCCount(remaining)
	if remaining == 0 then
		if self:GetTable().MyClassTask then
			self:GetTable().MyClassTask.npcCarryGoal = math.random(3, 6)
		end
	end
end

if CLIENT then
	ENT.mat = Material("effects/strider_muzzle")
	ENT.mat_trail = Material("trails/plasma")

	function ENT:Initialize()
		BaseClass.Initialize(self)

		self.trailLength = 16
		self.trailBones = {
			self:LookupBone("ValveBiped.Bip01_L_Calf"),
			self:LookupBone("ValveBiped.Bip01_R_Calf"),
			self:LookupBone("ValveBiped.Bip01_L_Hand"),
			self:LookupBone("ValveBiped.Bip01_R_Hand"),
		}
		self.trails = {}
		for i = 1, #self.trailBones do
			self.trails[i] = {}
		end
	end

	function ENT:Think()
		BaseClass.Think(self)

		if FrameTime() > 0 then
			local mypos = self:WorldSpaceCenter()
			local dying = self:GetIsDying()
			local elapsed = CurTime() - self:GetDeathTime()
			local deathfrac = dying and math.ease.InCubic(math.max(0, 1 - elapsed / 1.5)) or 1
			local myX, myY, myZ = mypos:Unpack()

			for i, bid in ipairs(self.trailBones) do
				local tt = self.trails[i]
				local bonePos = self:GetBonePosition(bid)
				local bx, by, bz = bonePos:Unpack()
				bonePos:SetUnpacked(
					Lerp(1 - deathfrac, bx, myX),
					Lerp(1 - deathfrac, by, myY),
					Lerp(1 - deathfrac, bz, myZ)
				)
				table.insert(tt, 1, bonePos)
				if tt[self.trailLength] then
					tt[self.trailLength] = nil
				end
			end
		end

		self:SetNextClientThink(CurTime() + 1 / self.trailLength)
		return true
	end

	function ENT:DrawTranslucent(flags)
		if render.GetRenderTarget() then return end

		local mypos = self:WorldSpaceCenter()
		local eyePos = EyePos()
		local distToEyes = eyePos:DistToSqr(mypos)

		self:RemoveAllDecals()

		local time = CurTime()
		local dying = self:GetIsDying()
		local elapsed = time - self:GetDeathTime()
		local deathfrac = dying and math.ease.InCubic(math.max(0, 1 - elapsed / 1.5)) or 1
		local blastfrac = dying and math.max(0, 1 - elapsed * 5) or 0

		render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)

			if GetFPSEstimate() > 30 then
				render.SetMaterial(self.mat_trail)
				for i, trailVectors in ipairs(self.trails) do
					local n = #trailVectors
					if n < 2 then continue end
					render.StartBeam(n)
					for j, v in ipairs(trailVectors) do
						local f = (j - 1) / (n - 1)
						render.AddBeam(v, 7 * deathfrac * (1 - f), f * 4, Color(255 * (1 - f), 0, 0))
					end
					render.EndBeam()
				end
			end

			if not dying then
				local colormod = math.sin(time * 4 + self:EntIndex()) * 0.5 + 700
				render.SetColorModulation(colormod, 1, 1)
					self:DrawModel()
				render.SetColorModulation(1, 1, 1)
			end

			if distToEyes < 3250 ^ 2 then
				surface.SetMaterial(self.mat)
				surface.SetAlphaMultiplier(1)
				surface.SetDrawColor(255 * deathfrac, 0, 0, 255 * deathfrac)
				local a = (mypos - eyePos):Angle()
				a:RotateAroundAxis(a:Right(), 90)
				for i = 1, 4 do
					cam.Start3D2D(mypos, a, 1 + blastfrac * i)
						local ti = (time + i / 4) % 1
						local size = (72 - ti * 32) * deathfrac
						surface.DrawTexturedRectRotated(0, 0, size, size, ti / 4 * i * 360)
					cam.End3D2D()
				end
			end

			if distToEyes < 2000 ^ 2 then
				local orbcount = self:GetCarriedNPCCount()
				if orbcount > 0 then
					local angShift = math.pi * 2 / orbcount
					for i = 1, orbcount do
						local a = (i + time % 1) * angShift
						local orbV = mypos + Vector(math.cos(a) * 32, math.sin(a) * 32, -8)
						local size = 64 * deathfrac + blastfrac * 4
						render.DrawSprite(orbV, size, size, ZOMBIE_COLOR)
					end
				end
			end

		render.OverrideBlend(false)
	end
end