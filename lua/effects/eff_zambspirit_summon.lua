-- Shrinking red sigil shown where a summoned zambie WAS standing.
-- Replaces the old "zambspirit_summoneffect" net message + PostDrawTranslucentRenderables hook.
--
-- Effect data:
--   origin = centre of the sigil
--   radius = starting size of the sigil

EFFECT.mat = Material( "effects/strider_muzzle" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local DURATION = 1
local DEFAULT_SIZE = 72

function EFFECT:Init( data )
    self.pos = data:GetOrigin()
    self.startSize = data:GetRadius()

    if self.startSize <= 0 then
        self.startSize = DEFAULT_SIZE
    end

    self.startTime = CurTime()

    -- Without this the effect gets culled whenever the entity's own origin is off screen
    local extent = Vector( self.startSize, self.startSize, self.startSize )
    self:SetPos( self.pos )
    self:SetRenderBoundsWS( self.pos - extent, self.pos + extent )
end

function EFFECT:Think()
    return CurTime() - self.startTime < DURATION
end

function EFFECT:Render()
    if render.GetRenderTarget() then return end

    local elapsed = CurTime() - self.startTime
    local fade = 1 - ( elapsed / DURATION )
    if fade <= 0 then return end

    -- Face the camera
    local facing = ( self.pos - EyePos() ):Angle()
    facing:RotateAroundAxis( facing:Right(), 90 )

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

    surface.SetMaterial( self.mat )
    surface.SetDrawColor( 255 * fade, 0, 0, 255 * fade )

    -- Four layers, each on its own offset of the same shrink cycle
    for i = 1, 4 do
        local cycle = ( elapsed + i / 4 ) % 1
        local size = ( self.startSize - cycle * ( self.startSize * 0.5 ) ) * fade

        cam.Start3D2D( self.pos, facing, 1 )
        surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * i * 360 )
        cam.End3D2D()
    end

    render.OverrideBlend( false )
end
