AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiebigheadcrab"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "One Fear"
ENT.Spawnable = true
ENT.AdminOnly = false

list.Set( "NPC", "terminator_nextbot_zambieonefear", {
    Name      = "One Fear",
    Class     = "terminator_nextbot_zambieonefear",
    Category  = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieonefear", ENT.PrintName )
    return
end

local FEAR_MODEL = "models/headcrab.mdl"
local BREATH_SND = "npc/fast_zombie/breathe_loop1.wav"

local FEAR_MATERIALS = {
    "models/zombie_fast/fast_zombie_sheet",
    "models/flesh",
    "models/gibs/hgibs/spine",
}

ENT.IsFodder    = false

ENT.SpawnHealth               = 1000
ENT.ExtraSpawnHealthPerPlayer = 0

ENT.JumpHeight        = 300
ENT.Term_Leaps        = true
ENT.WalkSpeed         = 220
ENT.MoveSpeed         = 350
ENT.RunSpeed          = 700
ENT.AccelerationSpeed = 400
ENT.DeccelerationSpeed = 1800

ENT.TERM_MODELSCALE       = 3
ENT.CollisionBounds       = { Vector( -4, -4, 0 ), Vector( 4, 4, 7 ) }
ENT.CrouchCollisionBounds = { Vector( -3, -3, 0 ), Vector( 3, 3, 4 ) }

ENT.FistDamageMul  = 1
ENT.FistForceMul   = 3
ENT.FistRangeMul   = 1.2
ENT.FistDamageType = bit.bor( DMG_SLASH, DMG_GENERIC )

ENT.zamb_MeleeAttackSpeed       = 1.8
ENT.zamb_MeleeAttackHitFrameMul = 30
ENT.zamb_AttackAnim             = ACT_RANGE_ATTACK1

ENT.ARNOLD_MODEL = FEAR_MODEL
ENT.Models       = { FEAR_MODEL }

ENT.necro_MaxMinionCount    = 0
ENT.necro_MinMinionCount    = 0
ENT.necro_NormalMinionClass = {}

local IdleActivity = "LookAround"
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]  = ACT_IDLE,
    [ACT_MP_WALK]        = ACT_RUN,
    [ACT_MP_RUN]         = ACT_RUN,
    [ACT_MP_CROUCH_IDLE] = ACT_IDLE,
    [ACT_MP_CROUCHWALK]  = ACT_RUN,
    [ACT_MP_JUMP]        = ACT_JUMP,
    [ACT_MP_JUMP_START]  = ACT_RANGE_ATTACK1,
    [ACT_MP_SWIM]        = ACT_RUN,
    [ACT_LAND]           = "ceiling_land",
}

ENT.MySpecialActions = {}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self.FistDamageMul = math.max( 0.1, 2.5 + math.Rand( -5, 5 ) )
        self:AddEFlags( EFL_NO_DISSOLVE )

        for i = 0, self:GetNumBodyGroups() - 1 do
            self:SetSubMaterial( i, FEAR_MATERIALS[ math.random( #FEAR_MATERIALS ) ] )
        end

        self.fearDead    = false
        data.nextBreath  = CurTime() + math.Rand( 1.1, 1.3 )
        data.breathPitch = math.random( 60, 200 )
    end,

    Think = function( self, data )
        if self.fearDead then return end
        local t = CurTime()
        if t >= data.nextBreath then
            self:EmitSound( BREATH_SND, 80, data.breathPitch, 1, CHAN_VOICE )
            data.nextBreath  = t + math.Rand( 1.1, 1.3 )
            data.breathPitch = math.random( 60, 200 )
        end
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        if self:GetClass() ~= "terminator_nextbot_zambieonefear" then return end
        local pos   = self:GetPos()
        local count = math.random( 2, 4 )
        timer.Simple( 0.1, function()
            for i = 1, count do
                local a   = ( ( i - 1 ) / count ) * 360
                local ent = ents.Create( "terminator_nextbot_zambiemanyfears" )
                if not IsValid( ent ) then continue end
                ent:SetPos( pos + Vector( math.cos( math.rad( a ) ) * 40, math.sin( math.rad( a ) ) * 40, 5 ) )
                ent:SetAngles( Angle( 0, math.random( 0, 360 ), 0 ) )
                ent:Spawn()
                ent:Activate()
            end
        end )
    end,

}

function ENT:OnRemove()
    self.fearDead = true
    self:StopSound( BREATH_SND )
    BaseClass.OnRemove( self )
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModel( FEAR_MODEL )

    self.fearDead           = false
    self.zamb_LoseCoolRatio = 0.5
    self.zamb_ForceApproach = true

    self.ZAMBIE_MINIONS       = {}
    self.zamb_NextMinionCheck = CurTime() + 10

    self.necro_MinionsWasteAway            = false
    self.necro_MinionCountMul              = 1
    self.necro_MinMinionCount              = 0
    self.necro_MaxMinionCount              = 0
    self.necro_NormalMinionClass           = {}
    self.necro_ReachableFastMinionChance   = 0
    self.necro_UnReachableFastMinionChance = 0
    self.necro_UnreachableCountAdd         = 0
    self.necro_NearDeathClassChance        = 0

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains                = true

    self.term_SoundPitchShift = 15
    self.term_SoundLevelShift = -10

    self.term_LoseEnemySound = "npc/headcrab/headcrab_alert2.wav"
    self.term_FindEnemySound = "npc/headcrab/headcrab_alert1.wav"
    self.term_AttackSound    = { "npc/headcrab/headcrab_attack1.wav" }
    self.term_AngerSound     = "npc/headcrab/headcrab_alert2.wav"
    self.term_DamagedSound   = { "npc/headcrab/headcrab_pain1.wav", "npc/headcrab/headcrab_pain2.wav" }
    self.term_DieSound       = "npc/headcrab/headcrab_die1.wav"
    self.term_JumpSound      = "npc/headcrab/headcrab_jump1.wav"

    self.IdleLoopingSounds  = {}
    self.AngryLoopingSounds = {}
    self.AlwaysPlayLooping  = false

    self.HeightToStartTakingDamage = 600
    self.FallDamagePerHeight       = 0.05
    self.DeathDropHeight           = 2000
    self.CanUseLadders             = false
end