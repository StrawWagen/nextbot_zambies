AddCSLuaFile()

function EFFECT:Init( effectData )
    self.origin = effectData:GetOrigin()
    self.size = effectData:GetScale() * 2.75
    self.growth = effectData:GetMagnitude() * 100 * 2.75
    self.R_color = effectData:GetColor()
    self.startTime = CurTime()

    self:SetModel( "models/hunter/misc/sphere2x2.mdl" )
    self:SetRenderMode( RENDERMODE_TRANSADD )
    self:SetMaterial( "reanimator/reanimator_orb" )
    self:SetModelScale( 0 )

    self:SetPos( self.origin )

    self.matOverlay = Material( "reanimator/reanimator_orb" )
    self.spinAngle = 0
end

function EFFECT:Think()
    local A_percent = ( self.size - self:GetModelScale() * 128 ) / self.size
    local A_value = 96 * A_percent + 8

    local newScale = ( ( CurTime() - self.startTime ) * self.growth ) / 128

    self:SetModelScale( newScale )
    self:SetColor( Color( self.R_color, 0, 0, A_value ) )

    self.spinAngle = ( self.spinAngle - FrameTime() * 120 ) % 360
    local ang = self:GetAngles()
    ang.y = self.spinAngle
    self:SetAngles( ang )

    if self:GetModelScale() > self.size / 128 then
        return false
    else
        return true
    end
end

function EFFECT:Render()
    local scrollSpeed = 0.5
    local offset = ( CurTime() * scrollSpeed ) % 1

    local mat = self.matOverlay
    if mat and not mat:IsError() then
        local matrixT = Matrix()
        matrixT:Translate( Vector( 0, offset, 0 ) )

        mat:SetMatrix( "$basetexturetransform", matrixT )
    end

    render.CullMode( MATERIAL_CULLMODE_NONE )
    render.MaterialOverride( mat )

    self:DrawModel()

    render.MaterialOverride( nil )
    render.CullMode( MATERIAL_CULLMODE_CCW )
end
