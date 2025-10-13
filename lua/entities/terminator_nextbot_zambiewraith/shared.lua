AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Wraith"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiewraith", {
    Name = "Zombie Wraith",
    Class = "terminator_nextbot_zambiewraith",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiewraith", ENT.PrintName )
    return

end

ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 20
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 600
ENT.Term_Leaps = true
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 50
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 100
ENT.MoveSpeed = 300
ENT.RunSpeed = 450
ENT.AccelerationSpeed = 350
ENT.neverManiac = true

ENT.CanUseStuff = true

ENT.zamb_AlwaysFlank = true
ENT.zamb_LookAheadWhenRunning = true -- turn this on since we do big bursts of damage unlike the normal fast z
ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 2.25
ENT.FistRangeMul = 1.5
ENT.DuelEnemyDist = 450

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { FAST_ZAMBIE_MODEL }
ENT.TERM_MODELSCALE = function() return math.Rand( 0.95, 1 ) end
ENT.MyPhysicsMass = 70
ENT.NoAnimLayering = true

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
ENT.zamb_AttackAnim = "BR2_Attack"

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/combine_advisor/body9" )

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
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = 10
    self.term_SoundLevelShift = -10

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "NPC_FastZombie.Attack" }
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {
        "ambient/levels/citadel/citadel_ambient_voices1.wav",

    }
    self.AngryLoopingSounds = {
        "ambient/levels/citadel/citadel_ambient_scream_loop1.wav",

    }

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.015
    self.DeathDropHeight = 1500
    self.zambwraith_InvisGraceMul = 1

end

ENT.IsWraith = true -- enable wraith cloaking logic
ENT.NotSolidWhenCloaked = true -- if we're a wraith, we become non-solid when cloaked

function ENT:PlayHideFX()
    self:EmitSound( "ambient/levels/citadel/pod_open1.wav", 74, math.random( 115, 125 ) )

end

function ENT:PlayUnhideFX()
    self:EmitSound( "ambient/levels/citadel/pod_close1.wav", 74, math.random( 115, 125 ) )
    self:EmitSound( "buttons/combine_button_locked.wav", 76, 50 )
    self:Term_SpeakSoundNow( { "NPC_FastZombie.Frenzy", "NPC_FastZombie.Scream" } )

end

ENT.wraithTerm_CloakDecidingTask = function( self, data ) -- ran in BehaveUpdatePriority
    local doHide = not self:IsGestureActive() and IsValid( self:GetEnemy() ) and not IsValid( self:GetGroundEntity() ) -- we cant stand on props!
    local enemDist = self.DistToEnemy
    local allyCount = #self:GetNearbyAllies()
    if doHide and self.IsSeeEnemy and math.random( 0, allyCount * 20 ) < 1 and allyCount >= 1 then
        if enemDist < 2500 and enemDist > 800 and not self:IsReallyAngry() and not self.zamb_CantCall then
            self:ZAMB_AngeringCall()
            self:ReallyAnger( 45 )
            doHide = false

        elseif self:IsReallyAngry() then
            if enemDist < 250 then
                doHide = false

            end
        elseif enemDist < 450 then
            doHide = false

        end
    elseif doHide and enemDist < 250 then
        doHide = false

    end

    self:DoHiding( doHide )

    if self.wraithTerm_IsCloaked and math.Rand( 0, 100 ) < 0.5 then
        self:CloakedMatFlicker()

    end
end