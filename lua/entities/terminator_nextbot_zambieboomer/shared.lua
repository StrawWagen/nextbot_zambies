-- Thanks to MerekiDor and JonahSoldier the creators of Map Sweepers for allowing this!
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Boomer"
ENT.Author    = "Map Sweepers + regunkyle"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieboomer", {
    Name      = "Zombie Boomer",
    Class     = "terminator_nextbot_zambieboomer",
    Category  = "Nextbot Zambies",
    AdminOnly = true,
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
ENT.zamb_BoomerFuseTime    = 2.5 -- seconds from arming to bursting, damage shortens it

-- 0 when the fuse is lit, 1 when it bursts
local function FuseFrac( self, burstTime )
    local fuseTime = self.zamb_BoomerFuseTime
    return math.Clamp( ( CurTime() - ( burstTime - fuseTime ) ) / fuseTime, 0, 1 )
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

    function ENT:OnRemove()
        if IsValid( self.zamb_BoomerHeadModel ) then
            self.zamb_BoomerHeadModel:Remove()
        end
    end

    -- Client-side Think: reads NW2 variables set by the server to drive inflate particles and sound.
    function ENT:Think()
        local isArmed = self:GetNW2Bool( "zamb_BoomerArmed", false )
        local armTime = self:GetNW2Float( "zamb_BoomerArmTime", 0 )
        if isArmed then
            local frac = FuseFrac( self, armTime )
            -- Play the inflate sound once per arm cycle.
            if not self.zamb_BoomerInflateSoundPlayed then
                self.zamb_BoomerInflateSoundPlayed = true
                self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )
            end

            -- Random blood splatter
            if math.random() < frac then
                local ed  = EffectData()
                local pos = self:WorldSpaceCenter()
                local ang = math.random() * math.pi * 2
                pos.x = pos.x + math.cos( ang ) * math.Rand( 5, 16 )
                pos.y = pos.y + math.sin( ang ) * math.Rand( 5, 16 )
                pos.z = pos.z + math.Rand( -32, 24 )
                ed:SetOrigin( pos )
                ed:SetColor( math.random( 1, 3 ) )
                util.Effect( "BloodImpact", ed )
                if math.random() < 0.6 then
                    self:EmitSound(
                        "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav",
                        100, 70 + frac * 60, 1
                    )
                end
            end
        else
            self.zamb_BoomerInflateSoundPlayed = false
        end
        self:SetNextClientThink( CurTime() + 0.05 )
        return true
    end

    function ENT:Draw()
        local isArmed = self:GetNW2Bool( "zamb_BoomerArmed", false )
        local armTime = self:GetNW2Float( "zamb_BoomerArmTime", 0 )
        local headmdl = GetOrCreateHead( self )
        headmdl:SetParent( self )
        if isArmed then
            local frac = FuseFrac( self, armTime )
            render.SetColorModulation( 3 + frac * 5, 2 + frac ^ 2 * 4, 1 )
            self:DrawModel()
            headmdl:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        else
            render.SetColorModulation( 3, 2, 1 )
            self:DrawModel()
            headmdl:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        end
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
end

local function ArmFuse( self )
    if self.zamb_BoomerArmed or self.zamb_BoomerBursting then return end
    self.zamb_BoomerArmed   = true
    self.zamb_BoomerArmTime = CurTime() + self.zamb_BoomerFuseTime
    BroadcastArmed( self, true )
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

local function SpawnCrabs( pos )
    for _ = 1, 7 do
        local crab = ents.Create( "terminator_nextbot_zambieblastcrab" )
        if not IsValid( crab ) then continue end
        crab:SetPos( pos + VectorRand( -25, 25 ) )
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

-- Only called from OnKilled, the fuse kills the boomer rather than bursting it directly.
-- We're still inside the damage call stack here, so the blast and crabs wait a tick.
local function DoBurst( self )
    if self.zamb_BoomerBursting then return end
    self.zamb_BoomerBursting = true
    BroadcastArmed( self, false )

    local pos         = self:WorldSpaceCenter()
    local primed      = self.zamb_BoomerPrimed
    local obliterated = self.zamb_BoomerObliterated

    local ed = EffectData()
    ed:SetOrigin( pos )
    ed:SetRadius( 350 )
    ed:SetMagnitude( primed and 1.4 or 1 )
    util.Effect( "eff_boomer_blast", ed, true, true )

    self:EmitSound( "npc/zombie/zombie_die1.wav", 100, 80, 1 )
    self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 70, 1 )

    timer.Simple( 0, function()
        if not IsValid( self ) then return end

        local dmg = DamageInfo()
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetReportedPosition( pos )
        dmg:SetDamageType( DMG_CRUSH )
        dmg:SetDamage( primed and 150 or 1 ) -- unprimed, the crabs are the real threat
        util.BlastDamageInfo( dmg, pos, 350 )

        if not obliterated then
            SpawnCrabs( pos )
        end

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

-- Module-level Angle mutated in place by the fuse Think
local zamb_JitterAngle = Angle( 0, 0, 0 )

ENT.MySpecialActions = {
    ["Detonate"] = {
        name      = "Detonate",
        desc      = "Lights the fuse",
        inBind    = IN_ATTACK,
        drawHint  = true,
        ratelimit = 0,
        svAction  = function( _driveController, _driver, bot )
            ArmFuse( bot )
        end,
    },
}

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self.zamb_BoomerArmTime = 0
    end,

    -- Think runs under playercontrol too, BehaveUpdatePriority doesn't
    Think = function( self, data )
        if not self.zamb_BoomerArmed or self.zamb_BoomerBursting then return end

        local frac = FuseFrac( self, self.zamb_BoomerArmTime )
        ScaleBones( self, 1 + frac ^ 6 * 0.9 )

        local spineBone = self.zamb_BoomerSpineBone
        if spineBone and spineBone >= 0 then
            local jitter = frac * 25
            zamb_JitterAngle.p = math.Rand( -jitter, jitter )
            zamb_JitterAngle.y = math.Rand( -jitter, jitter )
            zamb_JitterAngle.r = math.Rand( -jitter, jitter )
            self:ManipulateBoneAngles( spineBone, zamb_JitterAngle )
        end

        if CurTime() < self.zamb_BoomerArmTime then return end
        if self:Health() <= 0 then return end

        -- die properly, so OnKilled does the burst and death hooks still run
        local dmg = DamageInfo()
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetDamageType( DMG_GENERIC )
        dmg:SetDamage( self:Health() )
        self:TakeDamageInfo( dmg )
    end,

    BehaveUpdatePriority = function( self, data )
        if self.zamb_BoomerArmed then return end
        if not self.IsSeeEnemy then return end
        if not IsValid( self:GetEnemy() ) then return end
        if self.DistToEnemy > self.zamb_BoomerArmDistance then return end

        ArmFuse( self )
    end,

    OnDamaged = function( self, data, dmg )
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
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        DoBurst( self )
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

    self.isTerminatorHunterChummy = "zambies"
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
