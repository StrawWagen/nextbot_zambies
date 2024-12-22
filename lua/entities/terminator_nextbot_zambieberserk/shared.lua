AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Berserker"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieberserk", {
    Name = "Zombie Berserker",
    Class = "terminator_nextbot_zambieberserk",
    Category = "Nexbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambieberserk", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.0004
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 300
ENT.SpawnHealth = 1125
ENT.ExtraSpawnHealthPerPlayer = 50
ENT.HealthRegen = 1
ENT.HealthRegenInterval = 0.75
ENT.WalkSpeed = 50
ENT.MoveSpeed = 150
ENT.RunSpeed = 600
ENT.calm_AccelerationSpeed = 150
ENT.grumpy_AccelerationSpeed = 250
ENT.angry_AccelerationSpeed = 1000
ENT.AccelerationSpeed = ENT.calm_AccelerationSpeed

ENT.CanUseStuff = true

ENT.zamb_LookAheadWhenRunning = true -- running anim doesnt support different move/look angles

ENT.FistDamageMul = 3
ENT.zamb_MeleeAttackSpeed = 2
ENT.DuelEnemyDist = 350
ENT.CloseEnemyDistance = 500

ENT.Term_BaseTimeBetweenSteps = 400
ENT.Term_StepSoundTimeMul = 1.05

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

local GRUNT_MODEL = "models/player/zombine/combine_zombie.mdl"
ENT.ARNOLD_MODEL = GRUNT_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.1, 1.15 ) end
ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 55 ) } -- this is then scaled by modelscale

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Models = { GRUNT_MODEL }
ENT.term_AnimsWithIdealSpeed = true

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_HL2MP_WALK_ZOMBIE_06,
    [ACT_MP_RUN]                        = ACT_HL2MP_RUN_ZOMBIE_FAST,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = IdleActivity + 9,
    [ACT_LAND]                          = ACT_LAND,
}

function ENT:AdditionalInitialize()
    self:SetBloodColor( BLOOD_COLOR_ZOMBIE )
    self:SetModel( GRUNT_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = math.random( 0, 100 ) < 50
    terminator_Extras.RegisterListener( self )

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = -35
    self.term_SoundLevelShift = 20

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
    self.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
    self.term_FindEnemySound = "npc/fast_zombie/fz_alert_close1.wav"
    self.term_AttackSound = { "npc/fast_zombie/fz_scream1.wav", "npc/fast_zombie/fz_frenzy1.wav" }
    self.term_AngerSound = { "npc/fast_zombie/fz_scream1.wav", "npc/fast_zombie/fz_frenzy1.wav" }
    self.term_DamagedSound = "Zombie.Pain"
    self.term_DieSound = "npc/antlion_guard/antlion_guard_die2.wav"
    self.term_JumpSound = "npc/zombie/foot1.wav"
    self.IdleLoopingSounds = {
        "npc/antlion_guard/growl_high.wav",

    }
    self.AngryLoopingSounds = {
        "npc/antlion_guard/confused1.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

    self:SetSubMaterial( 0, "models/flesh" )

end

function ENT:AdditionalThink()
    local health = self:Health()
    local maxHealth = self:GetMaxHealth()
    local ideal = self.calm_AccelerationSpeed
    if health < maxHealth * 0.3 then
        ideal = self.angry_AccelerationSpeed
        self.HasBrains = true

    elseif health < maxHealth * 0.75 then
        ideal = self.grumpy_AccelerationSpeed

    end
    if self.AccelerationSpeed ~= ideal then
        self.AccelerationSpeed = ideal
        self.loco:SetAcceleration( self.AccelerationSpeed )

    end
end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( pos, foot, sound, volume, filter )
    local lvl = 77
    local pit = math.random( 75, 85 )
    local snd = foot and "NPC_AntlionGuard.StepHeavy" or "NPC_AntlionGuard.StepLight"
    local moveSpeed = self:GetVelocity():Length()
    if moveSpeed <= self.WalkSpeed * 1.15 then
        lvl = 76
        pit = math.random( 90, 100 )
        snd = foot and "npc/zombie_poison/pz_left_foot1.wav" or "npc/zombie_poison/pz_right_foot1.wav"

    else
        util.ScreenShake( self:GetPos(), 1, 20, 0.15, 200 + moveSpeed )

    end
    self:EmitSound( snd, lvl, pit, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

local HEAD = 1

-- does not flinch
function ENT:HandleFlinching( dmg, hitGroup )
    if hitGroup == HEAD then
        BaseClass.HandleFlinching( self, dmg, hitGroup )
    end
end