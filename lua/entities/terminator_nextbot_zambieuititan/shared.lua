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
    util.AddNetworkString( "zambieui_titan_arc" )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieuititan", ENT.PrintName )
    
    local auraAfterimages = {}
    local activeArcs = {}
    local matWhite = Material( "models/debug/debugwhite" )
    local matBeam = CreateMaterial( "zambieui_lightning_" .. math.random( 1, 99999 ), "UnlitGeneric", {
        ["$basetexture"] = "sprites/spotlight",
        ["$additive"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
    } )
    local matGlow = Material( "sprites/light_glow02_add" )
    
    local function GenerateLightningPoints( startPos, endPos, segments, chaos, jaggedness )
        local points = {}
        points[1] = startPos
        
        local dir = endPos - startPos
        local length = dir:Length()
        dir:Normalize()
        
        local right = dir:Cross( Vector( 0, 0, 1 ) )
        if right:LengthSqr() < 0.01 then
            right = dir:Cross( Vector( 0, 1, 0 ) )
        end
        right:Normalize()
        
        local up = dir:Cross( right )
        up:Normalize()
        
        local lastOffset = Vector( 0, 0, 0 )
        
        for i = 1, segments - 1 do
            local frac = i / segments
            local basePos = startPos + dir * ( length * frac )
            
            local chaosScale = math.sin( frac * math.pi ) * chaos
            
            local newOffset = right * math.Rand( -1, 1 ) * chaosScale + up * math.Rand( -1, 1 ) * chaosScale
            
            local offset = LerpVector( jaggedness, lastOffset, newOffset )
            lastOffset = offset
            
            points[i + 1] = basePos + offset
        end
        
        points[segments + 1] = endPos
        
        return points
    end
    
    local function CreateArc( startPos, endPos, duration, width, branches )
        local segments = math.random( 10, 16 )
        local arc = {
            startTime = CurTime(),
            endTime = CurTime() + duration,
            duration = duration,
            width = width or 10,
            points = GenerateLightningPoints( startPos, endPos, segments, 40, 0.7 ),
            branches = {},
            startPos = startPos,
            endPos = endPos,
            nextFlicker = CurTime(),
            flickerRate = 0.02,
        }
        
        if branches and branches > 0 then
            for i = 1, branches do
                local pointIndex = math.random( 2, math.floor( #arc.points * 0.7 ) )
                local branchStart = arc.points[pointIndex]
                
                local mainDir = ( endPos - startPos ):GetNormalized()
                local branchDir = mainDir + VectorRand() * 1.2
                branchDir.z = branchDir.z - math.Rand( 0.3, 0.8 )
                branchDir:Normalize()
                
                local branchLength = math.random( 40, 120 )
                local branchEnd = branchStart + branchDir * branchLength
                
                local traceData = {
                    start = branchStart,
                    endpos = branchEnd,
                    mask = MASK_SOLID_BRUSHONLY,
                }
                local trace = util.TraceLine( traceData )
                if trace.Hit then
                    branchEnd = trace.HitPos
                end
                
                arc.branches[i] = {
                    points = GenerateLightningPoints( branchStart, branchEnd, math.random( 4, 7 ), 20, 0.6 ),
                    width = arc.width * 0.4,
                    endPos = branchEnd,
                }
            end
        end
        
        table.insert( activeArcs, arc )
    end
    
    net.Receive( "zambieui_titan_arc", function()
        local ent = net.ReadEntity()
        local startPos = net.ReadVector()
        local endPos = net.ReadVector()
        
        if not IsValid( ent ) then return end
        
        CreateArc( startPos, endPos, math.Rand( 0.08, 0.15 ), math.random( 8, 14 ), math.random( 2, 4 ) )
        
        local dlight = DynamicLight( ent:EntIndex() + math.random( 1000, 9999 ) )
        if dlight then
            dlight.pos = endPos
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 6
            dlight.Decay = 5000
            dlight.Size = 350
            dlight.DieTime = CurTime() + 0.15
        end
        
        local dlightStart = DynamicLight( ent:EntIndex() + math.random( 10000, 19999 ) )
        if dlightStart then
            dlightStart.pos = startPos
            dlightStart.r = 255
            dlightStart.g = 255
            dlightStart.b = 255
            dlightStart.brightness = 4
            dlightStart.Decay = 5000
            dlightStart.Size = 250
            dlightStart.DieTime = CurTime() + 0.15
        end
    end )
    
    net.Receive( "zambieui_aura_afterimage", function()
        local ent = net.ReadEntity()
        local pos = net.ReadVector()
        local ang = net.ReadAngle()
        local sequence = net.ReadInt( 16 )
        local cycle = net.ReadFloat()
        local scale = net.ReadFloat()
        local velocity = net.ReadVector()
        
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
        
        local duration = 0.25
        local data = {
            model = model,
            startTime = CurTime(),
            dieTime = CurTime() + duration,
            duration = duration,
            entity = ent,
            pos = pos,
            velocity = velocity,
        }
        
        table.insert( auraAfterimages, data )
    end )
    
    hook.Add( "PostDrawTranslucentRenderables", "ZambieUITitan_AuraAfterimages", function()
        local curTime = CurTime()
        local frameTime = FrameTime()
        
        cam.Start3D()
        
        for i = #auraAfterimages, 1, -1 do
            local data = auraAfterimages[i]
            
            if curTime > data.dieTime or not IsValid( data.entity ) then
                if IsValid( data.model ) then
                    data.model:Remove()
                end
                table.remove( auraAfterimages, i )
            else
                if IsValid( data.model ) then
                    data.pos = data.pos + data.velocity * frameTime
                    data.model:SetPos( data.pos )
                    
                    local frac = ( curTime - data.startTime ) / data.duration
                    local alpha = math.Clamp( ( 1 - frac ) * 0.4, 0, 0.4 )
                    
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
    
    hook.Add( "PostDrawTranslucentRenderables", "ZambieUITitan_LightningArcs", function()
        local curTime = CurTime()
        
        for i = #activeArcs, 1, -1 do
            local arc = activeArcs[i]
            
            if curTime > arc.endTime then
                table.remove( activeArcs, i )
            else
                if curTime >= arc.nextFlicker then
                    arc.nextFlicker = curTime + arc.flickerRate
                    arc.points = GenerateLightningPoints( arc.startPos, arc.endPos, #arc.points - 1, 40, 0.7 )
                    
                    for _, branch in ipairs( arc.branches ) do
                        if branch.points and #branch.points > 1 then
                            branch.points = GenerateLightningPoints( branch.points[1], branch.endPos, #branch.points - 1, 20, 0.6 )
                        end
                    end
                end
                
                local frac = ( arc.endTime - curTime ) / arc.duration
                local alpha = math.Clamp( frac * 255, 0, 255 )
                local width = arc.width * frac
                
                render.SetMaterial( matBeam )
                local glowCol = Color( 255, 255, 255, alpha * 0.3 )
                for j = 1, #arc.points - 1 do
                    render.DrawBeam( arc.points[j], arc.points[j + 1], width * 4, 0, 1, glowCol )
                end
                
                local outerCol = Color( 240, 245, 255, alpha * 0.8 )
                for j = 1, #arc.points - 1 do
                    render.DrawBeam( arc.points[j], arc.points[j + 1], width * 1.5, 0, 1, outerCol )
                end
                
                local coreCol = Color( 255, 255, 255, alpha )
                for j = 1, #arc.points - 1 do
                    render.DrawBeam( arc.points[j], arc.points[j + 1], width * 0.5, 0, 1, coreCol )
                end
                
                for _, branch in ipairs( arc.branches ) do
                    local branchGlowCol = Color( 255, 255, 255, alpha * 0.2 )
                    for j = 1, #branch.points - 1 do
                        render.DrawBeam( branch.points[j], branch.points[j + 1], branch.width * frac * 3, 0, 1, branchGlowCol )
                    end
                    
                    local branchCol = Color( 240, 245, 255, alpha * 0.7 )
                    for j = 1, #branch.points - 1 do
                        render.DrawBeam( branch.points[j], branch.points[j + 1], branch.width * frac, 0, 1, branchCol )
                    end
                    
                    local branchCoreCol = Color( 255, 255, 255, alpha * 0.9 )
                    for j = 1, #branch.points - 1 do
                        render.DrawBeam( branch.points[j], branch.points[j + 1], branch.width * frac * 0.4, 0, 1, branchCoreCol )
                    end
                end
                
                render.SetMaterial( matGlow )
                local sparkAlpha = alpha * math.Rand( 0.5, 1 )
                local sparkSize = width * math.Rand( 2, 4 )
                render.DrawSprite( arc.endPos, sparkSize, sparkSize, Color( 255, 255, 255, sparkAlpha ) )
                render.DrawSprite( arc.startPos, sparkSize * 0.7, sparkSize * 0.7, Color( 255, 255, 255, sparkAlpha * 0.8 ) )
            end
        end
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
            local offset = VectorRand() * math.Rand( 15, 50 )
            
            local particle = self._particleEmitter:Add( "effects/spark", pos + offset )
            
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
        self:DrawModel()
        
        local dlight = DynamicLight( self:EntIndex() )
        if dlight then
            dlight.pos = self:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 4
            dlight.Decay = 2000
            dlight.Size = 512
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

ENT.UI_DODGE_CHANCE = 95
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
    
    self._lastArcTime = 0
    self._arcInterval = 0.3
    
    self.term_SoundPitchShift = 25
end

function ENT:FindArcTarget()
    local myCenter = self:WorldSpaceCenter()
    local myPos = self:GetPos()
    
    local arcType = math.random( 1, 3 )
    
    if arcType == 1 then
        local randomDir = VectorRand()
        randomDir.z = 0
        randomDir:Normalize()
        
        local traceData = {
            start = myCenter,
            endpos = myPos + randomDir * math.random( 250, 450 ) + Vector( 0, 0, -500 ),
            filter = self,
            mask = MASK_SOLID_BRUSHONLY,
        }
        
        local trace = util.TraceLine( traceData )
        
        if trace.Hit then
            return trace.HitPos
        end
    elseif arcType == 2 then
        local nearbyEnts = ents.FindInSphere( myCenter, 400 )
        
        for _, ent in ipairs( nearbyEnts ) do
            if IsValid( ent ) and ent ~= self and ent:GetClass() ~= "worldspawn" then
                if ent:IsPlayer() or ent:IsNPC() or ent:GetClass():find( "prop" ) then
                    return ent:WorldSpaceCenter()
                end
            end
        end
        
        local traceData = {
            start = myCenter,
            endpos = myPos + Vector( 0, 0, -500 ),
            filter = self,
            mask = MASK_SOLID_BRUSHONLY,
        }
        
        local trace = util.TraceLine( traceData )
        
        if trace.Hit then
            return trace.HitPos
        end
    else
        local randomDir = VectorRand()
        randomDir:Normalize()
        
        local traceData = {
            start = myCenter,
            endpos = myCenter + randomDir * math.random( 150, 350 ),
            filter = self,
            mask = MASK_SOLID,
        }
        
        local trace = util.TraceLine( traceData )
        
        if trace.Hit then
            return trace.HitPos
        end
    end
    
    return myPos + Vector( math.random( -150, 150 ), math.random( -150, 150 ), -80 )
end

function ENT:CreatePassiveArc()
    local myCenter = self:WorldSpaceCenter()
    local endPos = self:FindArcTarget()
    
    local randomOffset = VectorRand() * 25
    randomOffset.z = randomOffset.z * 0.5
    local startPos = myCenter + randomOffset
    
    net.Start( "zambieui_titan_arc" )
        net.WriteEntity( self )
        net.WriteVector( startPos )
        net.WriteVector( endPos )
    net.Broadcast()
    
    self:EmitSound( "ambient/energy/zap" .. math.random( 1, 9 ) .. ".wav", 70, math.random( 130, 160 ), 0.3 )
end

function ENT:CreateAuraAfterimage()
    local myPos = self:GetPos()
    local myAng = self:GetAngles()
    
    local offsetDist = math.random( 0, 5 )
    local randomDir = VectorRand()
    randomDir.z = randomDir.z * 0.3
    randomDir:Normalize()
    
    local spawnPos = myPos + randomDir * offsetDist
    
    local driftVel = randomDir * math.random( 15, 25 )
    driftVel.z = driftVel.z + math.random( 5, 10 )
    
    net.Start( "zambieui_aura_afterimage" )
        net.WriteEntity( self )
        net.WriteVector( spawnPos )
        net.WriteAngle( myAng )
        net.WriteInt( self:GetSequence(), 16 )
        net.WriteFloat( self:GetCycle() )
        net.WriteFloat( self:GetModelScale() )
        net.WriteVector( driftVel )
    net.Broadcast()
end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )
    
    local curTime = CurTime()
    
    if curTime >= self._lastAuraAfterimageTime + self._auraAfterimageInterval then
        self._lastAuraAfterimageTime = curTime
        self:CreateAuraAfterimage()
    end
    
    if curTime >= self._lastArcTime + self._arcInterval then
        self._lastArcTime = curTime
        self._arcInterval = math.Rand( 0.15, 0.35 )
        self:CreatePassiveArc()
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
    
    for i = 1, 2 do
        self:CreatePassiveArc()
    end
end