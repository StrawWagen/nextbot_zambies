-- shrinking red swirl left behind where a spirit pulled a zambie away from
-- radius is the swirl's starting size
EFFECT.mat = Material( "effects/strider_muzzle" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local DURATION = 1

function EFFECT:Init( data )
    self.pos       = data:GetOrigin()
    self.startSize = data:GetRadius()
    self.startTime = CurTime()

    local halfSize = Vector( self.startSize, self.startSize, self.startSize )
    self:SetRenderBoundsWS( self.pos - halfSize, self.pos + halfSize )
end

function EFFECT:Think()
    return CurTime() - self.startTime < DURATION
end

function EFFECT:Render()
    if render.GetRenderTarget() then return end

    local elapsed = CurTime() - self.startTime
    local frac    = 1 - ( elapsed / DURATION )
    if frac <= 0 then return end

    local pos   = self.pos
    local angle = ( pos - EyePos() ):Angle()
    angle:RotateAroundAxis( angle:Right(), 90 )

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
    surface.SetMaterial( self.mat )
    surface.SetDrawColor( 255 * frac, 0, 0, 255 * frac )

    -- four layers, each a quarter cycle out of step, shrinking and spinning
    local startSize = self.startSize
    for layer = 1, 4 do
        local cycle = ( elapsed + layer / 4 ) % 1
        local size  = ( startSize - cycle * ( startSize * 0.5 ) ) * frac

        cam.Start3D2D( pos, angle, 1 )
        surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * layer * 360 )
        cam.End3D2D()
    end

    render.OverrideBlend( false )
end
