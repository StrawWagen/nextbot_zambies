-- Zombie Boomer
-- Ported from Map Sweepers. Original boomer by MerekiDor and JonahSoldier,
-- used with their permission on the condition that they are credited.

AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Boomer"
ENT.Author = "Regun2 (port) - original by MerekiDor and JonahSoldier (Map Sweepers)"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieboomer", {
    Name = "Zombie Boomer",
    Class = "terminator_nextbot_zambieboomer",
    Category = "Nextbot Zambies",
} )

local BOOMER_MODEL = "models/player/zombie_soldier.mdl"
local BOOMER_HEAD = "models/Zombie/Fast.mdl"
local BOOMER_HEAD_MAT = "models/jcmsblastcrab/body"

-- Shared by client and server, so they have to be above the CLIENT block.
ENT.zamb_BoomerFuseTime = 2.5 -- seconds between arming and bursting
ENT.zamb_BoomerArmDistance = 200 -- AI arms itself when its enemy is this close
ENT.zamb_BoomerBlastRadius = 350
ENT.zamb_BoomerCrabCount = 7

-- The time the fuse runs out at, in CurTime(). 0 means the fuse isn't lit.
-- Networked, so the client can draw the inflate effects off the same clock as the server.
local NW_FUSE_END = "zamb_BoomerFuseEnd"

-- How far through the fuse we are, 0 = just lit, 1 = about to burst. 0 when not lit.
local function GetFuseFraction( self )
    local fuseEnd = self:GetNW2Float( NW_FUSE_END, 0 )
    if fuseEnd <= 0 then return 0 end

    local timeLeft = fuseEnd - CurTime()
    return math.Clamp( 1 - timeLeft / self.zamb_BoomerFuseTime, 0, 1 )
end

if CLIENT then
    language.Add( "terminator_nextbot_zambieboomer", ENT.PrintName )

    -- Static objects, so Draw doesn't allocate every frame
    local HEAD_CRAB_ANGLE = Angle( -24, 3.3, 21.8 )
    local HEAD_CRAB_POSITION = Vector( 0.9, 4.3, -3 )
    local VECTOR_ONE = Vector( 1, 1, 1 )

    -- Creates (or returns the cached) blastcrab-head overlay model parented to the boomer.
    local function GetOrCreateHead( self )
        if IsValid( self.zamb_BoomerHeadModel ) then return self.zamb_BoomerHeadModel end

        local headModel = ClientsideModel( BOOMER_HEAD )
        headModel:SetParent( self )
        headModel:AddEffects( EF_BONEMERGE )
        headModel:SetNoDraw( true )
        headModel:SetMaterial( BOOMER_HEAD_MAT )
        headModel:SetBodygroup( 1, 1 )

        -- Hide the whole fast zombie, then bring back just the headcrab bones
        for i = 0, headModel:GetBoneCount() - 1 do
            headModel:ManipulateBoneScale( i, vector_origin )
        end
        for i = 40, 51 do
            headModel:ManipulateBoneScale( i, VECTOR_ONE )
        end
        headModel:ManipulateBoneAngles( 40, HEAD_CRAB_ANGLE )
        headModel:ManipulateBonePosition( 40, HEAD_CRAB_POSITION )

        self.zamb_BoomerHeadModel = headModel
        return headModel
    end

    function ENT:OnRemove()
        if BaseClass.OnRemove then
            BaseClass.OnRemove( self )
        end

        if IsValid( self.zamb_BoomerHeadModel ) then
            self.zamb_BoomerHeadModel:Remove()
        end
    end

    -- Drives the inflate blood splatter and sounds off the networked fuse.
    function ENT:Think()
        if BaseClass.Think then
            BaseClass.Think( self )
        end

        self:SetNextClientThink( CurTime() + 0.05 )

        local fuseEnd = self:GetNW2Float( NW_FUSE_END, 0 )
        if fuseEnd <= 0 then
            self.zamb_BoomerInflateSoundPlayed = false
            return true
        end

        -- Play the inflate sound once per fuse
        if not self.zamb_BoomerInflateSoundPlayed then
            self.zamb_BoomerInflateSoundPlayed = true
            self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )
        end

        -- The closer to bursting, the more often it splatters
        local fraction = GetFuseFraction( self )
        if math.random() >= fraction then return true end

        local angle = math.random() * math.pi * 2
        local pos = self:WorldSpaceCenter()
        pos.x = pos.x + math.cos( angle ) * math.Rand( 5, 16 )
        pos.y = pos.y + math.sin( angle ) * math.Rand( 5, 16 )
        pos.z = pos.z + math.Rand( -32, 24 )

        local effectData = EffectData()
        effectData:SetOrigin( pos )
        effectData:SetColor( math.random( 1, 3 ) )
        util.Effect( "BloodImpact", effectData )

        if math.random() < 0.6 then
            self:EmitSound(
                "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav",
                100, 70 + fraction * 60, 1
            )
        end

        return true
    end

    function ENT:Draw()
        local headModel = GetOrCreateHead( self )
        headModel:SetParent( self )

        -- Glows brighter as the fuse burns down. Fraction is 0 when the fuse isn't lit.
        local fraction = GetFuseFraction( self )
        render.SetColorModulation( 3 + fraction * 5, 2 + fraction ^ 2 * 4, 1 )
        self:DrawModel()
        headModel:DrawModel()
        render.SetColorModulation( 1, 1, 1 )
    end

    return
