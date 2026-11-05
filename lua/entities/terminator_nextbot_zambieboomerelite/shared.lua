-- Sees you, loses it, sprints at you, blows up.
-- Kill it before it gets there, it goes off wherever it drops.
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieboomer"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Boomer Elite"
ENT.Spawnable = false
ENT.Author = "Octantis Addons + Straw W Wagen"
list.Set( "NPC", "terminator_nextbot_zambieboomerelite", {
    Name     = "Zombie Boomer Elite",
    Class    = "terminator_nextbot_zambieboomerelite",
    Category = "Nextbot Zambies",
} )

ENT.zamb_BoomerArmDistance = 250
ENT.zamb_BoomerArmDistancePerSpeed = 1
ENT.zamb_BoomerFuseTime = 10

if CLIENT then
    language.Add( "terminator_nextbot_zambieboomerelite", ENT.PrintName )

    local dripOffset = Vector( 0, 0, -20 )
    local DRIP_DECAL_DIR = Vector( 0, 0, -400 )
    local SPRAY_DECAL_DIST = 300

    -- Enraged, it drips and spits, and leaves a trail.
    function ENT:Think()
        local ret = BaseClass.Think( self )
        if self:IsDormant() then return ret end
        if not self:GetNW2Bool( "zamb_BoomerEnraged", false ) then return ret end
        if math.random() > 0.5 then return ret end

        local pos = terminator_Extras.GetRandomHitboxPoint( self )
        local scale = self:GetModelScale()
        local ed = EffectData()
        ed:SetOrigin( pos )
        ed:SetColor( BLOOD_COLOR_GREEN )
        if math.random() < 0.2 then
            local out = pos - self:WorldSpaceCenter()
            out:Normalize()
            out:Add( VectorRand() * 0.3 )
            ed:SetNormal( out )
            util.Effect( "BloodImpact", ed )
            terminator_Extras.zamb_BoomerBloodDecal( pos, out * SPRAY_DECAL_DIST * scale, scale )
            self:EmitSound( "npc/barnacle/barnacle_tongue_pull" .. math.random( 1, 3 ) .. ".wav", 75, math.random( 60, 80 ), 0.6 )

        else
            ed:SetNormal( dripOffset )
            util.Effect( "BloodImpact", ed )
            if math.random() < 0.15 then
                terminator_Extras.zamb_BoomerBloodDecal( pos, DRIP_DECAL_DIR, scale * 0.5 )

            end
        end
        return ret

    end

    return

end

ENT.IsFodder = false
ENT.IsStupid = false
ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 10

ENT.SpawnHealth = 2000
ENT.ExtraSpawnHealthPerPlayer = 200
ENT.neverManiac = true
ENT.PrefersVehicleEnemies = true

ENT.JumpHeight = 40
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 2
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight

ENT.WalkSpeed = 100
ENT.MoveSpeed = 150
ENT.RunSpeed = 300
ENT.AccelerationSpeed = 800

ENT.TERM_MODELSCALE = 2
ENT.CollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 30 ) }
ENT.CrouchCollisionBounds = { Vector( -4, -4, 0 ), Vector( 6, 6, 23 ) }
ENT.MyPhysicsMass = 5000
ENT.ReallyHeavy = true
ENT.ReallyStrong = true

ENT.ChargeCrushes = true
ENT.ChargeCrushDmgPerSpeed = 0.2
ENT.ChargeCrushDmgMinSpeed = 400 -- only the sprint, never the gallop

ENT.zamb_LookAheadWhenRunning = false

ENT.zamb_EliteEnragedRunSpeed = 1500
ENT.zamb_EliteEnragedAccel = 150 -- slow to get going, terrifying once it has
ENT.zamb_EliteDuelEnemyDist = 3000 -- run at them without pathing
ENT.zamb_EliteJumpHeight = 1000

ENT.zamb_EliteDetonateFrac = 0.5 -- below this much health, the fuse lights

ENT.zamb_EliteBlastRadius = 2000
ENT.zamb_EliteBlastDamage = 400

ENT.zamb_EliteCoreBlastRadius = 750 -- the heart of it, nothing survives
ENT.zamb_EliteCoreBlastDamage = 20000

ENT.zamb_EliteWallBlastRadius = 900 -- everything inside this gets hurt, cover or not

ENT.zamb_EliteFuseCancelDist = 500 -- a proximity fuse goes out once they've been this far past the arm distance, or out of sight,
ENT.zamb_EliteFuseCancelTime = 1.5 -- for this long
ENT.zamb_EliteFuseCommitFrac = 0.5 -- past this much of the fuse, it's going off

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_WALK]                       = ACT_HL2MP_WALK_ZOMBIE_06,
    [ACT_MP_RUN]                        = ACT_HL2MP_RUN_ZOMBIE_FAST,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_HL2MP_SWIM,
    [ACT_LAND]                          = ACT_LAND,
}
ENT.term_AnimsWithIdealSpeed = false

