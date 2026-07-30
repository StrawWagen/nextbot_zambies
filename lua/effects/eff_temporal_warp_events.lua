EFFECT.Holdable = false
EFFECT.Tickable = true

local CParticle = {}
CParticle.__index = CParticle

function CParticle:Create(pos, config, scale)
    local p = {}
    setmetatable(p, self)
    
    scale = scale or 1
    local dist = math.Rand(config.SpawnDistMin or 0, config.SpawnDistMax or 0)
    local dir = VectorRand()
    if config.SpawnBias then
        dir.x = dir.x * config.SpawnBias.x
        dir.y = dir.y * config.SpawnBias.y
        dir.z = dir.z * config.SpawnBias.z
    end
    p.origin = pos
    p.pos = pos + dir * dist * scale
    
    p.vel = (config.InitialVelocity or Vector(0,0,0))
    if config.VelocityNoise then
        p.vel = p.vel + VectorRand() * config.VelocityNoise
    end
    
    p.gravity = config.Gravity or Vector(0,0,0)
    p.drag = config.Drag or 0
    
    p.life = math.Rand(config.LifetimeMin or 1, config.LifetimeMax or 1)
    p.max_life = p.life
    
    p.initial_radius = math.Rand(config.RadiusMin or 5, config.RadiusMax or 5) * scale
    p.radius = p.initial_radius
    p.radius_scale_start = config.RadiusScaleStart or 1
    p.radius_scale_end = config.RadiusScaleEnd or 1
    
    local f = math.random()
    p.base_color = Color(
        Lerp(f, config.Color1.r, config.Color2.r),
        Lerp(f, config.Color1.g, config.Color2.g),
        Lerp(f, config.Color1.b, config.Color2.b)
    )
    p.base_alpha = Lerp(f, config.Color1.a / 255, config.Color2.a / 255)
    p.color = Color(p.base_color.r, p.base_color.g, p.base_color.b, 255)
    
    -- Dynamic Tinting for variety
    if config.DynamicTint then
        local choice = math.random(1, 2)
        if choice == 1 then
            -- Lighter shade
            local lighten = math.Rand(0.15, 0.4)
            p.color.r = math.Clamp(p.color.r + 255 * lighten, 0, 255)
            p.color.g = math.Clamp(p.color.g + 255 * lighten, 0, 255)
            p.color.b = math.Clamp(p.color.b + 255 * lighten, 0, 255)
        else
            -- Redder / Purplish shade
            local redden = math.Rand(0.15, 0.4)
            p.color.r = math.Clamp(p.color.r + 255 * redden, 0, 255)
            p.color.g = math.Clamp(p.color.g - 255 * redden * 0.5, 0, 255)
            p.color.b = math.Clamp(p.color.b - 255 * redden * 0.2, 0, 255)
        end
        -- Sync base_color so color fading doesn't override the tint
        p.base_color.r = p.color.r
        p.base_color.g = p.color.g
        p.base_color.b = p.color.b
    end
    
    p.alpha_fade_in = config.AlphaFadeIn or 0
    p.alpha_fade_out = config.AlphaFadeOut or 1
    
    p.color_fade = config.ColorFade
    p.color_fade_start = config.ColorFadeStart or 0
    p.color_fade_end = config.ColorFadeEnd or 0.5
    
    p.pull_force = config.PullForce
    p.pull_falloff = config.PullFalloff or 1
    
    if config.OscillateFreq then
        p.osc_freq = Vector(
            math.Rand(config.OscillateMinFreq.x, config.OscillateFreq.x),
            math.Rand(config.OscillateMinFreq.y, config.OscillateFreq.y),
            math.Rand(config.OscillateMinFreq.z, config.OscillateFreq.z)
        )
        p.osc_rate = Vector(
            math.Rand(config.OscillateMinRate.x, config.OscillateRate.x),
            math.Rand(config.OscillateMinRate.y, config.OscillateRate.y),
            math.Rand(config.OscillateMinRate.z, config.OscillateRate.z)
        )
        p.osc_phase = VectorRand() * math.pi
    end
    
    p.material = config.Material
    p.anim_rate = config.AnimRate or 1.3
    p.anim_offset = math.Rand(0, 10)
    
    return p