end

sound.Add( {
    name = "NPC_ZombieBoomer.Idle",
    channel = CHAN_VOICE,
    volume = 0.9,
    level = 75,
    pitch = 90,
    sound = {
        "npc/barnacle/barnacle_digesting1.wav",
        "npc/barnacle/barnacle_gulp1.wav",
        "npc/barnacle/barnacle_digesting2.wav",
        "npc/barnacle/barnacle_gulp2.wav",
    },
} )

sound.Add( {
    name = "NPC_ZombieBoomer.Angry",
    channel = CHAN_VOICE,
    volume = 1,
    level = 90,
    pitch = 90,
    sound = {
        "npc/barnacle/barnacle_pull1.wav",
        "npc/barnacle/barnacle_pull2.wav",
        "npc/barnacle/barnacle_pull3.wav",
        "npc/barnacle/barnacle_pull4.wav",
    },
} )

local scaleVec = Vector( 1, 1, 1 ) -- mutated in place by ScaleBones
local jitterAngle = Angle( 0, 0, 0 ) -- mutated in place by the fuse Think

-- Damage taken while the fuse is lit burns it down faster, this many damage = 1 second.
local DAMAGE_PER_FUSE_SECOND = 60

local function ScaleBones( self, scale )
    scaleVec.x = scale
    scaleVec.y = scale
    scaleVec.z = scale

    for i = 0, self:GetBoneCount() - 1 do
        self:ManipulateBoneScale( i, scaleVec )
    end
end

-- Sets a nextbot's velocity. Entity:SetVelocity is unreliable on nextbots, their locomotion owns the velocity.
local function LaunchBot( bot, velocity )
    local locomotion = bot.loco
    if locomotion then
        locomotion:SetVelocity( velocity )
        return
    end

    bot:SetVelocity( velocity )
end

local function IsFuseLit( self )
    return self:GetNW2Float( NW_FUSE_END, 0 ) > 0
end

-- Lights the fuse. Used by the AI when its enemy gets close, and by the Detonate action when a player drives it.
local function LightFuse( self )
    if self.zamb_BoomerFuseBlown then return end
    if IsFuseLit( self ) then return end

    self:SetNW2Float( NW_FUSE_END, CurTime() + self.zamb_BoomerFuseTime )
end

-- Defined further down, BlowFuse needs it for its fallback
local Burst

-- How long to wait for the killing blow to land before giving up on it and bursting anyway
local BLOW_FUSE_FALLBACK_DELAY = 0.1

-- The fuse ran out, kill the boomer.
-- Everything else happens in OnKilled, so there's only one way a boomer can burst
-- and the base's death handling ( reanim manager and so on ) always sees it die.
local function BlowFuse( self )
    -- Stops OnDamaged treating this killing blow as a normal hit
    self.zamb_BoomerFuseBlown = true

    -- The world is the attacker, not the boomer. Zambies are chummy with each other,
    -- and damage from itself or its own faction is the kind the base is likely to ignore.
    local world = game.GetWorld()

    local damageInfo = DamageInfo()
    damageInfo:SetAttacker( world )
    damageInfo:SetInflictor( world )
    damageInfo:SetDamageType( DMG_GENERIC )
    damageInfo:SetDamage( self:Health() + self:GetMaxHealth() )
    damageInfo:SetDamageForce( vector_origin )
    damageInfo:SetDamagePosition( self:WorldSpaceCenter() )
    self:TakeDamageInfo( damageInfo )

    -- If the killing blow was ignored, OnKilled never runs and the boomer would sit there swollen forever.
    -- Burst it directly instead. Burst only runs once, so if OnKilled did fire this does nothing.
    timer.Simple( BLOW_FUSE_FALLBACK_DELAY, function()
        if not IsValid( self ) then return end

        Burst( self )
    end )
