AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiewraith"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Wraith Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiewraithelite", {
    Name = "Zombie Wraith Elite",
    Class = "terminator_nextbot_zambiewraithelite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiewraithelite", ENT.PrintName )
    return

end

ENT.JumpHeight = 800
ENT.Term_Leaps = true
ENT.SpawnHealth = 250
ENT.HealthRegen = 25
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 150
ENT.MoveSpeed = 350
ENT.RunSpeed = 500
ENT.AccelerationSpeed = 450
ENT.DecelerationSpeed = 1000
ENT.neverManiac = true

ENT.zamb_AlwaysFlank = true
ENT.zamb_LookAheadWhenRunning = true -- turn this on since we do big bursts of damage unlike the normal fast z

ENT.FistDamageMul = 6
ENT.FistRangeMul = 2
ENT.zamb_MeleeAttackSpeed = 1.5
ENT.zamb_MeleeAttackHitFrameMul = 17
ENT.DuelEnemyDist = 650

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.TERM_MODELSCALE = function() return math.Rand( 1.2, 1.25 ) end
ENT.CollisionBounds = { Vector( -10, -10, 0 ), Vector( 10, 10, 40 ) }
ENT.MyPhysicsMass = 100

ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = "BR2_Attack"

function ENT:AdditionalInitialize()

    BaseClass.AdditionalInitialize( self )

    --[[
    for ind = 1, self:GetSequenceCount() do
        local inf = self:GetSequenceInfo( ind )
        if inf then
            PrintTable( inf )

        end
        print( "-----" )

    end--]]

    self.term_SoundPitchShift = -20
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "npc/fast_zombie/fz_frenzy1.wav", "npc/fast_zombie/fz_scream1.wav", "npc/fast_zombie/leap1.wav" }
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

    self.HeightToStartTakingDamage = 600
    self.FallDamagePerHeight = 0.015
    self.DeathDropHeight = 2000
    self.zambwraith_InvisGraceMul = 0.5

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl
    local snd
    if self:IsSolid() then
        lvl = 85
        if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
            lvl = 76

        end
        snd = foot and "NPC_FastZombie.GallopRight" or "NPC_FastZombie.GallopLeft"

    else
        lvl = 70 -- quieter than normal wraith...
        snd = "NPC_FastHeadcrab.Footstep"

    end
    self:EmitSound( snd, lvl, 80, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

function ENT:PostTookDamage( dmg )
    if self:Health() > 0 and self:Health() < self:GetMaxHealth() * 0.75 and self.DistToEnemy > 100 then
        self:DoHiding( true )

    end
    BaseClass.PostTookDamage( self, dmg )

end