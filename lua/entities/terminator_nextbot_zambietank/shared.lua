AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Tank"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambietank", {
    Name = "Zombie Tank",
    Class = "terminator_nextbot_zambietank",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambietank", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.65, 0.65, 0.4 )
        self:DrawModel()

    end

    return
end

ENT.CoroutineThresh = 0.00008

ENT.JumpHeight = 80
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 8000
ENT.ExtraSpawnHealthPerPlayer = 500
ENT.AimSpeed = 400
ENT.WalkSpeed = 60
ENT.MoveSpeed = 350
ENT.RunSpeed = 750
ENT.AccelerationSpeed = 1000
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = nil
ENT.zamb_MeleeAttackSpeed = 1
ENT.zamb_MeleeAttackHitFrameMul = 1.25
ENT.zamb_AttackAnim = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL -- ACT_RANGE_ATTACK1

ENT.FistDamageMul = 15
ENT.FistForceMul = 12
ENT.FistDamageType = bit.bor( DMG_SLASH, DMG_CLUB, DMG_GENERIC )
ENT.DuelEnemyDist = 600
ENT.PrefersVehicleEnemies = true

local TANK_ZAMBIE_MODEL = "models/player/zombine/combine_zombie.mdl"
ENT.ARNOLD_MODEL = TANK_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds = { Vector( -10, -10, 0 ), Vector( 10, 10, 35 ) }
ENT.MyPhysicsMass = 2500

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Term_BaseMsBetweenSteps = 400
ENT.Term_FootstepMsReductionPerUnitSpeed = 1.05


ENT.Models = { TANK_ZAMBIE_MODEL }
ENT.term_AnimsWithIdealSpeed = true

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

-- tanks dont care about body smell
function ENT:AdditionalAvoidAreas()
end

function ENT:canDoRun()
    if self:Health() < self:GetMaxHealth() * ( self.zamb_LoseCoolRatio / 2 ) and not self.zamb_HasArmor then
        return BaseClass.canDoRun( self )

    else
        return false

    end
end

function ENT:shouldDoWalk()
    if self.EnemiesVehicle or self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio and not self.zamb_HasArmor then
        return BaseClass.shouldDoWalk( self )

    else
        return true

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
    self.HasBrains = false

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = 0

    self.term_SoundPitchShift = -45
    self.term_SoundLevelShift = 20

    self.term_LoseEnemySound = "NPC_PoisonZombie.Idle"
    self.term_CallingSound = "npc/zombie_poison/pz_call1.wav"
    self.term_CallingSmallSound = "npc/zombie_poison/pz_throw3.wav"
    self.term_FindEnemySound = "NPC_PoisonZombie.Alert"
    self.term_AttackSound = { "NPC_PoisonZombie.Attack" }
    self.term_AngerSound = "NPC_PoisonZombie.Alert"
    self.term_DamagedSound = "NPC_PoisonZombie.Pain"
    self.term_DieSound = "NPC_AntlionGuard.Die"
    self.term_JumpSound = "npc/zombie_poison/pz_left_foot1.wav"
    self.IdleLoopingSounds = {
        "npc/zombie_poison/pz_breathe_loop2.wav",

    }
    self.AngryLoopingSounds = {
        "npc/antlion_guard/growl_idle.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1500
    self.CanUseLadders = false

    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/antlion/antlionhigh_sheet" )
    self.zamb_HasArmor = true
    self.zamb_LoseCoolRatio = 0.75
    self.zamb_UnderArmorMat = "models/flesh"

end

function ENT:BreakArmor()

    self.zamb_HasArmor = nil
    self:SetSubMaterial( 0, self.zamb_UnderArmorMat )
    self:Term_ClearStuffToSay()
    self:ZAMB_AngeringCall( true )
    self:ReallyAnger( 60 )
    self.Term_BaseMsBetweenSteps = 400
    self.Term_FootstepMsReductionPerUnitSpeed = 0.6


    self.JumpHeight = 300
    self.UnreachableAreas = {}
    self.FistRangeMul = 2

    self.zamb_LookAheadWhenRunning = true
    self.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE_FAST

    self:StopSound( self.AngryLoopingSounds[1] )
    self.AccelerationSpeed = 350
    self.loco:SetAcceleration( self.AccelerationSpeed )

    self.AlwaysPlayLooping = true
    self.AngryLoopingSounds = { -- berserker sound
        "npc/antlion_guard/confused1.wav",

    }

    local timerName = "zamb_crackedarmor" .. self:GetCreationID()
    local done = 0
    timer.Create( timerName, 0.01, 30, function()
        if not IsValid( self ) then return end
        if math.random( 0, 100 ) < done then return end
        done = done + 1
        self:EmitSound( "npc/antlion_guard/antlion_guard_shellcrack" .. math.random( 1, 2 ) .. ".wav", math.random( 75, 79 ) + done, math.random( 80, 90 ) - done )

    end )
end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl = 83
    local snd = foot and "npc/antlion_guard/foot_heavy1.wav" or "npc/antlion_guard/foot_light2.wav"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    return true

end

function ENT:IsImmuneToDmg( dmg )
    if not self.zamb_HasArmor then return end
    if dmg:GetDamage() <= math.Rand( 5, 12 ) then
        self:SetBloodColor( DONT_BLEED )
        self:EmitSound( "npc/antlion/shell_impact" .. math.random( 1, 4 ) .. ".wav", math.random( 75, 79 ), math.random( 120, 140 ), 1, CHAN_ITEM )
        return true

    end
end

function ENT:PostTookDamage( dmg )
    if self.zamb_HasArmor then
        if self:Health() <= self:GetMaxHealth() * self.zamb_LoseCoolRatio then
            self:BreakArmor()

        else
            dmg:ScaleDamage( 0.75 )
            self:SetBloodColor( BLOOD_COLOR_ANTLION )
            self:EmitSound( "npc/antlion_guard/antlion_guard_shellcrack" .. math.random( 1, 2 ) .. ".wav", math.random( 75, 79 ), math.random( 90, 110 ), 1, CHAN_ITEM )

        end
    else
        self:SetBloodColor( BLOOD_COLOR_ZOMBIE )

    end
    BaseClass.PostTookDamage( self, dmg )

end