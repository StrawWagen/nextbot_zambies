AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieenergy"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Energy Fast"
ENT.Author = "Regunkyle"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieenergyfast", {
    Name = "Zombie Energy Fast",
    Class = "terminator_nextbot_zambieenergyfast",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergyfast", ENT.PrintName )
    return
end

-- performance / pathing
ENT.CoroutineThresh = 0.00005
ENT.MaxPathingIterations = 25000

-- mobility
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

ENT.TERM_MODELSCALE = function() return math.Rand( 1.1, 1.18 ) end
local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL
ENT.MyPhysicsMass = 60

ENT.TERM_FISTS = "weapon_term_zombieclaws"
ENT.Models = { FAST_ZAMBIE_MODEL }

ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE_ANGRY,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_RUN,
    [ACT_MP_CROUCHWALK]                 = ACT_RUN,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = ACT_MELEE_ATTACK1,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = ACT_MELEE_ATTACK1,
    [ACT_MP_RELOAD_STAND]               = ACT_INVALID,
    [ACT_MP_RELOAD_CROUCH]              = ACT_INVALID,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_MP_SWIM]                       = ACT_RUN,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

-- purple color (same as main)
local ENERGY_COLOR = Color( 160, 40, 200 )

-- helpers (local so this file is standalone) -------------------------------------
local UP = Vector(0,0,1)
local ElectricSfxFast = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav",
    "ambient/energy/zap5.wav",
}

local function energyPuffFast(pos, scale)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetScale( math.max((scale or 1), 0.1) )
    ed:SetNormal(UP)
    util.Effect("effects/fluttercore_gmod", ed, true, true)
end

local function smallPurpleBloodSprayFast(pos, scale)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetScale( math.Clamp((scale or 4), 1, 8) )
    ed:SetNormal(UP)
    ed:SetFlags(4)
    ed:SetColor(7)
    util.Effect("bloodspray", ed, true, true)
end

local function dissolveEntitySafelyFast(target)
    if not IsValid(target) then return end
    local dissolver = ents.Create("env_entity_dissolver")
    if not IsValid(dissolver) then
        SafeRemoveEntityDelayed(target, 0.1)
        return
    end
    dissolver:SetPos(target:GetPos())
    dissolver:Spawn()
    dissolver:Activate()
    dissolver:SetKeyValue("dissolvetype", 0)
    dissolver:Fire("Dissolve", target, 0)
    timer.Simple(1.5, function()
        if IsValid(dissolver) then dissolver:Remove() end
    end)
end

-- AdditionalInitialize ---------------------------------------------------------
function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_EnergyFlesh" )
    self:SetColor( ENERGY_COLOR )

    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    if math.random(1,100) < 30 then
        self.HasBrains = true
        self.CanHearStuff = true
    end

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    -- sound tuning for fast
    self.term_SoundPitchShift = -3
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "NPC_FastZombie.Scream", "NPC_FastZombie.Frenzy" }
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"

    self.IdleLoopingSounds = { "npc/fast_zombie/breathe_loop1.wav" }
    self.AngryLoopingSounds = { "npc/fast_zombie/gurgle_loop1.wav" }
    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 800
    self.FallDamagePerHeight = 0.005
    self.DeathDropHeight = 3000
end

-- footsteps: smaller puff and smaller purple spray --------------------------------
function ENT:AdditionalFootstep( pos )
    local groundEnt = self:GetGroundEntity()

    if math.random(0,100) < 20 then
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 60, self:GetPos() )
            self:DoAoeEnergyDamage( groundEnt, 120 )
        end
    else
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 6, self:GetPos() )
        end
    end

    local speed = self:GetVelocity():Length()
    local puffScale = math.Clamp( speed / 80, 0.5, 3 )
    energyPuffFast( pos, puffScale )
    smallPurpleBloodSprayFast( pos, 4 )
end

-- OnRemove cleanup -------------------------------------------------------------
function ENT:OnRemove()
    -- stop any sounds if still playing (best-effort)
    for _, s in ipairs(ElectricSfxFast) do
        self:StopSound(s)
    end
end

-- death: dissolve the ragdoll instead of AoE ------------------------------------
function ENT:AdditionalOnKilled()
    self:EmitSound( ElectricSfxFast[ math.random(1,#ElectricSfxFast) ], 80, 120 )
    self:EmitSound( ElectricSfxFast[ math.random(1,#ElectricSfxFast) ], 90, 60 )

    local myPos = self:GetPos()
    timer.Simple(0.08, function()
        local found = false
        for _, e in ipairs( ents.FindInSphere( myPos, 160 ) ) do
            if IsValid(e) and e:GetClass():find("prop_ragdoll") then
                dissolveEntitySafelyFast(e)
                found = true
            end
        end
        if not found and IsValid(self) then
            dissolveEntitySafelyFast(self)
        end
    end)
end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )
end

-- don't flinch
function ENT:HandleFlinching() end
