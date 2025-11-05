AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Paper Zombie"
ENT.Spawnable = false
ENT.Author = "regunkyle"
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
    
    local setupMat
    local desiredBaseTexture = "models/props_c17/paper01"
    local mat = "nextbotZambies_PaperFlesh"
    
    function ENT:AdditionalClientInitialize()
        if setupMat then return end
        setupMat = true

        local newMat = CreateMaterial( mat, "VertexLitGeneric", {
            ["$basetexture"] = desiredBaseTexture,
        } )

        if newMat and newMat:GetKeyValues()["$basetexture"] then
            newMat:SetTexture( "$basetexture", desiredBaseTexture )
        end

        self:SetSubMaterial( 0, "!" .. mat )
    end
    return
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetModelScale( math.Rand( 0.85, 0.95 ) )
    self:SetSubMaterial( 0, "!nextbotZambies_PaperFlesh" )
    self:SetColor( Color( 230, 220, 200 ) )
    
    self.HeightToStartTakingDamage = 100
    self.FallDamagePerHeight = 0.3
    self.DeathDropHeight = 500
    
    self.Paper_NextBleedCheck = 0
end

function ENT:DoCustomTasks( defaultTasks )
    BaseClass.DoCustomTasks( self, defaultTasks )
    
    local oldOnAttack = self.TaskList["zambstuff_handler"].OnAttack
    self.TaskList["zambstuff_handler"].OnAttack = function( self, data )
        if oldOnAttack then
            oldOnAttack( self, data )
        end
        
        local enemy = self:GetEnemy()
        if IsValid( enemy ) and self.DistToEnemy < 100 then
            self:ApplyBleedEffect( enemy )
        end
    end
end

function ENT:ApplyBleedEffect( victim )
    if not IsValid( victim ) then return end
    
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
            if not IsValid( victim ) or not victim:Health() or victim:Health() <= 0 then return end
            
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
        end )
    end
end

function ENT:OnMeleeAttack( hitEnt )
    if not IsValid( hitEnt ) then return end
    
    local damage = DamageInfo()
    damage:SetAttacker( self )
    damage:SetInflictor( self )
    damage:SetDamage( 8 * self.FistDamageMul )
    damage:SetDamageType( DMG_SLASH )
    damage:SetDamagePosition( hitEnt:GetPos() )
    
    hitEnt:TakeDamageInfo( damage )
    
    self:ApplyBleedEffect( hitEnt )
end