AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Zombie Energy"
ENT.Author    = "Regunkyle"
ENT.Spawnable = false

list.Set("NPC","terminator_nextbot_zambieenergy",{
    Name     = "Zombie Energy",
    Class    = "terminator_nextbot_zambieenergy",
    Category = "Nextbot Zambies"
})

if CLIENT then
    language.Add("terminator_nextbot_zambieenergy", ENT.PrintName)

    CreateMaterial("nextbotZambies_EnergyFlesh","VertexLitGeneric",{
        ["$basetexture"] = "phoenix_storms/wire/pcb_blue",
        ["$treesway"]    = 1
    })

    function ENT:AdditionalClientInitialize()
        self:SetSubMaterial(0,"!nextbotZambies_EnergyFlesh")
    end

    return
end

local util_Effect, util_PrecacheSound = util.Effect, util.PrecacheSound
local ents_Create, ents_FindInSphere  = ents.Create, ents.FindInSphere
local timer_Simple                    = timer.Simple
local SafeRemoveDelayed               = SafeRemoveEntityDelayed
local IsValid                         = IsValid
local CurTime, Rand, Random           = CurTime, math.Rand, math.random
local Clamp                           = math.Clamp
local bor                             = bit.bor
local VEC_UP                          = vector_up or Vector(0,0,1)
local sqrt                            = math.sqrt

local ELECT_SFX = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav",
    "ambient/energy/zap5.wav"
}
local ELECT_SFX_N = #ELECT_SFX

local DMG_MASK    = bor(DMG_GENERIC, DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE)
local IMMUNE_MASK = bor(DMG_SHOCK,    DMG_ENERGYBEAM,          DMG_PLASMA, DMG_DISSOLVE, DMG_RADIATION)

ENT.DMG_MASK     = DMG_MASK
ENT.IMMUNE_MASK  = IMMUNE_MASK
ENT.ELECT_SFX    = ELECT_SFX
ENT.ENERGY_COLOR = Color(160,40,200)

ENT.SpawnHealth         = 125
ENT.HealthRegen         = 2
ENT.HealthRegenInterval = 1
ENT.FistDamageMul       = 1
ENT.FistDamageType      = DMG_MASK
ENT.IsFodder            = true
ENT.IsStupid            = true
ENT.CanSpeak            = true
ENT.TERM_MODELSCALE     = function() return math.Rand(1.08,1.10) end
ENT.MyPhysicsMass       = 85

ENT.ArcEnabled     = true
ENT.ArcIntervalMin = 0.5
ENT.ArcIntervalMax = 1.2
ENT.ArcRadius      = 160
ENT.ArcMagnitude   = 6
ENT.ArcScale       = 1

local function PrecacheSounds(s)
    if not s then return end
    if istable(s) then
        for i=1,#s do util_PrecacheSound(s[i]) end
    else
        util_PrecacheSound(s)
    end
end

function ENT:DoEffect(name, pos, scale, normal, flags, color)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    if scale  then ed:SetScale(scale) end
    if normal then ed:SetNormal(normal) end
    if flags  then ed:SetFlags(flags) end
    if color  then ed:SetColor(color) end
    util_Effect(name, ed, true, true)
end

function ENT:DoSelfArcFX()
    if not self.ArcEnabled then return end
    local ed = EffectData()
    ed:SetOrigin(self:WorldSpaceCenter())
    ed:SetEntity(self)
    ed:SetMagnitude(self.ArcMagnitude)
    ed:SetScale(self.ArcScale)
    ed:SetRadius(self.ArcRadius)
    util_Effect("TeslaHitBoxes", ed, true, true)
end

function ENT:DissolveTarget(target)
    if not IsValid(target) then return end
    local d = ents_Create("env_entity_dissolver")
    if not IsValid(d) then SafeRemoveDelayed(target, 0.1) return end
    d:SetPos(target:GetPos())
    d:Spawn()
    d:Activate()
    d:SetKeyValue("dissolvetype","0")
    d:Fire("Dissolve", target, 0)
    timer_Simple(1.2, function() if IsValid(d) then d:Remove() end end)
end

function ENT:IsImmuneToDmg(dmg)
    if dmg:IsDamageType(DMG_SHOCK)
    or dmg:IsDamageType(DMG_ENERGYBEAM)
    or dmg:IsDamageType(DMG_PLASMA)
    or dmg:IsDamageType(DMG_DISSOLVE) then
        return true
    end
end

