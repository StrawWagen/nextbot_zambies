AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Wraith"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiewraith", {
    Name = "Zombie Wraith",
    Class = "terminator_nextbot_zambiewraith",
    Category = "Nexbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiewraith", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.0005
ENT.MaxPathingIterations = 25000

ENT.JumpHeight = 600
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 50
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 100
ENT.MoveSpeed = 300
ENT.RunSpeed = 450
ENT.AccelerationSpeed = 350

ENT.zamb_AlwaysFlank = true
ENT.zamb_LookAheadWhenRunning = true -- turn this on since we do big bursts of damage unlike the normal fast z
ENT.zamb_MeleeAttackSpeed = 1

ENT.neverManiac = true

ENT.FistDamageMul = 3
ENT.FistRangeMul = 1.5
ENT.DuelEnemyDist = 450

local FAST_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = FAST_ZAMBIE_MODEL

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { FAST_ZAMBIE_MODEL }
ENT.TERM_MODELSCALE = function() return math.Rand( 0.95, 1 ) end
ENT.MyPhysicsMass = 70
ENT.NoAnimLayering = true

ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE_ANGRY,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_RUN,
    [ACT_MP_CROUCHWALK]                 = ACT_RUN,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = ACT_MELEE_ATTACK1,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = ACT_MELEE_ATTACK1,
    [ACT_MP_RELOAD_STAND]               = ACT_INVALID,
    [ACT_MP_RELOAD_CROUCH]              = ACT_INVALID,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = "BR2_Roar"
ENT.zamb_AttackAnim = "BR2_Attack"

function ENT:AdditionalInitialize()
    self:SetModel( FAST_ZAMBIE_MODEL )
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/combine_advisor/body9" )

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
    terminator_Extras.RegisterListener( self )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = 10
    self.term_SoundLevelShift = -10

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "NPC_FastZombie.Attack" }
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {
        "ambient/levels/citadel/citadel_ambient_voices1.wav",

    }
    self.AngryLoopingSounds = {
        "ambient/levels/citadel/citadel_ambient_scream_loop1.wav",

    }

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.015
    self.DeathDropHeight = 1500
    self.zambwraith_InvisGraceMul = 1

end

function ENT:CloakedMatFlicker()
    self:SetMaterial( "effects/combineshield/comshieldwall3" )
    self:SetRenderMode( RENDERMODE_NORMAL ) -- cfc ji defense compatibility
    timer.Simple( math.Rand( 0.25, 0.75 ), function()
        if not IsValid( self ) then return end
        if self:IsSolid() then return end
        self:SetRenderMode( RENDERMODE_TRANSALPHA )
        self:RemoveAllDecals() -- evil
        self:SetMaterial( "effects/combineshield/comshieldwall" )


    end )
end

function ENT:DoHiding( hide )
    local oldHide = not self:IsSolid()
    if hide == oldHide then return end
    local nextSwap = self.zamb_NextHidingSwap or 0
    if nextSwap > CurTime() then return end

    if hide then
        self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        self:SetSolidMask( MASK_NPCSOLID_BRUSHONLY )
        self:DrawShadow( false )
        self:AddFlags( FL_NOTARGET )
        self:SetNotSolid( true )
        self:EmitSound( "ambient/levels/citadel/pod_open1.wav", 74, math.random( 115, 125 ) )
        self.zamb_NextHidingSwap = CurTime() + math.Rand( 0.25, 0.75 )

        self:CloakedMatFlicker()

    else
        self:CloakedMatFlicker()
        self.zamb_NextHidingSwap = CurTime() + 0.25
        timer.Simple( 0.25 * self.zambwraith_InvisGraceMul, function()
            if not IsValid( self ) then return end
            self:SetCollisionGroup( COLLISION_GROUP_NPC )
            self:SetSolidMask( MASK_NPCSOLID )
            self:DrawShadow( true )
            self:SetMaterial( "" )
            self:RemoveFlags( FL_NOTARGET )
            self:SetNotSolid( false )
            self:EmitSound( "ambient/levels/citadel/pod_close1.wav", 74, math.random( 115, 125 ) )
            self:EmitSound( "buttons/combine_button_locked.wav", 76, 50 )
            self:Term_SpeakSoundNow( { "NPC_FastZombie.Frenzy", "NPC_FastZombie.Scream" } )
            self:SetRenderMode( RENDERMODE_NORMAL ) -- cfc jid
            self.zamb_NextHidingSwap = CurTime() + ( math.Rand( 2.5, 3.5 ) * self.zambwraith_InvisGraceMul )

        end )
    end

end

function ENT:AdditionalThink()
    local doHide = not self:IsGestureActive() and IsValid( self:GetEnemy() ) and not IsValid( self:GetGroundEntity() ) -- we cant stand on props!
    local enemDist = self.DistToEnemy
    local allyCount = #self:GetNearbyAllies()
    if doHide and self.IsSeeEnemy and math.random( 0, allyCount * 20 ) < 1 and allyCount >= 1 then
        if enemDist < 2500 and enemDist > 800 and not self:IsReallyAngry() and not self.zamb_CantCall then
            self:ZAMB_AngeringCall()
            self:ReallyAnger( 45 )
            doHide = false

        elseif self:IsReallyAngry() then
            if enemDist < 250 then
                doHide = false

            end
        elseif enemDist < 450 then
            doHide = false

        end
    elseif doHide and enemDist < 250 then
        doHide = false

    end

    self:DoHiding( doHide )

    if not self:IsSolid() and math.Rand( 0, 100 ) < 0.5 then
        self:CloakedMatFlicker()

    end
end

function ENT:IsImmuneToDmg( dmg )
    if not self:IsSolid() then
        dmg:ScaleDamage( 0.1 )

    end
end

function ENT:AdditionalOnKilled()
    self:DoHiding( false )

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( pos, foot, sound, volume, filter )
    local lvl
    local snd
    if self:IsSolid() then
        lvl = 85
        if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
            lvl = 76

        end
        snd = foot and "NPC_FastZombie.GallopRight" or "NPC_FastZombie.GallopLeft"

    else
        lvl = 72
        snd = "NPC_FastHeadcrab.Footstep"

    end
    self:EmitSound( snd, lvl, 100, volume + 1, CHAN_STATIC, sndFlags )
    return true

end