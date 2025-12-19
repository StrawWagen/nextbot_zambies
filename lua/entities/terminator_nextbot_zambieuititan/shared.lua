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
    local colorWhite = Color( 255, 255, 255 )
    
    local function GenerateLightningPoints( startPos, endPos, segments, chaos, jaggedness )
        local points = { [1] = startPos }
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
            
            lastOffset = LerpVector( jaggedness, lastOffset, newOffset )
            points[i + 1] = basePos + lastOffset
        end
        
        points[segments + 1] = endPos
        return points
    end
    
    local function DrawBeamSegments( points, width, col )
        for j = 1, #points - 1 do
            render.DrawBeam( points[j], points[j + 1], width, 0, 1, col )
        end
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
                
                local trace = util.TraceLine( {
                    start = branchStart,
                    endpos = branchEnd,
                    mask = MASK_SOLID_BRUSHONLY,
                } )
                
                if trace.Hit then branchEnd = trace.HitPos end
                
                arc.branches[i] = {
                    points = GenerateLightningPoints( branchStart, branchEnd, math.random( 4, 7 ), 20, 0.6 ),
                    width = arc.width * 0.4,
                    endPos = branchEnd,
                }
            end
        end
        
        table.insert( activeArcs, arc )
    end
    
    local function CreateDLight( index, pos, size, brightness, duration )
        local dlight = DynamicLight( index )
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = brightness
            dlight.Decay = 5000
            dlight.Size = size
            dlight.DieTime = CurTime() + duration
        end
    end
    
    net.Receive( "zambieui_titan_arc", function()
        local ent = net.ReadEntity()
        local startPos = net.ReadVector()
        local endPos = net.ReadVector()
        
        if not IsValid( ent ) then return end
        
        CreateArc( startPos, endPos, math.Rand( 0.08, 0.15 ), math.random( 8, 14 ), math.random( 2, 4 ) )
        
        local entIndex = ent:EntIndex()
        CreateDLight( entIndex + math.random( 1000, 9999 ), endPos, 350, 6, 0.15 )
        CreateDLight( entIndex + math.random( 10000, 19999 ), startPos, 250, 4, 0.15 )
    end )
    
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
                
                DrawBeamSegments( arc.points, width * 4, Color( 255, 255, 255, alpha * 0.3 ) )
                DrawBeamSegments( arc.points, width * 1.5, Color( 240, 245, 255, alpha * 0.8 ) )
                DrawBeamSegments( arc.points, width * 0.5, Color( 255, 255, 255, alpha ) )
                
                for _, branch in ipairs( arc.branches ) do
                    local bWidth = branch.width * frac
                    DrawBeamSegments( branch.points, bWidth * 3, Color( 255, 255, 255, alpha * 0.2 ) )
                    DrawBeamSegments( branch.points, bWidth, Color( 240, 245, 255, alpha * 0.7 ) )
                    DrawBeamSegments( branch.points, bWidth * 0.4, Color( 255, 255, 255, alpha * 0.9 ) )
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

local function DoTrace( start, endpos, filter, mask )
    return util.TraceLine( {
        start = start,
        endpos = endpos,
        filter = filter,
        mask = mask or MASK_SOLID_BRUSHONLY,
    } )
end

function ENT:FindArcTarget()
    local myCenter = self:WorldSpaceCenter()
    local myPos = self:GetPos()
    local arcType = math.random( 1, 3 )
    
    if arcType == 1 then
        local randomDir = VectorRand()
        randomDir.z = 0
        randomDir:Normalize()
        
        local trace = DoTrace( myCenter, myPos + randomDir * math.random( 250, 450 ) + Vector( 0, 0, -500 ), self )
        if trace.Hit then return trace.HitPos end
        
    elseif arcType == 2 then
        for _, ent in ipairs( ents.FindInSphere( myCenter, 400 ) ) do
            if IsValid( ent ) and ent ~= self and ent:GetClass() ~= "worldspawn" then
                if ent:IsPlayer() or ent:IsNPC() or ent:GetClass():find( "prop" ) then
                    return ent:WorldSpaceCenter()
                end
            end
        end
        
        local trace = DoTrace( myCenter, myPos + Vector( 0, 0, -500 ), self )
        if trace.Hit then return trace.HitPos end
        
    else
        local trace = DoTrace( myCenter, myCenter + VectorRand():GetNormalized() * math.random( 150, 350 ), self, MASK_SOLID )
        if trace.Hit then return trace.HitPos end
    end
    
    return myPos + Vector( math.random( -150, 150 ), math.random( -150, 150 ), -80 )
end

function ENT:CreatePassiveArc()
    local randomOffset = VectorRand() * 25
    randomOffset.z = randomOffset.z * 0.5
    
    net.Start( "zambieui_titan_arc" )
        net.WriteEntity( self )
        net.WriteVector( self:WorldSpaceCenter() + randomOffset )
        net.WriteVector( self:FindArcTarget() )
    net.Broadcast()
    
    self:EmitSound( "ambient/energy/zap" .. math.random( 1, 9 ) .. ".wav", 70, math.random( 130, 160 ), 0.3 )
end

function ENT:CreateAuraAfterimage()
    local randomDir = VectorRand()
    randomDir.z = randomDir.z * 0.3
    randomDir:Normalize()
    
    net.Start( "zambieui_aura_afterimage" )
        net.WriteEntity( self )
        net.WriteVector( self:GetPos() + randomDir * math.random( 0, 5 ) )
        net.WriteAngle( self:GetAngles() )
        net.WriteInt( self:GetSequence(), 16 )
        net.WriteFloat( self:GetCycle() )
        net.WriteFloat( self:GetModelScale() )
        net.WriteVector( randomDir * math.random( 15, 25 ) + Vector( 0, 0, math.random( 5, 10 ) ) )
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
