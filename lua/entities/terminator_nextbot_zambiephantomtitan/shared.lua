AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiephantomelite"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Phantom Titan"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambiephantomtitan", {
    Name = "Zombie Phantom Titan",
    Class = "terminator_nextbot_zambiephantomtitan",
    Category = "Nextbot Zambies",
} )

ENT.PhantomColor = Color( 65, 70, 80 )
ENT.PhantomParticleColor = Vector( 65, 70, 80 )
ENT.PhantomAlpha = 100

ENT.EnragedColor = Color( 120, 40, 40 )
ENT.EnragedParticleColor = Vector( 120, 40, 40 )
ENT.EnragedAlpha = 130

if CLIENT then
    language.Add( "terminator_nextbot_zambiephantomtitan", ENT.PrintName )

    local materialCreated = false

    function ENT:AdditionalClientInitialize()
        if not materialCreated then
            materialCreated = true
            CreateMaterial( "nextbotZambies_PhantomTitanFlesh", "VertexLitGeneric", {
                ["$basetexture"] = "models/magnusson_teleporter/magnusson_teleporter_fxglow1",
                ["$model"] = 1,
                ["$translucent"] = 1,
                ["$vertexalpha"] = 1,
                ["$vertexcolor"] = 1,
            } )
        end

        self:SetRenderMode( RENDERMODE_TRANSCOLOR )
        self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        self:SetSubMaterial( 0, "!nextbotZambies_PhantomTitanFlesh" )
        self:SetSubMaterial( 1, "!nextbotZambies_PhantomTitanFlesh" )
        self:DrawShadow( false )

        self.NextAmbientParticle = 0
        self.NextBoneJitter = 0
        self.BoneCount = self:GetBoneCount()
    end

    function ENT:Think()
        local curTime = CurTime()
        local isEnraged = self:GetNWBool( "PhantomEnraged", false )

        if isEnraged then
            if curTime >= self.NextBoneJitter then
                self.NextBoneJitter = curTime + 0.05

                for i = 0, self.BoneCount - 1 do
                    self:ManipulateBoneAngles( i, Angle( math.Rand( -8, 8 ), math.Rand( -8, 8 ), math.Rand( -8, 8 ) ) )
                end
            end

            self:SetColor( ColorAlpha( self.EnragedColor, self.EnragedAlpha ) )
        else
            self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        end

        if curTime < self.NextAmbientParticle then return end
        self.NextAmbientParticle = curTime + 0.08

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -25, 25 ), math.Rand( -25, 25 ), math.Rand( 5, 80 ) ) )
        effectData:SetStart( isEnraged and self.EnragedParticleColor or self.PhantomParticleColor )
        effectData:SetScale( 1.2 )
        util.Effect( "terminator_phantomambient", effectData )
    end

    return
end

ENT.SpawnHealth = 1600
ENT.WalkSpeed = 140
ENT.MoveSpeed = 380
ENT.RunSpeed = 500
ENT.AccelerationSpeed = 650

ENT.EnragedSpeedMult = 2.5

ENT.FistDamageMul = 1.2
ENT.MyPhysicsMass = 150

ENT.TERM_MODELSCALE = 1.4

ENT.PhaseChance = 0.70
ENT.PhaseCooldown = 0.3
ENT.PhaseInvulnTime = 0.35
ENT.ConsecutivePhasePenalty = 0.05
ENT.ParticleInterval = 0.06

ENT.TeleportDistance = 300
ENT.TeleportCooldown = 1.5
ENT.TeleportChance = 0.50

ENT.EnrageThreshold = 0.3
ENT.TouchDamage = 35
ENT.TouchDamageCooldown = 0.4
ENT.TouchDamageRadius = 80

