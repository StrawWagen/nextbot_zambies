EFFECT.mat_beam = Material("trails/plasma")
EFFECT.mat_soul = Material("effects/fluttercore_gmod")

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

function EFFECT:Init(data)
	self.origin = data:GetOrigin()
	self.ent = data:GetEntity()

	self.t = 0
	self.tout = 1.85
	self.seed = math.random() * 256
	self.color = Color(255, 255, 255)

	self:EmitSound("ambient/levels/citadel/portal_beam_shoot5.wav", 100, 200, 1)
	self:GenPoints()

	if IsValid(self.ent) then
		self:SetRenderBoundsWS(self.origin, self.ent:WorldSpaceCenter())
	end
end

function EFFECT:Think()
	local selfTbl = self:GetTable()
	if selfTbl.t < selfTbl.tout and IsValid(selfTbl.ent) then
		selfTbl.t = selfTbl.t + FrameTime()
		self:GenPoints()
		return true
	end
	return false
end

function EFFECT:GenPoints()
	local selfTbl = self:GetTable()
	if not selfTbl.origin then return end

	if not selfTbl.points then
		if not IsValid(selfTbl.ent) then return end

		local targetpos = selfTbl.ent:WorldSpaceCenter()
		local n = math.random(25, 30)

		selfTbl.targetpos = targetpos
		selfTbl.points = { selfTbl.origin }

		for i = 1, n do
			local nv = LerpVector(math.Remap(i + math.random() - 0.5, 0, n + 2, 0, 1), selfTbl.origin, targetpos)
			selfTbl.points[i + 1] = nv
		end
		selfTbl.points[n + 2] = targetpos
	else
		local n = #selfTbl.points
		local delta = FrameTime() * 70
		local tSeed = selfTbl.t + selfTbl.seed

		for i, nv in ipairs(selfTbl.points) do
			local f = math.TimeFraction(1, n, i)
			local parabolic = math.max(0, -4 * (f * f) + 4 * f) * delta

			local phase = tSeed + i / n
			local nvx, nvy, nvz = nv:Unpack()
			nv:SetUnpacked(
				nvx + math.sin(phase) * parabolic,
				nvy + math.sin(phase + 62) * parabolic,
				nvz + math.sin(phase + 523) * parabolic
			)
		end
	end
end

function EFFECT:Render()
	local selfTbl = self:GetTable()
	if not IsValid(selfTbl.ent) or not selfTbl.points then return end

	local n = #selfTbl.points
	local tf = 1 - (selfTbl.t / selfTbl.tout)
	local timeParabolic = math.max(0, -4 * (tf * tf) + 4 * tf)
	local tfOrig = selfTbl.t / selfTbl.tout

	selfTbl.color.r = Lerp(timeParabolic, 255, 230)
	selfTbl.color.g = Lerp(tfOrig, 64, 14)
	selfTbl.color.b = Lerp(tfOrig, 100, 14)

	render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_ONE, BLENDFUNC_ADD)

		render.SetMaterial(selfTbl.mat_beam)
		render.StartBeam(n)

		for i, point in ipairs(selfTbl.points) do
			local f = math.TimeFraction(1, n, i)
			local alphamax = math.max(0, 1 - math.abs(Lerp(tf * 2 - 1 + 1 - i / n, 2, -1)))
			local parabolic = math.max(0, -4 * (f * f) + 4 * f) * timeParabolic
			render.AddBeam(point, 15 * parabolic + timeParabolic * 8, math.Remap(i, 1, n, 0, tf), ColorAlpha(selfTbl.color, math.max(alphamax * 255, parabolic * 64)))
		end

		render.EndBeam()

		local tf2 = math.min(1, math.max(0, selfTbl.t - 0.15) * 3 / selfTbl.tout)
		local tp2 = math.max(0, -4 * (tf2 * tf2) + 4 * tf2)
		render.SetMaterial(selfTbl.mat_soul)
		render.DrawSprite(selfTbl.origin, 95 * tp2 * tp2, 64 * tp2, selfTbl.color)

	render.OverrideBlend(false)
end