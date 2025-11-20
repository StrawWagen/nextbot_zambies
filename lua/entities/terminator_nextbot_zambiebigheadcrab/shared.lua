AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambienecro"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Demigod Crab"
ENT.Spawnable = false
ENT.AdminOnly = true
list.Set( "NPC", "terminator_nextbot_zambiebigheadcrab", {
    Name = "Demigod Crab",
    Class = "terminator_nextbot_zambiebigheadcrab",
    Category = "Nextbot Zambies",
    AdminOnly = true,
} )

ENT.IsEldritch = true -- GLEE

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Release your spawn.", -- diff name
        ratelimit = 8, -- seconds between uses
        svAction = function( _drive, _driver, bot )
            bot:NECRO_TrySpawnMinions( true )

        end,
    }
}

if CLIENT then
    language.Add( "terminator_nextbot_zambiebigheadcrab", ENT.PrintName )

    return
end

ENT.IsFodder = false
ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 2

ENT.JumpHeight = 500
ENT.Term_Leaps = true
ENT.DefaultStepHeight = 25
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.PathGoalToleranceFinal = 75
ENT.SpawnHealth = 5000
ENT.ExtraSpawnHealthPerPlayer = 2000
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.CrouchSpeed = 300
ENT.WalkSpeed = 400
ENT.MoveSpeed = 600
ENT.RunSpeed = 1800
ENT.AccelerationSpeed = 550
ENT.DeccelerationSpeed = 2500
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 2
ENT.zamb_MeleeAttackHitFrameMul = 40
ENT.zamb_AttackAnim = ACT_RANGE_ATTACK1

ENT.FistDamageMul = 20
ENT.FistForceMul = 20
ENT.FistRangeMul = 2
ENT.FistDamageType = bit.bor( DMG_SLASH, DMG_CLUB, DMG_GENERIC )
ENT.DuelEnemyDist = 800
ENT.PrefersVehicleEnemies = true

local GOD_CRAB_MODEL = "models/headcrab.mdl"
ENT.ARNOLD_MODEL = GOD_CRAB_MODEL
ENT.TERM_MODELSCALE = 4
ENT.CollisionBounds = { Vector( -3, -3, 0 ), Vector( 3, 3, 5 ) }
ENT.CrouchCollisionBounds = { Vector( -1.5, -1.5, 0 ), Vector( 1.5, 1.5, 4.9 ) }
ENT.MyPhysicsMass = 5000
ENT.ReallyHeavy = true

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Term_BaseMsBetweenSteps = 800
ENT.Term_FootstepMsReductionPerUnitSpeed = 1.05


ENT.Models = { GOD_CRAB_MODEL }

local IdleActivity = "LookAround"
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE,
    [ACT_MP_WALK]                       = ACT_RUN,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_IDLE,
    [ACT_MP_CROUCHWALK]                 = ACT_RUN,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_MP_JUMP_START]                 = ACT_RANGE_ATTACK1,
    [ACT_MP_SWIM]                       = ACT_RUN,
    [ACT_LAND]                          = "ceiling_land",
}

ENT.zamb_CallAnim = "rearup"

function ENT:canDoRun()
    local lostCool = self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio
    if self.EnemiesVehicle or lostCool then
        if lostCool and not self.LostCoolCall then
            self:Term_ClearStuffToSay()
            self:ZAMB_AngeringCall()
            self.LostCoolCall = true

        end
        if self.EnemiesVehicle then
            return true

        end
        return BaseClass.canDoRun( self )

    else
        return false

    end
end

function ENT:shouldDoWalk()
    if self.EnemiesVehicle or self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio then
        return BaseClass.shouldDoWalk( self )

    else
        return true

    end
end

-- dont care about body smell
function ENT:AdditionalAvoidAreas()
end

-- launch stuff towards our enemy!
function ENT:PostHitObject( hit )
    local enemy = self:GetEnemy()
    if IsValid( hit ) and IsValid( enemy ) then
        local hitsObj = hit:GetPhysicsObject()
        if not IsValid( hitsObj ) then return end

        local force = terminator_Extras.dirToPos( self:GetShootPos(), enemy:WorldSpaceCenter() )
        force = force * 500
        force = force * hitsObj:GetMass()
        hitsObj:ApplyForceOffset( force, self:GetShootPos() )

    end
end

function ENT:AdditionalInitialize()
    self:SetModel( GOD_CRAB_MODEL )

    --[[
    for ind = 1, self:GetSequenceCount() do
        local inf = self:GetSequenceInfo( ind )
        if inf then
            PrintTable( inf )

        end
        print( "-----" )

    end--]]

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -35
    self.term_SoundLevelShift = 20

    self.term_LoseEnemySound = "NPC_AntlionGuard.Anger"
    self.term_CallingSound = "npc/stalker/go_alert2a.wav"
    self.term_CallingSmallSound = "npc/stalker/go_alert2.wav"
    self.term_FindEnemySound = "NPC_AntlionGuard.Anger"
    self.term_AttackSound = { "NPC_AntlionGuard.Roar" }
    self.term_AngerSound = "NPC_AntlionGuard.Anger"
    self.term_DamagedSound = { "npc/antlion_guard/antlion_guard_pain1.wav", "npc/antlion_guard/antlion_guard_pain2.wav" }
    self.term_DieSound = "NPC_AntlionGuard.Die"
    self.term_JumpSound = "npc/zombie_poison/pz_left_foot1.wav"
    self.IdleLoopingSounds = {
        "NPC_AntlionGuard.GrowlHigh",

    }
    self.AngryLoopingSounds = {
        "NPC_AntlionGuard.Confused",
    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 3000
    self.CanUseLadders = false

    self.zamb_LoseCoolRatio = 0.5
    self.ZAMBIE_MINIONS = {}
    self.zamb_NextMinionCheck = CurTime() + 10

    self.necro_MinionsWasteAway = false

    self.necro_MinionCountMul = 1
    self.necro_MinMinionCount = 0
    self.necro_MaxMinionCount = 12
    self.necro_NormalMinionClass = {
        "terminator_nextbot_zambiecrabbaby",

    }

    self.necro_ReachableFastMinionChance = 0
    self.necro_UnReachableFastMinionChance = 0
    self.necro_UnreachableCountAdd = 0

    self.necro_NearDeathClassChance = 0

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:AdditionalFootstep( pos, foot, _sound, volume, _filter )
    local lvl = 83
    local snd = foot and "NPC_AntlionGuard.StepLight" or "NPC_AntlionGuard.StepHeavy"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    util.ScreenShake( pos, lvl / 10, 20, 0.5, 500 )
    util.ScreenShake( pos, lvl / 40, 5, 1.5, 1500 )
    return true

end