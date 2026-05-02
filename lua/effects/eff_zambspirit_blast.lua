EFFECT.mat_fire = Material("particle/smokesprites_0002")
EFFECT.mat_beam = Material("trails/plasma")

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

local function DrawBeamRing(center, normal, radius, width, color, segments)
	local tangent = normal:Cross(Vector(0, 0, 1))
	if tangent:LengthSqr() < 0.001 then
		tangent = normal:Cross(Vector(0, 1, 0))
	end
	tangent:Normalize()
	local bitangent = normal:Cross(tangent)
	bitangent:Normalize()

	render.StartBeam(segments + 1)
	for i = 0, segments do
		local angle = (i / segments) * math.pi * 2
		local v = center + tangent * (math.cos(angle) * radius) + bitangent * (math.sin(angle) * radius)
		render.AddBeam(v, width, i / segments, color)
	end
	render.EndBeam()
end

function EFFECT:Init(data)
	self.pos = data:GetOrigin()
	self.size = data:GetRadius()

	self.normal = data:GetNormal()
	self.normal:Rotate(AngleRand(-16, 16))

	self.normal2 = VectorRand()
	self.normal2:Normalize()

	local durationMul = data:GetMagnitude() or 1
	self.t = 0
	self.tout = math.Rand(0.85, 1.12) * durationMul

	self.color = Color(255, 255, 255, 255)
	self.color_ring = Color(255, 255, 255, 255)
	self.color_ring2 = Color(255, 255, 255, 255)

	local dl = DynamicLight(self:EntIndex())
	if dl then
		dl.pos = self.pos
		dl.r = 255
		dl.g = 0
		dl.b = 32
		dl.brightness = 5
		dl.decay = 1000
		dl.size = self.size * 1.2
		dl.dietime = CurTime() + 1
	end
end

function EFFECT:Think()
	if self.t < self.tout then
		self.t = math.min(self.tout, self.t + FrameTime())
		return true
	end
	return false
end

function EFFECT:Render()
	local f = self.t / self.tout

	local a_flash = math.max(0, 1 - f * 4)
	local e_flash = math.max(0, 1 - f * 3)

	render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)

		if a_flash > 0 then
			local a3 = a_flash * a_flash * a_flash
			self.color.r = 255 * a_flash
			self.color.g = 150 * a3
			self.color.b = 150 * a3

			render.SetMaterial(self.mat_fire)
			render.DrawSprite(self.pos, self.size * e_flash * 2, self.size * e_flash * 2, self.color)
		end

		local fEased = math.ease.OutQuart(f)

		local a_ring = math.max(0, 1 - f) ^ 2
		local ringsize = Lerp(fEased, self.size * 0.5, self.size * 2 + 8)
		self.color_ring.r = 255 * a_ring
		self.color_ring.g = 255 * a_ring * a_ring
		self.color_ring.b = 255 * a_ring * a_ring
		self.color_ring.a = 255 * a_ring

		local a_ring2 = math.max(0, 1 - f * 2)
		local ringsize2 = Lerp(fEased, self.size * 0.75, self.size * 3 + 16)
		self.color_ring2.r = 255 * a_ring2
		self.color_ring2.g = 255 * a_ring2 * a_ring2
		self.color_ring2.b = 255 * a_ring2 * a_ring2
		self.color_ring2.a = 255 * a_ring2

		render.SetMaterial(self.mat_beam)
		DrawBeamRing(self.pos, self.normal, ringsize / 2, 8 * a_ring, self.color_ring, 32)
		DrawBeamRing(self.pos, self.normal2, ringsize2 / 2, 6 * a_ring2, self.color_ring2, 32)

	render.OverrideBlend(false)
end