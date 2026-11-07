-- Thanks to MerekiDor and JonahSoldier the creators of Map Sweepers for allowing this!
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Boomer"
ENT.Author    = "Octantis Addons + regunkyle"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieboomer", {
    Name      = "Zombie Boomer",
    Class     = "terminator_nextbot_zambieboomer",
    Category  = "Nextbot Zambies",
    AdminOnly = false,
} )

local BOOMER_MODEL    = "models/player/zombie_soldier.mdl"
local BOOMER_HEAD     = "models/Zombie/Fast.mdl"
local BOOMER_HEAD_MAT = "models/jcmsblastcrab/body"

-- Static objects to avoid per-frame allocation in GetOrCreateHead and ScaleBones
local HEAD_CRAB_ANGLE    = Angle( -24, 3.3, 21.8 )
local HEAD_CRAB_POSITION = Vector( 0.9, 4.3, -3 )
local VECTOR_ONE         = Vector( 1, 1, 1 )
local zamb_BoomerScaleVec = Vector( 1, 1, 1 )

ENT.zamb_BoomerArmDistance = 200 -- starts the fuse when an enemy it can see gets this close
ENT.zamb_BoomerArmDistancePerSpeed = 0 -- plus this much per unit of our speed, so a charge lights it sooner
ENT.zamb_BoomerFuseTime    = 2.5 -- seconds from arming to bursting, damage shortens it

-- 0 when the fuse is lit, 1 when it bursts.
-- Put out, it runs back down to 0 as fast as it burned.
function ENT:BoomerFuseFrac()
    local fuseTime = self.zamb_BoomerFuseTime
    if self:GetNW2Bool( "zamb_BoomerArmed", false ) then
        return math.Clamp( 1 - ( self:GetNW2Float( "zamb_BoomerArmTime", 0 ) - CurTime() ) / fuseTime, 0, 1 )
    end
    return math.Clamp( ( self:GetNW2Float( "zamb_BoomerCoolTime", 0 ) - CurTime() ) / fuseTime, 0, 1 )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieboomer", ENT.PrintName )

    -- Creates (or returns cached) the blastcrab-head overlay model parented to the boomer.
    local function GetOrCreateHead( self )
        if IsValid( self.zamb_BoomerHeadModel ) then return self.zamb_BoomerHeadModel end
        local mdl = ClientsideModel( BOOMER_HEAD )
        mdl:SetParent( self )
        mdl:AddEffects( EF_BONEMERGE )
        mdl:SetNoDraw( true )
        mdl:SetMaterial( BOOMER_HEAD_MAT )
        mdl:SetBodygroup( 1, 1 )
        mdl:SetLOD( 0 ) -- lower LODs fold the crab's bones into ones we scale to zero
        for i = 0, mdl:GetBoneCount() - 1 do
            mdl:ManipulateBoneScale( i, vector_origin )
        end
        for i = 40, 51 do
            mdl:ManipulateBoneScale( i, VECTOR_ONE )
        end
        mdl:ManipulateBoneAngles( 40,   HEAD_CRAB_ANGLE )
        mdl:ManipulateBonePosition( 40, HEAD_CRAB_POSITION )
        self.zamb_BoomerHeadModel = mdl
        return mdl
    end

    local BLOOD_DRIP_DIR = Vector( 0, 0, -300 )

    function ENT:OnRemove()
        if IsValid( self.zamb_BoomerHeadModel ) then
            self.zamb_BoomerHeadModel:Remove()
        end
    end

    -- Client-side Think: reads NW2 variables set by the server to drive inflate particles and sound.
    function ENT:Think()
        -- Play the inflate sound once per arm cycle.
        if not self:GetNW2Bool( "zamb_BoomerArmed", false ) then
            self.zamb_BoomerInflateSoundPlayed = false
        elseif not self.zamb_BoomerInflateSoundPlayed then
            self.zamb_BoomerInflateSoundPlayed = true
            self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )
        end

        -- Random blood splatter, still going while a put out fuse winds down
        local frac = self:BoomerFuseFrac()
        if not self:IsDormant() and math.random() < frac then
            local ed  = EffectData()
            local pos = terminator_Extras.GetRandomHitboxPoint( self )
            ed:SetOrigin( pos )
            ed:SetColor( BLOOD_COLOR_GREEN )
            util.Effect( "BloodImpact", ed )
            if math.random() < 0.2 then
                terminator_Extras.zamb_BoomerBloodDecal( pos, BLOOD_DRIP_DIR, self:GetModelScale() )
            end
            if math.random() < 0.6 then
                self:EmitSound(
                    "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav",
                    100, 70 + frac * 60, 1
                )
            end
        end
        self:SetNextClientThink( CurTime() + 0.05 )
        return true
    end

    function ENT:Draw()
        local headmdl = GetOrCreateHead( self )
        headmdl:SetParent( self )
        local frac = self:BoomerFuseFrac()
        render.SetColorModulation( 3 + frac * 5, 2 + frac ^ 2 * 4, 1 )
        self:DrawModel()
        headmdl:DrawModel()
        render.SetColorModulation( 1, 1, 1 )
    end

    return