end

local function SpawnBlastCrabs( pos, count )
    for _ = 1, count do
        local crab = ents.Create( "terminator_nextbot_zambieblastcrab" )
        if not IsValid( crab ) then continue end

        crab:SetPos( pos + VectorRand( -25, 25 ) )
        crab:Spawn()
        crab:Activate()

        local angle = math.random() * math.pi * 2
        LaunchBot( crab, Vector(
            math.cos( angle ) * math.random() * 320,
            math.sin( angle ) * math.random() * 320,
            math.Rand( -150, 420 )
        ) )
    end
end

-- The one and only burst. Called from OnKilled.
-- Deferred by a tick so it's clear of the base's death call stack. All state is captured first.
function Burst( self )
    if self.zamb_BoomerBursting then return end
    self.zamb_BoomerBursting = true

    self:SetNW2Float( NW_FUSE_END, 0 )

    local pos = self:WorldSpaceCenter()
    local radius = self.zamb_BoomerBlastRadius
    local crabCount = self.zamb_BoomerCrabCount
    local primed = self.zamb_BoomerPrimed
    local obliterated = self.zamb_BoomerObliterated

    timer.Simple( 0, function()
        local effectData = EffectData()
        effectData:SetOrigin( pos )
        effectData:SetRadius( radius )
        effectData:SetNormal( vector_up )
        effectData:SetMagnitude( primed and 1.4 or 0.6 )
        util.Effect( "eff_boomer_blast", effectData, true, true )

        sound.Play( "npc/zombie/zombie_die1.wav", pos, 100, 80, 1 )
        sound.Play( "physics/flesh/flesh_bloody_break.wav", pos, 100, 70, 1 )

        -- Only boomers that were hit by something hard enough to be primed hurt, the rest just pop.
        local damageInfo = DamageInfo()
        damageInfo:SetAttacker( IsValid( self ) and self or game.GetWorld() )
        damageInfo:SetInflictor( IsValid( self ) and self or game.GetWorld() )
        damageInfo:SetReportedPosition( pos )
        damageInfo:SetDamageType( DMG_CRUSH )
        damageInfo:SetDamage( primed and 150 or 1 )
        util.BlastDamageInfo( damageInfo, pos, radius )

        -- Blasting the boomer apart ( obliterated ) leaves no crabs
        if not obliterated then
            SpawnBlastCrabs( pos, crabCount )
        end

        if IsValid( self ) then
            self:Remove()
        end
    end )
end

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

ENT.SpawnHealth = 37
ENT.ExtraSpawnHealthPerPlayer = 0

ENT.WalkSpeed = 40
ENT.MoveSpeed = 115
ENT.RunSpeed = 350
ENT.AccelerationSpeed = 350
ENT.DeccelerationSpeed = 900

ENT.FistDamageMul = 0
ENT.DuelEnemyDist = 200
ENT.CloseEnemyDistance = 200

ENT.ARNOLD_MODEL = BOOMER_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.02, 1.08 ) end

ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 65 ) }
ENT.MyPhysicsMass = 150

ENT.TERM_FISTS = "weapon_term_zombieclaws"
ENT.Models = { BOOMER_MODEL }

ENT.Term_FootstepSoundWalking = {
    { path = "Zombie.ScuffLeft", lvl = 76, pitch = 90 },
    { path = "Zombie.ScuffRight", lvl = 76, pitch = 90 },
}

ENT.Term_FootstepSound = {
    { path = "npc/zombie/foot1.wav", lvl = 77, pitch = 80 },
    { path = "npc/zombie/foot2.wav", lvl = 77, pitch = 80 },
}

