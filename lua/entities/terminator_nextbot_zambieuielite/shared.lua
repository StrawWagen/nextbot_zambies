AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieui"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Ultra Instinct Elite"
ENT.Spawnable = false
ENT.Author = "regunkyle"

list.Set( "NPC", "terminator_nextbot_zambieuielite", {
    Name = "Zombie Ultra Instinct Elite",
    Class = "terminator_nextbot_zambieuielite",
    Category = "Nextbot Zambies",
} )

if SERVER then
    util.AddNetworkString( "zambieui_createafterimage" )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieuielite", ENT.PrintName )
    
    local allAfterimages = {}
    local matWhite = Material( "models/debug/debugwhite" )
    
    net.Receive( "zambieui_createafterimage", function()
        local ent = net.ReadEntity()
        local pos = net.ReadVector()
        local ang = net.ReadAngle()
        local sequence = net.ReadInt( 16 )
        local cycle = net.ReadFloat()
        local scale = net.ReadFloat()
        
        if not IsValid( ent ) then return end
        
        local model = ClientsideModel( ent:GetModel(), RENDERGROUP_BOTH )
        if not IsValid( model ) then return end
        
        model:SetPos( pos )
        model:SetAngles( ang )
        model:SetModelScale( scale, 0 )
        model:SetSequence( sequence )
        model:SetCycle( cycle )
        model:SetNoDraw( true )
        
        for i = 0, ent:GetNumBodyGroups() - 1 do
            model:SetBodygroup( i, ent:GetBodygroup( i ) )
        end
        
        local duration = 0.35
        local data = {
            model = model,
            startTime = CurTime(),
            dieTime = CurTime() + duration,
            duration = duration,
            entity = ent,
        }
        
        table.insert( allAfterimages, data )
    end )
    
    hook.Add( "PostDrawTranslucentRenderables", "ZambieUIElite_Afterimages", function()
        local curTime = CurTime()
        
        cam.Start3D()
        
        for i = #allAfterimages, 1, -1 do
            local data = allAfterimages[i]
            
            if curTime > data.dieTime or not IsValid( data.entity ) then
                if IsValid( data.model ) then
                    data.model:Remove()
                end
                table.remove( allAfterimages, i )
            else
                if IsValid( data.model ) then
                    local frac = ( curTime - data.startTime ) / data.duration
                    
                    local alpha = math.Clamp( ( 1 - frac ) * 0.5, 0, 0.5 )
                    
                    render.SetBlend( alpha )
                    render.MaterialOverride( matWhite )
                    render.SetColorModulation( 1, 1, 1 )
                    
                    data.model:DrawModel()
                    
                    render.MaterialOverride( nil )
                    render.SetBlend( 1 )
                    render.SetColorModulation( 1, 1, 1 )
                end
            end
        end
        
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
            self._nextParticle = CurTime() + 0.015
            
            local pos = self:WorldSpaceCenter()
            local offset = VectorRand() * math.Rand( 10, 30 )
            
            local particle = self._particleEmitter:Add( "effects/spark", pos + offset )
            
            if particle then
                particle:SetVelocity( VectorRand() * 30 )
                particle:SetLifeTime( 0 )
                particle:SetDieTime( math.Rand( 0.4, 0.8 ) )
                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 0 )
                particle:SetStartSize( math.Rand( 3, 6 ) )
                particle:SetEndSize( 0 )
                particle:SetColor( 255, 255, 255 )
                particle:SetAirResistance( 100 )
                particle:SetGravity( Vector( 0, 0, 50 ) )
            end
        end
    end
    
    function ENT:Draw()
        self:DrawModel()
        
        local dlight = DynamicLight( self:EntIndex() )
        if dlight then
            dlight.pos = self:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 2
            dlight.Decay = 1000
            dlight.Size = 256
            dlight.DieTime = CurTime() + 0.1
        end
    end
    
    function ENT:OnRemove()
        if self._particleEmitter then
            self._particleEmitter:Finish()
        end
    end
    
    return
end

ENT.SpawnHealth = 15000
ENT.HealthRegen = 10
ENT.HealthRegenInterval = 1.5

ENT.AimSpeed = 1000
ENT.WalkSpeed = 120
ENT.MoveSpeed = 400
ENT.RunSpeed = 700

ENT.FistDamageMul = 2
ENT.zamb_MeleeAttackSpeed = 2.5

ENT.TERM_MODELSCALE = function() return math.Rand( 1.15, 1.20 ) end
ENT.MyPhysicsMass = 95

ENT.UI_DODGE_CHANCE = 65
ENT.UI_DODGE_COOLDOWN = 0.3
ENT.UI_DODGE_DISTANCE = 700

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetColor( Color( 255, 255, 255, 255 ) )
    
    self.HasBrains = true
    self.CanHearStuff = true
    
    self._lastAfterimagePos = self:GetPos()
    self._lastAfterimageTime = 0
    self._afterimageInterval = 0.1
    
    self.term_SoundPitchShift = 20
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

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )
    
    local curTime = CurTime()
    
    local vel = self.loco:GetVelocity()
    local speed = vel:Length()
    
    if speed > 100 and curTime >= self._lastAfterimageTime + self._afterimageInterval then
        local moved = self:GetPos():Distance( self._lastAfterimagePos )
        
        if moved > 20 then
            self._lastAfterimageTime = curTime
            self._lastAfterimagePos = self:GetPos()
            
            self:CreateAfterimageServer()
        end
    end
end

function ENT:DodgeEffect( hitPos )
    BaseClass.DodgeEffect( self, hitPos )
    
    local effectdata = EffectData()
    effectdata:SetOrigin( hitPos or self:WorldSpaceCenter() )
    effectdata:SetNormal( Vector( 0, 0, 1 ) )
    effectdata:SetMagnitude( 2 )
    effectdata:SetScale( 3 )
    effectdata:SetRadius( 5 )
    util.Effect( "ManhackSparks", effectdata )
    
    self:CreateAfterimageServer()
end

