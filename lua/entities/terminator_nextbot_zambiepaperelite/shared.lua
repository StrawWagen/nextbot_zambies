AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiepaper"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Paper Elite"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiepaperelite", {
    Name = "Zombie Paper Elite",
    Class = "terminator_nextbot_zambiepaperelite",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 80
ENT.WalkSpeed = 70
ENT.MoveSpeed = 210
ENT.RunSpeed = 350
ENT.FistDamageMul = 0.35
ENT.MyPhysicsMass = 55

ENT.term_SoundPitchShift = 10
ENT.zamb_BrainsChance = 40

ENT.TERM_MODELSCALE = function() return math.Rand( 1.0, 1.1 ) end
ENT.CollisionBounds = { Vector( -12, -12, 0 ), Vector( 12, 12, 72 ) }

ENT.BleedDuration = 5
ENT.BleedDamage = 3
ENT.BleedTicks = 10

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
    
    self:SetSubMaterial( 0, "models/props_c17/paper01" )
    
    self.HeightToStartTakingDamage = 120
    self.FallDamagePerHeight = 0.25
    self.DeathDropHeight = 600
    
    self.HasBrains = math.random( 1, 100 ) < 40
end