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

ENT.PhantomColor = Color( 65, 70, 80 )
ENT.PhantomParticleColor = Vector( 65, 70, 80 )
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
        if self:IsDormant() then return end

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

ENT.SpawnHealth = 150
ENT.WalkSpeed = 160
ENT.MoveSpeed = 450
ENT.RunSpeed = 600
ENT.AccelerationSpeed = 700

ENT.FistDamageMul = 0.55
ENT.MyPhysicsMass = 50

ENT.TERM_MODELSCALE = 1.05
ENT.CollisionBounds = { Vector( -12, -12, 0 ), Vector( 12, 12, 55 ) } -- this is then scaled by modelscale
ENT.FistRangeMul = 1.15

ENT.MaxTeleportDistance = 400
ENT.MinTeleportDistance = 100
ENT.TeleportCooldown = 1
ENT.TeleportChance = 0.5

ENT.ParticleInterval = 0.07

ENT.DeathExplosionMagnitude = 300
ENT.PhatntomThrowMul = 1

ENT.term_SoundPitchShift = -10

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self:SetSubMaterial( 0, "!nextbotZambies_PhantomFlesh" )
        self:SetSubMaterial( 1, "!nextbotZambies_PhantomFlesh" )
        self:PhantomOnCreated( data )

    end,

    Think = function( self, data )
        self:PhantomThink( data )

    end,

    OnDamaged = function( self, data, dmg )
        if not self:IsReallyAngry() then
            self:TakeAction( "AngeringCall" )

        end
        return self:PhantomOnDamaged( data, dmg )

    end,

    PreventBecomeRagdollOnKilled = function( self, data )
        self:PhantomDie()
        SafeRemoveEntityDelayed( self, 0 )
        return true, true

    end,

    ZambAngeringCall = function( self, data )
        self:TakeAction( "ThrowNearbyProp" )

    end,
}

ENT.MySpecialActions = {
    ["ThrowNearbyProp"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Throw Prop",
        desc = "Catapult a nearby prop at your enemy.",
        ratelimit = 2, -- seconds between uses
        svAction = function( _drive, _driver, bot )
            local enemy = bot:GetEnemy()
            local at
            if IsValid( enemy ) then
                at = enemy

            else
                at = bot:GetEyeTrace().HitPos

            end
            bot:PhantomCatapultDisrespectorAt( at )

        end,
    },
}

function ENT:PhantomOnCreated( data )
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
    self:DrawShadow( false )

    data.nextParticle = 0
    data.nextTeleport = 0

end

function ENT:PhantomThink( data )
    local curTime = CurTime()

    if curTime < data.nextParticle then
        data.nextParticle = curTime + self.ParticleInterval
        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -18, 18 ), math.Rand( -18, 18 ), math.Rand( 10, 55 ) ) )
        effectData:SetStart( self:GetPhantomParticleColor() )
        effectData:SetScale( 0.9 )
        effectData:SetMagnitude( 3 )
        util.Effect( "terminator_phantomdust", effectData )

    end

    self:PushingThink()

    local wantPush = self.NothingOrBreakableBetweenEnemy or ( self:IsReallyAngry() and math.random() < 0.05 )
    if not wantPush then return end

    local disrespector = self:GetCachedDisrespector()
    if not IsValid( disrespector ) then return end

    if disrespector.Disposition then
        local myDispToThem = self:Disposition( disrespector )
        if myDispToThem == D_LI or myDispToThem == D_NU then return end

    end

    -- dont get stuck trying to push unpushable props
    local nextPush = disrespector.zamb_NextPushTime or 0
    if CurTime() < nextPush then return end
    disrespector.zamb_NextPushTime = CurTime() + math.Rand( 4, 12 )

    if self:CanTakeAction( "ThrowNearbyProp" ) then
        self:TakeAction( "ThrowNearbyProp" )

    end
end

