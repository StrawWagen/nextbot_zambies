-- Boomer / blastcrab explosion.
-- Replaces the old eff_boomer_explosion + eff_boomer_blast pair, they were ~90% the same code.
-- Everything scales off data:GetMagnitude(), 1 = a full boomer burst, ~0.6 = a small blastcrab pop.
--
-- Effect data:
--   origin    = where it goes off
--   radius    = blast radius in units
--   magnitude = scale of the whole effect

EFFECT.mat_fire = Material( "particle/smokesprites_0002" )
EFFECT.mat_beam = Material( "trails/plasma" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local BLOOD_DECALS = {}
for i = 1, 9 do
    BLOOD_DECALS[i] = Material( "decals/blood" .. i )
end

local gravFire = Vector( 0, 0, -40 )
local gravFall = Vector( 0, 0, -900 )
local gravSmoke = Vector( 0, 0, 20 )

-- Bright toxic green
local BLAST_R, BLAST_G, BLAST_B = 40, 220, 50

local crossVec1 = Vector( 0, 0, 1 )
local crossVec2 = Vector( 0, 1, 0 )

-- Reused for every ring point, so drawing a ring allocates no vectors per segment, per frame.
local ringPoint = Vector()

-- Draws a flat ring of beam segments.
-- Call render.SetMaterial first, the caller picks the beam material.
local function DrawBeamRing( center, normal, radius, width, color, segments )
    -- Build two vectors that lie flat on the ring's plane.
    local tangent = normal:Cross( crossVec1 )
    if tangent:LengthSqr() < 0.001 then
        -- normal was parallel to crossVec1, use the other axis instead.
        tangent = normal:Cross( crossVec2 )
    end
    tangent:Normalize()

    local bitangent = normal:Cross( tangent )
    bitangent:Normalize()

    local centerX, centerY, centerZ = center:Unpack()
    local tangentX, tangentY, tangentZ = tangent:Unpack()
    local bitangentX, bitangentY, bitangentZ = bitangent:Unpack()

    render.StartBeam( segments + 1 )
    for i = 0, segments do
        local fraction = i / segments
        local angle = fraction * math.pi * 2
        local alongTangent = math.cos( angle ) * radius
        local alongBitangent = math.sin( angle ) * radius

        ringPoint:SetUnpacked(
            centerX + tangentX * alongTangent + bitangentX * alongBitangent,
            centerY + tangentY * alongTangent + bitangentY * alongBitangent,
            centerZ + tangentZ * alongTangent + bitangentZ * alongBitangent
        )
        render.AddBeam( ringPoint, width, fraction, color )
    end
    render.EndBeam()
end

-- Random unit vector.
-- VectorRand() samples a cube, it does NOT return a unit vector, so normalize it.
local function RandomDirection()
    local direction = VectorRand()
    direction:Normalize()
    return direction
end

local function SpawnParticles( pos, radius, decalCount, scale )
    local emitter = ParticleEmitter( pos )
    if not emitter then return end

    -- Quick bright flash
    for _ = 1, 2 do
        local particle = emitter:Add( "sprites/light_glow02_add", pos )
        if not particle then continue end

        particle:SetVelocity( RandomDirection() * math.Rand( 5, 15 ) )
        particle:SetDieTime( math.Rand( 0.04, 0.09 ) )
        particle:SetStartAlpha( 180 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( radius * math.Rand( 0.4, 0.6 ) * scale )
        particle:SetEndSize( radius * math.Rand( 0.7, 1.0 ) * scale )
        particle:SetColor( BLAST_R, BLAST_G, BLAST_B )
    end

    -- Slow rolling fireball
    for _ = 1, math.floor( 26 * scale ) do
        local particle = emitter:Add( "particle/fire", pos )
        if not particle then continue end

        local size = math.Rand( radius * 0.2, radius * 0.45 ) * scale
        particle:SetVelocity( RandomDirection() * math.Rand( 20, 90 ) * scale )
        particle:SetDieTime( math.Rand( 0.25, 0.55 ) )
        particle:SetStartAlpha( 255 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( size * 0.3 )
        particle:SetEndSize( size )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetRollDelta( math.Rand( -2, 2 ) )
        particle:SetGravity( gravFire )
        particle:SetColor( BLAST_R, BLAST_G, BLAST_B )
    end

    -- Fast chunks that fall and bounce
    for _ = 1, math.floor( 24 * scale ) do
        local particle = emitter:Add( "particle/fire", pos )
        if not particle then continue end

        local size = math.Rand( 4, 10 ) * scale
        particle:SetVelocity( RandomDirection() * math.Rand( 200, 620 ) * scale )
        particle:SetDieTime( math.Rand( 0.4, 1.2 ) )
        particle:SetStartAlpha( 255 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( size )
        particle:SetEndSize( size * 0.1 )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetRollDelta( 0 )
        particle:SetGravity( gravFall )
        particle:SetColor( BLAST_R, BLAST_G, BLAST_B )
        particle:SetCollide( true )
        particle:SetBounce( 0.1 )
    end

    -- Glowing drips, thrown upwards more than sideways
    for _ = 1, math.floor( 28 * scale ) do
        local particle = emitter:Add( "sprites/light_glow02_add", pos )
        if not particle then continue end

        local direction = VectorRand()
        direction.z = math.abs( direction.z ) * 1.2 + 0.3
        direction:Normalize()

        particle:SetVelocity( direction * math.Rand( 120, 500 ) * scale )
        particle:SetDieTime( math.Rand( 0.4, 1.1 ) )
        particle:SetStartAlpha( 210 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( math.Rand( 3, 9 ) * scale )
        particle:SetEndSize( 0 )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetGravity( gravFall )
        particle:SetColor( BLAST_R, BLAST_G, BLAST_B )
        particle:SetCollide( true )
        particle:SetBounce( 0.05 )
    end

    -- Drifting smoke
    for _ = 1, math.floor( 5 * scale ) do
        local particle = emitter:Add( "particle/smokesprites_0001", pos )
        if not particle then continue end

        local direction = VectorRand()
        direction.z = math.abs( direction.z ) + 0.5
        direction:Normalize()

        local size = math.Rand( radius * 0.08, radius * 0.18 ) * scale
        particle:SetVelocity( direction * math.Rand( 30, 90 ) * scale )
        particle:SetDieTime( math.Rand( 0.5, 1.2 ) )
        particle:SetStartAlpha( 90 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( size )
        particle:SetEndSize( size * 1.8 )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetRollDelta( math.Rand( -1, 1 ) )
        particle:SetGravity( gravSmoke )
        particle:SetColor( 25, 50, 25 )
        particle:SetCollide( false )
    end

    emitter:Finish()

    -- Blood splatter on nearby brushes
    for _ = 1, decalCount do
        local trace = util.TraceLine( {
            start = pos,
            endpos = pos + RandomDirection() * radius,
            mask = MASK_SOLID_BRUSHONLY,
        } )
        if not trace.Hit then continue end

        local material = BLOOD_DECALS[ math.random( 1, #BLOOD_DECALS ) ]
        if not material or material:IsError() then continue end

        util.DecalEx(
            material, trace.Entity, trace.HitPos, trace.HitNormal,
            Color( BLAST_R, BLAST_G, BLAST_B ),
            math.Rand( 0.6, 1.6 ) * scale,
            math.Rand( 0.6, 1.6 ) * scale
        )
    end
end

function EFFECT:Init( data )
    self.pos = data:GetOrigin()
    self.radius = data:GetRadius()
    self.scale = data:GetMagnitude()

    -- Effects sent without a magnitude read as 0, fall back to a full-size blast.
    if self.scale <= 0 then
        self.scale = 1
    end

    local scale = self.scale

    -- Each ring spins on its own random plane
    self.normal1 = RandomDirection()
    self.normal2 = RandomDirection()
    self.normal3 = RandomDirection()

    -- Small blasts finish a bit faster than big ones
    self.t = 0
    self.tout = math.Rand( 0.78, 0.96 ) * math.Clamp( scale, 0.65, 1.2 )

    -- Only big blasts get the third, outermost ring
    self.drawThirdRing = scale >= 0.8

    self.col_flash = Color( 255, 255, 255, 255 )
    self.col_ring1 = Color( 255, 255, 255, 255 )
    self.col_ring2 = Color( 255, 255, 255, 255 )
    self.col_ring3 = Color( 255, 255, 255, 255 )

    SpawnParticles( self.pos, self.radius, math.floor( 12 * scale ), scale )

    util.ScreenShake( self.pos, 12 * scale, 9 * scale, 0.8, self.radius * 2.2 )

    local dynamicLight = DynamicLight( self:EntIndex() )
    if dynamicLight then
        dynamicLight.pos = self.pos
        dynamicLight.r = BLAST_R
        dynamicLight.g = BLAST_G
        dynamicLight.b = BLAST_B
        dynamicLight.brightness = 3 * scale
        dynamicLight.decay = 1400
        dynamicLight.size = self.radius * 1.5 * scale
        dynamicLight.dietime = CurTime() + 0.2
    end
end

function EFFECT:Think()
    if self.t >= self.tout then return false end

    self.t = math.min( self.tout, self.t + FrameTime() )
    return true
end

function EFFECT:Render()
    local fraction = self.t / self.tout
    local eased = math.ease.OutQuart( fraction )
    local scale = self.scale
    local radius = self.radius
    local pos = self.pos

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

    -- Initial flash, gone by a quarter of the way through
    local flashAlpha = math.max( 0, 1 - fraction * 4 )
    if flashAlpha > 0 then
        local flashAlphaCubed = flashAlpha * flashAlpha * flashAlpha
        local flashShrink = math.max( 0, 1 - fraction * 3 )
        local flashSize = radius * flashShrink * 2 * scale

        self.col_flash.r = math.Round( 80 * flashAlpha )
        self.col_flash.g = math.Round( 255 * flashAlpha )
        self.col_flash.b = math.Round( 60 * flashAlphaCubed )
        self.col_flash.a = 255

        render.SetMaterial( self.mat_fire )
        render.DrawSprite( pos, flashSize, flashSize, self.col_flash )
    end

    render.SetMaterial( self.mat_beam )

    -- Ring 1, brightest and fastest to fade
    local alpha1 = math.max( 0, 1 - fraction ) ^ 2
    local diameter1 = Lerp( eased, radius * 0.4 * scale, radius * 1.8 * scale )
    self.col_ring1.r = math.Round( 80 * alpha1 )
    self.col_ring1.g = math.Round( 255 * alpha1 )
    self.col_ring1.b = math.Round( 60 * alpha1 * alpha1 )
    self.col_ring1.a = math.Round( 255 * alpha1 )
    DrawBeamRing( pos, self.normal1, diameter1 / 2, 10 * alpha1 * scale, self.col_ring1, 32 )

    -- Ring 2
    local alpha2 = math.max( 0, 1 - fraction * 1.4 ) ^ 2
    local diameter2 = Lerp( eased, radius * 0.6 * scale, radius * 2.4 * scale )
    self.col_ring2.r = math.Round( 60 * alpha2 )
    self.col_ring2.g = math.Round( 220 * alpha2 )
    self.col_ring2.b = math.Round( 50 * alpha2 * alpha2 )
    self.col_ring2.a = math.Round( 255 * alpha2 )
    DrawBeamRing( pos, self.normal2, diameter2 / 2, 7 * alpha2 * scale, self.col_ring2, 32 )

    -- Ring 3, outermost, big blasts only
    if self.drawThirdRing then
        local alpha3 = math.max( 0, 1 - fraction * 2 )
        local diameter3 = Lerp( eased, radius * 0.8 * scale, radius * 3.0 * scale )
        self.col_ring3.r = math.Round( 40 * alpha3 )
        self.col_ring3.g = math.Round( 180 * alpha3 )
        self.col_ring3.b = math.Round( 40 * alpha3 * alpha3 )
        self.col_ring3.a = math.Round( 255 * alpha3 )
        DrawBeamRing( pos, self.normal3, diameter3 / 2, 5 * alpha3 * scale, self.col_ring3, 32 )
    end

    render.OverrideBlend( false )
end