end

function CParticle:Update(dt)
    self.life = self.life - dt
    if self.life <= 0 then return false end
    
    local life_frac = 1 - (self.life / self.max_life)
    
    if self.pull_force then
        local dir = self.origin - self.pos
        local dist = dir:Length()
        if dist > 1 then
            dir:Normalize()
            self.vel = self.vel + dir * (self.pull_force / math.pow(dist, self.pull_falloff)) * dt
        end
    end
    
    self.vel = self.vel + self.gravity * dt
    self.vel = self.vel * (1 - self.drag * dt)
    self.pos = self.pos + self.vel * dt
    
    if self.osc_freq then
        local t = CurTime()
        local ox = math.sin(t * self.osc_freq.x + self.osc_phase.x) * self.osc_rate.x
        local oy = math.sin(t * self.osc_freq.y + self.osc_phase.y) * self.osc_rate.y
        local oz = math.sin(t * self.osc_freq.z + self.osc_phase.z) * self.osc_rate.z
        self.pos = self.pos + Vector(ox, oy, oz) * dt
    end
    
    self.radius = self.initial_radius * Lerp(life_frac, self.radius_scale_start, self.radius_scale_end)
    
    if self.color_fade then
        local fade_frac = 0
        if life_frac >= self.color_fade_end then
            fade_frac = 1
        elseif life_frac > self.color_fade_start then
            fade_frac = (life_frac - self.color_fade_start) / (self.color_fade_end - self.color_fade_start)
        end
        self.color.r = Lerp(fade_frac, self.base_color.r, self.color_fade.r)
        self.color.g = Lerp(fade_frac, self.base_color.g, self.color_fade.g)
        self.color.b = Lerp(fade_frac, self.base_color.b, self.color_fade.b)
    end
    
    local alpha = self.base_alpha
    if self.alpha_fade_in > 0 and life_frac < self.alpha_fade_in then
        alpha = alpha * (life_frac / self.alpha_fade_in)
    end
    if self.alpha_fade_out > 0 then
        local start_frac = 1 - self.alpha_fade_out
        if life_frac > start_frac then
            alpha = alpha * (1 - (life_frac - start_frac) / self.alpha_fade_out)
        end
    end
    self.color.a = math.Clamp(alpha * 255, 0, 255)
    
    return true
end

