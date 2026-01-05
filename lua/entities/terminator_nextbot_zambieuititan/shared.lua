AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieuielite"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Ultra Instinct Titan"
ENT.Spawnable = false
ENT.Author = "regunkyle"

list.Set( "NPC", "terminator_nextbot_zambieuititan", {
    Name = "Zombie Ultra Instinct Titan",
    Class = "terminator_nextbot_zambieuititan",
    Category = "Nextbot Zambies",
} )

if SERVER then
    util.AddNetworkString( "zambieui_aura_afterimage" )
    util.AddNetworkString( "zambieui_titan_death_explosion" )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieuititan", ENT.PrintName )
    
    local auraAfterimages = {}
    local matWhite = Material( "models/debug/debugwhite" )
    
    net.Receive( "zambieui_aura_afterimage", function()
        local ent = net.ReadEntity()
        if not IsValid( ent ) then return end
        
        local model = ClientsideModel( ent:GetModel(), RENDERGROUP_BOTH )
        if not IsValid( model ) then return end
        
        local pos = net.ReadVector()
        model:SetPos( pos )
        model:SetAngles( net.ReadAngle() )
        model:SetModelScale( net.ReadFloat(), 0 )
        model:SetSequence( net.ReadInt( 16 ) )
        model:SetCycle( net.ReadFloat() )
        model:SetNoDraw( true )
        
        for i = 0, ent:GetNumBodyGroups() - 1 do
            model:SetBodygroup( i, ent:GetBodygroup( i ) )
        end
        
        local duration = 0.25
        table.insert( auraAfterimages, {
            model = model,
            startTime = CurTime(),
            dieTime = CurTime() + duration,
            duration = duration,
            entity = ent,
            pos = pos,
            velocity = net.ReadVector(),
        } )
    end )
    
    net.Receive( "zambieui_titan_death_explosion", function()
        local pos = net.ReadVector()
        local radius = net.ReadFloat()
        
        local emitter = ParticleEmitter( pos )
        if emitter then
            for i = 1, 150 do
                local dir = VectorRand():GetNormalized()
                local particle = emitter:Add( "effects/spark", pos + dir * math.Rand( 10, 50 ) )
                
                if particle then
                    particle:SetVelocity( dir * math.Rand( 400, 1000 ) )
                    particle:SetLifeTime( 0 )
                    particle:SetDieTime( math.Rand( 0.8, 2 ) )
                    particle:SetStartAlpha( 255 )
                    particle:SetEndAlpha( 0 )
                    particle:SetStartSize( math.Rand( 15, 35 ) )
                    particle:SetEndSize( 0 )
                    particle:SetColor( 255, 255, 255 )
                    particle:SetAirResistance( 50 )
                    particle:SetGravity( Vector( 0, 0, -100 ) )
                end
            end
            
            for i = 1, 50 do
                local dir = VectorRand():GetNormalized()
                local particle = emitter:Add( "sprites/light_glow02_add", pos )
                
                if particle then
                    particle:SetVelocity( dir * math.Rand( 200, 600 ) )
                    particle:SetLifeTime( 0 )
                    particle:SetDieTime( math.Rand( 0.3, 0.8 ) )
                    particle:SetStartAlpha( 255 )
                    particle:SetEndAlpha( 0 )
                    particle:SetStartSize( math.Rand( 40, 80 ) )
                    particle:SetEndSize( math.Rand( 100, 200 ) )
                    particle:SetColor( 255, 255, 255 )
                end
            end
            
            emitter:Finish()
        end
        
        local dlight = DynamicLight( math.random( 100000, 999999 ) )
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 10
            dlight.Decay = 1500
            dlight.Size = 1500
            dlight.DieTime = CurTime() + 0.8
        end
    end )
    
    hook.Add( "PostDrawTranslucentRenderables", "ZambieUITitan_AuraAfterimages", function()
        local curTime = CurTime()
        local frameTime = FrameTime()
        
        cam.Start3D()
        render.MaterialOverride( matWhite )
        
        for i = #auraAfterimages, 1, -1 do
            local data = auraAfterimages[i]
            
            if curTime > data.dieTime or not IsValid( data.entity ) then
                if IsValid( data.model ) then
                    data.model:Remove()
                end
                table.remove( auraAfterimages, i )
            elseif IsValid( data.model ) then
                data.pos = data.pos + data.velocity * frameTime
                data.model:SetPos( data.pos )
                
                local alpha = math.Clamp( ( 1 - ( curTime - data.startTime ) / data.duration ) * 0.4, 0, 0.4 )
                
                render.SetBlend( alpha )
                render.SetColorModulation( 1, 1, 1 )
                data.model:DrawModel()
            end
        end
        
        render.MaterialOverride( nil )
        render.SetBlend( 1 )
        cam.End3D()
    end )
    
    function ENT:AdditionalClientInitialize()
        if BaseClass.AdditionalClientInitialize then
            BaseClass.AdditionalClientInitialize( self )
        end
        
        self._particleEmitter = ParticleEmitter( self:GetPos() )
        self._nextParticle = 0
    end
    
    function ENT:Think()
        if BaseClass.Think then
            BaseClass.Think( self )
        end
        
        if self._particleEmitter and CurTime() >= self._nextParticle then
            self._nextParticle = CurTime() + 0.005
            
            local pos = self:WorldSpaceCenter()
            local particle = self._particleEmitter:Add( "effects/spark", pos + VectorRand() * math.Rand( 15, 50 ) )
            
            if particle then
                particle:SetVelocity( VectorRand() * 50 )
                particle:SetLifeTime( 0 )
                particle:SetDieTime( math.Rand( 0.6, 1.2 ) )
                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 0 )
                particle:SetStartSize( math.Rand( 5, 10 ) )
                particle:SetEndSize( 0 )
                particle:SetColor( 255, 255, 255 )
                particle:SetAirResistance( 100 )
                particle:SetGravity( Vector( 0, 0, 100 ) )
            end
        end
    end
    
    function ENT:Draw()
        local enraged = self:GetNWBool( "Enraged", false )
        
        if enraged then
            render.SuppressEngineLighting( true )
            render.MaterialOverride( matWhite )
            render.SetColorModulation( 1, 1, 1 )
        end
        
        self:DrawModel()
        
        if enraged then
            render.MaterialOverride( nil )
            render.SuppressEngineLighting( false )
        end
        
        local dlight = DynamicLight( self:EntIndex() )
        if dlight then
            dlight.pos = self:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = enraged and 8 or 4
            dlight.Decay = 2000
            dlight.Size = enraged and 768 or 512
            dlight.DieTime = CurTime() + 0.1
        end
    end
    
    return
