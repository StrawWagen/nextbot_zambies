AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Fast Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiefastgrunt", {
    Name = "Zombie Fast Elite",
    Class = "terminator_nextbot_zambiefastgrunt",
    Category = "Nexbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiefastgrunt", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.7, 0.7, 0.4 )
        self:DrawModel()

    end
    return

end

ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 450
ENT.SpawnHealth = 175
ENT.AimSpeed = 400
ENT.WalkSpeed = 90
ENT.MoveSpeed = 250
ENT.RunSpeed = 650
ENT.AccelerationSpeed = 500

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 2.5

ENT.FistDamageMul = 0.65

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.15, 1.25 ) end
ENT.MyPhysicsMass = 85

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Models = { FAST_ZAMBIE_MODEL }

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = math.random( 1, 100 ) < 85
    terminator_Extras.RegisterListener( self )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = -15
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "npc/fast_zombie/fz_alert_close1.wav"
    self.term_AttackSound = { "npc/fast_zombie/fz_scream1.wav", "npc/fast_zombie/fz_frenzy1.wav" }
    self.term_AngerSound = "npc/fast_zombie/fz_alert_close1.wav"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {
        "npc/fast_zombie/breathe_loop1.wav",

    }
    self.AngryLoopingSounds = {
        "npc/fast_zombie/gurgle_loop1.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

end

function ENT:OnFootstep( _pos, _foot, _sound, volume, _filter )
    local lvl = 88
    local snd = "npc/fast_zombie/foot" .. math.random( 1, 4 ) .. ".wav"
    local moveSpeed = self:GetVelocity():Length()
    if moveSpeed <= self.WalkSpeed then
        lvl = 80

    elseif moveSpeed > self.RunSpeed * 0.5 then
        local speedNormalized = moveSpeed / self.RunSpeed
        local secPit = math.random( 45, 55 ) + speedNormalized * 50
        local secSnd = "npc/antlion/foot" .. math.random( 1, 4 ) .. ".wav"
        local secVolume = ( speedNormalized * 0.5 ) ^ 1.1
        self:EmitSound( secSnd, lvl, secPit, secVolume, CHAN_STATIC )
        util.ScreenShake( self:GetPos(), 1 + speedNormalized * 2, 20, 0.15, 200 + moveSpeed )

    end
    self:EmitSound( snd, lvl, 80, volume + 1, CHAN_STATIC )
    return true

end