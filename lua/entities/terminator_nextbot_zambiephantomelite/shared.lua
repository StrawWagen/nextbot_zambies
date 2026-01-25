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

ENT.PhantomColor = Color( 25, 30, 35 )
ENT.PhantomParticleColor = Vector( 25, 30, 35 )
ENT.PhantomAlpha = 110

ENT.EnragedColor = Color( 115, 40, 40 )
ENT.EnragedParticleColor = Vector( 115, 40, 40 )
ENT.EnragedAlpha = 140

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
        self.NextBoneJitter = 0
        self.BoneCount = self:GetBoneCount()
    end

    function ENT:Think()
        local curTime = CurTime()
        local isEnraged = self:GetNWBool( "PhantomEnraged", false )

        if isEnraged then
            if curTime >= self.NextBoneJitter then
                self.NextBoneJitter = curTime + math.Rand( 0.05, 0.1 )

                for i = 0, self.BoneCount - 1 do
                    self:ManipulateBoneAngles( i, Angle( math.Rand( -6, 6 ), math.Rand( -6, 6 ), math.Rand( -6, 6 ) ) )
                end
            end

            self:SetColor( ColorAlpha( self.EnragedColor, self.EnragedAlpha ) )
        else
            self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        end

        if curTime < self.NextAmbientParticle then return end
        self.NextAmbientParticle = curTime + 0.07

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -22, 22 ), math.Rand( -22, 22 ), math.Rand( 5, 70 ) ) )
        effectData:SetStart( isEnraged and self.EnragedParticleColor or self.PhantomParticleColor )
        effectData:SetScale( 1.1 )
        util.Effect( "terminator_phantomambient", effectData )
    end

    return
end

ENT.SpawnHealth = 2000
ENT.SpawnHealthPerPlayer = 500
ENT.WalkSpeed = 130
ENT.MoveSpeed = 500
ENT.RunSpeed = 800
ENT.AccelerationSpeed = 600

ENT.EnragedSpeedMult = 2

ENT.FistDamageMul = 0.85
ENT.FistForceMul = 100
ENT.MyPhysicsMass = 120

ENT.TERM_MODELSCALE = 1.35
ENT.CollisionBounds = { Vector( -11, -11, 0 ), Vector( 11, 11, 48 ) } -- this is then scaled by modelscale
ENT.FistRangeMul = 1.4

ENT.ParticleInterval = 0.06

ENT.MaxTeleportDistance = 500
ENT.MinTeleportDistance = 200
ENT.TeleportCooldown = 2
ENT.TeleportChance = 0.5
ENT.TeleportChanceEnraged = 0.9

ENT.EnrageThreshold = 0.45
ENT.TouchDamage = 20
ENT.TouchDamageCooldown = 0.5
ENT.TouchDamageRadius = 70

ENT.DeathBlastRadius = 400
ENT.DeathBlastForce = 600
ENT.DeathBlastDamage = 30
ENT.DeathExplosionMagnitude = 200

ENT.term_SoundPitchShift = 10

function ENT:PhantomOnCreated( data )
    BaseClass.PhantomOnCreated( self, data )

    self:SetNWBool( "PhantomEnraged", false )

    self.isEnraged = false
    self.baseWalkSpeed = self.WalkSpeed
    self.baseMoveSpeed = self.MoveSpeed
    self.baseRunSpeed = self.RunSpeed

    data.touchDamageCooldowns = {}

    self.IdleLoopingSounds = {
        "npc/advisor/advisor_speak01.wav",
    }
    self.AngryLoopingSounds = {
        "ambient/levels/advisor_barn/ol07_advisor_00_28_15.wav",
        "ambient/levels/advisor_barn/ol07_advisor_00_50_11.wav",
        "ambient/levels/advisor_barn/ol07_advisor_00_30_22.wav",
        "ambient/levels/advisor_barn/ol07_advisor_00_36_25.wav",
    }

    self.term_LoseEnemySound = "npc/advisor/advisor_speak01.wav"
    self.term_CallingSound = "npc/advisor/advisor_scream.wav"
    self.term_CallingSmallSound = "npc/stalker/stalker_scream2.wav"
    self.term_FindEnemySound = "ambient/outro/advisorattack03.wav"
    self.term_AttackSound = "ambient/levels/advisor_barn/ol07_advisor_00_50_11.wav"
    self.term_AngerSound = "ambient/levels/advisor_barn/ol07_advisor_00_48_16.wav"
    self.term_DamagedSound = {
        "npc/stalker/stalker_pain1.wav",
        "npc/stalker/stalker_pain2.wav",
        "npc/stalker/stalker_pain3.wav",
    }
    self.term_DieSound = ""
    self.term_JumpSound = "npc/zombie/foot1.wav"

    self.AlwaysPlayLooping = true
end

