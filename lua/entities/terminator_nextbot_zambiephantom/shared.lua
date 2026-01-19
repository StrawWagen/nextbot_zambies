AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Phantom"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambiephantom", {
    Name = "Zombie Phantom",
    Class = "terminator_nextbot_zambiephantom",
    Category = "Nextbot Zambies",
} )

ENT.PhantomColor = Color( 70, 140, 80 )
ENT.PhantomParticleColor = Vector( 70, 140, 80 )
ENT.PhantomAlpha = 130

if CLIENT then
    language.Add( "terminator_nextbot_zambiephantom", ENT.PrintName )

    local materialCreated = false

    function ENT:AdditionalClientInitialize()
        if not materialCreated then
            materialCreated = true
            CreateMaterial( "nextbotZambies_PhantomFlesh", "VertexLitGeneric", {
                ["$basetexture"] = "models/magnusson_teleporter/magnusson_teleporter_fxglow1",
                ["$model"] = 1,
                ["$translucent"] = 1,
                ["$vertexalpha"] = 1,
                ["$vertexcolor"] = 1,
            } )
        end

        self:SetRenderMode( RENDERMODE_TRANSCOLOR )
        self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        self:SetSubMaterial( 0, "!nextbotZambies_PhantomFlesh" )
        self:SetSubMaterial( 1, "!nextbotZambies_PhantomFlesh" )
        self:DrawShadow( false )

        self.NextAmbientParticle = 0
    end

    function ENT:Think()
        local curTime = CurTime()
        if curTime < self.NextAmbientParticle then return end
        self.NextAmbientParticle = curTime + 0.08

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -18, 18 ), math.Rand( -18, 18 ), math.Rand( 5, 55 ) ) )
        effectData:SetStart( self.PhantomParticleColor )
        effectData:SetScale( 0.9 )
        util.Effect( "terminator_phantomambient", effectData )
    end

    return
end

ENT.SpawnHealth = 180
ENT.WalkSpeed = 160
ENT.MoveSpeed = 400
ENT.RunSpeed = 520
ENT.AccelerationSpeed = 700

ENT.FistDamageMul = 0.55
ENT.MyPhysicsMass = 50

ENT.TERM_MODELSCALE = 1.15
ENT.FistRangeMul = 1.15

ENT.PhaseChance = 0.50
ENT.PhaseCooldown = 0.45
ENT.PhaseInvulnTime = 0.25
ENT.ConsecutivePhasePenalty = 0.08

ENT.TeleportDistance = 200
ENT.TeleportCooldown = 3
ENT.TeleportChance = 0.30
ENT.TeleportInvulnTime = 0.35

ENT.ParticleInterval = 0.07
ENT.PhaseSound = "ambient/levels/citadel/weapon_disintegrate2.wav"

ENT.DeathExplosionMagnitude = 100

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self:PhantomOnCreated( data )
    end,

    Think = function( self, data )
        self:PhantomThink( data )
    end,

    OnDamaged = function( self, data, dmg )
        return self:PhantomOnDamaged( data, dmg )
    end,

    PreventBecomeRagdollOnKilled = function( self, data )
        self:PhantomDie()
        SafeRemoveEntityDelayed( self, 0 )
        return true, true
    end,
}

function ENT:PhantomOnCreated( data )
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
    self:DrawShadow( false )

    data.nextParticle = 0
    data.nextPhase = 0
    data.consecutivePhases = 0
    data.lastPhaseReset = 0
    data.invulnUntil = 0
    data.nextTeleport = 0
end

function ENT:PhantomThink( data )
    local curTime = CurTime()

    if curTime - data.lastPhaseReset > 2 then
        data.consecutivePhases = math.max( 0, data.consecutivePhases - 1 )
        data.lastPhaseReset = curTime
    end

    if curTime < data.nextParticle then return end
    data.nextParticle = curTime + self.ParticleInterval

    local effectData = EffectData()
    effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -18, 18 ), math.Rand( -18, 18 ), math.Rand( 10, 55 ) ) )
    effectData:SetStart( self:GetPhantomParticleColor() )
    effectData:SetScale( 0.9 )
    effectData:SetMagnitude( 3 )
    util.Effect( "terminator_phantomdust", effectData )
end

function ENT:PhantomOnDamaged( data, dmg )
    local curTime = CurTime()

    if curTime < data.invulnUntil then
        return true
    end

    if curTime > data.nextTeleport and math.random() < self.TeleportChance then
        data.nextTeleport = curTime + self.TeleportCooldown
        self:PerformTeleport( data, dmg )
        return true
    end

    if curTime < data.nextPhase then return end

    local damageType = dmg:GetDamageType()
    local phaseChance = self.PhaseChance - ( data.consecutivePhases * self.ConsecutivePhasePenalty )

    if bit.band( damageType, DMG_BULLET ) ~= 0 then
        phaseChance = phaseChance + 0.15
    elseif bit.band( damageType, DMG_BLAST ) ~= 0 then
        phaseChance = phaseChance - 0.1
    elseif bit.band( damageType, DMG_CLUB + DMG_SLASH ) ~= 0 then
        phaseChance = phaseChance + 0.1
    end

    if self:Health() < self:GetMaxHealth() * 0.4 then
        phaseChance = phaseChance + 0.15
    end

    if math.random() >= math.Clamp( phaseChance, 0.15, 0.75 ) then return end

    self:PerformPhase( data )
    return true
