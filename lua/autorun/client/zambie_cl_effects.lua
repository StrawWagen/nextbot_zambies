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