ENT.DeathBlastRadius = 500
ENT.DeathBlastForce = 800
ENT.DeathBlastDamage = 50

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self:SetRenderMode( RENDERMODE_TRANSCOLOR )
        self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        self:DrawShadow( false )
        self:SetNWBool( "PhantomEnraged", false )

        self.isEnraged = false
        self.baseWalkSpeed = self.WalkSpeed
        self.baseMoveSpeed = self.MoveSpeed
        self.baseRunSpeed = self.RunSpeed

        data.nextParticle = 0
        data.nextPhase = 0
        data.consecutivePhases = 0
        data.lastPhaseReset = 0
        data.invulnUntil = 0
        data.nextTeleport = 0
        data.touchDamageCooldowns = {}
    end,

    Think = function( self, data )
        local curTime = CurTime()

        if curTime - data.lastPhaseReset > 2 then
            data.consecutivePhases = math.max( 0, data.consecutivePhases - 1 )
            data.lastPhaseReset = curTime
        end

        if not self.isEnraged and self:Health() / self:GetMaxHealth() <= self.EnrageThreshold then
            self:BecomeEnraged()
        end

        if self.isEnraged then
            self:DoTouchDamage( data, curTime )
        end

        if curTime < data.nextParticle then return end
        data.nextParticle = curTime + self.ParticleInterval

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -25, 25 ), math.Rand( -25, 25 ), math.Rand( 10, 75 ) ) )
        effectData:SetStart( self.isEnraged and self.EnragedParticleColor or self.PhantomParticleColor )
        effectData:SetScale( 1.2 )
        effectData:SetMagnitude( 3 )
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

        if self.isEnraged then
            phaseChance = phaseChance + 0.15
        elseif self:Health() < self:GetMaxHealth() * 0.5 then
            phaseChance = phaseChance + 0.1
        end

        if math.random() >= math.Clamp( phaseChance, 0.25, 0.9 ) then return end

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
    local particleColor = self.isEnraged and self.EnragedParticleColor or self.PhantomParticleColor

    self:EmitSound( "ambient/explosions/explode_4.wav", 100, 70, 1 )
    self:EmitSound( "ambient/levels/labs/electric_explosion5.wav", 95, 50, 1 )
    self:EmitSound( "ambient/levels/citadel/strange_talk" .. math.random( 3, 11 ) .. ".wav", 90, 60, 1 )

    local effectData = EffectData()
    effectData:SetOrigin( pos )
    effectData:SetStart( particleColor )
    effectData:SetScale( 7 )
    effectData:SetMagnitude( 70 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( particleColor )
    smokeData:SetScale( 4 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    for i = 1, 32 do
        local ang = ( i / 32 ) * math.pi * 2
        local ringEffect = EffectData()
        ringEffect:SetOrigin( pos + Vector( math.cos( ang ), math.sin( ang ), 0 ) * self.DeathBlastRadius * 0.5 )
        ringEffect:SetStart( particleColor )
        ringEffect:SetScale( 2 )
        ringEffect:SetMagnitude( 6 )
        util.Effect( "terminator_phantomdust", ringEffect )
    end

    for _, ent in ipairs( ents.FindInSphere( pos, self.DeathBlastRadius ) ) do
        if ent == self then continue end

        local entPos = ent:GetPos()
        local pushDir = ( entPos - pos ):GetNormalized()
        pushDir.z = math.max( pushDir.z, 0.4 )

        local dist = entPos:Distance( pos )
        local forceMult = math.Clamp( 1 - ( dist / self.DeathBlastRadius ), 0.3, 1 )
        local force = pushDir * self.DeathBlastForce * forceMult

        if ent:IsPlayer() then
            ent:SetVelocity( force )
            ent:ScreenFade( SCREENFADE.IN, Color( particleColor.x, particleColor.y, particleColor.z, 150 ), 0.5, 0.2 )

            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage( self.DeathBlastDamage * forceMult )
            dmgInfo:SetDamageType( DMG_SONIC + DMG_BLAST )
            dmgInfo:SetAttacker( self )
            dmgInfo:SetInflictor( self )
            ent:TakeDamageInfo( dmgInfo )
        elseif ent:IsNPC() or ent:IsNextBot() then
            if ent.SetVelocity then
                ent:SetVelocity( force )
            end

            local disp = self:Disposition( ent )
            if disp == D_HT or disp == D_FR then
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage( self.DeathBlastDamage * forceMult )
                dmgInfo:SetDamageType( DMG_SONIC + DMG_BLAST )
                dmgInfo:SetAttacker( self )
                dmgInfo:SetInflictor( self )
                ent:TakeDamageInfo( dmgInfo )
            end
        else
            local phys = ent:GetPhysicsObject()
            if IsValid( phys ) then
                phys:ApplyForceCenter( force * phys:GetMass() * 0.5 )
            end
        end
    end
end

function ENT:PerformPhase( data )
    local curTime = CurTime()

    data.nextPhase = curTime + self.PhaseCooldown
    data.consecutivePhases = data.consecutivePhases + 1
    data.lastPhaseReset = curTime
    data.invulnUntil = curTime + self.PhaseInvulnTime

    local particleColor = self.isEnraged and self.EnragedParticleColor or self.PhantomParticleColor
    local oldColor = self.isEnraged and self.EnragedColor or self.PhantomColor
    local oldAlpha = self.isEnraged and self.EnragedAlpha or self.PhantomAlpha

    local effectData = EffectData()
    effectData:SetOrigin( self:WorldSpaceCenter() )
    effectData:SetStart( particleColor )
    effectData:SetScale( 2.5 )
    effectData:SetMagnitude( 18 )
    util.Effect( "terminator_phantomdust", effectData )

    self:SetColor( ColorAlpha( oldColor, 20 ) )

    timer.Simple( self.PhaseInvulnTime, function()
        if IsValid( self ) then
            self:SetColor( ColorAlpha( oldColor, oldAlpha ) )
        end
    end )

    self:EmitSound( self.PhaseSound, 75, math.random( 120, 140 ), 0.8 )
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
    local particleColor = self.isEnraged and self.EnragedParticleColor or self.PhantomParticleColor

    local effectData = EffectData()
    effectData:SetOrigin( startPos + Vector( 0, 0, 50 ) )
    effectData:SetStart( particleColor )
    effectData:SetScale( 2 )
    util.Effect( "terminator_phantomsmoke", effectData )

    self:EmitSound( "ambient/machines/teleport3.wav", 80, 100, 1 )

    data.invulnUntil = CurTime() + 0.5

    self:SetPos( teleportPos )

    local effectDataEnd = EffectData()
    effectDataEnd:SetOrigin( teleportPos + Vector( 0, 0, 50 ) )
    effectDataEnd:SetStart( particleColor )
    effectDataEnd:SetScale( 2 )
    util.Effect( "terminator_phantomsmoke", effectDataEnd )

    self:EmitSound( "ambient/machines/teleport4.wav", 80, 100, 1 )
end

function ENT:BecomeEnraged()
    self.isEnraged = true
    self:SetNWBool( "PhantomEnraged", true )

    self.WalkSpeed = self.baseWalkSpeed * self.EnragedSpeedMult
    self.MoveSpeed = self.baseMoveSpeed * self.EnragedSpeedMult
    self.RunSpeed = self.baseRunSpeed * self.EnragedSpeedMult

    self:SetColor( ColorAlpha( self.EnragedColor, self.EnragedAlpha ) )

    self:EmitSound( "ambient/levels/citadel/strange_talk" .. math.random( 3, 11 ) .. ".wav", 95, 40, 1 )
    self:EmitSound( "ambient/machines/teleport1.wav", 90, 60, 1 )

    local effectData = EffectData()
    effectData:SetOrigin( self:WorldSpaceCenter() )
    effectData:SetStart( self.EnragedParticleColor )
    effectData:SetScale( 4 )
    effectData:SetMagnitude( 30 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( self:WorldSpaceCenter() )
    smokeData:SetStart( self.EnragedParticleColor )
    smokeData:SetScale( 2 )
    util.Effect( "terminator_phantomsmoke", smokeData )
end

function ENT:DoTouchDamage( data, curTime )
    local pos = self:WorldSpaceCenter()

    for _, ent in ipairs( ents.FindInSphere( pos, self.TouchDamageRadius ) ) do
        if ent == self then continue end
        if not ent:IsPlayer() and not ent:IsNPC() and not ent:IsNextBot() then continue end

        local disp = self:Disposition( ent )
        if disp ~= D_HT and disp ~= D_FR then continue end

        local entIndex = ent:EntIndex()
        if data.touchDamageCooldowns[entIndex] and curTime < data.touchDamageCooldowns[entIndex] then continue end

        data.touchDamageCooldowns[entIndex] = curTime + self.TouchDamageCooldown

        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage( self.TouchDamage )
        dmgInfo:SetDamageType( DMG_BURN + DMG_DIRECT )
        dmgInfo:SetAttacker( self )
        dmgInfo:SetInflictor( self )
        ent:TakeDamageInfo( dmgInfo )

        local effectData = EffectData()
        effectData:SetOrigin( ent:WorldSpaceCenter() )
        effectData:SetStart( self.EnragedParticleColor )
        effectData:SetScale( 1 )
        effectData:SetMagnitude( 6 )
        util.Effect( "terminator_phantomdust", effectData )

        self:EmitSound( "ambient/energy/spark" .. math.random( 1, 6 ) .. ".wav", 65, math.random( 70, 90 ), 0.6 )
    end
end