
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiereanimator"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName	= "Zombie Reanimator Elite"
ENT.Spawnable	= false
ENT.Author		= "Bluekrakan"

list.Set( "NPC", "terminator_nextbot_zambiereanimatorelite", {
	Name		= "Zombie Reanimator Elite",
	Class		= "terminator_nextbot_zambiereanimatorelite",
	Category	= "Nextbot Zambies"
} )

ENT.JumpHeight = 650
ENT.SpawnHealth = 4000
ENT.ExtraSpawnHealthPerPlayer = 100
ENT.HealthRegen = 3
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 500
ENT.WalkSpeed = 175
ENT.MoveSpeed = 600
ENT.RunSpeed = 900
ENT.AccelerationSpeed = 800

ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 3
ENT.FistForceMul = 2
ENT.FistRangeMul = 2
ENT.PrefersVehicleEnemies = false

ENT.TERM_MODELSCALE = 2
ENT.CollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 30 ) }
ENT.MyPhysicsMass = 1600

local IdleActivity = ACT_IDLE_ANGRY
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_WALK,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_WALK,
    [ACT_LAND]                          = ACT_LAND,
}

if CLIENT then
	language.Add( "terminator_nextbot_zambiereanimatorelite", ENT.PrintName )

	function ENT:Draw()
		render.SetColorModulation( 0.75, 0.75, 0.2 )
		BaseClass.Draw( self )
		
	end
end

function ENT:AdditionalInitialize()
	BaseClass.AdditionalInitialize( self )
	
	self.term_SoundPitchShift = -50
	self.reanim_ReviveDebuff = -10
	self.reanim_ShriekSoundLevelShift = 40 -- Make it heard from farther
	self.reanim_PulseColor = 144
	self.reanim_PulseRadius = 3500

end