ENT.Term_FootstepTiming = "perfect"
ENT.PerfectFootsteps_FeetBones = { "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot" }
ENT.PerfectFootsteps_SteppingCriteria = -0.75
ENT.Term_FootstepSoundWalking = {
    {
        path = "npc/antlion_guard/foot_heavy1.wav",
        lvl = 80,
        pitch = math.random( 40, 60 ),
    },
    {
        path = "npc/antlion_guard/foot_light2.wav",
        lvl = 80,
        pitch = math.random( 40, 60 ),
    },
}
ENT.Term_FootstepSound = {
    { path = "NPC_Strider.Footstep", lvl = 78, pitch = 90 },
    { path = "NPC_Strider.Footstep", lvl = 78, pitch = 90 },
}
ENT.Term_FootstepShake = {
    amplitude = 2,
    frequency = 20,
    duration  = 0.35,
    radius    = 1500,
}

-- One way, nothing calms it back down.
function ENT:EliteEnrage()
    if self.zamb_EliteEnraged then return end
    self.zamb_EliteEnraged = true
    self:SetNW2Bool( "zamb_BoomerEnraged", true )

    self.zamb_LookAheadWhenRunning = true -- the sprint can't strafe
    self.RunSpeed = self.zamb_EliteEnragedRunSpeed
    self.AccelerationSpeed = self.zamb_EliteEnragedAccel
    self.DuelEnemyDist = self.zamb_EliteDuelEnemyDist
    self.JumpHeight = self.zamb_EliteJumpHeight

    self.FistDamageMul = 25
    self.FistRangeMul = 2
    self.zamb_MeleeAttackSpeed = 2
    self.zamb_MeleeAttackAdditionalDelay = -1

    for _, loop in ipairs( self.AngryLoopingSounds ) do
        self:StopSound( loop )

    end
    self.AngryLoopingSounds = { "npc/antlion_guard/confused1.wav" }

    self:Term_ClearStuffToSay()
    self:ZAMB_AngeringCall( true, 2 )
    self:ReallyAnger( 999 )
    self:EmitSound( "npc/antlion_guard/antlion_guard_die1.wav", 100, 80, 1, CHAN_STATIC )
    util.ScreenShake( self:GetPos(), 20, 20, 2, 2000, true )

    self:KillAllTasksWith( "movement" )
    self:StartTask( "movement_handler", "i've had enough" )
    self:RestartMotionCoroutine()

end

-- Enraged and up to speed, it sprints, leaps, and tramples.
-- Same speed it starts trampling at, so the sprint is what crushes.
function ENT:EliteIsSprinting()
    return self.zamb_EliteEnraged and self:GetCurrentSpeed() >= self.ChargeCrushDmgMinSpeed

end

-- Nothing primes, obliterates, or hurries it, it always goes off the same.
-- Hurt enough, the fuse lights wherever it is, and nothing puts it out.
function ENT:BoomerOnDamaged( dmg )
    -- the fuse's pops, it's still vulnerable, just not to itself
    if dmg:GetAttacker() == self and dmg:IsExplosionDamage() then return true end

    if self:Health() - dmg:GetDamage() < self:GetMaxHealth() * self.zamb_EliteDetonateFrac then
        self.zamb_EliteFuseLocked = true
        self:BoomerArm()

    end
end

-- They got away, so the proximity fuse goes out.
function ENT:EliteFuseCancelThink()
    local cur = CurTime()
    if self.IsSeeEnemy and self.DistToEnemy <= self:BoomerArmDistance() + self.zamb_EliteFuseCancelDist then
        self.zamb_EliteLastNearEnemy = cur
        return

    end

    if not self.zamb_BoomerArmed or self.zamb_EliteFuseLocked then return end
    if self:BoomerFuseFrac() >= self.zamb_EliteFuseCommitFrac then
        self.zamb_EliteFuseLocked = true
        return

    end
    if cur - ( self.zamb_EliteLastNearEnemy or cur ) < self.zamb_EliteFuseCancelTime then return end

    self:BoomerDisarm()
    self:EmitSound( "npc/antlion_guard/antlion_guard_pain1.wav", 95, 50, 1, CHAN_STATIC )

end

local POP_INTERVAL_START = 1 -- seconds between the fuse's pops, shrinking as it burns
local POP_INTERVAL_END = 0.1
local FINAL_CALL_LEAD = 4 -- seconds before the blast it calls the horde in
local FINAL_CALL_FORCE = 1
local RUMBLE_INTERVAL = 0.25

