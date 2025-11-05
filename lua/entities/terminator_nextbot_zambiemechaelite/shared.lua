AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiemecha"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Mecha Zombie Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiemechaelite", {
    Name = "Mecha Zombie Elite",
    Class = "terminator_nextbot_zambiemechaelite",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 5000
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 2

ENT.WalkSpeed = 85
ENT.MoveSpeed = 240
ENT.RunSpeed = 420
ENT.AccelerationSpeed = 1200

ENT.FistDamageMul = 2.0
ENT.MyPhysicsMass = 300
ENT.JumpHeight = 300

ENT.DuelEnemyDist = 500
ENT.CloseEnemyDistance = 600

ENT.HeightToStartTakingDamage = 500
ENT.FallDamagePerHeight = 0.025
ENT.DeathDropHeight = 3000

ENT.term_SoundPitchShift = -45
ENT.term_SoundLevelShift = 20

ENT.Mecha_ShockwaveCooldown = 4
ENT.Mecha_ShockwaveThreshold = 250
ENT.Mecha_CriticalHealth = 0.25

ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds = { Vector( -18, -18, 0 ), Vector( 18, 18, 90 ) }

if CLIENT then
    language.Add( "terminator_nextbot_zambiemechaelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.4, 0.4, 0.6 )
        self:DrawModel()
        render.SetColorModulation( 1, 1, 1 )
    end
    
    function ENT:AdditionalClientInitialize()
        self:SetSubMaterial( 0, "phoenix_storms/cube" )
    end
    
    return
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetModelScale( 2.25 )
    self:SetSubMaterial( 0, "phoenix_storms/cube" )
    self:SetColor( Color( 35, 35, 55 ) )
    
    self.HasBrains = true
    self.IsStupid = false
    
    self.Mecha_IsEnraged = false
    self.Mecha_NextHealthRegen = 0
end

ENT.MyClassTask = {
    BehaveUpdate = function( self, data )
        local cur = CurTime()
        
        if self.Mecha_NextHealthRegen < cur then
            self.Mecha_NextHealthRegen = cur + self.HealthRegenInterval
            local newHealth = math.min( self:Health() + self.HealthRegen, self:GetMaxHealth() )
            self:SetHealth( newHealth )
        end
        
        if not self.Mecha_IsEnraged then
            local healthPercent = self:Health() / self:GetMaxHealth()
            if healthPercent <= self.Mecha_CriticalHealth then
                self:EnterEnragedState()
            end
        end
    end,
    
    OnLandOnGround = function( self, data, landedOn, height )
        if height > self.Mecha_ShockwaveThreshold then
            self:CreateEliteShockwave( height )
        end
    end,
    
    OnKilled = function( self, data, damage, rag )
        self:EliteSelfDestruct()
    end,
    
    OnDamaged = function( self, data, damage )
        if damage:IsFallDamage() and damage:GetDamage() < 150 then
            return true
        end
        
        if not damage:IsFallDamage() and damage:GetDamage() > 20 and math.random( 1, 100 ) < 15 then
            timer.Simple( 0.1, function()
                if not IsValid( self ) then return end
                self:CreateMiniShockwave()
            end )
        end
    end,
}

function ENT:EnterEnragedState()
    self.Mecha_IsEnraged = true
    
    self.RunSpeed = self.RunSpeed * 1.3
    self.FistDamageMul = self.FistDamageMul * 1.4
    self.Mecha_ShockwaveCooldown = 2.5
    
    self:EmitSound( "npc/strider/strider_pain" .. math.random( 1, 5 ) .. ".wav", 110, 60 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 110, 70 )
    
    util.ScreenShake( self:GetPos(), 15, 10, 2, 1000 )
    
    for i = 1, 5 do
        timer.Simple( i * 0.1, function()
            if not IsValid( self ) then return end
            
            local pos = self:WorldSpaceCenter()
            local sparks = EffectData()
            sparks:SetOrigin( pos + VectorRand() * 50 )
            sparks:SetNormal( VectorRand() )
            sparks:SetMagnitude( 10 )
            sparks:SetScale( 5 )
            util.Effect( "ElectricSpark", sparks )
        end )
    end
    
    self:ReallyAnger( 100 )
end

function ENT:CreateMiniShockwave()
    local pos = self:GetPos()
    local radius = 250
    local damage = 25
    
    self:EmitSound( "ambient/energy/zap" .. math.random( 1, 9 ) .. ".wav", 85, math.random( 80, 120 ) )
    
    for i = 1, 3 do
        timer.Simple( i * 0.05, function()
            local color = Color( 100, 100, 255 )
            effects.BeamRingPoint( pos, 0.2, 5, ( radius / 3 ) * i, 12, 0, color, { material = "sprites/physbeam", framerate = 20 } )
        end )
    end
    
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self then continue end
        if not IsValid( ent ) then continue end
        if not ent:Health() or ent:Health() <= 0 then continue end
        
        local dist = ent:GetPos():Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        local dmg = DamageInfo()
        dmg:SetDamage( damage * distFrac )
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetDamageType( DMG_SHOCK )
        ent:TakeDamageInfo( dmg )
    end
end

function ENT:CreateEliteShockwave( height )
    local cur = CurTime()
    if self.Mecha_LastShockwave + self.Mecha_ShockwaveCooldown > cur then return end
    self.Mecha_LastShockwave = cur
    
    local pos = self:GetPos()
    local radius = math.Clamp( height * 3, 400, 1200 )
    local damage = math.Clamp( height * 0.8, 60, 300 )
    
    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", 115, 50 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 115, 60 )
    self:EmitSound( "npc/strider/fire.wav", 110, 80 )
    
    local rings = 8
    for i = 1, rings do
        timer.Simple( i * 0.07, function()
            if not IsValid( self ) then return end
            
            local ringRadius = ( radius / rings ) * i
            
            local color1 = Color( 255, 120, 20 )
            effects.BeamRingPoint( pos, 0.5, 20, ringRadius, 24, 0, color1, { material = "sprites/physbeam", framerate = 20 } )
            
            timer.Simple( 0.04, function()
                local color2 = Color( 80, 120, 255 )
                effects.BeamRingPoint( pos, 0.4, 15, ringRadius * 0.8, 20, 0, color2, { material = "sprites/physbeam", framerate = 20 } )
            end )
        end )
    end
    
    for i = 1, 12 do
        timer.Simple( math.Rand( 0, 0.3 ), function()
            local dustPos = pos + VectorRand() * ( radius * 0.5 )
            dustPos.z = pos.z
            
            local dust = EffectData()
            dust:SetOrigin( dustPos )
            dust:SetScale( 10 )
            dust:SetMagnitude( 5 )
            util.Effect( "ThumperDust", dust )
        end )
    end
    
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self then continue end
        if not IsValid( ent ) then continue end
        
        local entPos = ent:GetPos()
        local dir = ( entPos - pos ):GetNormalized()
        local dist = entPos:Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        if ent:Health() and ent:Health() > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage( damage * distFrac )
            dmg:SetAttacker( self )
            dmg:SetInflictor( self )
            dmg:SetDamageType( DMG_BLAST )
            dmg:SetDamageForce( dir * 18000 * distFrac )
            ent:TakeDamageInfo( dmg )
        end
        
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 1800 * distFrac + Vector( 0, 0, 700 * distFrac ) )
        elseif ent:GetPhysicsObject():IsValid() then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 1400 * distFrac + Vector( 0, 0, phys:GetMass() * 500 * distFrac ) )
        end
    end
    
    util.ScreenShake( pos, 25, 10, 2.5, radius * 2 )
