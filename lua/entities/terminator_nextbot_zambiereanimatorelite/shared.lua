
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiereanimator"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName   = "Zombie Reanimator Elite"
ENT.Spawnable   = false
ENT.Author	    = "Bluekrakan"

list.Set( "NPC", "terminator_nextbot_zambiereanimatorelite", {
	Name = "Zombie Reanimator Elite",
	Class = "terminator_nextbot_zambiereanimatorelite",
	Category = "Nextbot Zambies"
} )

ENT.JumpHeight = 650
ENT.SpawnHealth = 20000
ENT.ExtraSpawnHealthPerPlayer = 500
ENT.HealthRegen = 3
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 500
ENT.WalkSpeed = 175
ENT.MoveSpeed = 650
ENT.RunSpeed = 900
ENT.AccelerationSpeed = 800

ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 3
ENT.FistForceMul = 2
ENT.FistRangeMul = 2
ENT.PrefersVehicleEnemies = false

ENT.TERM_MODELSCALE = 2.5
ENT.CollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 22 ) }
ENT.MyPhysicsMass = 5000

if CLIENT then
    language.Add( "terminator_nextbot_zambiereanimatorelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.8, 0.8, 0.5 )
        BaseClass.Draw( self )

    end
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self.term_SoundPitchShift = -50

    self.reanim_ReviveDebuff = -10
    self.reanim_ReviveThruWalls = true -- :steamhappy:
    self.reanim_TryReviveInterval = 6
    self.reanim_PulseColor = 144
    self.reanim_PulseRadius = 6000

end
