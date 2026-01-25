function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local color = data:GetStart()
    local scale = data:GetScale() or 1

    local emitter = ParticleEmitter( pos, false )
    if not emitter then return end

    for _ = 1, 3 do
        local particle = emitter:Add( "particle/particle_smokegrenade", pos )
        if particle then
            local vel = Vector( math.Rand( -8, 8 ), math.Rand( -8, 8 ), math.Rand( 15, 45 ) )
            particle:SetVelocity( vel )
            particle:SetDieTime( math.Rand( 1.5, 2.5 ) )
            particle:SetStartAlpha( math.Rand( 120, 180 ) )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( math.Rand( 6, 12 ) * scale )
            particle:SetEndSize( math.Rand( 18, 30 ) * scale )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -1, 1 ) )
            particle:SetColor( color.x, color.y, color.z )
            particle:SetGravity( Vector( 0, 0, 25 ) )
            particle:SetAirResistance( 100 )
            particle:SetCollide( false )
            particle:SetLighting( false )

        end
    end

    local wisp = emitter:Add( "effects/splash2", pos )
    if wisp then
        local vel = Vector( math.Rand( -5, 5 ), math.Rand( -5, 5 ), math.Rand( 25, 60 ) )
        wisp:SetVelocity( vel )
        wisp:SetDieTime( math.Rand( 1, 2 ) )
        wisp:SetStartAlpha( math.Rand( 100, 160 ) )
        wisp:SetEndAlpha( 0 )
        wisp:SetStartSize( math.Rand( 4, 8 ) * scale )
        wisp:SetEndSize( math.Rand( 12, 18 ) * scale )
        wisp:SetRoll( math.Rand( 0, 360 ) )
        wisp:SetRollDelta( math.Rand( -1.5, 1.5 ) )
        wisp:SetColor( color.x * 1.2, color.y * 1.2, color.z * 1.2 )
        wisp:SetGravity( Vector( 0, 0, 35 ) )
        wisp:SetAirResistance( 80 )
        wisp:SetCollide( false )
        wisp:SetLighting( false )

    end

    emitter:Finish()

end

function EFFECT:Think()
    return false

end

function EFFECT:Render()
end