ENT.Term_FootstepShake = {
    amplitude = 0.5,
    frequency = 10,
    duration = 0.1,
    radius = 300,
}

ENT.MySpecialActions = {
    [ "Detonate" ] = {
        name = "Detonate",
        desc = "Light the fuse, you burst when it runs out",
        inBind = IN_ATTACK,
        drawHint = true,
        ratelimit = 0,
        svAction = function( _driveController, _driver, bot )
            LightFuse( bot )
        end,
    },
}

ENT.MyClassTask = {
    -- Think runs for AI and player-driven bots alike ( BehaveUpdatePriority is skipped while a player drives ),
    -- so the fuse counts down no matter who is in control.
    Think = function( self, _data )
        if self.zamb_BoomerFuseBlown then return end
        if self.zamb_BoomerBursting then return end
        if not IsFuseLit( self ) then return end

        local fraction = GetFuseFraction( self )

        -- Swell up, slowly at first and then all at once
        ScaleBones( self, 1 + fraction ^ 6 * 0.9 )

        -- Shake the spine harder the closer it gets
        local spineBone = self.zamb_BoomerSpineBone
        if spineBone and spineBone >= 0 then
            local jitter = fraction * 25
            jitterAngle.p = math.Rand( -jitter, jitter )
            jitterAngle.y = math.Rand( -jitter, jitter )
            jitterAngle.r = math.Rand( -jitter, jitter )
            self:ManipulateBoneAngles( spineBone, jitterAngle )
        end

        if CurTime() < self:GetNW2Float( NW_FUSE_END, 0 ) then return end

        BlowFuse( self )
    end,

    -- AI only. Lights the fuse once it's up close to its enemy.
    BehaveUpdatePriority = function( self, _data )
        if self.zamb_BoomerFuseBlown then return end
        if IsFuseLit( self ) then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        if not self.IsSeeEnemy then return end

        if not self.DistToEnemy then return end
        if self.DistToEnemy > self.zamb_BoomerArmDistance then return end

        LightFuse( self )
    end,

    OnDamaged = function( self, _data, damageInfo )
        if self.zamb_BoomerFuseBlown then return end
        if self.zamb_BoomerBursting then return end

        local damageType = damageInfo:GetDamageType()
        local amount = damageInfo:GetDamage()

        -- Hit hard enough, or by something explosive enough, and there's nothing left for the crabs
        local isObliterating = bit.band( damageType, bit.bor( DMG_BLAST, DMG_RADIATION, DMG_DISSOLVE ) ) > 0
        local obliterateThreshold = isObliterating and 75 or 300
        if amount >= obliterateThreshold then
            self.zamb_BoomerObliterated = true
        end

        -- Blasts, sonic and club hits prime the boomer, it will hurt things when it bursts
        if bit.band( damageType, bit.bor( DMG_BLAST, DMG_SONIC, DMG_CLUB ) ) > 0 then
            self.zamb_BoomerPrimed = true
        end

        -- Shorten the fuse by the damage taken
        local fuseEnd = self:GetNW2Float( NW_FUSE_END, 0 )
        if fuseEnd > 0 then
            self:SetNW2Float( NW_FUSE_END, fuseEnd - amount / DAMAGE_PER_FUSE_SECOND )
        end
    end,

    OnKilled = function( self, _data, _attacker, _inflictor, _ragdoll )
        Burst( self )
    end,

    PreventBecomeRagdollOnKilled = function( _self, _data, _damageInfo )
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

    -- Burst state, this is the only place it's set up
    self.zamb_BoomerFuseBlown = false
    self.zamb_BoomerBursting = false
    self.zamb_BoomerPrimed = false
    self.zamb_BoomerObliterated = false
    self:SetNW2Float( NW_FUSE_END, 0 )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = false

    self.term_SoundPitchShift = -10
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "NPC_ZombieBoomer.Idle"
    self.term_FindEnemySound = "NPC_ZombieBoomer.Angry"
    self.term_AttackSound = { "NPC_ZombieBoomer.Angry" }
    self.term_AngerSound = "NPC_ZombieBoomer.Angry"
    self.term_DamagedSound = "Zombie.Pain"
    self.term_DieSound = "Zombie.Die"
    self.term_JumpSound = "npc/zombie/foot1.wav"

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
    self.FallDamagePerHeight = 0.03
    self.DeathDropHeight = 1500
end
