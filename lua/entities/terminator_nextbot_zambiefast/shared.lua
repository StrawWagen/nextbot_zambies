AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Fast Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiefast", {
    Name = "Zombie Fast",
    Class = "terminator_nextbot_zambiefast",
    Category = "Nexbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiefast", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.0005
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 200
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 65
ENT.AimSpeed = 400
ENT.WalkSpeed = 100
ENT.MoveSpeed = 300
ENT.RunSpeed = 400
ENT.AccelerationSpeed = 450

ENT.zamb_LookAheadWhenRunning = true -- mdl doesnt support different move/look angles
ENT.zamb_MeleeAttackSpeed = 1.15

ENT.FistDamageMul = 0.35
ENT.DuelEnemyDist = 450

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL

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
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1 -- ACT_RANGE_ATTACK1

function ENT:OnKilledGenericEnemyLine( enemyLost )
end

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )

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
    terminator_Extras.RegisterListener( self )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "NPC_FastZombie.Scream", "NPC_FastZombie.Frenzy" }
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {
        "npc/fast_zombie/breathe_loop1.wav",

    }
    self.AngryLoopingSounds = {
        "npc/fast_zombie/gurgle_loop1.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.015
    self.DeathDropHeight = 1500

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( pos, foot, sound, volume, filter )
    local lvl = 85
    local snd = foot and "NPC_FastZombie.GallopRight" or "NPC_FastZombie.GallopLeft"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end
    self:EmitSound( snd, lvl, 100, volume + 1, CHAN_STATIC, sndFlags )
    return true

end