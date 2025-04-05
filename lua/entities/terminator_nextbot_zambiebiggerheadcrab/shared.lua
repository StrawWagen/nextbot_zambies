AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiebigheadcrab"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "The God Crab"
ENT.Spawnable = false
ENT.AdminOnly = true
list.Set( "NPC", "terminator_nextbot_zambiebiggerheadcrab", {
    Name = "The God Crab",
    Class = "terminator_nextbot_zambiebiggerheadcrab",
    Category = "Nextbot Zambies",
    AdminOnly = true,
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiebiggerheadcrab", ENT.PrintName )

    return
end

ENT.JumpHeight = 3000
ENT.DefaultStepHeight = 50
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.PathGoalToleranceFinal = 175
ENT.SpawnHealth = 50000
ENT.ExtraSpawnHealthPerPlayer = 5000
ENT.HealthRegen = 8
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 300
ENT.CrouchSpeed = 575
ENT.WalkSpeed = 600
ENT.MoveSpeed = 1000
ENT.RunSpeed = 3000
ENT.AccelerationSpeed = 750

ENT.zamb_MeleeAttackSpeed = 2
ENT.zamb_MeleeAttackHitFrameMul = 40
ENT.zamb_AttackAnim = ACT_RANGE_ATTACK1

ENT.FistDamageMul = 40
ENT.FistForceMul = 40
ENT.FistRangeMul = 5
ENT.DuelEnemyDist = 1250

local GOD_CRAB_MODEL = "models/headcrab.mdl"
ENT.ARNOLD_MODEL = GOD_CRAB_MODEL
ENT.TERM_MODELSCALE = 8
ENT.CollisionBounds = { Vector( -1, -1, 0 ), Vector( 1, 1, 2 ) }
ENT.CrouchCollisionBounds = { Vector( -0.75, -0.75, 0 ), Vector( 0.75, 0.75, 1.75 ) }
ENT.MyPhysicsMass = 15000

ENT.Term_BaseTimeBetweenSteps = 1100
ENT.Term_StepSoundTimeMul = 1.05

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

    self.term_SoundPitchShift = -45
    self.term_SoundLevelShift = 25

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

    self.DeathDropHeight = 30000
    self.TakesFallDamage = false
    self.CanUseLadders = false

    self.zamb_LoseCoolRatio = 1
    self.ZAMBIE_MINIONS = {}
    self.zamb_NextMinionCheck = CurTime() + 10

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( pos, _foot, _sound, volume, _filter )
    local lvl = 83
    local snd = "NPC_Strider.Footstep"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    util.ScreenShake( pos, lvl / 10, 20, 0.5, 500 )
    util.ScreenShake( pos, lvl / 40, 5, 1.5, 1500 )
    return true

end

function ENT:ZAMB_AngeringCall()
    BaseClass.ZAMB_AngeringCall( self )
    util.ScreenShake( self:GetPos(), 40, 10, 6, 1800, true )
    util.ScreenShake( self:GetPos(), 5, 5, 10, 5000 )

end


local screamsOfTheDamned = {
    "vo/npc/male01/pain07.wav",
    "vo/npc/male01/pain08.wav",
    "vo/npc/male01/pain09.wav",
    "vo/npc/male01/runforyourlife01.wav",
    "vo/npc/male01/runforyourlife02.wav",
    "vo/npc/male01/runforyourlife03.wav",
    "vo/npc/male01/strider_run.wav",
    "vo/npc/male01/takecover02.wav",
    "vo/npc/male01/overthere01.wav",
    "vo/npc/male01/overthere02.wav",
    "vo/npc/male01/no02.wav",
    "vo/npc/male01/no01.wav",

}

function ENT:AdditionalThink( myTbl )
    BaseClass.AdditionalThink( self, myTbl )
    local cur = CurTime()
    local nextForced = myTbl.hugeHeadcrabForceScream or 0

    if math.Rand( 0, 100 ) > 3 and nextForced > cur then return end
    myTbl.hugeHeadcrabForceScream = cur + math.Rand( 3, 5 )

    self:EmitSound( screamsOfTheDamned[math.random( 1, #screamsOfTheDamned )], 64 + myTbl.term_SoundLevelShift, math.random( 90, 110 ) + myTbl.term_SoundPitchShift, 1, CHAN_STATIC )

end