end

sound.Add( {
    name    = "NPC_ZombieBoomer.Idle",
    channel = CHAN_VOICE,
    volume  = 0.9,
    level   = 75,
    pitch   = 90,
    sound   = {
        "npc/barnacle/barnacle_digesting1.wav",
        "npc/barnacle/barnacle_gulp1.wav",
        "npc/barnacle/barnacle_digesting2.wav",
        "npc/barnacle/barnacle_gulp2.wav",
    },
} )

sound.Add( {
    name    = "NPC_ZombieBoomer.Angry",
    channel = CHAN_VOICE,
    volume  = 1,
    level   = 90,
    pitch   = 90,
    sound   = {
        "npc/barnacle/barnacle_pull1.wav",
        "npc/barnacle/barnacle_pull2.wav",
        "npc/barnacle/barnacle_pull3.wav",
        "npc/barnacle/barnacle_pull4.wav",
    },
} )

-- Sets the NW2 variables that the client reads in Draw/Think for inflate FX.
local function BroadcastArmed( self, armed )
    self:SetNW2Bool( "zamb_BoomerArmed", armed )
    self:SetNW2Float( "zamb_BoomerArmTime", self.zamb_BoomerArmTime )
    self:SetNW2Float( "zamb_BoomerCoolTime", self.zamb_BoomerCoolTime or 0 )
end

local function ScaleBones( self, sc )
    zamb_BoomerScaleVec.x = sc
    zamb_BoomerScaleVec.y = sc
    zamb_BoomerScaleVec.z = sc
    local count  = self:GetBoneCount()
    for i = 0, count - 1 do
        self:ManipulateBoneScale( i, zamb_BoomerScaleVec )
    end
end

ENT.zamb_BoomerBlastRadius   = 350
ENT.zamb_BoomerPrimedDamage  = 125 -- unprimed it does 1, the crabs are the real threat
ENT.zamb_BoomerCrabCount     = 4
ENT.zamb_BoomerCrabClass     = "terminator_nextbot_zambieblastcrab"

-- MyClassTask hands off to these, subclasses override them.

-- Arming mid wind down picks up where the fuse had fallen to.
function ENT:BoomerArm()
    if self.zamb_BoomerArmed or self.zamb_BoomerBursting then return end
    local frac = self:BoomerFuseFrac()
    self.zamb_BoomerArmed   = true
    self.zamb_BoomerArmTime = CurTime() + ( 1 - frac ) * self.zamb_BoomerFuseTime
    BroadcastArmed( self, true )
end

-- Puts the fuse out, it winds back down as fast as it burned.
function ENT:BoomerDisarm()
    if not self.zamb_BoomerArmed or self.zamb_BoomerBursting then return end
    local frac = self:BoomerFuseFrac()
    self.zamb_BoomerArmed    = false
    self.zamb_BoomerCoolTime = CurTime() + frac * self.zamb_BoomerFuseTime
    BroadcastArmed( self, false )
end

function ENT:BoomerArmDistance()
    return self.zamb_BoomerArmDistance + self:GetCurrentSpeed() * self.zamb_BoomerArmDistancePerSpeed
end

-- No lighting up through a wall.
function ENT:BoomerShouldArm()
    if not self.IsSeeEnemy then return false end
    if not self.NothingOrBreakableBetweenEnemy then return false end
    if not IsValid( self:GetEnemy() ) then return false end
    return self.DistToEnemy <= self:BoomerArmDistance()
end

-- Module-level Angle mutated in place by the fuse Think
local zamb_JitterAngle = Angle( 0, 0, 0 )

