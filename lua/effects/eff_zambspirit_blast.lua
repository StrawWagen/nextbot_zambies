-- Red shockwave played when a spirit dies.
--
-- Effect data:
--   origin    = where it goes off
--   radius    = size of the flash and rings
--   normal    = axis of the first ring
--   magnitude = duration multiplier

EFFECT.mat_fire = Material( "particle/smokesprites_0002" )
EFFECT.mat_beam = Material( "trails/plasma" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

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

function EFFECT:Init( data )
    self.pos = data:GetOrigin()
    self.size = data:GetRadius()

    -- Tilt the first ring a little so repeated blasts don't look identical
    self.normal = data:GetNormal()
    self.normal:Rotate( AngleRand( -16, 16 ) )

    -- VectorRand() isn't a unit vector, so normalize it
    self.normal2 = VectorRand()
    self.normal2:Normalize()

    local durationMul = data:GetMagnitude() or 1
    self.t = 0
    self.tout = math.Rand( 0.85, 1.12 ) * durationMul

    self.color = Color( 255, 255, 255, 255 )
    self.color_ring = Color( 255, 255, 255, 255 )
    self.color_ring2 = Color( 255, 255, 255, 255 )

    local dynamicLight = DynamicLight( self:EntIndex() )
    if dynamicLight then
        dynamicLight.pos = self.pos
        dynamicLight.r = 255
        dynamicLight.g = 0
        dynamicLight.b = 32
        dynamicLight.brightness = 5
        dynamicLight.decay = 1000
        dynamicLight.size = self.size * 1.2
        dynamicLight.dietime = CurTime() + 1
    end
end

function EFFECT:Think()
    if self.t >= self.tout then return false end

    self.t = math.min( self.tout, self.t + FrameTime() )
    return true
end

function EFFECT:Render()
    local fraction = self.t / self.tout

    local flashAlpha = math.max( 0, 1 - fraction * 4 )
    local flashShrink = math.max( 0, 1 - fraction * 3 )

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

    if flashAlpha > 0 then
        local flashAlphaCubed = flashAlpha * flashAlpha * flashAlpha
        local flashSize = self.size * flashShrink * 2

        self.color.r = 255 * flashAlpha
        self.color.g = 150 * flashAlphaCubed
        self.color.b = 150 * flashAlphaCubed

        render.SetMaterial( self.mat_fire )
        render.DrawSprite( self.pos, flashSize, flashSize, self.color )
    end

    local eased = math.ease.OutQuart( fraction )

    -- Ring 1
    local ringAlpha = math.max( 0, 1 - fraction ) ^ 2
    local ringSize = Lerp( eased, self.size * 0.5, self.size * 2 + 8 )
    self.color_ring.r = 255 * ringAlpha
    self.color_ring.g = 255 * ringAlpha * ringAlpha
    self.color_ring.b = 255 * ringAlpha * ringAlpha
    self.color_ring.a = 255 * ringAlpha

    -- Ring 2, fades out twice as fast
    local ringAlpha2 = math.max( 0, 1 - fraction * 2 )
    local ringSize2 = Lerp( eased, self.size * 0.75, self.size * 3 + 16 )
    self.color_ring2.r = 255 * ringAlpha2
    self.color_ring2.g = 255 * ringAlpha2 * ringAlpha2
    self.color_ring2.b = 255 * ringAlpha2 * ringAlpha2
    self.color_ring2.a = 255 * ringAlpha2

    render.SetMaterial( self.mat_beam )
    DrawBeamRing( self.pos, self.normal, ringSize / 2, 8 * ringAlpha, self.color_ring, 32 )
    DrawBeamRing( self.pos, self.normal2, ringSize2 / 2, 6 * ringAlpha2, self.color_ring2, 32 )

    render.OverrideBlend( false )
end
