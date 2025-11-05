AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Mecha Zombie"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiemecha", {
    Name = "Mecha Zombie",
    Class = "terminator_nextbot_zambiemecha",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 500
ENT.WalkSpeed = 70
ENT.MoveSpeed = 180
ENT.RunSpeed = 300
ENT.AccelerationSpeed = 1000
ENT.FistDamageMul = 1.5
ENT.MyPhysicsMass = 200
ENT.JumpHeight = 200

ENT.DoMetallicDamage = true
ENT.MetallicMoveSounds = true
ENT.ReallyStrong = true
ENT.ReallyHeavy = true

ENT.HasBrains = true
ENT.IsStupid = false
ENT.IsFodder = false

ENT.term_SoundPitchShift = -30
ENT.term_SoundLevelShift = 10

ENT.Mecha_LastShockwave = 0
ENT.Mecha_ShockwaveCooldown = 5

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Call",
        desc = "Let out your anger in a loud call.",
        ratelimit = 4,
        svAction = function( _drive, _driver, bot )
            bot:ZAMB_AngeringCall( true, 1, true )
        end,
    }
}

if CLIENT then
    language.Add( "terminator_nextbot_zambiemecha", ENT.PrintName )
    
    local setupMat
    local desiredBaseTexture = "phoenix_storms/cube"
    local mat = "nextbotZambies_MechaFlesh"
    
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
    
    self:SetModelScale( 1.5 )
    self:SetSubMaterial( 0, "!nextbotZambies_MechaFlesh" )
    self:SetColor( Color( 60, 60, 80 ) )
    
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.05
    self.DeathDropHeight = 2000
    
    self.HasBrains = true
    self.IsStupid = false
end

function ENT:DoCustomTasks( defaultTasks )
    BaseClass.DoCustomTasks( self, defaultTasks )
    
    local oldOnLandOnGround = self.TaskList["zambstuff_handler"].OnLandOnGround
    self.TaskList["zambstuff_handler"].OnLandOnGround = function( self, data, landedOn, height )
        if oldOnLandOnGround then
            oldOnLandOnGround( self, data, landedOn, height )
        end
        
        if height > 350 then
            self:CreateShockwave( height )
        end
    end
    
    -- Override OnKilled to add self-destruct
    local oldOnKilled = self.TaskList["zambstuff_handler"].OnKilled
    self.TaskList["zambstuff_handler"].OnKilled = function( self, data, damage, rag )
        if oldOnKilled then
            oldOnKilled( self, data, damage, rag )
        end
        
        self:SelfDestruct()
    end
end

function ENT:CreateShockwave( height )
    local cur = CurTime()
    if self.Mecha_LastShockwave + self.Mecha_ShockwaveCooldown > cur then return end
    self.Mecha_LastShockwave = cur
    
    local pos = self:GetPos()
    local radius = math.Clamp( height * 2, 300, 800 )
    local damage = math.Clamp( height * 0.5, 30, 150 )
    
    -- Sound
    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", 100, 70 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 100, 80 )
    
    -- Create beam ring effects
    local rings = 5
    for i = 1, rings do
        timer.Simple( i * 0.1, function()
            if not IsValid( self ) then return end
            
            local ringRadius = ( radius / rings ) * i
            local color = Color( 255, 100, 0 )
            
            effects.BeamRingPoint( pos, 0.3, 10, ringRadius, 16, 0, color, { material = "sprites/physbeam", framerate = 20 } )
        end )
    end
    
    -- Damage and push entities
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self then continue end
        if not IsValid( ent ) then continue end
        
        local entPos = ent:GetPos()
        local dir = ( entPos - pos ):GetNormalized()
        local dist = entPos:Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        -- Damage
        if ent:Health() and ent:Health() > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage( damage * distFrac )
            dmg:SetAttacker( self )
            dmg:SetInflictor( self )
            dmg:SetDamageType( DMG_BLAST )
            dmg:SetDamageForce( dir * 10000 * distFrac )
            ent:TakeDamageInfo( dmg )
        end
        
        -- Push
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 1000 * distFrac + Vector( 0, 0, 400 * distFrac ) )
        elseif ent:GetPhysicsObject():IsValid() then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 800 * distFrac + Vector( 0, 0, phys:GetMass() * 200 * distFrac ) )
        end
    end
    
    -- Screen shake
    util.ScreenShake( pos, 15, 5, 1.5, radius * 1.5 )
end

function ENT:SelfDestruct()
    local pos = self:GetPos()
    local radius = 650
    local damage = 250
    
    -- Explosion sound
    sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 120, 70 )
    
    -- Large explosion effect at center
    local explode = EffectData()
    explode:SetOrigin( pos )
    explode:SetMagnitude( 15 )
    explode:SetScale( 8 )
    explode:SetRadius( radius )
    util.Effect( "Explosion", explode )
    
    -- Additional helicopter bomb effects
    for i = 1, 5 do
        timer.Simple( i * 0.08, function()
            local explode2 = EffectData()
            explode2:SetOrigin( pos + VectorRand() * 80 )
            explode2:SetMagnitude( 10 )
            explode2:SetScale( 4 )
            util.Effect( "HelicopterMegaBomb", explode2 )
        end )
    end
    
    -- Massive sparks and metal debris
    for i = 1, 20 do
        timer.Simple( math.Rand( 0, 0.5 ), function()
            local sparkPos = pos + VectorRand() * 150
            local sparks = EffectData()
            sparks:SetOrigin( sparkPos )
            sparks:SetNormal( VectorRand() )
            sparks:SetMagnitude( 12 )
            sparks:SetScale( 8 )
            sparks:SetRadius( 10 )
            util.Effect( "MetalSpark", sparks )
        end )
    end
    
    -- Fire/smoke plume
    for i = 1, 10 do
        timer.Simple( i * 0.1, function()
            local smoke = EffectData()
            smoke:SetOrigin( pos + Vector( 0, 0, i * 30 ) )
            smoke:SetScale( 20 )
            util.Effect( "explosion_satchel", smoke )
        end )
    end
    
    -- Damage and push entities
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if not IsValid( ent ) then continue end
        
        local entPos = ent:GetPos()
        local dir = ( entPos - pos ):GetNormalized()
        local dist = entPos:Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        -- Damage
        if ent:Health() and ent:Health() > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage( damage * distFrac )
            dmg:SetAttacker( game.GetWorld() )
            dmg:SetInflictor( game.GetWorld() )
            dmg:SetDamageType( bit.bor( DMG_BLAST, DMG_BURN ) )
            dmg:SetDamageForce( dir * 25000 * distFrac )
            ent:TakeDamageInfo( dmg )
        end
        
        -- Push
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 2000 * distFrac + Vector( 0, 0, 800 * distFrac ) )
        elseif ent:GetPhysicsObject():IsValid() then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 1500 * distFrac + Vector( 0, 0, phys:GetMass() * 600 * distFrac ) )
        end
        
        -- Ignite nearby entities
        if dist < radius * 0.6 and ent.Ignite then
            ent:Ignite( 15 * distFrac )
        end
    end
    
    -- Massive screen shake
    util.ScreenShake( pos, 30, 15, 3, radius * 2.5 )
    
    -- Create sprite effect
    local sprite = EffectData()
    sprite:SetOrigin( pos )
    sprite:SetScale( 15 )
    sprite:SetMagnitude( 3 )
    util.Effect( "cball_explode", sprite )
end

function ENT:OnInjured( damage )
    if damage:IsFallDamage() and damage:GetDamage() < 50 then
        return true
    end
    
    return BaseClass.OnInjured and BaseClass.OnInjured( self, damage )
end