function ENT:PushingThink()
    local nextPush = self.zamb_nextAmbientPush or 0
    if CurTime() < nextPush then return end
    self.zamb_nextAmbientPush = CurTime() + math.Rand( 0.05, 0.1 )

    local disrespector = self:GetCachedDisrespector()
    if not IsValid( disrespector ) then return end

    local disrespectorsPhys = disrespector:GetPhysicsObject()
    if not IsValid( disrespectorsPhys ) then return end

    local myPos = self:WorldSpaceCenter()

    local nearestToMe = disrespector:NearestPoint( myPos )
    if nearestToMe:Distance( myPos ) > 100 then return end

    local toDisrespector = terminator_Extras.dirToPos( self:GetShootPos(), disrespector:WorldSpaceCenter() )
    local force = toDisrespector * 10000 * self.PhatntomThrowMul
    disrespectorsPhys:ApplyForceOffset( force, self:GetShootPos() )

    local effectData = EffectData()
    effectData:SetOrigin( disrespector:NearestPoint( myPos ) )
    effectData:SetStart( self.PhantomParticleColor )
    effectData:SetScale( 0.9 )
    util.Effect( "terminator_phantomambient", effectData )

end

function ENT:PhantomCatapultDisrespectorAt( at )
    local disrespector = self:GetCachedDisrespector()
    if not IsValid( disrespector ) then return end
    if disrespector:IsPlayer() or disrespector:IsNPC() or disrespector:IsNextBot() then return end

    local atFallback
    if IsValid( at ) then
        atFallback = at:WorldSpaceCenter()

    else
        atFallback = at

    end

    self:StopMoving()
    self:ZAMB_NormalCall()

    local levitatePos = disrespector:WorldSpaceCenter() + Vector( 0, 0, 45 )
    local levitateTimerName = "ZAMB_Phantom_LevitateDisrespector_" .. disrespector:GetCreationID()

    disrespector.zamb_beingThrown = true
    disrespector:EmitSound( "npc/advisor/advisor_blast1.wav", 75, math.random( 130, 140 ), 1, CHAN_STATIC )

    self:CreatePhantomExplosion( self:WorldSpaceCenter(), 150 )

    timer.Create( levitateTimerName, 0.05, 0, function()
        if not IsValid( self ) then timer.Remove( levitateTimerName ) return end
        if not IsValid( disrespector ) then timer.Remove( levitateTimerName ) return end
        if not disrespector.zamb_beingThrown then timer.Remove( levitateTimerName ) return end

        local disrespectorsPhys = disrespector:GetPhysicsObject()
        if not IsValid( disrespectorsPhys ) then timer.Remove( levitateTimerName ) return end

        local toLevitateDir = levitatePos - disrespectorsPhys:GetMassCenter()
        toLevitateDir:Normalize()

        local force = toLevitateDir * disrespectorsPhys:GetMass()
        disrespectorsPhys:ApplyForceCenter( force )

    end )

    timer.Simple( 0.75, function()
        if not IsValid( disrespector ) then return end
        disrespector.zamb_beingThrown = false

        if not IsValid( self ) then return end

        if disrespector:IsPlayerHolding() then
            disrespector:ForcePlayerDrop()

        end

        local disrespectorsPhys = disrespector:GetPhysicsObject()
        if not IsValid( disrespectorsPhys ) then return end
        if not disrespectorsPhys:IsMotionEnabled() then return end
        if not disrespectorsPhys:IsMoveable() then return end

        local pos
        if IsValid( at ) then
            pos = at:WorldSpaceCenter()

        elseif isvector( at ) then
            pos = at

        else
            pos = atFallback

        end

        local toEnemy = terminator_Extras.dirToPos( disrespector:WorldSpaceCenter(), pos )
        local force = toEnemy * 350000
        if self.isEnraged then
            force = force * 2

        end

        force = force * self.PhatntomThrowMul

        disrespectorsPhys:ApplyForceCenter( force )
        disrespector:EmitSound( "npc/advisor/advisor_blast6.wav", 75, math.random( 120, 110 ), 1, CHAN_STATIC )

        for _ = 1, 5 do
            local effectData = EffectData()
            local offset = VectorRand() * 5000
            local randomPosOnDisrespector = disrespector:NearestPoint( disrespector:LocalToWorld( offset ) )
            effectData:SetOrigin( randomPosOnDisrespector )
            effectData:SetStart( self.PhantomParticleColor )
            effectData:SetScale( 1.5 )
            util.Effect( "terminator_phantomambient", effectData )

        end
    end )
end

