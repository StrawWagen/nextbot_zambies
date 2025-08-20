AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Energy"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieenergy", {
    Name = "Zombie Energy",
    Class = "terminator_nextbot_zambieenergy",
    Category = "Nextbot Zambies",
} )

-- stub, make sure you add this shared, this is called for client ragdolls too
function ENT:AdditionalRagdollDeathEffects( ragdoll )
    if not IsValid( ragdoll ) then return end

    local duration = 5
    local step = duration / 100
    local endTime = CurTime() + duration
    local timerName = "zmb_energy_ragdoll_jitter_" .. ragdoll:GetCreationID()

    -- wake up physics so impulses actually move it
    local count = ragdoll.GetPhysicsObjectCount and ragdoll:GetPhysicsObjectCount() or 0
    for i = 0, count - 1 do
        local phys = ragdoll:GetPhysicsObjectNum( i )
        if IsValid( phys ) then phys:Wake() end
    end

    ragdoll.Chance = 100

    timer.Create( timerName, step, 0, function()
        if not IsValid( ragdoll ) then
            timer.Remove( timerName )
            return
        end

        local timeLeft = endTime - CurTime()
        if timeLeft <= 0 then
            timer.Remove( timerName )
            return
        end

        ragdoll.Chance = ragdoll.Chance - 1
        if math.random( 0, 100 ) > ragdoll.Chance then return end

        local frac = math.Clamp( timeLeft / duration, 0, 1 )
        local force = 600 * frac + 100 -- start stronger, taper off

        local countInternal = ragdoll.GetPhysicsObjectCount and ragdoll:GetPhysicsObjectCount() or 0
        for i = 0, countInternal - 1 do
            local phys = ragdoll:GetPhysicsObjectNum( i )
            if IsValid( phys ) then
                local dir = VectorRand()
                phys:ApplyForceCenter( dir * force )
                phys:ApplyForceOffset( -dir * force, phys:GetPos() + dir * 5 )

                if math.random( 0, 400 ) < ragdoll.Chance then
                    local eff = EffectData()
                    eff:SetOrigin( phys:GetPos() )
                    eff:SetRadius( 2 )
                    eff:SetMagnitude( math.Rand( 0.1, 0.5 ) )
                    eff:SetScale( math.Rand( 0.1, 1.5 ) )
                    util.Effect( "Sparks", eff )

                end
            end
        end
    end )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergy", ENT.PrintName )

    local setupMat
    local desiredBaseTexture = "models/vortigaunt/vortigaunt_warp"
    local mat = "nextbotZambies_BurntFlesh"
    function ENT:AdditionalClientInitialize()
        if setupMat then return end
        setupMat = true

        local newMat = CreateMaterial( mat, "VertexLitGeneric", {
            ["$basetexture"] = desiredBaseTexture,
        } )

        if newMat and newMat:GetKeyValues()["$basetexture"] then
            newMat:SetTexture( "$basetexture", desiredBaseTexture )
        end

        self:SetSubMaterial( 0, "!" .. mat )

    end
    return

end

-- stats
ENT.SpawnHealth = 50
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1

ENT.CoroutineThresh = 0.00005
ENT.AimSpeed = 600
ENT.WalkSpeed = 75
ENT.MoveSpeed = 300
ENT.RunSpeed = 500

ENT.FistDamageMul = 1
ENT.zamb_MeleeAttackSpeed = 3
ENT.FistDamageType = bit.bor( DMG_SHOCK, DMG_DISSOLVE )

ENT.TERM_MODELSCALE = function() return math.Rand( 1.08, 1.10 ) end
ENT.MyPhysicsMass = 85

-- visuals / damage
ENT.ENERGY_COLOR = Color( 150, 150, 150 )
ENT.DMG_MASK = bit.bor( DMG_SHOCK, DMG_ENERGYBEAM, DMG_DISSOLVE )
ENT.IMMUNE_MASK = bit.bor( DMG_SHOCK, DMG_ENERGYBEAM, DMG_DISSOLVE, DMG_RADIATION )

-- arc FX
ENT.ArcEnabled = true
ENT.ArcMagnitude = 6
ENT.ArcIntervalMin = 0.50
ENT.ArcIntervalMax = 1.20

local function arcingFx( ent )
    if not ent.ArcEnabled then return end

    local effDat = EffectData()
    effDat:SetEntity( ent )
    effDat:SetMagnitude( ent.ArcMagnitude )
    util.Effect( "TeslaHitBoxes", effDat )

end

-- sfx
ENT.ELECT_SFX = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav",
    "ambient/energy/zap5.wav",
}

function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_BurntFlesh" )
    self:SetColor( self.ENERGY_COLOR )

    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false

    if math.random( 1, 100 ) < 30 then
        self.HasBrains = true
        self.CanHearStuff = true

    end

    self.term_DMG_ImmunityMask = self.IMMUNE_MASK
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = 25
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/energy/zap1.wav"
    self.term_CallingSmallSound = "ambient/energy/zap2.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = "ambient/energy/zap3.wav"
    self.term_AngerSound = "ambient/energy/spark4.wav"
    self.term_DamagedSound = "ambient/energy/zap4.wav"
    self.term_DieSound = "ambient/energy/weld1.wav"
    self.term_JumpSound = "ambient/energy/spark6.wav"

    self.zamb_IdleTauntInterval = 0 -- taunt FAST

    self.IdleLoopingSounds = {
        "ambient/energy/newspark01.wav",
        "ambient/energy/newspark02.wav",
        "ambient/energy/newspark03.wav",
        "ambient/energy/newspark04.wav",
        "ambient/energy/newspark05.wav",
        "ambient/energy/newspark06.wav",
    }
    self.AngryLoopingSounds = { "ambient/energy/electric_loop.wav" }
    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

    self._nextArc = CurTime() + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )

