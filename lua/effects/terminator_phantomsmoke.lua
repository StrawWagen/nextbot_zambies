function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local color = data:GetStart()
    local scale = data:GetScale() or 1

    local emitter = ParticleEmitter( pos, false )
    if not emitter then return end

    for _ = 1, 25 do
        local particle = emitter:Add( "particle/particle_smokegrenade", pos + VectorRand() * 25 * scale )
        if particle then
            local outward = VectorRand()
            outward.z = math.abs( outward.z ) * 0.7
            particle:SetVelocity( outward * math.Rand( 60, 140 ) * scale )
            particle:SetDieTime( math.Rand( 0.8, 1.6 ) )
            particle:SetStartAlpha( math.Rand( 200, 255 ) )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( math.Rand( 15, 28 ) * scale )
            particle:SetEndSize( math.Rand( 45, 70 ) * scale )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -2, 2 ) )
            particle:SetColor( color.x, color.y, color.z )
            particle:SetGravity( Vector( 0, 0, 30 ) )
            particle:SetAirResistance( 120 )
            particle:SetCollide( false )
            particle:SetLighting( false )

        end
    end

    for _ = 1, 15 do
        local spark = emitter:Add( "effects/spark", pos + VectorRand() * 15 * scale )
        if spark then
            local outward = VectorRand()
            outward.z = math.Rand( 0.2, 0.8 )
            spark:SetVelocity( outward * math.Rand( 80, 180 ) * scale )
            spark:SetDieTime( math.Rand( 0.4, 0.9 ) )
            spark:SetStartAlpha( 255 )
            spark:SetEndAlpha( 0 )
            spark:SetStartSize( math.Rand( 3, 6 ) * scale )
            spark:SetEndSize( 0 )
            spark:SetRoll( math.Rand( 0, 360 ) )
            spark:SetColor( color.x * 1.5, color.y * 1.5, color.z * 1.5 )
            spark:SetGravity( Vector( 0, 0, -50 ) )
            spark:SetAirResistance( 50 )
            spark:SetCollide( false )
            spark:SetLighting( false )

        end
    end

    emitter:Finish()

end

function EFFECT:Think()
    return false

end

function EFFECT:Render()
end