end

function ENT:EliteSelfDestruct()
    local pos = self:GetPos()
    local radius = 1000
    local damage = 500
    
    for i = 1, 3 do
        timer.Simple( i * 0.2, function()
            sound.Play( "buttons/button17.wav", pos, 100, 150 - ( i * 30 ) )
        end )
    end
    
    timer.Simple( 0.6, function()
        sound.Play( "npc/strider/strider_die1.wav", pos, 140, 50 )
        sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 140, 50 )
        sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 140, 70 )
        sound.Play( "ambient/levels/labs/electric_explosion1.wav", pos, 140, 60 )
        
        local explode = EffectData()
        explode:SetOrigin( pos )
        explode:SetMagnitude( 25 )
        explode:SetScale( 15 )
        explode:SetRadius( radius )
        util.Effect( "Explosion", explode )
        
        for i = 1, 12 do
            timer.Simple( i * 0.05, function()
                local bombPos = pos + VectorRand() * 150
                local bomb = EffectData()
                bomb:SetOrigin( bombPos )
                bomb:SetMagnitude( 18 )
                bomb:SetScale( 8 )
                util.Effect( "HelicopterMegaBomb", bomb )
            end )
        end
        
        for i = 1, 40 do
            timer.Simple( math.Rand( 0, 0.8 ), function()
                local sparkPos = pos + VectorRand() * 250
                local sparks = EffectData()
                sparks:SetOrigin( sparkPos )
                sparks:SetNormal( VectorRand() )
                sparks:SetMagnitude( 18 )
                sparks:SetScale( 12 )
                sparks:SetRadius( 15 )
                util.Effect( "MetalSpark", sparks )
            end )
        end
        
        for i = 1, 20 do
            timer.Simple( math.Rand( 0, 0.6 ), function()
                local arcPos = pos + VectorRand() * 300
                local arc = EffectData()
                arc:SetOrigin( arcPos )
                arc:SetMagnitude( 12 )
                arc:SetScale( 5 )
                util.Effect( "ElectricSpark", arc )
            end )
        end
        
        for i = 1, 20 do
            timer.Simple( i * 0.06, function()
                local smoke = EffectData()
                smoke:SetOrigin( pos + Vector( 0, 0, i * 50 ) + VectorRand() * 100 )
                smoke:SetScale( 40 )
                util.Effect( "explosion_satchel", smoke )
            end )
        end
        
        for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
            if not IsValid( ent ) then continue end
            
            local entPos = ent:GetPos()
            local dir = ( entPos - pos ):GetNormalized()
            local dist = entPos:Distance( pos )
            local distFrac = 1 - ( dist / radius )
            
            if ent:Health() and ent:Health() > 0 then
                local dmg = DamageInfo()
                dmg:SetDamage( damage * distFrac )
                dmg:SetAttacker( game.GetWorld() )
                dmg:SetInflictor( game.GetWorld() )
                dmg:SetDamageType( bit.bor( DMG_BLAST, DMG_BURN, DMG_SHOCK ) )
                dmg:SetDamageForce( dir * 40000 * distFrac )
                ent:TakeDamageInfo( dmg )
            end
            
            if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                ent:SetVelocity( dir * 3000 * distFrac + Vector( 0, 0, 1200 * distFrac ) )
            elseif ent:GetPhysicsObject():IsValid() then
                local phys = ent:GetPhysicsObject()
                phys:ApplyForceCenter( dir * phys:GetMass() * 2500 * distFrac + Vector( 0, 0, phys:GetMass() * 1000 * distFrac ) )
            end
            
            if dist < radius * 0.75 and ent.Ignite then
                ent:Ignite( 25 * distFrac )
            end
        end
        
        util.ScreenShake( pos, 50, 25, 5, radius * 3 )
        
        local sprite = EffectData()
        sprite:SetOrigin( pos )
        sprite:SetScale( 30 )
        sprite:SetMagnitude( 8 )
        util.Effect( "cball_explode", sprite )
    end )
end

function ENT:AdditionalFootstep( _pos, _foot, _sound, volume, _filter )
    local moveSpeed = self:GetVelocity():Length()
    local speedFrac = moveSpeed / self.RunSpeed
    
    local snd = "npc/antlion_guard/foot_heavy" .. math.random( 1, 2 ) .. ".wav"
    local lvl = 95
    local pit = 60
    
    self:EmitSound( snd, lvl, pit, volume + 0.8, CHAN_STATIC )
    
    if math.random( 1, 100 ) < 50 then
        self:EmitSound( "npc/scanner/scanner_nearmiss" .. math.random( 1, 2 ) .. ".wav", 75, 50, 0.3, CHAN_STATIC )
    end
    
    if moveSpeed > self.WalkSpeed then
        local shakeAmt = 2 + ( speedFrac * 4 )
        util.ScreenShake( self:GetPos(), shakeAmt, 20, 0.2, 400 + ( moveSpeed * 0.5 ) )
    end
    
    if speedFrac > 0.5 then
        local dust = EffectData()
        dust:SetOrigin( _pos )
        dust:SetScale( 3 )
        dust:SetMagnitude( 2 )
        util.Effect( "ThumperDust", dust )
    end
    
    return true
end