AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiepaper"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Paper Zombie Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiepaperelite", {
    Name = "Paper Zombie Elite",
    Class = "terminator_nextbot_zambiepaperelite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiepaperelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.9, 0.8, 0.7 )
        self:DrawModel()
    end
    return
end

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

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetModelScale( math.Rand( 1.0, 1.1 ) )
    self:SetSubMaterial( 0, "models/props_c17/paper01" )
    self:SetColor( Color( 210, 190, 170 ) )
    
    self.HeightToStartTakingDamage = 120
    self.FallDamagePerHeight = 0.25
    self.DeathDropHeight = 600
    
    self.HasBrains = math.random( 1, 100 ) < 40
end

-- Enhanced bleed effect
function ENT:ApplyBleedEffect( victim )
    if not IsValid( victim ) then return end
    if not victim:Health() or victim:Health() <= 0 then return end
    
    if victim.PaperZombie_Bleeding then return end
    victim.PaperZombie_Bleeding = true
    
    local bleedDuration = 5 -- Longer bleed
    local bleedDamage = 3 -- More damage
    local bleedTicks = 10 -- More ticks
    local tickDelay = bleedDuration / bleedTicks
    
    local effectdata = EffectData()
    effectdata:SetOrigin( victim:GetPos() + Vector( 0, 0, 40 ) )
    effectdata:SetColor( victim:GetBloodColor() )
    effectdata:SetScale( 2 )
    util.Effect( "bloodspray", effectdata )
    
    victim:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav", 75, math.random( 85, 105 ) )
    
    for i = 1, bleedTicks do
        timer.Simple( tickDelay * i, function()
            if not IsValid( victim ) or not victim:Health() or victim:Health() <= 0 then 
                if IsValid( victim ) then
                    victim.PaperZombie_Bleeding = nil
                end
                return 
            end
            
            local dmg = DamageInfo()
            dmg:SetDamage( bleedDamage )
            dmg:SetAttacker( IsValid( self ) and self or game.GetWorld() )
            dmg:SetInflictor( IsValid( self ) and self or game.GetWorld() )
            dmg:SetDamageType( DMG_SLASH )
            victim:TakeDamageInfo( dmg )
            
            if i % 2 == 0 then
                local bloodeffect = EffectData()
                bloodeffect:SetOrigin( victim:GetPos() + Vector( 0, 0, 40 ) )
                bloodeffect:SetColor( victim:GetBloodColor() )
                bloodeffect:SetScale( 1 )
                util.Effect( "bloodspray", bloodeffect )
            end
            
            if i == bleedTicks then
                victim.PaperZombie_Bleeding = nil
            end
        end )
    end
end