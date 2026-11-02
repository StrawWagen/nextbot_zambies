-- green blood burst, for boomers and blastcrabs
-- magnitude scales everything, blastcrabs use 0.6, boomers 1 or more
EFFECT.mat_fire = Material( "particle/smokesprites_0002" )
EFFECT.mat_beam = Material( "trails/plasma" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local BLOOD_DECALS = {}
for i = 1, 9 do
    BLOOD_DECALS[i] = Material( "decals/blood" .. i )
end

local BLOOD_R, BLOOD_G, BLOOD_B = 40, 220, 50
local bloodColor = Color( BLOOD_R, BLOOD_G, BLOOD_B )

local gravFire  = Vector( 0, 0, -40 )
local gravFall  = Vector( 0, 0, -900 )
local gravSmoke = Vector( 0, 0, 20 )

local function RandomDirection()
    local dir = VectorRand() -- not unit length, VectorRand samples a cube
    dir:Normalize()
    return dir

end

local function SpawnParticles( pos, radius, scale )
    local emitter = ParticleEmitter( pos )
    if not emitter then return end

    -- brief flash
    for _ = 1, 2 do
        local particle = emitter:Add( "sprites/light_glow02_add", pos )
        if not particle then continue end

        particle:SetVelocity( RandomDirection() * math.Rand( 5, 15 ) )
        particle:SetDieTime( math.Rand( 0.04, 0.09 ) )
        particle:SetStartAlpha( 180 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( radius * math.Rand( 0.4, 0.6 ) * scale )
        particle:SetEndSize( radius * math.Rand( 0.7, 1.0 ) * scale )
        particle:SetColor( BLOOD_R, BLOOD_G, BLOOD_B )

    end

    -- puff of gore
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
        particle:SetColor( BLOOD_R, BLOOD_G, BLOOD_B )

    end

    -- chunks flung out
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
        particle:SetGravity( gravFall )
        particle:SetColor( BLOOD_R, BLOOD_G, BLOOD_B )
        particle:SetCollide( true )
        particle:SetBounce( 0.1 )

    end

    -- glowing drips, biased upwards so they arc
    for _ = 1, math.floor( 28 * scale ) do
        local particle = emitter:Add( "sprites/light_glow02_add", pos )
        if not particle then continue end

        local dir = VectorRand()
        dir.z = math.abs( dir.z ) * 1.2 + 0.3
        dir:Normalize()

        particle:SetVelocity( dir * math.Rand( 120, 500 ) * scale )
        particle:SetDieTime( math.Rand( 0.4, 1.1 ) )
        particle:SetStartAlpha( 210 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( math.Rand( 3, 9 ) * scale )
        particle:SetEndSize( 0 )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetGravity( gravFall )
        particle:SetColor( BLOOD_R, BLOOD_G, BLOOD_B )
        particle:SetCollide( true )
        particle:SetBounce( 0.05 )

    end

    -- lingering smoke
    for _ = 1, math.floor( 5 * scale ) do
        local particle = emitter:Add( "particle/smokesprites_0001", pos )
        if not particle then continue end

        local dir = VectorRand()
        dir.z = math.abs( dir.z ) + 0.5
        dir:Normalize()

        local size = math.Rand( radius * 0.08, radius * 0.18 ) * scale
        particle:SetVelocity( dir * math.Rand( 30, 90 ) * scale )
        particle:SetDieTime( math.Rand( 0.5, 1.2 ) )
        particle:SetStartAlpha( 90 )
        particle:SetEndAlpha( 0 )
        particle:SetStartSize( size )
        particle:SetEndSize( size * 1.8 )
        particle:SetRoll( math.Rand( 0, 360 ) )
        particle:SetRollDelta( math.Rand( -1, 1 ) )
        particle:SetGravity( gravSmoke )
        particle:SetColor( 25, 50, 25 )

    end

    emitter:Finish()

end

local function SplatterDecals( pos, radius, scale )
    for _ = 1, math.Round( 12 * scale ) do
        local tr = util.TraceLine( {
            start  = pos,
            endpos = pos + RandomDirection() * radius,
            mask   = MASK_SOLID_BRUSHONLY,
        } )
        if not tr.Hit then continue end

        local mat = BLOOD_DECALS[math.random( 1, #BLOOD_DECALS )]
        if mat:IsError() then continue end

        util.DecalEx( mat, tr.Entity, tr.HitPos, tr.HitNormal, bloodColor, math.Rand( 0.6, 1.6 ) * scale, math.Rand( 0.6, 1.6 ) * scale )

    end
end

function EFFECT:Init( data )
    self.pos    = data:GetOrigin()
    self.radius = data:GetRadius()
    self.scale  = data:GetMagnitude()

    -- each ring faces a random way, bigger blasts get a third ring
    self.rings = {}
    local ringCount = self.scale >= 1 and 3 or 2
    for i = 1, ringCount do
        local tangent, bitangent = terminator_Extras.zamb_RingBasis( RandomDirection() )
        self.rings[i] = { tangent = tangent, bitangent = bitangent, color = Color( 255, 255, 255 ) }

    end
    self.flashColor = Color( 255, 255, 255 )

    self.t    = 0
    self.tout = math.Rand( 0.78, 0.96 ) * self.scale ^ 0.75

    SpawnParticles( self.pos, self.radius, self.scale )
    SplatterDecals( self.pos, self.radius, self.scale )

    util.ScreenShake( self.pos, 12 * self.scale, 9 * self.scale, 0.8, self.radius * 2.2 )

    local dl = DynamicLight( self:EntIndex() )
    if dl then
        dl.pos        = self.pos
        dl.r          = BLOOD_R
        dl.g          = BLOOD_G
        dl.b          = BLOOD_B
        dl.brightness = 3 * self.scale
        dl.decay      = 1400
        dl.size       = self.radius * 1.5 * self.scale
        dl.dietime    = CurTime() + 0.2
    end
end

function EFFECT:Think()
    if self.t < self.tout then
        self.t = math.min( self.tout, self.t + FrameTime() )
        return true
    end
    return false
end

-- per ring: how fast it fades, start and end size as a fraction of radius, beam width, and full color
local RING_SHAPES = {
    { fadeSpeed = 1,   startSize = 0.4, endSize = 1.8, width = 10, squaredFade = true,  r = 80, g = 255, b = 60 },
    { fadeSpeed = 1.4, startSize = 0.6, endSize = 2.4, width = 7,  squaredFade = true,  r = 60, g = 220, b = 50 },
    { fadeSpeed = 2,   startSize = 0.8, endSize = 3.0, width = 5,  squaredFade = false, r = 40, g = 180, b = 40 },
}

function EFFECT:Render()
    local frac      = self.t / self.tout
    local fracEased = math.ease.OutQuart( frac )
    local scale     = self.scale
    local radius    = self.radius
    local pos       = self.pos

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

    -- the flash fades out in the first quarter, its blue goes first so it shifts green
    local flashAlpha = math.max( 0, 1 - frac * 4 )
    if flashAlpha > 0 then
        local flashColor = self.flashColor
        flashColor.r = math.Round( 80 * flashAlpha )
        flashColor.g = math.Round( 255 * flashAlpha )
        flashColor.b = math.Round( 60 * flashAlpha ^ 3 )

        local flashShrink = math.max( 0, 1 - frac * 3 )
        local flashSize = radius * flashShrink * 2 * scale

        render.SetMaterial( self.mat_fire )
        render.DrawSprite( pos, flashSize, flashSize, flashColor )

    end

    render.SetMaterial( self.mat_beam )
    for i, ring in ipairs( self.rings ) do
        local shape = RING_SHAPES[i]
        local alpha = math.max( 0, 1 - frac * shape.fadeSpeed )
        if shape.squaredFade then
            alpha = alpha ^ 2

        end

        local color = ring.color
        color.r = math.Round( shape.r * alpha )
        color.g = math.Round( shape.g * alpha )
        color.b = math.Round( shape.b * alpha * alpha )
        color.a = math.Round( 255 * alpha )

        local ringRadius = Lerp( fracEased, radius * shape.startSize, radius * shape.endSize ) * scale / 2
        terminator_Extras.zamb_DrawBeamRing( pos, ring.tangent, ring.bitangent, ringRadius, shape.width * alpha * scale, color, 32 )

    end

    render.OverrideBlend( false )
end
