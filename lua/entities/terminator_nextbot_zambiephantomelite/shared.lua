AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiephantom"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Phantom Elite"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambiephantomelite", {
    Name = "Zombie Phantom Elite",
    Class = "terminator_nextbot_zambiephantomelite",
    Category = "Nextbot Zambies",
} )

ENT.PhantomColor = Color( 50, 110, 65 )
ENT.PhantomParticleColor = Vector( 50, 110, 65 )
ENT.PhantomAlpha = 120

if CLIENT then
    language.Add( "terminator_nextbot_zambiephantomelite", ENT.PrintName )

    local materialCreated = false

    function ENT:AdditionalClientInitialize()
        if not materialCreated then
            materialCreated = true
            CreateMaterial( "nextbotZambies_PhantomEliteFlesh", "VertexLitGeneric", {
                ["$basetexture"] = "models/magnusson_teleporter/magnusson_teleporter_fxglow1",
                ["$model"] = 1,
                ["$translucent"] = 1,
                ["$vertexalpha"] = 1,
                ["$vertexcolor"] = 1,
            } )
        end

        self:SetRenderMode( RENDERMODE_TRANSCOLOR )
        self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        self:SetSubMaterial( 0, "!nextbotZambies_PhantomEliteFlesh" )
        self:SetSubMaterial( 1, "!nextbotZambies_PhantomEliteFlesh" )
        self:DrawShadow( false )

        self.NextAmbientParticle = 0
    end

    function ENT:Think()
        local curTime = CurTime()
        if curTime < self.NextAmbientParticle then return end
        self.NextAmbientParticle = curTime + 0.07

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( 5, 60 ) ) )
        effectData:SetStart( self.PhantomParticleColor )
        effectData:SetScale( 1 )
        util.Effect( "terminator_phantomambient", effectData )
    end

    return
end

ENT.SpawnHealth = 250
ENT.WalkSpeed = 180
ENT.MoveSpeed = 450
ENT.RunSpeed = 580
ENT.AccelerationSpeed = 750

ENT.FistDamageMul = 0.7
ENT.MyPhysicsMass = 55

ENT.TERM_MODELSCALE = 1.15

ENT.PhaseChance = 0.65
ENT.PhaseCooldown = 0.35
ENT.PhaseInvulnTime = 0.3
ENT.ConsecutivePhasePenalty = 0.06
ENT.ParticleInterval = 0.06

ENT.TeleportDistance = 250
ENT.TeleportCooldown = 2.5
ENT.TeleportChance = 0.45

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self:SetRenderMode( RENDERMODE_TRANSCOLOR )
        self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        self:DrawShadow( false )

        data.nextParticle = 0
        data.nextPhase = 0
        data.consecutivePhases = 0
        data.lastPhaseReset = 0
        data.invulnUntil = 0
        data.nextTeleport = 0
    end,

    Think = function( self, data )
        local curTime = CurTime()

        if curTime - data.lastPhaseReset > 2 then
            data.consecutivePhases = math.max( 0, data.consecutivePhases - 1 )
            data.lastPhaseReset = curTime
        end

        if curTime < data.nextParticle then return end
        data.nextParticle = curTime + self.ParticleInterval

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -20, 20 ), math.Rand( -20, 20 ), math.Rand( 10, 55 ) ) )
        effectData:SetStart( self.PhantomParticleColor )
        effectData:SetScale( 1 )
        effectData:SetMagnitude( 4 )
        util.Effect( "terminator_phantomdust", effectData )
    end,

    OnDamaged = function( self, data, dmg )
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

        if math.random() >= math.Clamp( phaseChance, 0.2, 0.85 ) then return end

        self:PerformPhase( data )
        return true
    end,

    PreventBecomeRagdollOnKilled = function( self, data )
        self:PhantomDie()
        SafeRemoveEntityDelayed( self, 0 )
        return true, true
    end,
}

function ENT:PhantomDie()
    local pos = self:WorldSpaceCenter()

    local effectData = EffectData()
    effectData:SetOrigin( pos )
    effectData:SetStart( self.PhantomParticleColor )
    effectData:SetScale( 4 )
    effectData:SetMagnitude( 35 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( self.PhantomParticleColor )
    smokeData:SetScale( 1.8 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    self:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav", 75, 120, 1 )
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

    local effectData = EffectData()
    effectData:SetOrigin( startPos + Vector( 0, 0, 40 ) )
    effectData:SetStart( self.PhantomParticleColor )
    effectData:SetScale( 1.3 )
    util.Effect( "terminator_phantomsmoke", effectData )

    self:EmitSound( "ambient/machines/teleport3.wav", 70, 130, 0.8 )

    data.invulnUntil = CurTime() + 0.4

    self:SetPos( teleportPos )

    local effectDataEnd = EffectData()
    effectDataEnd:SetOrigin( teleportPos + Vector( 0, 0, 40 ) )
    effectDataEnd:SetStart( self.PhantomParticleColor )
    effectDataEnd:SetScale( 1.3 )
    util.Effect( "terminator_phantomsmoke", effectDataEnd )

    self:EmitSound( "ambient/machines/teleport4.wav", 70, 130, 0.8 )
end