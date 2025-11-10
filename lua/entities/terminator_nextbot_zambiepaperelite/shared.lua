AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiepaper"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Fast Papercut Zombie"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiepaperelite", {
    Name = "Zombie Papercut Fast", -- diff name in list, so when its spawned by non-spawnmenu, ENT.PrintName will be used
    Class = "terminator_nextbot_zambiepaperelite",
    Category = "Nextbot Zambies",
} )

ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 20
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 400
ENT.Term_Leaps = true
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 80
ENT.AimSpeed = 400
ENT.WalkSpeed = 100
ENT.MoveSpeed = 300
ENT.RunSpeed = 400
ENT.AccelerationSpeed = 450

ENT.zamb_LookAheadWhenRunning = true -- fast zombie model doesnt have aimlayers
ENT.zamb_MeleeAttackSpeed = 1.15

ENT.FistDamageMul = 0.4
ENT.DuelEnemyDist = 450
ENT.MyPhysicsMass = 65

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL

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

ENT.TERM_MODELSCALE = function() return math.Rand( 1.05, 1.15 ) end

ENT.BleedDuration = 3
ENT.BleedDamage = 2
ENT.BleedTicks = 6

ENT.Term_FootstepSoundWalking = {
    {
        path = "NPC_FastZombie.GallopLeft",
        lvl = 76,
    },
    {
        path = "NPC_FastZombie.GallopRight",
        lvl = 76,
    },
}
ENT.Term_FootstepSound = {
    {
        path = "NPC_FastZombie.GallopLeft",
        lvl = 85,
        pitch = 110,
    },
    {
        path = "NPC_FastZombie.GallopRight",
        lvl = 85,
        pitch = 110,
    },
}

ENT.IsPaperZambie = true

if CLIENT then
    language.Add( "terminator_nextbot_zambiepaperelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.85, 0.75, 0.65 )
        self:DrawModel()
        render.SetColorModulation( 1, 1, 1 )
    end
    return
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/props_c17/paper01" )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true
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