function EFFECT:Init(data)
    self.EmitPos = data:GetOrigin()
    self.Scale = data:GetScale()
    if self.Scale == 0 then self.Scale = 1 end
    self.Particles = {}
    
    local is_appear = data:GetFlags() == 1
    local burst_mat = is_appear and Material("particle/warp1_warp.vmt") or Material("particle/warp2_warp.vmt")
    
    -- Correctly unpack RGB using bitwise operations
    local colorVal = data:GetColor()
    local c1, c2, fadeColor
    if isnumber(colorVal) and colorVal > 0 then
        local r = bit.band( colorVal, 0xFF )
        local g = bit.band( bit.rshift( colorVal, 8 ), 0xFF )
        local b = bit.band( bit.rshift( colorVal, 16 ), 0xFF )
        c1 = Color(r, g, b, 255)
        c2 = Color(math.Clamp(r * 0.7, 0, 255), math.Clamp(g * 0.7, 0, 255), math.Clamp(b * 0.7, 0, 255), 255)
        fadeColor = Color(math.Clamp(r * 0.3, 0, 255), math.Clamp(g * 0.3, 0, 255), math.Clamp(b * 0.3, 0, 255), 255)
    else
        c1 = Color(0, 114, 255, 255)
        c2 = Color(95, 53, 233, 255)
        fadeColor = Color(0, 56, 107, 255)
    end

    self.Configs = {
        {
            Name = "Warp Burst",
            Material = burst_mat,
            EmitCount = 25,
            LifetimeMin = 1.5, LifetimeMax = 1.5,
            RadiusMin = 2, RadiusMax = 20,
            Color1 = c1, Color2 = c2,
            SpawnDistMax = 3,
            VelocityNoise = 25,
            Drag = 0.1,
            RadiusScaleStart = 0.5, RadiusScaleEnd = 3.0,
            AlphaFadeOut = 1.0,
            AnimRate = 1.3,
            DynamicTint = true
        },
        {
            Name = "Swirl Trails",
            Material = Material("effects/portal_cleanser.vmt"),
            EmitCount = 40,
            LifetimeMin = 1, LifetimeMax = 3,
            RadiusMin = 1, RadiusMax = 3,
            Color1 = c1, Color2 = c2,
            SpawnDistMin = 40, SpawnDistMax = 60,
            VelocityNoise = 125,
            Drag = 0.08,
            RadiusScaleStart = 1.0, RadiusScaleEnd = 0.0,
            AlphaFadeIn = 0.25, AlphaFadeOut = 0.125,
            PullForce = 15000, PullFalloff = 0.45,
            OscillateFreq = Vector(4,4,4), OscillateMinFreq = Vector(1,1,1),
            OscillateRate = Vector(7,7,7), OscillateMinRate = Vector(-1,-1,-1),
            ColorFade = fadeColor, ColorFadeStart = 0, ColorFadeEnd = 0.5,
            AnimRate = 1.3
        },
        {
            Name = "Attach Ring",
            Material = Material("effects/select_ring"),
            EmitCount = 2,
            LifetimeMin = 0.6, LifetimeMax = 1.0,
            RadiusMin = 5, RadiusMax = 15,
            Color1 = c1, Color2 = c2,
            SpawnDistMax = 5, SpawnBias = Vector(1,1,3),
            RadiusScaleStart = 0.1, RadiusScaleEnd = 25.0,
            AlphaFadeOut = 1.0,
            Drag = 0.1,
            AnimRate = 1.3
        },
        {
            Name = "Attach Flash",
            Material = Material("effects/fluttercore_gmod"),
            EmitCount = 3,
            LifetimeMin = 0.15, LifetimeMax = 0.3,
            RadiusMin = 5, RadiusMax = 10,
            Color1 = c1, Color2 = c2,
            SpawnDistMax = 5, SpawnBias = Vector(1,1,3),
            RadiusScaleStart = 0.5, RadiusScaleEnd = 15.0,
            AlphaFadeOut = 0.3,
            ColorFade = fadeColor, ColorFadeStart = 0, ColorFadeEnd = 0.5,
            AnimRate = 1.3
        },
    }
    
    for _, cfg in ipairs(self.Configs) do
        if cfg.EmitCount then
            for _ = 1, cfg.EmitCount do
                table.insert(self.Particles, CParticle:Create(self.EmitPos, cfg, self.Scale))
            end
        end
    end
end

function EFFECT:Think()
    local dt = FrameTime()
    local idx = 0
    for i = 1, #self.Particles do
        local p = self.Particles[i]
        if p:Update(dt) then
            idx = idx + 1
            self.Particles[idx] = p
        end
    end
    for i = idx + 1, #self.Particles do self.Particles[i] = nil end
    
    return #self.Particles > 0
end

function EFFECT:Render()
    local eyePos = EyePos()
    table.sort(self.Particles, function(a, b)
        return a.pos:DistToSqr(eyePos) > b.pos:DistToSqr(eyePos)
    end)

    for _, p in ipairs(self.Particles) do
        if p.radius > 0.1 and p.color.a > 0 then
            local mat = p.material
            local numFrames = mat:GetInt("$numframes") or 0
            if numFrames > 1 then
                local frame = math.floor((CurTime() * p.anim_rate + p.anim_offset) % numFrames)
                mat:SetInt("$frame", frame)
            end
            
            render.SetColorModulation(p.color.r / 255, p.color.g / 255, p.color.b / 255)
            render.SetBlend(p.color.a / 255)
            render.SetMaterial(mat)
            render.DrawSprite(p.pos, p.radius, p.radius, p.color)
        end
    end

    -- Reset render states to prevent bleeding
    render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
end