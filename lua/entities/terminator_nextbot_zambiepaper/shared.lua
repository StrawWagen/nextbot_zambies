AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Paper Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiepaper", {
    Name = "Paper Zombie",
    Class = "terminator_nextbot_zambiepaper",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 25
ENT.WalkSpeed = 60
ENT.MoveSpeed = 180
ENT.RunSpeed = 280
ENT.FistDamageMul = 0.15
ENT.MyPhysicsMass = 40

ENT.term_SoundPitchShift = 20
ENT.zamb_BrainsChance = 5

if CLIENT then
    language.Add( "terminator_nextbot_zambiepaper", ENT.PrintName )
    
    function ENT:AdditionalClientInitialize()
        self:SetSubMaterial( 0, "models/props_c17/paper01" )
    end
    return
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetModelScale( math.Rand( 0.85, 0.95 ) )
    self:SetSubMaterial( 0, "models/props_c17/paper01" )
    self:SetColor( Color( 230, 220, 200 ) )
    
    self.HeightToStartTakingDamage = 100
    self.FallDamagePerHeight = 0.3
    self.DeathDropHeight = 500
end

ENT.MyClassTask = {
    OnStart = function( self, data )
        -- Hook to apply bleed on successful damage
        hook.Add( "PostEntityTakeDamage", "PaperZombie_BleedEffect_" .. self:EntIndex(), function( target, dmg, took )
            if not IsValid( self ) then 
                hook.Remove( "PostEntityTakeDamage", "PaperZombie_BleedEffect_" .. self:EntIndex() )
                return 
            end
            if not took then return end
            if dmg:GetAttacker() ~= self then return end
            
            self:ApplyBleedEffect( target )
        end )
    end,
    OnKilled = function( self, data )
        -- Clean up hook
        hook.Remove( "PostEntityTakeDamage", "PaperZombie_BleedEffect_" .. self:EntIndex() )
    end,
}

function ENT:ApplyBleedEffect( victim )
    if not IsValid( victim ) then return end
    if not victim:Health() or victim:Health() <= 0 then return end
    
    -- Prevent multiple bleeds on same victim
    if victim.PaperZombie_Bleeding then return end
    victim.PaperZombie_Bleeding = true
    
    local bleedDuration = 3
    local bleedDamage = 2
    local bleedTicks = 6
    local tickDelay = bleedDuration / bleedTicks
    
    local effectdata = EffectData()
    effectdata:SetOrigin( victim:GetPos() + Vector( 0, 0, 40 ) )
    effectdata:SetColor( victim:GetBloodColor() )
    effectdata:SetScale( 1 )
    util.Effect( "bloodspray", effectdata )
    
    victim:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav", 70, math.random( 90, 110 ) )
    
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
                bloodeffect:SetScale( 0.5 )
                util.Effect( "bloodspray", bloodeffect )
            end
            
            -- Clear bleeding flag on last tick
            if i == bleedTicks then
                victim.PaperZombie_Bleeding = nil
            end
        end )
    end
end