end

function ENT:DissolveTarget( target )
    if not IsValid( target ) then return end

    local dissolver = ents.Create( "env_entity_dissolver" )
    if not IsValid( dissolver ) then
        SafeRemoveEntityDelayed( target, 0.1 )
        return

    end

    dissolver:SetPos( target:GetPos() )
    dissolver:Spawn()
    dissolver:Activate()
    dissolver:SetKeyValue( "dissolvetype", "0" )
    dissolver:Fire( "Dissolve", target, 0 )

    SafeRemoveEntityDelayed( dissolver, 1.2 )

end

function ENT:DealEnergyDamageTo( ent, dmg, pos )
    if not IsValid( ent ) then return end

    local pals = ent.isTerminatorHunterChummy and ent.isTerminatorHunterChummy == self.isTerminatorHunterChummy
    if pals then
        dmg = dmg / 4

    end

    local dmgInfo = DamageInfo()
    dmgInfo:SetDamage( dmg )
    dmgInfo:SetDamageType( self.DMG_MASK )
    dmgInfo:SetAttacker( self )
    dmgInfo:SetInflictor( self )
    dmgInfo:SetDamagePosition( pos or self:WorldSpaceCenter() )
    ent:TakeDamageInfo( dmgInfo )

    ent:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 60 + ( dmg / 40 ), 120 + ( -dmg / 10 ) )

    local myPos = self:WorldSpaceCenter()
    local itsNearestToMe = ent:NearestPoint( myPos )
    local myNearestToIt = self:NearestPoint( itsNearestToMe )
    local dirToMyPos = terminator_Extras.dirToPos( itsNearestToMe, myPos )

    -- help communicate that damage did happen
    local effDat = EffectData()
    effDat:SetMagnitude( 1 )
    effDat:SetScale( 5 )
    effDat:SetOrigin( myNearestToIt )
    effDat:SetNormal( dirToMyPos )
    util.Effect( "ElectricSpark", effDat )

    effDat = EffectData()
    effDat:SetMagnitude( 1 )
    effDat:SetScale( 1 )
    effDat:SetOrigin( itsNearestToMe )
    effDat:SetNormal( dirToMyPos )
    util.Effect( "Sparks", effDat )

    if not pals then return end

    if ent.zambie_Overcharged then return end
    if not ent.IsNextBot or not ent:IsNextBot() then return end

    ent.zambie_Overcharged = true
    local duration = math.Rand( 3, 5 )

    local myMaxHealth = self:GetMaxHealth()
    if ent:GetMaxHealth() < myMaxHealth * 2 then return end -- dont mess with boss zombies

    ent:RunTask( "ZambOnGrumpy" )

    local mul = math.Rand( 1.25, 1.5 )
    local originalMoveSpeed = ent.MoveSpeed
    local originalRunSpeed = ent.RunSpeed
    ent.MoveSpeed = originalMoveSpeed * mul
    ent.RunSpeed = originalRunSpeed * mul
    timer.Simple( duration, function()
        if not IsValid( ent ) then return end
        ent.zambie_Overcharged = nil
        ent.MoveSpeed = originalMoveSpeed
        ent.RunSpeed = originalRunSpeed

    end )
end

function ENT:DoAoeEnergyDamage( ent, rad )
    if not IsValid( ent ) then return end

    rad = rad or 200
    local areaDamagePos = ent:NearestPoint( self:WorldSpaceCenter() )

    for _, aoeEnt in ipairs( ents.FindInSphere( areaDamagePos, rad ) ) do
        if IsValid( aoeEnt:GetParent() ) then continue end
        if aoeEnt == ent then continue end
        if aoeEnt == self then continue end

        if aoeEnt:GetMaxHealth() > 1 and aoeEnt:Health() <= 0 then return end

        local dmg = rad - aoeEnt:NearestPoint( areaDamagePos ):Distance( areaDamagePos )
        local entsClass = aoeEnt:GetClass()
        if not ( string.find( entsClass, "wire" ) or string.find( entsClass, "starfall" ) ) then -- more damage to wiremod components/all chips
            dmg = dmg / 8

        end
        if dmg < 1 then continue end

        self:DealEnergyDamageTo( aoeEnt, dmg, areaDamagePos )

    end
end

local scorchUpOffs = Vector( 0, 0, 10 )
local scorchDownOffs = Vector( 0, 0, -20 )

function ENT:AdditionalFootstep( pos )
    if math.random( 0, 100 ) < 25 then
        snd = "ambient/energy/spark" .. math.random( 1, 6 ) .. ".wav"
        pit = math.random( 120, 140 )
        self:EmitSound( snd, 75, pit )
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 100, self:GetPos() )
            self:DoAoeEnergyDamage( groundEnt )

        end
    else
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 10, self:GetPos() )

        end
    end
    util.Decal( "SmallScorch", pos + scorchUpOffs, pos + scorchDownOffs, self )

end

function ENT:PostHitObject( hit )
    self:DoAoeEnergyDamage( hit, 200 )

end

function ENT:AdditionalOnKilled()
    self:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 80, 120 )
    self:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 90, 60 )

    self:DoAoeEnergyDamage( self, 300 )

end

function ENT:AdditionalThink()
    if self.ArcEnabled then
        local now = CurTime()
        if now >= ( self._nextArc or 0 ) then
            self._nextArc = now + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )
            arcingFx( self )

        end
    end
    BaseClass.AdditionalThink( self )

end