function ENT:AdditionalInitialize()
    self:SetBodygroup(1,1)
    self:SetSubMaterial(0,"!nextbotZambies_EnergyFlesh")
    self:SetColor(self.ENERGY_COLOR)

    self.isTerminatorHunterChummy = "zambies"

    if Random(1,100) < 30 then
        self.HasBrains    = true
        self.CanHearStuff = true
    else
        self.HasBrains    = false
        self.CanHearStuff = false
    end

    self.term_DMG_ImmunityMask = self.IMMUNE_MASK
    self.nextInterceptTry       = 0
    self.term_NextIdleTaunt     = CurTime() + 4

    self.term_SoundPitchShift   = 5
    self.term_SoundLevelShift   = 5
    self.term_LoseEnemySound    = "Zombie.Idle"
    self.term_CallingSound      = "ambient/energy/zap1.wav"
    self.term_CallingSmallSound = "ambient/energy/zap2.wav"
    self.term_FindEnemySound    = "Zombie.Alert"
    self.term_AttackSound       = "ambient/energy/zap3.wav"
    self.term_AngerSound        = "ambient/energy/spark4.wav"
    self.term_DamagedSound      = "ambient/energy/zap4.wav"
    self.term_DieSound          = "ambient/energy/weld1.wav"
    self.term_JumpSound         = "ambient/energy/spark6.wav"

    self.IdleLoopingSounds      = {"ambient/machines/combine_shield_loop3.wav"}
    self.AngryLoopingSounds     = {"ambient/energy/force_field_loop1.wav"}
    self.AlwaysPlayLooping      = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight       = 0.03
    self.DeathDropHeight           = 1500

    for i=1,ELECT_SFX_N do util_PrecacheSound(ELECT_SFX[i]) end
    PrecacheSounds(self.term_LoseEnemySound)
    PrecacheSounds(self.term_CallingSound)
    PrecacheSounds(self.term_CallingSmallSound)
    PrecacheSounds(self.term_FindEnemySound)
    PrecacheSounds(self.term_AttackSound)
    PrecacheSounds(self.term_AngerSound)
    PrecacheSounds(self.term_DamagedSound)
    PrecacheSounds(self.term_DieSound)
    PrecacheSounds(self.term_JumpSound)
    PrecacheSounds(self.IdleLoopingSounds)
    PrecacheSounds(self.AngryLoopingSounds)

    self._nextArc = CurTime() + Rand(self.ArcIntervalMin, self.ArcIntervalMax)
end

function ENT:DealEnergyDamageTo(ent, dmg, pos)
    if not IsValid(ent) then return end
    local di = DamageInfo()
    di:SetDamage(dmg)
    di:SetDamageType(self.DMG_MASK)
    di:SetAttacker(self)
    di:SetInflictor(self)
    di:SetDamagePosition(pos or self:WorldSpaceCenter())
    ent:TakeDamageInfo(di)

    ent:EmitSound(self.ELECT_SFX[Random(1, ELECT_SFX_N)], 60 + (dmg/40), 120 + (-dmg/10))
end

function ENT:DoAoeEnergyDamage(ent, rad)
    if not IsValid(ent) then return end
    rad = rad or 200

    local center = self:WorldSpaceCenter()
    local areaDamagePos = ent:NearestPoint(center)
    self:DoEffect("effects/fluttercore_gmod", areaDamagePos, Clamp(rad/200, 0.5, 3), VEC_UP)

    local radSqr = rad * rad
    for _, aoeEnt in ipairs(ents_FindInSphere(areaDamagePos, rad)) do
        if aoeEnt == ent or aoeEnt == self then continue end
        if IsValid(aoeEnt:GetParent()) then continue end
        if aoeEnt:GetMaxHealth() > 1 and aoeEnt:Health() <= 0 then continue end

        local nearest = aoeEnt:NearestPoint(areaDamagePos)
        local distSqr = nearest:DistToSqr(areaDamagePos)
        if distSqr > radSqr then continue end

        local dist = sqrt(distSqr)
        local dmg = (rad - dist) * 4
        if aoeEnt:IsNPC() or aoeEnt:IsPlayer() then
            dmg = dmg / 100
        end
        if dmg > 0 then
            self:DealEnergyDamageTo(aoeEnt, dmg, areaDamagePos)
        end
    end
end

function ENT:AdditionalFootstep(pos)
    local groundEnt = self:GetGroundEntity()
    if Random(0,100) < 25 then
        if IsValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt, 100, self:GetPos())
            self:DoAoeEnergyDamage(groundEnt, 200)
        end
    else
        if IsValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt, 10, self:GetPos())
        end
    end

    local speed = self:GetVelocity():Length()
    self:DoEffect("effects/fluttercore_gmod", pos, Clamp(speed/100, 0.5, 3), VEC_UP)
    self:DoEffect("bloodspray",               pos, 6,                        VEC_UP, 4, 7)
end

function ENT:PostHitObject(hit)
    self:DoAoeEnergyDamage(hit, 200)
end

function ENT:AdditionalOnKilled()
    self:EmitSound(self.ELECT_SFX[Random(1,ELECT_SFX_N)], 80, 120)
    self:EmitSound(self.ELECT_SFX[Random(1,ELECT_SFX_N)], 90,  60)

    local myPos = self:GetPos()
    timer_Simple(0.06, function()
        local found = false
        for _, e in ipairs(ents_FindInSphere(myPos, 120)) do
            if IsValid(e) and e:GetClass():find("prop_ragdoll") then
                self:DissolveTarget(e)
                found = true
                break
            end
        end
        if not found and IsValid(self) then self:DissolveTarget(self) end
    end)
end

function ENT:OnRemove()
    for i=1,ELECT_SFX_N do
        self:StopSound(ELECT_SFX[i])
    end
end

function ENT:AdditionalThink()
    if self.ArcEnabled then
        local now = CurTime()
        if now >= (self._nextArc or 0) then
            self._nextArc = now + Rand(self.ArcIntervalMin, self.ArcIntervalMax)
            self:DoSelfArcFX()
        end
    end

    BaseClass.AdditionalThink(self)
end


function ENT:HandleFlinching() end
