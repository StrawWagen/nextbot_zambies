AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieonefear"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Many, Many Fears"
ENT.Spawnable = true

if CLIENT then
    language.Add( "terminator_nextbot_zambiemanymanyfears", ENT.PrintName )
    return
end

local FEAR_MODEL = "models/headcrab.mdl"
local BREATH_SND = "npc/fast_zombie/breathe_loop1.wav"

local function RunDrain( self, data )
    if not data.draining then
        if CurTime() < data.drainStartTime then return end
        data.draining      = true
        data.lastDrainTick = CurTime()
    end
    local now   = CurTime()
    local delta = now - data.lastDrainTick
    data.lastDrainTick = now
    local hp = self:Health() - 100 * delta
    if hp <= 1 then
        self:TakeDamage( self:Health(), self, self )
    else
        self:SetHealth( hp )
    end
end

ENT.IsFodder = true

ENT.SpawnHealth               = 50
ENT.ExtraSpawnHealthPerPlayer = 0

ENT.WalkSpeed          = 440
ENT.MoveSpeed          = 700
ENT.RunSpeed           = 1400
ENT.AccelerationSpeed  = 800
ENT.DeccelerationSpeed = 3600

ENT.zamb_MeleeAttackSpeed       = 3.6
ENT.zamb_MeleeAttackHitFrameMul = 60

ENT.TERM_MODELSCALE       = 1
ENT.CollisionBounds       = { Vector( -12.5, -12.5, 0 ), Vector( 12.5, 12.5, 20 ) }
ENT.CrouchCollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 10 ) }

ENT.FistDamageMul  = 0.75
ENT.FistForceMul   = 1
ENT.FistRangeMul   = 0.9

ENT.MySpecialActions = {}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self:AddEFlags( EFL_NO_DISSOLVE )

        data.spawnEffectFired = false
        data.spawnEffectTime  = CurTime() + 0.15
        data.drainStartTime   = CurTime() + math.Rand( 180, 240 )
        data.draining         = false
    end,

    Think = function( self, data )
        if self.fearDead then return end

        if not data.spawnEffectFired and CurTime() >= data.spawnEffectTime then
            data.spawnEffectFired = true
            local origin = self:GetPos() + Vector( 0, 0, 7 )
            for _ = 1, 5 do
                local ed = EffectData()
                ed:SetOrigin( origin )
                ed:SetNormal( Vector( 0, 0, 1 ) )
                ed:SetScale( 1 )
                util.Effect( "BloodImpact", ed )
            end
        end

        RunDrain( self, data )
    end,

}

function ENT:OnRemove()
    self.fearDead = true
    self:StopSound( BREATH_SND )
    BaseClass.OnRemove( self )
end

function ENT:AdditionalFootstep( pos, foot, sound, volume, filter )
    return true
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( FEAR_MODEL )

    self.fearDead           = false
    self.zamb_LoseCoolRatio = 0.5

    self.necro_MinionCountMul              = 1
    self.necro_MinMinionCount              = 0
    self.necro_MaxMinionCount              = 0
    self.necro_NormalMinionClass           = {}
    self.necro_MinionsWasteAway            = false
    self.necro_ReachableFastMinionChance   = 0
    self.necro_UnReachableFastMinionChance = 0
    self.necro_UnreachableCountAdd         = 0
    self.necro_NearDeathClassChance        = 0

    self.ZAMBIE_MINIONS       = {}
    self.zamb_NextMinionCheck = CurTime() + 10

    self.term_SoundPitchShift = 30
    self.term_SoundLevelShift = -20

    self.HeightToStartTakingDamage = 800
    self.FallDamagePerHeight       = 0.02
    self.DeathDropHeight           = 3000

    self.term_DamagedSound = { "npc/headcrab/headcrab_pain1.wav" }
end