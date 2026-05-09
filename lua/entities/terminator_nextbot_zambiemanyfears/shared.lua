AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieonefear"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Many Fears"
ENT.Spawnable = true

if CLIENT then
    language.Add( "terminator_nextbot_zambiemanyfears", ENT.PrintName )
    return
end

local FEAR_MODEL = "models/headcrab.mdl"
local BREATH_SND = "npc/fast_zombie/breathe_loop1.wav"

ENT.IsFodder = false

ENT.SpawnHealth               = 150
ENT.ExtraSpawnHealthPerPlayer = 10

ENT.WalkSpeed          = 330
ENT.MoveSpeed          = 525
ENT.RunSpeed           = 1050
ENT.AccelerationSpeed  = 600
ENT.DeccelerationSpeed = 2700

ENT.zamb_MeleeAttackSpeed       = 2.7
ENT.zamb_MeleeAttackHitFrameMul = 45

ENT.TERM_MODELSCALE       = 2
ENT.CollisionBounds       = { Vector( -5, -5, 0 ), Vector( 5, 5, 8   ) }
ENT.CrouchCollisionBounds = { Vector( -2, -2, 0 ), Vector( 2, 2, 5.5 ) }

ENT.FistForceMul = 4
ENT.FistRangeMul = 1.1

ENT.MySpecialActions = {}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self.FistDamageMul = math.max( 0.1, 1.5 + math.Rand( -2, 2 ) )
        self:AddEFlags( EFL_NO_DISSOLVE )

        data.spawnEffectFired = false
        data.spawnEffectTime  = CurTime() + 0.15
        data.drainStartTime   = CurTime() + math.Rand( 240, 300 )
        data.draining         = false
    end,

    Think = function( self, data )
        if self.fearDead then return end

        if not data.spawnEffectFired and CurTime() >= data.spawnEffectTime then
            data.spawnEffectFired = true
            local origin = self:LocalToWorld( Vector( -0.337, -0.813, 0 ) )
            for _ = 1, 5 do
                local ed = EffectData()
                ed:SetOrigin( origin )
                ed:SetNormal( Vector( 0, 0, 1 ) )
                ed:SetScale( 1 )
                util.Effect( "BloodImpact", ed )
            end
        end

        -- Drain is defined on zambieonefear to avoid duplication across tiers
        self:zamb_FearRunDrain( data )
    end,

    -- NOTE: the GetClass guard is currently necessary — see zambieonefear for explanation
    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        if self:GetClass() ~= "terminator_nextbot_zambiemanyfears" then return end
        local pos   = self:GetPos()
        local count = math.random( 3, 6 )
        timer.Simple( 0.1, function()
            for i = 1, count do
                local a   = ( ( i - 1 ) / count ) * 360
                local ent = ents.Create( "terminator_nextbot_zambiemanymanyfears" )
                if not IsValid( ent ) then continue end
                ent:SetPos( pos + Vector( math.cos( math.rad( a ) ) * 30, math.sin( math.rad( a ) ) * 30, 5 ) )
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

    self.term_SoundPitchShift = 5
    self.term_SoundLevelShift = 5

    self.HeightToStartTakingDamage = 500
    self.FallDamagePerHeight       = 0.08
    self.DeathDropHeight           = 2500
end