function ENT:PhantomOnDamaged( data, dmg )
    local curTime = CurTime()

    local teleport = curTime > data.nextTeleport and math.random() < self.TeleportChance

    if dmg:GetDamage() >= self:GetMaxHealth() * 0.5 and not data.oneFreebie then
        data.oneFreebie = true
        teleport = true
        dmg:ScaleDamage( 0.1 )

    end

    if teleport then
        data.nextTeleport = curTime + self.TeleportCooldown
        self:PerformTeleport( data, dmg )
        return true

    end
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
    if not IsValid( explosion ) then return end
    explosion:SetPos( pos )
    explosion:SetKeyValue( "magnitude", magnitude )
    explosion:SetKeyValue( "radius", magnitude * 2 )
    explosion:SetKeyValue( "spawnflags", "1" )
    explosion:Spawn()
    explosion:Fire( "Explode", "", 0 )
    explosion:Fire( "Kill", "", 0.1 )

end

function ENT:PerformTeleport( data, dmg )
    local startPos = self:GetPos()
    local attacker = dmg:GetAttacker()
    local attackersPos
    local teleportDir
    local tpDirections
    local teleportTrace

    if IsValid( attacker ) then
        attackersPos = attacker:GetPos()
        local toAttacker = ( attackersPos - startPos )
        toAttacker.z = 0
        toAttacker:Normalize()

        local rightVec = toAttacker:Cross( Vector( 0, 0, 1 ) )

        tpDirections = {
            rightVec,
            -rightVec,
            toAttacker,
            ( toAttacker + rightVec ):GetNormalized(),
            ( toAttacker - rightVec ):GetNormalized(),
        }

        -- shuffle dirs
        for i = #tpDirections, 2, -1 do
            local j = math.random( i )
            tpDirections[i], tpDirections[j] = tpDirections[j], tpDirections[i]
        end

    else
        local randDir = VectorRand()
        randDir.z = 0
        randDir:Normalize()
        tpDirections = { randDir }

    end

    for _, dir in ipairs( tpDirections ) do
        local dist = math.random( self.MinTeleportDistance, self.MaxTeleportDistance )
        local trace = util.TraceHull( {
            start = startPos,
            endpos = startPos + dir * dist,
            filter = self,
            mins = self:OBBMins(),
            maxs = self:OBBMaxs(),
            mask = MASK_NPCSOLID,
        } )
        if not trace.StartSolid and trace.Fraction > 0.5 then
            teleportDir = dir
            teleportTrace = trace
            break

        end
    end

    if not teleportDir then
        self:TakeAction( "AngeringCall" )
        return

    end

    local teleportPos = teleportTrace.HitPos
    local particleColor = self:GetPhantomParticleColor()
    local effectHeight = self:OBBMaxs().z * 0.6

    local effectData = EffectData()
    effectData:SetOrigin( startPos + Vector( 0, 0, effectHeight ) )
    effectData:SetStart( particleColor )
    effectData:SetScale( 1.2 )
    util.Effect( "terminator_phantomsmoke", effectData )

    local effectDataEnd = EffectData()
    effectDataEnd:SetOrigin( teleportPos + Vector( 0, 0, effectHeight ) )
    effectDataEnd:SetStart( particleColor )
    effectDataEnd:SetScale( 1.2 )
    util.Effect( "terminator_phantomsmoke", effectDataEnd )

    local pitch = math.random( 80, 90 )
    self:EmitSound( "ambient/levels/citadel/stalk_stalkertrainxtrabump02.wav", 90, pitch, 1, CHAN_STATIC )

    pitch = math.random( 90, 110 )
    self:EmitSound( "ambient/levels/citadel/weapon_disintegrate" .. math.random( 3, 4 ) .. ".wav", 90, pitch, 0.8, CHAN_STATIC )

    self:SetNoDraw( true )
    timer.Simple( 0.1, function()
        if not IsValid( self ) then return end
        self:SetNoDraw( false )

    end )

    timer.Simple( 0, function()
        self:SetPosNoTeleport( teleportPos )

    end )

    local myHealth = self:Health()
    local myMaxHp = self:GetMaxHealth()
    if myHealth > myMaxHp * 0.95 then
        if not data.angeringCalledAfterTeleport then
            data.angeringCalledAfterTeleport = true
            self:ZAMB_AngeringCall()

        else
            self:ZAMB_NormalCall()

        end
        self:StopMoving()

    elseif attackersPos and myHealth < myMaxHp * 0.5 then
        timer.Simple( 0.2, function()
            if not IsValid( self ) then return end
            self:JumpToPos( attackersPos )

        end )
    end

    self:CreatePhantomExplosion( startPos, 40 )

end

