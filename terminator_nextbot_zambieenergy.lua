AddCSLuaFile()
ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Energy"
ENT.Author = "Regunkyle"
ENT.Spawnable = false
list.Set("NPC","terminator_nextbot_zambieenergy",{Name="Zombie Energy",Class="terminator_nextbot_zambieenergy",Category="Nextbot Zambies"})

if CLIENT then
    language.Add("terminator_nextbot_zambieenergy",ENT.PrintName)
    local _setup
    function ENT:AdditionalClientInitialize()
        if _setup then return end
        _setup = true
        CreateMaterial("nextbotZambies_EnergyFlesh","VertexLitGeneric",{["$basetexture"]="phoenix_storms/wire/pcb_blue",["$treesway"]=1})
        self:SetSubMaterial(0,"!nextbotZambies_EnergyFlesh")
    end
    return
end

local utilEffect = util.Effect
local entsCreate = ents.Create
local timerSimple = timer.Simple
local safeRemoveDelayed = SafeRemoveEntityDelayed
local isValid = IsValid
local mathClamp = math.Clamp
local mathRandom = math.random
local bitBor = bit.bor
local UP = Vector(0,0,1)
local ELECT_SFX = {"ambient/energy/zap1.wav","ambient/energy/zap2.wav","ambient/energy/zap3.wav","ambient/energy/zap5.wav"}
local DMG_MASK = bitBor(DMG_GENERIC,DMG_SHOCK,DMG_ENERGYBEAM,DMG_PLASMA,DMG_DISSOLVE)
local IMMUNE_MASK = bitBor(DMG_SHOCK,DMG_ENERGYBEAM,DMG_PLASMA,DMG_DISSOLVE,DMG_RADIATION)

ENT.SpawnHealth = 125
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.FistDamageMul = 1
ENT.FistDamageType = DMG_MASK
ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true
ENT.TERM_MODELSCALE = function() return math.Rand(1.08,1.10) end
ENT.MyPhysicsMass = 85

local ENERGY_COLOR = Color(160,40,200)

local function DoEffect(name,pos,scale,normal,flags,color)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    if scale then ed:SetScale(scale) end
    if normal then ed:SetNormal(normal) end
    if flags then ed:SetFlags(flags) end
    if color then ed:SetColor(color) end
    utilEffect(name,ed,true,true)
end

local function DissolveTarget(target)
    if not isValid(target) then return end
    local d = entsCreate("env_entity_dissolver")
    if not isValid(d) then safeRemoveDelayed(target,0.1) return end
    d:SetPos(target:GetPos())
    d:Spawn()
    d:Activate()
    d:SetKeyValue("dissolvetype","0")
    d:Fire("Dissolve",target,0)
    timerSimple(1.2,function() if isValid(d) then d:Remove() end end)
end

function ENT:IsImmuneToDmg(dmg)
    if dmg:IsDamageType(DMG_SHOCK) or dmg:IsDamageType(DMG_ENERGYBEAM) or dmg:IsDamageType(DMG_PLASMA) or dmg:IsDamageType(DMG_DISSOLVE) then
        return true
    end
end

function ENT:AdditionalInitialize()
    self:SetBodygroup(1,1)
    self:SetSubMaterial(0,"!nextbotZambies_EnergyFlesh")
    self:SetColor(ENERGY_COLOR)
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    if mathRandom(1,100) < 30 then self.HasBrains = true self.CanHearStuff = true end
    self.term_DMG_ImmunityMask = IMMUNE_MASK
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4
    self.term_SoundPitchShift = 5
    self.term_SoundLevelShift = 5
    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/energy/zap1.wav"
    self.term_CallingSmallSound = "ambient/energy/zap2.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = "ambient/energy/zap3.wav"
    self.term_AngerSound = "ambient/energy/spark4.wav"
    self.term_DamagedSound = "ambient/energy/zap4.wav"
    self.term_DieSound = "ambient/energy/weld1.wav"
    self.term_JumpSound = "ambient/energy/spark6.wav"
    self.IdleLoopingSounds = {"ambient/machines/combine_shield_loop3.wav"}
    self.AngryLoopingSounds = {"ambient/energy/force_field_loop1.wav"}
    self.AlwaysPlayLooping = true
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.03
    self.DeathDropHeight = 1500
end

function ENT:DealEnergyDamageTo(ent,dmg,pos)
    if not isValid(ent) then return end
    local di = DamageInfo()
    di:SetDamage(dmg)
    di:SetDamageType(DMG_MASK)
    di:SetAttacker(self)
    di:SetInflictor(self)
    di:SetDamagePosition(pos or self:WorldSpaceCenter())
    ent:TakeDamageInfo(di)
    local pitch = 120 + (-dmg/10)
    local level = 60 + (dmg/40)
    ent:EmitSound(ELECT_SFX[mathRandom(1,#ELECT_SFX)],level,pitch)
end

function ENT:DoAoeEnergyDamage(ent,rad)
    rad = rad or 200
    local areaDamagePos = ent:NearestPoint(self:WorldSpaceCenter())
    DoEffect("effects/fluttercore_gmod",areaDamagePos,mathClamp(rad/200,0.5,3),UP)
    for _,aoeEnt in ipairs(ents.FindInSphere(areaDamagePos,rad)) do
        if isValid(aoeEnt:GetParent()) then continue end
        if aoeEnt==ent or aoeEnt==self then continue end
        if aoeEnt:GetMaxHealth()>1 and aoeEnt:Health()<=0 then continue end
        local isSignificant = aoeEnt:IsNPC() or aoeEnt:IsPlayer()
        local dmg = rad - aoeEnt:NearestPoint(areaDamagePos):Distance(areaDamagePos)
        dmg = dmg * 4
        if isSignificant then dmg = dmg/100 end
        self:DealEnergyDamageTo(aoeEnt,dmg,areaDamagePos)
    end
end

function ENT:AdditionalFootstep(pos)
    local groundEnt = self:GetGroundEntity()
    if mathRandom(0,100) < 25 then
        if isValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt,100,self:GetPos())
            self:DoAoeEnergyDamage(groundEnt,200)
        end
    else
        if isValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt,10,self:GetPos())
        end
    end
    local speed = self:GetVelocity():Length()
    DoEffect("effects/fluttercore_gmod",pos,mathClamp(speed/100,0.5,3),UP)
    DoEffect("bloodspray",pos,6,UP,4,7)
end

function ENT:PostHitObject(hit)
    self:DoAoeEnergyDamage(hit,200)
end

function ENT:AdditionalOnKilled()
    self:EmitSound(ELECT_SFX[mathRandom(1,#ELECT_SFX)],80,120)
    self:EmitSound(ELECT_SFX[mathRandom(1,#ELECT_SFX)],90,60)
    local myPos = self:GetPos()
    timerSimple(0.06,function()
        local found = false
        for _,e in ipairs(ents.FindInSphere(myPos,120)) do
            if isValid(e) and e:GetClass():find("prop_ragdoll") then
                DissolveTarget(e)
                found = true
                break
            end
        end
        if not found and isValid(self) then DissolveTarget(self) end
    end)
end

function ENT:OnRemove()
    for _,s in ipairs(ELECT_SFX) do self:StopSound(s) end
end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink(self)
end

function ENT:HandleFlinching() end