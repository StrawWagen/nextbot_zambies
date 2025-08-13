AddCSLuaFile()
ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Energy Fast"
ENT.Author = "Regunkyle"
ENT.Spawnable = false
list.Set("NPC","terminator_nextbot_zambieenergyfast",{Name="Zombie Energy Fast",Class="terminator_nextbot_zambieenergyfast",Category="Nextbot Zambies"})

if CLIENT then
    language.Add("terminator_nextbot_zambieenergyfast",ENT.PrintName)
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

ENT.CoroutineThresh = 0.00005
ENT.MaxPathingIterations = 25000
ENT.JumpHeight = 400
ENT.Term_Leaps = true
ENT.SpawnHealth = 100
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.WalkSpeed = 150
ENT.MoveSpeed = 350
ENT.RunSpeed = 500
ENT.AccelerationSpeed = 450
ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 1.15
ENT.FistDamageMul = 0.25
ENT.DuelEnemyDist = 450
ENT.TERM_MODELSCALE = function() return math.Rand(1.1,1.18) end
local FAST_ZOMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZOMBIE_MODEL
ENT.MyPhysicsMass = 60
ENT.TERM_FISTS = "weapon_term_zombieclaws"
ENT.Models = {FAST_ZOMBIE_MODEL}
ENT.IdleActivityTranslations = {[ACT_MP_STAND_IDLE]=ACT_IDLE_ANGRY,[ACT_MP_WALK]=ACT_WALK,[ACT_MP_RUN]=ACT_RUN,[ACT_MP_CROUCH_IDLE]=ACT_RUN,[ACT_MP_CROUCHWALK]=ACT_RUN,[ACT_MP_ATTACK_STAND_PRIMARYFIRE]=ACT_MELEE_ATTACK1,[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]=ACT_MELEE_ATTACK1,[ACT_MP_RELOAD_STAND]=ACT_INVALID,[ACT_MP_RELOAD_CROUCH]=ACT_INVALID,[ACT_MP_JUMP]=ACT_JUMP,[ACT_MP_SWIM]=ACT_RUN,[ACT_LAND]=ACT_LAND}
ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1
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

function ENT:AdditionalInitialize()
    self:SetModel(FAST_ZOMBIE_MODEL)
    self:SetBodygroup(1,1)
    self:SetSubMaterial(0,"!nextbotZambies_EnergyFlesh")
    self:SetColor(ENERGY_COLOR)
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    if mathRandom(1,100) < 30 then self.HasBrains = true self.CanHearStuff = true end
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4
    self.term_SoundPitchShift = -3
    self.term_SoundLevelShift = 10
    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = {"NPC_FastZombie.Scream","NPC_FastZombie.Frenzy"}
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {"npc/fast_zombie/breathe_loop1.wav"}
    self.AngryLoopingSounds = {"npc/fast_zombie/gurgle_loop1.wav"}
    self.AlwaysPlayLooping = true
    self.HeightToStartTakingDamage = 800
    self.FallDamagePerHeight = 0.005
    self.DeathDropHeight = 3000
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
    rad = rad or 120
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
    if mathRandom(0,100) < 20 then
        if isValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt,60,self:GetPos())
            self:DoAoeEnergyDamage(groundEnt,120)
        end
    else
        if isValid(groundEnt) then
            self:DealEnergyDamageTo(groundEnt,6,self:GetPos())
        end
    end
    local speed = self:GetVelocity():Length()
    DoEffect("effects/fluttercore_gmod",pos,mathClamp(speed/80,0.5,3),UP)
    DoEffect("bloodspray",pos,4,UP,4,7)
end

function ENT:OnRemove()
    for _,s in ipairs(ELECT_SFX) do self:StopSound(s) end
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

function ENT:AdditionalThink()
    BaseClass.AdditionalThink(self)
end

function ENT:HandleFlinching() end