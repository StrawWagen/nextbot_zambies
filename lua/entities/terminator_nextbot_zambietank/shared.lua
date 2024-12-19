AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Tank"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambietank", {
    Name = "Zombie Tank",
    Class = "terminator_nextbot_zambietank",
    Category = "Nexbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambietank", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.65, 0.65, 0.4 )
        self:DrawModel()

    end

    return
end

ENT.CoroutineThresh = 0.0004

ENT.JumpHeight = 80
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 5000
ENT.ExtraSpawnHealthPerPlayer = 1000
ENT.AimSpeed = 400
ENT.WalkSpeed = 60
ENT.MoveSpeed = 80
ENT.RunSpeed = 120
ENT.AccelerationSpeed = 1500
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = nil
ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 12
ENT.FistForceMul = 12
ENT.DuelEnemyDist = 350

local TANK_ZAMBIE_MODEL = "models/player/zombine/combine_zombie.mdl"
ENT.ARNOLD_MODEL = TANK_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.35

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Term_BaseTimeBetweenSteps = 400
ENT.Term_StepSoundTimeMul = 1.05


ENT.Models = { TANK_ZAMBIE_MODEL }

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_RUN]                        = ACT_HL2MP_WALK_ZOMBIE_02,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity+5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity+5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity+6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity+7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = IdleActivity+9,
    [ACT_LAND]                          = ACT_LAND,
}

function ENT:OnKilledGenericEnemyLine( enemyLost )
end

-- tanks dont care about body smell
function ENT:AdditionalAvoidAreas()
end

function ENT:canDoRun()
    if self:Health() < self:GetMaxHealth() * 0.5 then
        return BaseClass.canDoRun( self )

    else
        return false

    end
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
    self:SetModel( TANK_ZAMBIE_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true
    terminator_Extras.RegisterListener( self )

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -30
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "NPC_PoisonZombie.Idle"
    self.term_CallingSound = "npc/zombie_poison/pz_call1.wav"
    self.term_CallingSmallSound = "npc/zombie_poison/pz_throw3.wav"
    self.term_FindEnemySound = "NPC_PoisonZombie.Alert"
    self.term_AttackSound = { "NPC_PoisonZombie.Attack" }
    self.term_AngerSound = "NPC_PoisonZombie.AlertNear"
    self.term_DamagedSound = "NPC_PoisonZombie.Pain"
    self.term_DieSound = "NPC_PoisonZombie.Die"
    self.term_JumpSound = "npc/zombie_poison/pz_left_foot1.wav"
    self.IdleLoopingSounds = {
        "NPC_AntlionGuard.GrowlIdle",

    }
    self.AngryLoopingSounds = {
        "npc/zombie_poison/pz_breathe_loop2.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1500
    self.CanUseLadders = false

    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/antlion/antlionhigh_sheet" )

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( pos, foot, sound, volume, filter )
    local lvl = 83
    local snd = foot and "npc/antlion_guard/foot_heavy1.wav" or "npc/antlion_guard/foot_light2.wav"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

-- does not flinch
function ENT:HandleFlinching()
end