end

function ENT:GetPhantomParticleColor()
    return self.PhantomParticleColor
end

function ENT:GetPhantomColor()
    return self.PhantomColor
end

function ENT:GetPhantomAlpha()
    return self.PhantomAlpha
end

function ENT:PhantomDie()
    local pos = self:WorldSpaceCenter()
    local particleColor = self:GetPhantomParticleColor()

    local effectData = EffectData()
    effectData:SetOrigin( pos )
    effectData:SetStart( particleColor )
    effectData:SetScale( 3.5 )
    effectData:SetMagnitude( 30 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( particleColor )
    smokeData:SetScale( 1.6 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    self:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav", 70, 130, 0.8 )

    self:CreatePhantomExplosion( pos, self.DeathExplosionMagnitude )
end

function ENT:CreatePhantomExplosion( pos, magnitude )
    local explosion = ents.Create( "env_physexplosion" )
    if IsValid( explosion ) then
        explosion:SetPos( pos )
        explosion:SetKeyValue( "magnitude", magnitude )
        explosion:SetKeyValue( "radius", magnitude * 2 )
        explosion:SetKeyValue( "spawnflags", "1" )
        explosion:Spawn()
        explosion:Fire( "Explode", "", 0 )
        explosion:Fire( "Kill", "", 0.1 )
    end
end

function ENT:PerformPhase( data )
    local curTime = CurTime()

    data.nextPhase = curTime + self.PhaseCooldown
    data.consecutivePhases = data.consecutivePhases + 1
    data.lastPhaseReset = curTime
    data.invulnUntil = curTime + self.PhaseInvulnTime

    local effectData = EffectData()
    effectData:SetOrigin( self:WorldSpaceCenter() )
    effectData:SetStart( self:GetPhantomParticleColor() )
    effectData:SetScale( 1.5 )
    effectData:SetMagnitude( 12 )
    util.Effect( "terminator_phantomdust", effectData )

    self:SetColor( ColorAlpha( self:GetPhantomColor(), 30 ) )

    local restoreAlpha = self:GetPhantomAlpha()
    local restoreColor = self:GetPhantomColor()

    timer.Simple( self.PhaseInvulnTime, function()
        if IsValid( self ) then
            self:SetColor( ColorAlpha( restoreColor, restoreAlpha ) )
        end
    end )

    self:EmitSound( self.PhaseSound, 60, math.random( 150, 170 ), 0.6 )
end

function ENT:PerformTeleport( data, dmg )
    local startPos = self:GetPos()
    local attacker = dmg:GetAttacker()
    local teleportDir

    if IsValid( attacker ) then
        local toAttacker = ( attacker:GetPos() - startPos )
        toAttacker.z = 0
        toAttacker:Normalize()

        local rightVec = toAttacker:Cross( Vector( 0, 0, 1 ) )

        local directions = {
            rightVec,
            -rightVec,
            -toAttacker,
            ( -toAttacker + rightVec ):GetNormalized(),
            ( -toAttacker - rightVec ):GetNormalized(),
        }

        for i = #directions, 2, -1 do
            local j = math.random( i )
            directions[i], directions[j] = directions[j], directions[i]
        end

        for _, dir in ipairs( directions ) do
            local trace = util.TraceHull( {
                start = startPos,
                endpos = startPos + dir * self.TeleportDistance,
                filter = self,
                mins = self:OBBMins(),
                maxs = self:OBBMaxs(),
                mask = MASK_NPCSOLID,
            } )
            if not trace.StartSolid and trace.Fraction > 0.5 then
                teleportDir = dir
                break
            end
        end

        teleportDir = teleportDir or -toAttacker
    else
        teleportDir = VectorRand()
        teleportDir.z = 0
        teleportDir:Normalize()
    end

    local trace = util.TraceHull( {
        start = startPos,
        endpos = startPos + teleportDir * self.TeleportDistance,
        filter = self,
        mins = self:OBBMins(),
        maxs = self:OBBMaxs(),
        mask = MASK_NPCSOLID,
    } )

    if trace.StartSolid then return end

    local teleportPos = trace.HitPos
    local particleColor = self:GetPhantomParticleColor()
    local effectHeight = self:OBBMaxs().z * 0.6

    local effectData = EffectData()
    effectData:SetOrigin( startPos + Vector( 0, 0, effectHeight ) )
    effectData:SetStart( particleColor )
    effectData:SetScale( 1.2 )
    util.Effect( "terminator_phantomsmoke", effectData )

    self:EmitSound( "ambient/machines/teleport3.wav", 70, 130, 0.8 )

    data.invulnUntil = CurTime() + self.TeleportInvulnTime

    self:SetPosNoTeleport( teleportPos )

    local effectDataEnd = EffectData()
    effectDataEnd:SetOrigin( teleportPos + Vector( 0, 0, effectHeight ) )
    effectDataEnd:SetStart( particleColor )
    effectDataEnd:SetScale( 1.2 )
    util.Effect( "terminator_phantomsmoke", effectDataEnd )

    self:EmitSound( "ambient/machines/teleport4.wav", 70, 130, 0.8 )

    self:CreatePhantomExplosion( startPos, 40 )
end