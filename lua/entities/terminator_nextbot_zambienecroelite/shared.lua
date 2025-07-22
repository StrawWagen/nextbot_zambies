AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambienecro"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Necromancer Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambienecroelite", {
    Name = "Zombie Necromancer Elite",
    Class = "terminator_nextbot_zambienecroelite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambienecroelite", ENT.PrintName )
    return

end

ENT.IsFodder = false
ENT.CoroutineThresh = 0.0001

ENT.JumpHeight = 40
ENT.DefaultStepHeight = 20
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 25000
ENT.ExtraSpawnHealthPerPlayer = 2500
ENT.HealthRegen = 25
ENT.HealthRegenInterval = 1
ENT.WalkSpeed = 100
ENT.MoveSpeed = 150
ENT.RunSpeed = 300
ENT.neverManiac = true

ENT.FistDamageMul = 25
ENT.FistForceMul = 20
ENT.FistRangeMul = 2
ENT.zamb_MeleeAttackHitFrameMul = 0.5

ENT.PrefersVehicleEnemies = true

ENT.TERM_MODELSCALE = 2.5
ENT.CollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 22 ) }
ENT.MyPhysicsMass = 5000


function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self.term_SoundPitchShift = -40
    self.term_SoundLevelShift = 20

    self.HeightToStartTakingDamage = 600
    self.DeathDropHeight = 3000

    self.zamb_LoseCoolRatio = 0.75

    self.necro_MinionCountMul = 1.75
    self.necro_MinMinionCount = 2
    self.necro_MaxMinionCount = 20
    self.necro_NormalMinionClass = {
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambiegrunt",

    }

    self.necro_ReachableFastMinionChance = 15
    self.necro_UnReachableFastMinionChance = 55
    self.necro_UnreachableCountAdd = 4
    self.necro_FastMinionClass = {
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefast",
        "terminator_nextbot_zambiefastgrunt",

    }

    self.necro_NearDeathClassChance = 25
    self.necro_NearDeathMinionClass = {
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambieberserk",
        "terminator_nextbot_zambiewraith",
        "terminator_nextbot_zambiewraith",
        "terminator_nextbot_zambiewraith",
        "terminator_nextbot_zambiewraith",
        "terminator_nextbot_zambiewraithelite",

    }

end


ENT.Term_FootstepTiming = "perfect"
ENT.PerfectFootsteps_FeetBones = { "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot" }
ENT.PerfectFootsteps_SteppingCriteria = -0.75
ENT.Term_FootstepSoundWalking = {
    {
        path = "NPC_Strider.Footstep",
        lvl = 78,
        pitch = 90,
    },
    {
        path = "NPC_Strider.Footstep",
        lvl = 78,
        pitch = 90,
    },
}
ENT.Term_FootstepSound = { -- running sounds
    {
        path = "Zombie.FootstepLeft",
        lvl = 93,
        pitch = 80,
    },
    {
        path = "Zombie.FootstepRight",
        lvl = 93,
        pitch = 80,
    },
}
ENT.Term_FootstepShake = {
    amplitude = 2,
    frequency = 20,
    duration = 0.35,
    radius = 1500,
}