-- The base swells and shakes us, this adds pops and a rumble that grow as the fuse burns.
function ENT:BoomerFuseThink()
    BaseClass.BoomerFuseThink( self )
    if not self.zamb_BoomerArmed or self.zamb_BoomerBursting then return end

    local cur = CurTime()
    local frac = self:BoomerFuseFrac()
    local pos = self:WorldSpaceCenter()

    -- held until there's no wall between us, but never past FINAL_CALL_FORCE, and not at all with nobody to hold for
    local untilBlast = self.zamb_BoomerArmTime - cur
    local clear = self.NothingOrBreakableBetweenEnemy or not IsValid( self:GetEnemy() )
    if not self.zamb_EliteFinalCalled and untilBlast <= FINAL_CALL_LEAD and ( clear or untilBlast <= FINAL_CALL_FORCE ) then
        self.zamb_EliteFinalCalled = true
        self:ZAMB_AngeringCall( true )

    end

    if ( self.zamb_EliteNextRumble or 0 ) <= cur then
        self.zamb_EliteNextRumble = cur + RUMBLE_INTERVAL
        util.ScreenShake( pos, frac ^ 2 * 10, 30, RUMBLE_INTERVAL * 2, Lerp( frac, 600, 3000 ), true )

    end

    -- pops mean it's going off, so none while it could still put itself out
    if not self.zamb_EliteFuseLocked and frac < self.zamb_EliteFuseCommitFrac then return end
    if ( self.zamb_EliteNextPop or 0 ) > cur then return end
    self.zamb_EliteNextPop = cur + Lerp( frac, POP_INTERVAL_START, POP_INTERVAL_END )

    local popPos = terminator_Extras.GetRandomHitboxPoint( self )
    local explosion = ents.Create( "env_explosion" )
    explosion:SetPos( popPos )
    explosion:SetOwner( self )
    explosion:Spawn()
    explosion:SetKeyValue( "iMagnitude", math.Round( Lerp( frac, 25, 200 ) ) )
    explosion:Fire( "Explode", 0, 0 )

    util.ScreenShake( popPos, 5 + frac * 30, 20, 0.5, 1000 + frac * 2000, true )
    self:EmitSound( "npc/antlion_guard/antlion_guard_pain" .. math.random( 1, 2 ) .. ".wav", 90 + frac * 30, 60 - frac * 30, 1, CHAN_STATIC )

end

ENT.MyClassTask = {
    -- not Think, a driver's detonation is theirs to keep
    BehaveUpdatePriority = function( self, _data )
        self:EliteFuseCancelThink()
        if not self.IsSeeEnemy then return end
        self:EliteEnrage()

    end,
    -- gallops until it's built up speed, then breaks into the sprint
    TranslateActivity = function( self, _data, act )
        if act ~= ACT_MP_RUN then return end
        if not self:EliteIsSprinting() then return end
        return ACT_HL2MP_RUN_FAST

    end,
}

function ENT:BoomerBlastFX( pos )
    local filterAllPlayers = RecipientFilter()
    filterAllPlayers:AddAllPlayers()

    local ed = EffectData()
    ed:SetOrigin( pos )
    ed:SetRadius( self.zamb_EliteBlastRadius )
    ed:SetMagnitude( 3.4 )
    util.Effect( "eff_boomer_blast", ed, true, filterAllPlayers )

    local splode = EffectData()
    splode:SetOrigin( pos )
    splode:SetNormal( vector_up )
    splode:SetScale( 8 )
    util.Effect( "huge_m9k_yoinked_splode", splode, true, filterAllPlayers )

    local shock = EffectData()
    shock:SetOrigin( pos )
    shock:SetScale( 3 )
    util.Effect( "m9k_yoinked_shockwave", shock, true, filterAllPlayers )

    util.ScreenShake( pos, 100, 50, 5, self.zamb_EliteBlastRadius * 5, true )
    self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 120, 50, 1, CHAN_STATIC, SND_NOFLAGS, 0, filterAllPlayers )
    self:EmitSound( "explode_9", 150, 80, 1, CHAN_STATIC, SND_NOFLAGS, 0, filterAllPlayers )

end

-- One big blast, no crabs.
function ENT:BoomerBlast( pos )
    util.BlastDamage( self, self, pos, self.zamb_EliteBlastRadius, self.zamb_EliteBlastDamage )
    util.BlastDamage( self, self, pos, self.zamb_EliteCoreBlastRadius, self.zamb_EliteCoreBlastDamage )
    self:EliteWallBlast( pos )

end

local WALL_BLAST_FALLOFF = 1.25 -- higher keeps the edge of the radius gentle and the middle lethal

-- BlastDamage stops at cover, this doesn't.
-- Everything in range takes at least 1, rising sharply toward the middle.
function ENT:EliteWallBlast( pos )
    local radius = self.zamb_EliteWallBlastRadius

    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self or ent:Health() <= 0 then continue end

        local center = ent:WorldSpaceCenter()
        local closeness = math.max( 0, 1 - pos:Distance( center ) / radius )

        local dmg = DamageInfo()
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetDamageType( DMG_BLAST )
        dmg:SetDamagePosition( center )
        dmg:SetDamageForce( ( center - pos ):GetNormalized() * 50000 )
        dmg:SetDamage( math.max( 1, self.zamb_EliteBlastDamage * closeness ^ WALL_BLAST_FALLOFF ) )
        ent:TakeDamageInfo( dmg )

    end
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self.HasBrains = true
    self.term_SoundPitchShift = -40
    self.term_SoundLevelShift = 20

    self.HeightToStartTakingDamage = 600
    self.DeathDropHeight = 3000
    self.CanUseLadders = false

end

function ENT:canDoRun()
    if self.IsSeeEnemy then return true end

    return BaseClass.canDoRun( self )

end


function ENT:shouldDoWalk()
    if self.IsSeeEnemy then return false end

    return BaseClass.shouldDoWalk( self )

end
