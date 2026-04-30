EFFECT.mat_fire = Material( "particle/smokesprites_0002" )
EFFECT.mat_beam = Material( "trails/plasma" )

EFFECT.RenderGroup = RENDERGROUP_TRANSLUCENT

-- ── Shared decal table ────────────────────────────────────────────────────────
local BLOOD_DECALS = {}
for i = 1, 9 do
    BLOOD_DECALS[i] = Material( "decals/blood" .. i )
end

-- ── Beam-ring helper (identical to the reference pattern) ─────────────────────
local function DrawBeamRing( center, normal, radius, width, color, segments )
    local tangent = normal:Cross( Vector( 0, 0, 1 ) )
    if tangent:LengthSqr() < 0.001 then
        tangent = normal:Cross( Vector( 0, 1, 0 ) )
    end
    tangent:Normalize()
    local bitangent = normal:Cross( tangent )
    bitangent:Normalize()

    render.StartBeam( segments + 1 )
    for i = 0, segments do
        local angle = ( i / segments ) * math.pi * 2
        local v = center
            + tangent   * ( math.cos( angle ) * radius )
            + bitangent * ( math.sin( angle ) * radius )
        render.AddBeam( v, width, i / segments, color )
    end
    render.EndBeam()
end

-- ── One-shot particle burst (called once from Init) ───────────────────────────
local function SpawnParticles( pos, radius, r, g, b, decalTable, decalCount, scale )

    -- Wet burst flash
    local emitterFlash = ParticleEmitter( pos )
    if emitterFlash then
        for i = 1, 2 do
            local p = emitterFlash:Add( "sprites/light_glow02_add", pos )
            if p then
                local dir = VectorRand(); dir:Normalize()
                p:SetVelocity( dir * math.Rand( 5, 15 ) )
                p:SetDieTime( math.Rand( 0.04, 0.09 ) )
                p:SetStartAlpha( 180 ); p:SetEndAlpha( 0 )
                p:SetStartSize( radius * math.Rand( 0.4, 0.6 ) * scale )
                p:SetEndSize(   radius * math.Rand( 0.7, 1.0 ) * scale )
                p:SetColor( r, g, b )
            end
        end
        emitterFlash:Finish()
    end

    -- Bile fireball
    local emitterFire = ParticleEmitter( pos )
    if emitterFire then
        for i = 1, math.floor( 26 * scale ) do
            local p = emitterFire:Add( "particle/fire", pos )
            if p then
                local dir = VectorRand(); dir:Normalize()
                p:SetVelocity( dir * math.Rand( 20, 90 ) * scale )
                p:SetDieTime( math.Rand( 0.25, 0.55 ) )
                p:SetStartAlpha( 255 ); p:SetEndAlpha( 0 )
                local sz = math.Rand( radius * 0.2, radius * 0.45 ) * scale
                p:SetStartSize( sz * 0.3 ); p:SetEndSize( sz )
                p:SetRoll( math.Rand( 0, 360 ) )
                p:SetRollDelta( math.Rand( -2, 2 ) )
                p:SetGravity( Vector( 0, 0, -40 ) )
                p:SetColor( r, g, b )
            end
        end
        emitterFire:Finish()
    end

    -- Gore chunks
    local emitterChunks = ParticleEmitter( pos )
    if emitterChunks then
        for i = 1, math.floor( 24 * scale ) do
            local p = emitterChunks:Add( "particle/fire", pos )
            if p then
                local dir = VectorRand(); dir:Normalize()
                p:SetVelocity( dir * math.Rand( 200, 620 ) * scale )
                p:SetDieTime( math.Rand( 0.4, 1.2 ) )
                p:SetStartAlpha( 255 ); p:SetEndAlpha( 0 )
                local sz = math.Rand( 4, 10 ) * scale
                p:SetStartSize( sz ); p:SetEndSize( sz * 0.1 )
                p:SetRoll( math.Rand( 0, 360 ) ); p:SetRollDelta( 0 )
                p:SetGravity( Vector( 0, 0, -900 ) )
                p:SetColor( r, g, b )
                p:SetCollide( true ); p:SetBounce( 0.1 )
            end
        end
        emitterChunks:Finish()
    end

    -- Bile drips
    local emitterDrips = ParticleEmitter( pos )
    if emitterDrips then
        for i = 1, math.floor( 28 * scale ) do
            local p = emitterDrips:Add( "sprites/light_glow02_add", pos )
            if p then
                local dir = VectorRand()
                dir.z = math.abs( dir.z ) * 1.2 + 0.3
                dir:Normalize()
                p:SetVelocity( dir * math.Rand( 120, 500 ) * scale )
                p:SetDieTime( math.Rand( 0.4, 1.1 ) )
                p:SetStartAlpha( 210 ); p:SetEndAlpha( 0 )
                p:SetStartSize( math.Rand( 3, 9 ) * scale ); p:SetEndSize( 0 )
                p:SetRoll( math.Rand( 0, 360 ) )
                p:SetGravity( Vector( 0, 0, -900 ) )
                p:SetColor( r, g, b )
                p:SetCollide( true ); p:SetBounce( 0.05 )
            end
        end
        emitterDrips:Finish()
    end

    -- Vapour wisps
    local emitterSmoke = ParticleEmitter( pos )
    if emitterSmoke then
        for i = 1, math.floor( 5 * scale ) do
            local p = emitterSmoke:Add( "particle/smokesprites_0001", pos )
            if p then
                local dir = VectorRand()
                dir.z = math.abs( dir.z ) + 0.5
                dir:Normalize()
                p:SetVelocity( dir * math.Rand( 30, 90 ) * scale )
                p:SetDieTime( math.Rand( 0.5, 1.2 ) )
                p:SetStartAlpha( 90 ); p:SetEndAlpha( 0 )
                local sz = math.Rand( radius * 0.08, radius * 0.18 ) * scale
                p:SetStartSize( sz ); p:SetEndSize( sz * 1.8 )
                p:SetRoll( math.Rand( 0, 360 ) )
                p:SetRollDelta( math.Rand( -1, 1 ) )
                p:SetGravity( Vector( 0, 0, 20 ) )
                p:SetColor( 25, 50, 25 )
                p:SetCollide( false )
            end
        end
        emitterSmoke:Finish()
    end

    -- Blood decals on nearby surfaces
    for i = 1, decalCount do
        local dir = VectorRand(); dir:Normalize()
        local tr = util.TraceLine({
            start  = pos,
            endpos = pos + dir * radius,
            mask   = MASK_SOLID_BRUSHONLY,
        })
        if tr.Hit then
            local mat = decalTable[ math.random( 1, #decalTable ) ]
            if mat and not mat:IsError() then
                util.DecalEx(
                    mat, tr.Entity, tr.HitPos, tr.HitNormal,
                    Color( r, g, b ),
                    math.Rand( 0.6, 1.6 ) * scale,
                    math.Rand( 0.6, 1.6 ) * scale
                )
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────

function EFFECT:Init( data )
    self.pos    = data:GetOrigin()
    self.radius = data:GetRadius()
    self.scale  = 1.0

    -- Three randomly-oriented ring normals for visual variety
    self.normal1 = VectorRand(); self.normal1:Normalize()
    self.normal2 = VectorRand(); self.normal2:Normalize()
    self.normal3 = VectorRand(); self.normal3:Normalize()

    -- Animation state
    self.t    = 0
    self.tout = math.Rand( 0.78, 0.96 )

    -- Pre-allocate color tables (avoids per-frame garbage)
    self.col_flash = Color( 255, 255, 255, 255 )
    self.col_ring1 = Color( 255, 255, 255, 255 )
    self.col_ring2 = Color( 255, 255, 255, 255 )
    self.col_ring3 = Color( 255, 255, 255, 255 )

    -- Burst particles immediately
    SpawnParticles( self.pos, self.radius, 40, 220, 50, BLOOD_DECALS, 12, self.scale )

    -- Screen shake
    util.ScreenShake( self.pos, 12 * self.scale, 9 * self.scale, 0.8, self.radius * 2.2 )

    -- Dynamic light (uses EntIndex so it is unique to this effect entity)
    local dl = DynamicLight( self:EntIndex() )
    if dl then
        dl.Pos        = self.pos
        dl.r          = 40
        dl.g          = 220
        dl.b          = 50
        dl.brightness = 3 * self.scale
        dl.decay      = 1400
        dl.size       = self.radius * 1.5 * self.scale
        dl.dietime    = CurTime() + 0.2
    end
end

function EFFECT:Think()
    if self.t < self.tout then
        self.t = math.min( self.tout, self.t + FrameTime() )
        return true
    end
    return false
end

function EFFECT:Render()
    local f      = self.t / self.tout           -- 0 → 1 over the effect lifetime
    local fEased = math.ease.OutQuart( f )      -- eased expansion, same as reference
    local scale  = self.scale
    local radius = self.radius
    local pos    = self.pos

    render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        -- ── Central bile-burst sprite (fades out very fast, first quarter) ────
        local a_flash = math.max( 0, 1 - f * 4 )
        if a_flash > 0 then
            local a3 = a_flash * a_flash * a_flash
            self.col_flash.r = math.Round( 80  * a_flash )
            self.col_flash.g = math.Round( 255 * a_flash )
            self.col_flash.b = math.Round( 60  * a3 )
            self.col_flash.a = 255
            render.SetMaterial( self.mat_fire )
            local e_flash = math.max( 0, 1 - f * 3 )
            local spr = radius * e_flash * 2 * scale
            render.DrawSprite( pos, spr, spr, self.col_flash )
        end

        render.SetMaterial( self.mat_beam )

        -- ── Ring 1 — inner, tight, fast fade ─────────────────────────────────
        local a1  = math.max( 0, 1 - f ) ^ 2
        local rs1 = Lerp( fEased, radius * 0.4 * scale, radius * 1.8 * scale )
        self.col_ring1.r = math.Round( 80  * a1 )
        self.col_ring1.g = math.Round( 255 * a1 )
        self.col_ring1.b = math.Round( 60  * a1 * a1 )
        self.col_ring1.a = math.Round( 255 * a1 )
        DrawBeamRing( pos, self.normal1, rs1 / 2, 10 * a1 * scale, self.col_ring1, 32 )

        -- ── Ring 2 — mid, slightly slower ────────────────────────────────────
        local a2  = math.max( 0, 1 - f * 1.4 ) ^ 2
        local rs2 = Lerp( fEased, radius * 0.6 * scale, radius * 2.4 * scale )
        self.col_ring2.r = math.Round( 60  * a2 )
        self.col_ring2.g = math.Round( 220 * a2 )
        self.col_ring2.b = math.Round( 50  * a2 * a2 )
        self.col_ring2.a = math.Round( 255 * a2 )
        DrawBeamRing( pos, self.normal2, rs2 / 2, 7 * a2 * scale, self.col_ring2, 32 )

        -- ── Ring 3 — outer, wide, slowest fade ───────────────────────────────
        local a3  = math.max( 0, 1 - f * 2 )
        local rs3 = Lerp( fEased, radius * 0.8 * scale, radius * 3.0 * scale )
        self.col_ring3.r = math.Round( 40  * a3 )
        self.col_ring3.g = math.Round( 180 * a3 )
        self.col_ring3.b = math.Round( 40  * a3 * a3 )
        self.col_ring3.a = math.Round( 255 * a3 )
        DrawBeamRing( pos, self.normal3, rs3 / 2, 5 * a3 * scale, self.col_ring3, 32 )

    render.OverrideBlend( false )
end