AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Baby Crab"
ENT.Spawnable = false

if CLIENT then
    language.Add( "terminator_nextbot_zambiecrabbaby", ENT.PrintName )

    return
end

ENT.CoroutineThresh = 0.000005

ENT.JumpHeight = 600
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 10
ENT.AimSpeed = 400
ENT.WalkSpeed = 200
ENT.MoveSpeed = 400
ENT.RunSpeed = 800
ENT.AccelerationSpeed = 350
ENT.DeccelerationSpeed = 350
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 2
ENT.zamb_AttackAnim = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL -- ACT_RANGE_ATTACK1

ENT.FistDamageMul = 0.75
ENT.FistRangeMul = 0.5
ENT.FistDamageType = bit.bor( DMG_SLASH, DMG_CRUSH )
ENT.DuelEnemyDist = 500

local BABY_CRAB_MODEL = "models/headcrab.mdl"
ENT.ARNOLD_MODEL = BABY_CRAB_MODEL
ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds = { Vector( -5, -5, 0 ), Vector( 5, 5, 12 ) }
ENT.MyPhysicsMass = 55
ENT.AlwaysCrouching = true

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { TANK_ZAMBIE_MODEL }
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

ENT.zamb_CallAnim = "rearup"
ENT.zamb_AttackAnim = ACT_RANGE_ATTACK1

ENT.zamb_CantCall = true

function ENT:AdditionalInitialize()
    self:SetModel( BABY_CRAB_MODEL )

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

    self.term_SoundPitchShift = -5
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "NPC_FastHeadcrab.Idle"
    self.term_FindEnemySound = "NPC_FastHeadcrab.Attack"
    self.term_AttackSound = { "NPC_FastHeadcrab.Bite" }
    self.term_AngerSound = "NPC_FastHeadcrab.Attack"
    self.term_DamagedSound = "NPC_FastHeadcrab.Pain"
    self.term_DieSound = "NPC_FastHeadcrab.Die"
    self.term_JumpSound = "NPC_FastHeadcrab.Footstep"
    self.IdleLoopingSounds = nil
    self.AngryLoopingSounds = nil

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1500
    self.CanUseLadders = false

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, _foot, _sound, volume, _filter )
    local lvl = 75
    local snd = "NPC_FastHeadcrab.Footstep"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 73

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    return true

end