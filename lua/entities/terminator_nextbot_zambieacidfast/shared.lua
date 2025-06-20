AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieacid"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Acid Fast"
ENT.Author = "Broadcloth0"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieacidfast", {
    Name = "Zombie Acid Fast",
    Class = "terminator_nextbot_zambieacidfast",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieacidfast", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.00005
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 200
ENT.SpawnHealth = 100
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.WalkSpeed = 150
ENT.MoveSpeed = 350
ENT.RunSpeed = 500
ENT.AccelerationSpeed = 450

ENT.zamb_LookAheadWhenRunning = true -- mdl doesnt support different move/look angles
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
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1 -- ACT_RANGE_ATTACK1

local ACIDIC_COLOR = Color( 10, 250, 0 )

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )
    self:SetColor( ACIDIC_COLOR )

    --[[
    for ind = 1, self:GetSequenceCount() do
        local inf = self:GetSequenceInfo( ind )
        if inf then
            PrintTable( inf )

        end
        print( "-----" )

    end--]]

    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    local hasBrains = math.random( 1, 100 ) < 30
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true

    end
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

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
    self.IdleLoopingSounds = {
        "npc/fast_zombie/breathe_loop1.wav",

    }
    self.AngryLoopingSounds = {
        "npc/fast_zombie/gurgle_loop1.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 800
    self.FallDamagePerHeight = 0.005
    self.DeathDropHeight = 3000

end
