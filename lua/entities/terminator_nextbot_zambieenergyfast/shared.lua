AddCSLuaFile( )

ENT.Base = "terminator_nextbot_zambieenergy"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Energy Fast"
ENT.Author    = "Regunkyle"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieenergyfast", {
    Name     = "Zombie Energy Fast",
    Class    = "terminator_nextbot_zambieenergyfast",
    Category = "Nextbot Zambies"
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergyfast", ENT.PrintName )
    return
end

-- movement/stats
ENT.CoroutineThresh           = 0.00005
ENT.MaxPathingIterations      = 25000
ENT.JumpHeight                = 400
ENT.Term_Leaps                = true

ENT.SpawnHealth               = 100
ENT.HealthRegen               = 2
ENT.HealthRegenInterval       = 1

ENT.WalkSpeed                 = 150
ENT.MoveSpeed                 = 350
ENT.RunSpeed                  = 500
ENT.AccelerationSpeed         = 450

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed     = 1.15

ENT.FistDamageMul             = 0.25
ENT.DuelEnemyDist             = 450
ENT.TERM_MODELSCALE           = function( ) return math.Rand( 1.1, 1.18 ) end

-- arcs enabled on fast, tighter and quicker
ENT.ArcEnabled     = true
ENT.ArcIntervalMin = 0.35
ENT.ArcIntervalMax = 0.8
ENT.ArcRadius      = 120
ENT.ArcMagnitude   = 5
ENT.ArcScale       = 0.9

-- melee aim lowered (fix swinging over targets)
ENT.term_MeleeAimOffset         = Vector( 0, 0, -18 )
ENT.term_MeleeTraceZOffset      = -18
ENT.term_MeleeTraceStartOffset  = Vector( 0, 0, -12 )

local FAST_ZOMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL        = FAST_ZOMBIE_MODEL
ENT.MyPhysicsMass       = 60
ENT.TERM_FISTS          = "weapon_term_zombieclaws"
ENT.Models              = { FAST_ZOMBIE_MODEL }

ENT.IdleActivityTranslations = {
    [ ACT_MP_STAND_IDLE ]                = ACT_IDLE_ANGRY,
    [ ACT_MP_WALK ]                      = ACT_WALK,
    [ ACT_MP_RUN ]                       = ACT_RUN,
    [ ACT_MP_CROUCH_IDLE ]               = ACT_RUN,
    [ ACT_MP_CROUCHWALK ]                = ACT_RUN,
    [ ACT_MP_ATTACK_STAND_PRIMARYFIRE ]  = ACT_MELEE_ATTACK1,
    [ ACT_MP_ATTACK_CROUCH_PRIMARYFIRE ] = ACT_MELEE_ATTACK1,
    [ ACT_MP_RELOAD_STAND ]              = ACT_INVALID,
    [ ACT_MP_RELOAD_CROUCH ]             = ACT_INVALID,
    [ ACT_MP_JUMP ]                      = ACT_JUMP,
    [ ACT_MP_SWIM ]                      = ACT_RUN,
    [ ACT_LAND ]                         = ACT_LAND
}

ENT.zamb_CallAnim   = "BR2_Roar"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

local Random, Clamp = math.random, math.Clamp
local VEC_UP        = vector_up or Vector( 0, 0, 1 )

function ENT:AdditionalInitialize( )
    self:SetModel( FAST_ZOMBIE_MODEL )
    BaseClass.AdditionalInitialize( self )

    -- fast zombie sound profile
    self.term_SoundPitchShift   = -3
    self.term_SoundLevelShift   = 10
    self.term_LoseEnemySound    = "NPC_FastZombie.Idle"
    self.term_CallingSound      = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound    = "NPC_FastZombie.AlertNear"
    self.term_AttackSound       = { "NPC_FastZombie.Scream", "NPC_FastZombie.Frenzy" }
    self.term_AngerSound        = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound      = "NPC_FastZombie.Pain"
    self.term_DieSound          = "NPC_FastZombie.Die"
    self.term_JumpSound         = "NPC_FastZombie.LeapAttack"

    self.IdleLoopingSounds      = { "npc/fast_zombie/breathe_loop1.wav" }
    self.AngryLoopingSounds     = { "npc/fast_zombie/gurgle_loop1.wav" }
    self.AlwaysPlayLooping      = true

    self.HeightToStartTakingDamage = 800
    self.FallDamagePerHeight       = 0.005
    self.DeathDropHeight           = 3000

    self._nextArc = CurTime( ) + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )
end

-- hard override if base supports it (guarantee lower aim)
function ENT:ComputeMeleeAimPos( enemy )
    local base = BaseClass.ComputeMeleeAimPos and BaseClass.ComputeMeleeAimPos( self, enemy )
    local pos  = base or ( IsValid( enemy ) and enemy:WorldSpaceCenter( ) ) or ( self:GetPos( ) + Vector( 0, 0, 48 ) )

    return pos + Vector( 0, 0, -18 )
end

function ENT:AdditionalFootstep( pos )
    local groundEnt = self:GetGroundEntity( )

    if Random( 0, 100 ) < 20 then
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 60, self:GetPos( ) )
            self:DoAoeEnergyDamage( groundEnt, 120 )
        end
    else
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 6, self:GetPos( ) )
        end
    end

    local speed = self:GetVelocity( ):Length( )
    self:DoEffect( "effects/fluttercore_gmod", pos, Clamp( speed / 80, 0.5, 3 ), VEC_UP )
    self:DoEffect( "bloodspray",               pos, 4,                          VEC_UP, 4, 7 )
end

function ENT:AdditionalThink( )
    BaseClass.AdditionalThink( self )
end

function ENT:HandleFlinching( ) end