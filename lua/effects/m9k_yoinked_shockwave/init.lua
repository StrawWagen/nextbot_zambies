-- yoinked because m9k is the goat

function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local scale = data:GetScale()

    self.Emitter = ParticleEmitter( pos )

    local maxsize = 350 * scale
    local ptclCount = 300 * scale

    for _ = 1, ptclCount do
        local particle = self.Emitter:Add( "particle/smokesprites_000" .. math.random( 1, 9 ), pos )
        if particle then
            particle:SetVelocity( Vector( math.random( -10, 10 ), math.random( -10, 10 ), 0 ):GetNormal() * 10000 * scale )
            particle:SetDieTime( 3.5 * scale )
            particle:SetStartAlpha( math.Rand( 40, 60 ) )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( math.Rand( maxsize * 0.4, maxsize * 0.5 ) )
            particle:SetEndSize( math.Rand( maxsize * 0.8, maxsize ) )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -1, 1 ) )
            particle:SetColor( 90, 83, 68 )
            particle:SetAirResistance( 50 )
            particle:SetCollide( true )
            particle:SetBounce( 0 )
        end
    end
end

function EFFECT:Think()
    self.Emitter:Finish()
    return false
end

function EFFECT:Render()

end