end

ENT.SpawnHealth = 50000
ENT.HealthRegen = 25
ENT.HealthRegenInterval = 1

ENT.AimSpeed = 1500
ENT.WalkSpeed = 150
ENT.MoveSpeed = 500
ENT.RunSpeed = 900

ENT.FistDamageMul = 4
ENT.zamb_MeleeAttackSpeed = 3

ENT.TERM_MODELSCALE = function() return math.Rand( 1.725, 1.80 ) end
ENT.MyPhysicsMass = 200

ENT.UI_DODGE_CHANCE = 80
ENT.UI_DODGE_COOLDOWN = 0.2
ENT.UI_DODGE_DISTANCE = 1000

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetColor( Color( 255, 255, 255, 255 ) )
    
    self.HasBrains = true
    self.CanHearStuff = true
    
    self._lastAfterimagePos = self:GetPos()
    self._lastAfterimageTime = 0
    self._afterimageInterval = 0.05
    
    self._lastAuraAfterimageTime = 0
    self._auraAfterimageInterval = 0.2
    
    self.term_SoundPitchShift = 25
    
    self._baseWalkSpeed = self.WalkSpeed
    self._baseMoveSpeed = self.MoveSpeed
    self._baseRunSpeed = self.RunSpeed
    self._baseFistDamageMul = self.FistDamageMul
    self._baseJumpHeight = self.loco:GetJumpHeight()
    
    self:SetNWBool( "Enraged", false )
