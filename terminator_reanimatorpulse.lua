
AddCSLuaFile()

function EFFECT:Init( effectData )
	self.origin = effectData:GetOrigin()
	self.size = effectData:GetScale()
	self.growth = effectData:GetMagnitude() * 100
	self.R_color = effectData:GetColor()
	self.startTime = CurTime()

	self:SetModel( "models/hunter/misc/shell2x2.mdl" )
	self:SetRenderMode( RENDERMODE_TRANSADD )
	self:SetMaterial( "lights/white002" )
	self:SetModelScale( 0 )
	
	self:SetPos( self.origin )

end

function EFFECT:Think()
	local A_percent = ( self.size - self:GetModelScale() * 128 ) / self.size
	local A_value = 96 * A_percent + 8
	
	local newScale = ( ( CurTime() - self.startTime ) * self.growth ) / 128
	
	self:SetModelScale( newScale )
	self:SetColor( Color( self.R_color, 0, 0, A_value ) )
	
	if self:GetModelScale() > self.size / 128 then
		return false
		
	else
		return true
		
	end
	
end

function EFFECT:Render()
	self:DrawModel()
	
end