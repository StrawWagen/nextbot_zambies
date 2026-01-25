function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local color = data:GetStart()
    local scale = data:GetScale() or 1
    local count = math.floor( data:GetMagnitude() or 5 )

    local emitter = ParticleEmitter( pos, false )
    if not emitter then return end

    for _ = 1, count do
        local particle = emitter:Add( "particle/particle_smokegrenade", pos + VectorRand() * 10 * scale )
        if particle then
            local vel = Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( 30, 80 ) ) * scale
            particle:SetVelocity( vel )
            particle:SetDieTime( math.Rand( 1.2, 2.2 ) )
            particle:SetStartAlpha( math.Rand( 180, 230 ) )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( math.Rand( 8, 16 ) * scale )
            particle:SetEndSize( math.Rand( 25, 40 ) * scale )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -1.5, 1.5 ) )
            particle:SetColor( color.x, color.y, color.z )
            particle:SetGravity( Vector( 0, 0, 40 ) )
            particle:SetAirResistance( 80 )
            particle:SetCollide( false )
            particle:SetLighting( false )

        end

        local wisp = emitter:Add( "effects/splash2", pos + VectorRand() * 6 * scale )
        if wisp then
            local vel = Vector( math.Rand( -15, 15 ), math.Rand( -15, 15 ), math.Rand( 40, 100 ) ) * scale
            wisp:SetVelocity( vel )
            wisp:SetDieTime( math.Rand( 0.8, 1.5 ) )
            wisp:SetStartAlpha( math.Rand( 150, 200 ) )
            wisp:SetEndAlpha( 0 )
            wisp:SetStartSize( math.Rand( 4, 8 ) * scale )
            wisp:SetEndSize( math.Rand( 12, 20 ) * scale )
            wisp:SetRoll( math.Rand( 0, 360 ) )
            wisp:SetRollDelta( math.Rand( -2, 2 ) )
            wisp:SetColor( color.x * 1.3, color.y * 1.3, color.z * 1.3 )
            wisp:SetGravity( Vector( 0, 0, 60 ) )
            wisp:SetAirResistance( 60 )
            wisp:SetCollide( false )
            wisp:SetLighting( false )

        end
    end

    emitter:Finish()

end

function EFFECT:Think()
    return false

end

function EFFECT:Render()
end