end

function ENT:EnterEnrageMode()
    self:SetNWBool( "Enraged", true )
    
    self.WalkSpeed = self._baseWalkSpeed * 2
    self.MoveSpeed = self._baseMoveSpeed * 2
    self.RunSpeed = self._baseRunSpeed * 2
    self.FistDamageMul = self._baseFistDamageMul * 2
    self.loco:SetJumpHeight( self._baseJumpHeight * 2 )
    
    self:EmitSound( "ambient/energy/whiteflash.wav", 100, 80, 1 )
    
    for i = 1, 5 do
        self:CreateAuraAfterimage()
    end
end

function ENT:CreateAuraAfterimage()
    local randomDir = VectorRand()
    randomDir.z = randomDir.z * 0.3
    randomDir:Normalize()
    
    net.Start( "zambieui_aura_afterimage" )
        net.WriteEntity( self )
        net.WriteVector( self:GetPos() + randomDir * math.random( 0, 5 ) )
        net.WriteAngle( self:GetAngles() )
        net.WriteFloat( self:GetModelScale() )
        net.WriteInt( self:GetSequence(), 16 )
        net.WriteFloat( self:GetCycle() )
        net.WriteVector( randomDir * math.random( 15, 25 ) + Vector( 0, 0, math.random( 5, 10 ) ) )
    net.Broadcast()
end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )
    
    local curTime = CurTime()
    
    if not self:GetNWBool( "Enraged", false ) and self:Health() <= self.SpawnHealth * 0.3 then
        self:EnterEnrageMode()
    end
    
    if curTime >= self._lastAuraAfterimageTime + self._auraAfterimageInterval then
        self._lastAuraAfterimageTime = curTime
        self:CreateAuraAfterimage()
    end
end

function ENT:CreateAfterimageServer()
    net.Start( "zambieui_createafterimage" )
        net.WriteEntity( self )
        net.WriteVector( self:GetPos() )
        net.WriteAngle( self:GetAngles() )
        net.WriteInt( self:GetSequence(), 16 )
        net.WriteFloat( self:GetCycle() )
        net.WriteFloat( self:GetModelScale() )
    net.Broadcast()
end

function ENT:DeathExplosion()
    local pos = self:WorldSpaceCenter()
    local radius = 800
    local pushForce = 2000
    
    net.Start( "zambieui_titan_death_explosion" )
        net.WriteVector( pos )
        net.WriteFloat( radius )
    net.Broadcast()
    
    self:EmitSound( "ambient/energy/whiteflash.wav", 100, 50, 1 )
    
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent ~= self and IsValid( ent ) then
            local entPos = ent:WorldSpaceCenter()
            local dir = ( entPos - pos ):GetNormalized()
            local dist = pos:Distance( entPos )
            local falloff = 1 - ( dist / radius )
            local force = dir * pushForce * falloff
            
            if ent:IsPlayer() then
                ent:SetVelocity( force )
            elseif ent:IsNPC() or ent:IsNextBot() then
                ent:SetVelocity( force )
            elseif IsValid( ent:GetPhysicsObject() ) then
                ent:GetPhysicsObject():ApplyForceCenter( force * ent:GetPhysicsObject():GetMass() )
            end
        end
    end
end

function ENT:OnKilled( dmginfo )
    self:DeathExplosion()
    
    BaseClass.OnKilled( self, dmginfo )
end

function ENT:DodgeEffect( hitPos )
    BaseClass.DodgeEffect( self, hitPos )
    
    local effectdata = EffectData()
    effectdata:SetOrigin( hitPos or self:WorldSpaceCenter() )
    effectdata:SetNormal( Vector( 0, 0, 1 ) )
    effectdata:SetMagnitude( 4 )
    effectdata:SetScale( 6 )
    effectdata:SetRadius( 8 )
    util.Effect( "ManhackSparks", effectdata )
    
    util.ScreenShake( self:GetPos(), 5, 5, 0.5, 500 )
    
    self:CreateAfterimageServer()
    
    for i = 1, 3 do
        self:CreateAuraAfterimage()
    end
end
