terminator_Extras = terminator_Extras or {}

local crossVecUp = Vector( 0, 0, 1 )
local crossVecSide = Vector( 0, 1, 0 )

-- two directions spanning the plane a ring faces, compute once per ring, not per frame
-- local tangent, bitangent = terminator_Extras.zamb_RingBasis( normal )
function terminator_Extras.zamb_RingBasis( normal )
    local tangent = normal:Cross( crossVecUp )
    if tangent:LengthSqr() < 0.001 then -- normal points straight up, cross with something else
        tangent = normal:Cross( crossVecSide )

    end
    tangent:Normalize()

    local bitangent = normal:Cross( tangent )
    bitangent:Normalize()

    return tangent, bitangent

end

-- boomers and their crabs bleed this, keep their particles, drips and decals on it
terminator_Extras.zamb_BoomerBloodColor = Color( 40, 220, 50 )

-- alien blood, the tint multiplies the texture so red blood decals stay red
local BOOMER_BLOOD_DECALS = {}
for i = 1, 6 do
    BOOMER_BLOOD_DECALS[i] = Material( "decals/yblood" .. i )

end

local decalTr = { mask = MASK_SOLID_BRUSHONLY }

-- splats boomer blood wherever a trace from start along dir lands, if it lands
function terminator_Extras.zamb_BoomerBloodDecal( start, dir, scale )
    decalTr.start = start
    decalTr.endpos = start + dir
    local tr = util.TraceLine( decalTr )
    if not tr.Hit then return end

    local mat = BOOMER_BLOOD_DECALS[math.random( 1, #BOOMER_BLOOD_DECALS )]
    if mat:IsError() then return end

    util.DecalEx( mat, tr.Entity, tr.HitPos, tr.HitNormal, terminator_Extras.zamb_BoomerBloodColor, math.Rand( 0.6, 1.6 ) * scale, math.Rand( 0.6, 1.6 ) * scale )

end

local ringPoint = Vector()

-- draws a ring of beam, call between render.SetMaterial and the next material change
function terminator_Extras.zamb_DrawBeamRing( center, tangent, bitangent, radius, width, color, segments )
    local centerX, centerY, centerZ = center:Unpack()
    local tangentX, tangentY, tangentZ = tangent:Unpack()
    local bitangentX, bitangentY, bitangentZ = bitangent:Unpack()

    render.StartBeam( segments + 1 )
    for i = 0, segments do
        local angle = ( i / segments ) * math.pi * 2
        local tangentOffset = math.cos( angle ) * radius
        local bitangentOffset = math.sin( angle ) * radius

        ringPoint:SetUnpacked(
            centerX + tangentX * tangentOffset + bitangentX * bitangentOffset,
            centerY + tangentY * tangentOffset + bitangentY * bitangentOffset,
            centerZ + tangentZ * tangentOffset + bitangentZ * bitangentOffset
        )
        render.AddBeam( ringPoint, width, i / segments, color )

    end
    render.EndBeam()

end
