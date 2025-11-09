AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Paper"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiepaper", {
    Name = "Zombie Paper",
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

ENT.TERM_MODELSCALE = function() return math.Rand( 0.85, 0.95 ) end

ENT.BleedDuration = 3
ENT.BleedDamage = 2
ENT.BleedTicks = 6

ENT.IsPaperZambie = true

if CLIENT then
    language.Add( "terminator_nextbot_zambiepaper", ENT.PrintName )
    return

end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetSubMaterial( 0, "models/props_c17/paper01" )
    self:SetColor( Color( 230, 220, 200 ) )

    self.HeightToStartTakingDamage = 100
    self.FallDamagePerHeight = 0.3
    self.DeathDropHeight = 500

end

local paperZombieCount = #ents.FindByClass( "terminator_nextbot_zambiepaper*" )

ENT.MyClassTask = {
    OnStart = function( self, data )
        paperZombieCount = paperZombieCount + 1
        if paperZombieCount <= 1 then
            hook.Add( "PostEntityTakeDamage", "PaperZombie_BleedEffect", function( target, dmg, took )
                if not took then return end

                local attacker = dmg:GetAttacker()
                if not attacker.IsPaperZambie then return end

                attacker:ApplyBleedEffect( target )

            end )
        end
    end,
}

function ENT:OnRemove()
    paperZombieCount = paperZombieCount - 1
    if paperZombieCount <= 0 then
        hook.Remove( "PostEntityTakeDamage", "PaperZombie_BleedEffect" )

    end
end

function ENT:ApplyBleedEffect( victim )
    if not IsValid( victim ) then return end
    if not victim:Health() or victim:Health() <= 0 then return end

    local cur = CurTime()
    if victim.PaperZombie_BleedingUntil and victim.PaperZombie_BleedingUntil > cur then return end

    local bleedDuration = self.BleedDuration
    local bleedDamage = self.BleedDamage
    local bleedTicks = self.BleedTicks
    local tickDelay = bleedDuration / bleedTicks

    victim.PaperZombie_BleedingUntil = cur + bleedDuration

    local effectdata = EffectData()
    effectdata:SetOrigin( victim:GetPos() + Vector( 0, 0, 40 ) )
    effectdata:SetColor( victim:GetBloodColor() )
    effectdata:SetScale( 1 )
    util.Effect( "bloodspray", effectdata )

    victim:EmitSound( "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav", 70, math.random( 90, 110 ) )

    local timerName = "PaperZombie_Bleed_" .. victim:EntIndex() .. "_" .. cur
    local tickCount = 0

    timer.Create( timerName, tickDelay, bleedTicks, function()
        if not IsValid( victim ) or not victim:Health() or victim:Health() <= 0 then
            timer.Remove( timerName )
            return

        end

        tickCount = tickCount + 1

        local dmg = DamageInfo()
        dmg:SetDamage( bleedDamage )
        dmg:SetAttacker( IsValid( self ) and self or game.GetWorld() )
        dmg:SetInflictor( IsValid( self ) and self or game.GetWorld() )
        dmg:SetDamageType( DMG_SLASH )
        victim:TakeDamageInfo( dmg )

        if tickCount % 2 == 0 then
            local bloodeffect = EffectData()
            bloodeffect:SetOrigin( victim:GetPos() + Vector( 0, 0, 40 ) )
            bloodeffect:SetColor( victim:GetBloodColor() )
            bloodeffect:SetScale( 0.5 )
            util.Effect( "bloodspray", bloodeffect )

        end
    end )
end