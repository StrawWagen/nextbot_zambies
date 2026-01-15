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
ENT.PhantomAlpha = 140

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
        self.NextAmbientParticle = curTime + 0.1

        local effectData = EffectData()
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -16, 16 ), math.Rand( -16, 16 ), math.Rand( 5, 50 ) ) )
        effectData:SetStart( self.PhantomParticleColor )
        effectData:SetScale( 0.8 )
        util.Effect( "terminator_phantomambient", effectData )
    end

    return
end

ENT.SpawnHealth = 120
ENT.WalkSpeed = 160
ENT.MoveSpeed = 400
ENT.RunSpeed = 520
ENT.AccelerationSpeed = 650

ENT.FistDamageMul = 0.5
ENT.MyPhysicsMass = 40

ENT.PhaseChance = 0.55
ENT.PhaseCooldown = 0.45
ENT.PhaseInvulnTime = 0.25
ENT.ConsecutivePhasePenalty = 0.08

ENT.ParticleInterval = 0.08
ENT.PhaseSound = "ambient/levels/citadel/weapon_disintegrate2.wav"

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
        effectData:SetOrigin( self:GetPos() + Vector( math.Rand( -16, 16 ), math.Rand( -16, 16 ), math.Rand( 10, 50 ) ) )
        effectData:SetStart( self.PhantomParticleColor )
        effectData:SetScale( 0.8 )
        effectData:SetMagnitude( 3 )
        util.Effect( "terminator_phantomdust", effectData )
    end,

    OnDamaged = function( self, data, dmg )
        local curTime = CurTime()

        if curTime < data.invulnUntil then
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

        if math.random() >= math.Clamp( phaseChance, 0.15, 0.8 ) then return end

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
    effectData:SetScale( 3.5 )
    effectData:SetMagnitude( 30 )
    util.Effect( "terminator_phantomdust", effectData )

    local smokeData = EffectData()
    smokeData:SetOrigin( pos )
    smokeData:SetStart( self.PhantomParticleColor )
    smokeData:SetScale( 1.5 )
    util.Effect( "terminator_phantomsmoke", smokeData )

    self:EmitSound( "ambient/levels/citadel/portal_beam_shoot5.wav", 70, 130, 0.8 )
end

function ENT:PerformPhase( data )
    local curTime = CurTime()

    data.nextPhase = curTime + self.PhaseCooldown
    data.consecutivePhases = data.consecutivePhases + 1
    data.lastPhaseReset = curTime
    data.invulnUntil = curTime + self.PhaseInvulnTime

    local effectData = EffectData()
    effectData:SetOrigin( self:WorldSpaceCenter() )
    effectData:SetStart( self.PhantomParticleColor )
    effectData:SetScale( 1.5 )
    effectData:SetMagnitude( 12 )
    util.Effect( "terminator_phantomdust", effectData )

    self:SetColor( ColorAlpha( self.PhantomColor, 30 ) )

    timer.Simple( self.PhaseInvulnTime, function()
        if IsValid( self ) then
            self:SetColor( ColorAlpha( self.PhantomColor, self.PhantomAlpha ) )
        end
    end )

    self:EmitSound( self.PhaseSound, 60, math.random( 150, 170 ), 0.6 )
end