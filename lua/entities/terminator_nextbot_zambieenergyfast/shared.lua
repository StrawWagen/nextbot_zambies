AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieenergy"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Energy Fast"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambieenergyfast", {
    Name = "Zombie Energy Fast",
    Class = "terminator_nextbot_zambieenergyfast",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergyfast", ENT.PrintName )
    return

end

-- pathing/move
ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 20
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 400
ENT.Term_Leaps = true

ENT.SpawnHealth = 100
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1

ENT.WalkSpeed = 150
ENT.MoveSpeed = 700
ENT.RunSpeed = 1000
ENT.AccelerationSpeed = 450

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 1.15

ENT.FistDamageMul = 0.25
ENT.zamb_MeleeAttackSpeed = 3
ENT.DuelEnemyDist = 450

ENT.TERM_MODELSCALE = function() return math.Rand( 1.10, 1.18 ) end
ENT.MyPhysicsMass = 60

ENT.TERM_FISTS = "weapon_term_zombieclaws"

-- arcs (faster, smaller)
ENT.ArcEnabled = true
ENT.ArcIntervalMin = 0.35
ENT.ArcIntervalMax = 0.80
ENT.ArcRadius = 120
ENT.ArcMagnitude = 5
ENT.ArcScale = 0.9

-- swing lower so it doesn’t over-shoot targets
ENT.term_MeleeAimOffset = Vector( 0, 0, -18 )
ENT.term_MeleeTraceZOffset = -18
ENT.term_MeleeTraceStartOffset = Vector( 0, 0, -12 )

local FAST_ZOMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZOMBIE_MODEL
ENT.Models = { FAST_ZOMBIE_MODEL }

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
    [ ACT_LAND ]                         = ACT_LAND,
}

ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZOMBIE_MODEL )
    BaseClass.AdditionalInitialize( self )

    self.HasBrains = true

    self.term_SoundPitchShift = 35
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

    self._nextArc = CurTime() + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )

end

-- fallback aim override if base supports it
function ENT:ComputeMeleeAimPos( enemy )
    local base = BaseClass.ComputeMeleeAimPos and BaseClass.ComputeMeleeAimPos( self, enemy )
    local pos = base or ( IsValid( enemy ) and enemy:WorldSpaceCenter() ) or ( self:GetPos() + Vector( 0, 0, 48 ) )

    return pos + Vector( 0, 0, -18 )

end

local scorchUpOffs = Vector( 0, 0, 10 )
local scorchDownOffs = Vector( 0, 0, -20 )

function ENT:AdditionalFootstep( pos )
    if math.random( 0, 100 ) < 25 then
        local snd = "ambient/energy/spark" .. math.random( 1, 6 ) .. ".wav"
        local pit = math.random( 120, 140 )
        self:EmitSound( snd, 75, pit )
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 100, self:GetPos() )
            self:DoAoeEnergyDamage( groundEnt )

        end
    else
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 10, self:GetPos() )

        end
    end
    util.Decal( "SmallScorch", pos + scorchUpOffs, pos + scorchDownOffs, self )
    local effData = EffectData()
    effData:SetOrigin( pos + Vector( math.random( -10, 10 ), math.random( -10, 10 ), 0 ) )
    effData:SetScale( 4 )
    effData:SetRadius( 8 )
    effData:SetMagnitude( math.Rand( 1, 2 ) )
    effData:SetNormal( scorchUpOffs )
    util.Effect( "ElectricSpark", effData )

end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )

end

function ENT:HandleFlinching() end