-- Swells and shakes us as the fuse burns, then kills us when it's out.
function ENT:BoomerFuseThink()
    if self.zamb_BoomerBursting then return end

    local frac = self:BoomerFuseFrac()
    if frac <= 0 and not self.zamb_BoomerArmed then
        -- wound all the way down, settle once and stop touching the bones
        if not self.zamb_BoomerSwelling then return end
        self.zamb_BoomerSwelling = nil
        frac = 0

    else
        self.zamb_BoomerSwelling = true

    end

    ScaleBones( self, 1 + frac ^ 6 * 0.9 )

    local spineBone = self.zamb_BoomerSpineBone
    if spineBone and spineBone >= 0 then
        local jitter = frac * 25
        zamb_JitterAngle.p = math.Rand( -jitter, jitter )
        zamb_JitterAngle.y = math.Rand( -jitter, jitter )
        zamb_JitterAngle.r = math.Rand( -jitter, jitter )
        self:ManipulateBoneAngles( spineBone, zamb_JitterAngle )
    end

    if not self.zamb_BoomerArmed then return end
    if CurTime() < self.zamb_BoomerArmTime then return end
    if self:Health() <= 0 then return end

    -- die properly, so OnKilled does the burst and death hooks still run
    local dmg = DamageInfo()
    dmg:SetAttacker( self )
    dmg:SetInflictor( self )
    dmg:SetDamageType( DMG_GENERIC )
    dmg:SetDamage( self:Health() )
    self:TakeDamageInfo( dmg )
end

function ENT:BoomerOnDamaged( dmg )
    if self.zamb_BoomerBursting then return end
    if dmg:GetAttacker() == self then return end -- the fuse finishing us off

    local dtype  = dmg:GetDamageType()
    local amount = dmg:GetDamage()
    local isObliterating = bit.band( dtype, bit.bor( DMG_BLAST, DMG_RADIATION, DMG_DISSOLVE ) ) > 0
    if amount >= ( isObliterating and 75 or 300 ) then
        self.zamb_BoomerObliterated = true
    end
    if bit.band( dtype, bit.bor( DMG_BLAST, DMG_SONIC, DMG_CLUB ) ) > 0 then
        self.zamb_BoomerPrimed = true
    end
    if self.zamb_BoomerArmed then
        self.zamb_BoomerArmTime = self.zamb_BoomerArmTime - amount / 60
        BroadcastArmed( self, true )
    end
end

local CRAB_LAG_FRAC = 0.5 -- below this much of the ideal tickrate, no more crabs

function ENT:BoomerSpawnCrabs( pos )
    if terminator_Extras.zamb_IsLagging( CRAB_LAG_FRAC ) then return end
    for _ = 1, self.zamb_BoomerCrabCount do
        local crab = ents.Create( self.zamb_BoomerCrabClass )
        if not IsValid( crab ) then continue end
        crab:SetPos( pos + VectorRand( -25, 25 ) )
        crab.zamb_BlastCrabLagFrac = CRAB_LAG_FRAC -- see the blastcrab's Think, these pop themselves under lag
        crab:Spawn()
        crab:Activate()

        local a = math.random() * math.pi * 2
        crab.loco:Jump()
        crab.loco:SetVelocity( Vector(
            math.cos( a ) * math.random() * 320,
            math.sin( a ) * math.random() * 320,
            math.Rand( -150, 420 )
        ) )
    end
end

function ENT:BoomerBlastFX( pos )
    local ed = EffectData()
    ed:SetOrigin( pos )
    ed:SetRadius( self.zamb_BoomerBlastRadius )
    ed:SetMagnitude( self.zamb_BoomerPrimed and 1.4 or 1 )
    util.Effect( "eff_boomer_blast", ed, true, true )

    self:EmitSound( "npc/zombie/zombie_die1.wav", 80, 80, 1 )
    self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 90, 70, 1 )
end

function ENT:BoomerBlast( pos )
    local dmg = DamageInfo()
    dmg:SetAttacker( self )
    dmg:SetInflictor( self )
    dmg:SetReportedPosition( pos )
    dmg:SetDamageType( DMG_CRUSH )
    dmg:SetDamage( self.zamb_BoomerPrimed and self.zamb_BoomerPrimedDamage or 1 )
    util.BlastDamageInfo( dmg, pos, self.zamb_BoomerBlastRadius )

    if not self.zamb_BoomerObliterated then
        self:BoomerSpawnCrabs( pos )
    end
end