function ENT:PhantomThink( data )
    local curTime = CurTime()

    if not self.isEnraged and self:Health() / self:GetMaxHealth() <= self.EnrageThreshold then
        self:BecomeEnraged()
    end

    if self.isEnraged then
        self:DoTouchDamage( data, curTime )
    end

    if curTime < data.nextParticle then
        data.nextParticle = curTime + self.ParticleInterval

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -22, 22 ), math.Rand( -22, 22 ), math.Rand( 10, 65 ) ) )
        effectData:SetStart( self:GetPhantomParticleColor() )
        effectData:SetScale( 1.1 )
        effectData:SetMagnitude( 3 )
        util.Effect( "terminator_phantomdust", effectData )

    end

    self:PushingThink()

    local disrespector = self:GetCachedDisrespector()
    if not IsValid( disrespector ) then return end

    if self:CanTakeAction( "ThrowNearbyProp" ) then
        self:TakeAction( "ThrowNearbyProp" )

    end
end

function ENT:PhantomOnDamaged( data, dmg )
    local curTime = CurTime()

    local chance = self.isEnraged and self.TeleportChanceEnraged or self.TeleportChance
    local teleport = curTime > data.nextTeleport and math.random() < chance

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
    return self.isEnraged and self.EnragedParticleColor or self.PhantomParticleColor
end

function ENT:GetPhantomColor()
    return self.isEnraged and self.EnragedColor or self.PhantomColor
end

function ENT:GetPhantomAlpha()
    return self.isEnraged and self.EnragedAlpha or self.PhantomAlpha
end

function ENT:PhantomDie()
    local pos = self:WorldSpaceCenter()
    local particleColor = self:GetPhantomParticleColor()

    self:EmitSound( "npc/advisor/advisor_scream.wav", 95, math.random( 80, 90 ), 1, CHAN_STATIC )
    self:EmitSound( "ambient/levels/labs/electric_explosion5.wav", 90, 55, 1, CHAN_STATIC )
    self:EmitSound( "ambient/levels/citadel/strange_talk" .. math.random( 3, 11 ) .. ".wav", 95, 50, 1, CHAN_STATIC )

    local effectData = EffectData()
    effectData:SetOrigin( pos )
    effectData:SetStart( particleColor )
    effectData:SetScale( 5.5 )
    effectData:SetMagnitude( 55 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( particleColor )
    smokeData:SetScale( 3 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    for i = 1, 24 do
        local ang = ( i / 24 ) * math.pi * 2
        local ringEffect = EffectData()
        ringEffect:SetOrigin( pos + Vector( math.cos( ang ), math.sin( ang ), 0 ) * self.DeathBlastRadius * 0.5 )
        ringEffect:SetStart( particleColor )
        ringEffect:SetScale( 1.6 )
        ringEffect:SetMagnitude( 5 )
        util.Effect( "terminator_phantomdust", ringEffect )
    end

    self:CreatePhantomExplosion( pos, self.DeathExplosionMagnitude )

    for _, ent in ipairs( ents.FindInSphere( pos, self.DeathBlastRadius ) ) do
        if ent == self then continue end

        local entPos = ent:GetPos()
        local pushDir = ( entPos - pos ):GetNormalized()
        pushDir.z = math.max( pushDir.z, 0.35 )

        local dist = entPos:Distance( pos )
        local forceMult = math.Clamp( 1 - ( dist / self.DeathBlastRadius ), 0.3, 1 )
        local force = pushDir * self.DeathBlastForce * forceMult

        if ent:IsPlayer() then
            ent:SetVelocity( force )
            ent:ScreenFade( SCREENFADE.IN, Color( particleColor.x, particleColor.y, particleColor.z, 120 ), 0.4, 0.2 )

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
                phys:ApplyForceCenter( force * phys:GetMass() * 0.4 )
            end
        end
    end
end

function ENT:BecomeEnraged()
    self.isEnraged = true
    self:SetNWBool( "PhantomEnraged", true )
    self:ZAMB_AngeringCall( true, 2 )

    self.WalkSpeed = self.baseWalkSpeed * self.EnragedSpeedMult
    self.MoveSpeed = self.baseMoveSpeed * self.EnragedSpeedMult
    self.RunSpeed = self.baseRunSpeed * self.EnragedSpeedMult

    self:SetColor( ColorAlpha( self.EnragedColor, self.EnragedAlpha ) )

    self:EmitSound( "ambient/levels/citadel/strange_talk" .. math.random( 3, 11 ) .. ".wav", 90, 45, 1, CHAN_STATIC )
    self:EmitSound( "ambient/levels/advisor_barn/ol07_advisor_00_50_11.wav", 90, 65, 1, CHAN_STATIC )

    local pos = self:WorldSpaceCenter()

    local effectData = EffectData()
    effectData:SetOrigin( pos )
    effectData:SetStart( self.EnragedParticleColor )
    effectData:SetScale( 3.5 )
    effectData:SetMagnitude( 25 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( self.EnragedParticleColor )
    smokeData:SetScale( 1.8 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    self:CreatePhantomExplosion( pos, 120 )
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
        effectData:SetScale( 0.9 )
        effectData:SetMagnitude( 5 )
        util.Effect( "terminator_phantomdust", effectData )

        self:EmitSound( "ambient/energy/spark" .. math.random( 1, 6 ) .. ".wav", 60, math.random( 75, 95 ), 0.5 )
    end

end
