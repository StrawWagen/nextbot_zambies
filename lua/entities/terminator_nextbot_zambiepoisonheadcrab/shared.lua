AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Poison Headcrab"
ENT.Spawnable = false
ENT.Author = "Broadcloth0"

if CLIENT then
    language.Add( "terminator_nextbot_zambiepoisonheadcrab", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.000005

ENT.JumpHeight = 50
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 10
ENT.AimSpeed = 400
ENT.WalkSpeed = 50
ENT.MoveSpeed = 50
ENT.RunSpeed = 90
ENT.NoAnimLayering = true

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 2.1
ENT.zamb_AttackAnim = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL -- ACT_RANGE_ATTACK1

ENT.FistDamageMul = 1
ENT.FistRangeMul = 0.5
ENT.FistDamageType = bit.bor( DMG_POISON )
ENT.DuelEnemyDist = 500

local POISONHEAD_CRAB_MODEL = "models/headcrabblack.mdl"
ENT.ARNOLD_MODEL = POISONHEAD_CRAB_MODEL
ENT.TERM_MODELSCALE = 1
ENT.CollisionBounds = { Vector( -8, -6, -5 ), Vector( 8, 6, 35 ) }
ENT.MyPhysicsMass = 55
ENT.AlwaysCrouching = true
ENT.Term_BaseTimeBetweenSteps = 300
ENT.Term_StepSoundTimeMul = 1.01

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { POISONHEAD_CRAB_MODEL }
ENT.term_AnimsWithIdealSpeed = true

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE,
    [ACT_MP_WALK]                       = ACT_RUN,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_IDLE,
    [ACT_MP_CROUCHWALK]                 = ACT_RUN,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_RANGE_ATTACK1,
    [ACT_MP_SWIM]                       = ACT_RUN,
    [ACT_LAND]                          = 2089,
}

local ACT_ZOM_RELEASECRAB = "releasecrab"

ENT.zamb_CallAnim = ACT_ZOM_RELEASECRAB
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1 -- ACT_RANGE_ATTACK1

ENT.zamb_CallAnim = "rearup"
ENT.zamb_AttackAnim = ACT_RANGE_ATTACK1

ENT.zamb_CantCall = true

function ENT:AdditionalInitialize()
    self:SetModel( POISONHEAD_CRAB_MODEL )

    --[[
    for ind = 1, self:GetSequenceCount() do
        local inf = self:GetSequenceInfo( ind )
        if inf then
            PrintTable( inf )

        end
        print( "-----" )

    end--]]

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = 0
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "npc/headcrab_poison/ph_idle1.wav"
    self.term_FindEnemySound = {
        "npc/headcrab_poison/ph_talk2.wav",
        "npc/headcrab_poison/ph_talk1.wav",
        "npc/headcrab_poison/ph_talk3.wav"
    }
    self.term_AttackSound = {
        "npc/headcrab_poison/ph_scream1.wav",
        "npc/headcrab_poison/ph_scream2.wav"
    }
    self.term_AngerSound = "NPC_BlackHeadcrab.Pain"
    self.term_DamagedSound = "NPC_BlackHeadcrab.Pain"
    self.term_DieSound = "NPC_BlackHeadcrab.Die"
    self.term_JumpSound = "NPC_BlackHeadcrab.Footstep"
    self.IdleLoopingSounds = {
        "npc/headcrab_poison/ph_idle1.wav",
        "npc/headcrab_poison/ph_idle2.wav",
        "npc/headcrab_poison/ph_idle3.wav"
    }
    self.AngryLoopingSounds = nil
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1500
    self.CanUseLadders = false

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, _foot, _sound, volume, _filter )
    local lvl = 75
    local snd = "NPC_BlackHeadcrab.Footstep"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 62

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    return true

end