-- Only called from OnKilled, the fuse kills the boomer rather than bursting it directly.
-- We're still inside the damage call stack here, so the blast and crabs wait a tick.
function ENT:BoomerBurst()
    if self.zamb_BoomerBursting then return end
    self.zamb_BoomerBursting = true
    BroadcastArmed( self, false )

    local pos = self:WorldSpaceCenter()
    self:BoomerBlastFX( pos )

    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        -- full damage to the horde too, killing a boomer in a crowd is the play
        self.term_BypassFriendlyFire = true
        self:BoomerBlast( pos )
        self.term_BypassFriendlyFire = nil
        self:Remove()
    end )
end

ENT.IsFodder    = true
ENT.IsStupid    = true
ENT.CanSpeak    = true

ENT.SpawnHealth               = 37
ENT.ExtraSpawnHealthPerPlayer = 0

ENT.WalkSpeed          = 40
ENT.MoveSpeed          = 115
ENT.RunSpeed           = 350
ENT.AccelerationSpeed  = 350
ENT.DeccelerationSpeed = 900

ENT.FistDamageMul      = 0
ENT.DuelEnemyDist      = 200
ENT.CloseEnemyDistance = 200

ENT.ARNOLD_MODEL    = BOOMER_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.02, 1.08 ) end

ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 65 ) }
ENT.MyPhysicsMass   = 150

ENT.Term_BloodColor = BLOOD_COLOR_GREEN

ENT.TERM_FISTS = "weapon_term_zombieclaws"
ENT.Models     = { BOOMER_MODEL }

ENT.Term_FootstepSoundWalking = {
    { path = "Zombie.ScuffLeft",  lvl = 76, pitch = 90 },
    { path = "Zombie.ScuffRight", lvl = 76, pitch = 90 },
}

ENT.Term_FootstepSound = {
    { path = "npc/zombie/foot1.wav", lvl = 77, pitch = 80 },
    { path = "npc/zombie/foot2.wav", lvl = 77, pitch = 80 },
}

ENT.Term_FootstepShake = {
    amplitude = 0.5,
    frequency = 10,
    duration  = 0.1,
    radius    = 300,
}

ENT.MySpecialActions = {
    ["Detonate"] = {
        name      = "Detonate",
        desc      = "Lights the fuse",
        inBind    = IN_ATTACK,
        drawHint  = true,
        ratelimit = 0,
        svAction  = function( _driveController, _driver, bot )
            bot:BoomerArm()
        end,
    },
}

ENT.MyClassTask = {
    OnCreated = function( self, _data )
        self.zamb_BoomerArmTime = 0
    end,

    -- Think runs under playercontrol too, BehaveUpdatePriority doesn't
    Think = function( self, _data )
        self:BoomerFuseThink()
    end,

    BehaveUpdatePriority = function( self, _data )
        if self.zamb_BoomerArmed then return end
        if not self:BoomerShouldArm() then return end
        self:BoomerArm()
    end,

    OnDamaged = function( self, _data, dmg )
        return self:BoomerOnDamaged( dmg )
    end,

    OnKilled = function( self, _data )
        self:BoomerBurst()
    end,

    PreventBecomeRagdollOnKilled = function( self, data, dmg )
        return true, true
    end,
}

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( BOOMER_MODEL )

    local spine = self:LookupBone( "ValveBiped.Bip01_Spine1" )
    if not spine or spine < 0 then
        spine = self:LookupBone( "ValveBiped.Bip01_Spine" )
    end
    self.zamb_BoomerSpineBone = spine


    self.HasBrains                = false

    self.term_SoundPitchShift = -10
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound  = "NPC_ZombieBoomer.Idle"
    self.term_FindEnemySound  = "NPC_ZombieBoomer.Angry"
    self.term_AttackSound     = { "NPC_ZombieBoomer.Angry" }
    self.term_AngerSound      = "NPC_ZombieBoomer.Angry"
    self.term_DamagedSound    = "Zombie.Pain"
    self.term_DieSound        = "Zombie.Die"
    self.term_JumpSound       = "npc/zombie/foot1.wav"

    self.IdleLoopingSounds = {
        "npc/zombie/zombie_voice_idle1.wav",
        "npc/zombie/zombie_voice_idle2.wav",
        "npc/zombie/zombie_voice_idle3.wav",
        "npc/zombie/zombie_voice_idle4.wav",
        "npc/zombie_poison/pz_breathe_loop1.wav",
        "npc/zombie/moan_loop2.wav",
    }

    self.AngryLoopingSounds = {
        "npc/zombie/moan_loop1.wav",
        "npc/zombie/moan_loop3.wav",
    }

    self.AlwaysPlayLooping = true
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight       = 0.03
    self.DeathDropHeight           = 1500
end
