AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambietank"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Necromancer"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambienecro", {
    Name = "Zombie Necromancer",
    Class = "terminator_nextbot_zambienecro",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambienecro", ENT.PrintName )
    return

end

ENT.JumpHeight = 20
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 4000
ENT.ExtraSpawnHealthPerPlayer = 750
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 60
ENT.MoveSpeed = 80
ENT.RunSpeed = 110
ENT.AccelerationSpeed = 1500
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = nil
ENT.zamb_MeleeAttackSpeed = 1

ENT.DuelEnemyDist = 350
ENT.NoAnimLayering = true

local NECRO_ZAMBIE_MODEL = "models/Zombie/Poison.mdl"
ENT.ARNOLD_MODEL = NECRO_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.35
ENT.CollisionBounds = { Vector( -16, -16, 0 ), Vector( 16, 16, 40 ) }
ENT.MyPhysicsMass = 1000

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { NECRO_ZAMBIE_MODEL }
ENT.Term_BaseTimeBetweenSteps = 500

IdleActivity = ACT_IDLE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_WALK,
    [ACT_MP_CROUCH_IDLE]                = ACT_WALK,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_WALK,
    [ACT_LAND]                          = ACT_LAND,
}

local ACT_ZOM_RELEASECRAB = "releasecrab"

ENT.zamb_CallAnim = ACT_ZOM_RELEASECRAB
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1 -- ACT_RANGE_ATTACK1

-- tanks dont care about body smell
function ENT:AdditionalAvoidAreas()
end

function ENT:AdditionalInitialize()
    self:SetModel( NECRO_ZAMBIE_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -30
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "NPC_PoisonZombie.Idle"
    self.term_CallingSound = "npc/zombie_poison/pz_call1.wav"
    self.term_CallingSmallSound = "npc/zombie_poison/pz_throw3.wav"
    self.term_FindEnemySound = "NPC_PoisonZombie.Alert"
    self.term_AttackSound = { "NPC_PoisonZombie.Attack" }
    self.term_AngerSound = "NPC_PoisonZombie.Alert"
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

    self.zamb_NextMinionCheck = CurTime() + 2.5
    self.ZAMBIE_MINIONS = {}

    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/flesh" )
    self.zamb_LoseCoolRatio = 0.5

    hook.Add( "zamb_OnBecomeTorso", self, function( me, died, newTorso )
        local diedsOwner = died:GetOwner()
        if diedsOwner ~= me then return end
        newTorso:SetOwner( me )
        table.insert( me.ZAMBIE_MINIONS, newTorso )

    end )

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
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

local flattener = Vector( 1,1,0.1 )

function ENT:AdditionalThink()

    if self.zamb_NextMinionCheck > CurTime() then return end
    if self:IsGestureActive() then return end

    self.zamb_NextMinionCheck = CurTime() + 1
    local aliveCount = 0
    local newTbl = {}
    for _, minion in ipairs( self.ZAMBIE_MINIONS ) do
        if IsValid( minion ) and minion:Health() > 0 then
            table.insert( newTbl, minion )
            aliveCount = aliveCount + 1
        end
    end
    self.ZAMBIE_MINIONS = newTbl

    local desiredAliveCount = 1
    local myEnem = self:GetEnemy()
    local reachable
    if IsValid( myEnem ) then
        desiredAliveCount = 2

        local result = terminator_Extras.getNearestPosOnNav( myEnem:GetPos() )
        reachable = self:areaIsReachable( result.area )

        if not reachable then
            desiredAliveCount = desiredAliveCount + 1

        end
    end
    local nearDeath
    if self:IsReallyAngry() and self:Health() < self:GetMaxHealth() * 0.35 then
        nearDeath = true
        desiredAliveCount = desiredAliveCount + 5

    elseif self:IsReallyAngry() then
        desiredAliveCount = desiredAliveCount + 3

    elseif self:IsAngry() then
        desiredAliveCount = desiredAliveCount + 1

    end

    desiredAliveCount = math.Clamp( desiredAliveCount, 0, 12 )

    if aliveCount < desiredAliveCount then
        local diff = desiredAliveCount - aliveCount
        if diff > 2 or nearDeath then
            self:Term_ClearStuffToSay()
            self:ZAMB_AngeringCall()
            if nearDeath then
                self.zamb_NextMinionCheck = CurTime() + 2

            else
                self.zamb_NextMinionCheck = CurTime() + 10

            end

        else
            self:ZAMB_NormalCall()
            self.zamb_NextMinionCheck = CurTime() + 4

        end
        for _ = 1, diff do
            local time = 0.8 + math.Rand( 0, 1 )
            timer.Simple( time, function()
                if not IsValid( self ) then return end
                if self:Health() <= 0 then return end

                local class = "terminator_nextbot_zambie"
                local fastChance = reachable and 50 or 90
                if math.random( 1, 100 ) < fastChance then
                    class = "terminator_nextbot_zambiefast"

                end
                if nearDeath and math.random( 1, 100 ) < 10 then
                    class = "terminator_nextbot_zambieberserk"

                end
                local minion = ents.Create( class )

                if not IsValid( minion ) then return end

                minion:SetOwner( self )
                table.insert( self.ZAMBIE_MINIONS, minion )

                local flatRand = VectorRand() * flattener
                flatRand:Normalize()

                minion:SetPos( self:WorldSpaceCenter() + flatRand * 50 )
                minion:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
                minion.HealthRegen = 0
                minion:Spawn()
                minion.HealthRegen = 0 -- here also for good measure
                minion:SetSubMaterial( 0, "models/flesh" )
                minion:SetHealth( math.max( minion:GetMaxHealth() / 2, 1 ) )

                local timerId = "zambie_minionmaintain_" .. minion:GetCreationID()
                timer.Create( timerId, math.Rand( 3, 6 ), 0, function()
                    if not IsValid( minion ) then timer.Remove( timerId ) return end
                    if minion:Health() <= 0 then SafeRemoveEntity( minion ) timer.Remove( timerId ) return end

                    local owner = minion:GetOwner()
                    if not IsValid( owner ) or owner:Health() <= 0 then minion:Ignite( 999 ) return end

                    minion:TakeDamage( 1, minion, minion ) -- slowly die
                    if not IsValid( minion:GetEnemy() ) and IsValid( owner:GetEnemy() ) then minion:SetEnemy( owner:GetEnemy() ) end

                end )
            end )
        end
    end
end

function ENT:OnRemove()
    for _, minion in ipairs( self.ZAMBIE_MINIONS ) do
        if IsValid( minion ) then
            minion:SetHealth( math.min( minion:Health(), 10 ) )
            timer.Simple( math.Rand( 0, 1 ), function()
                if not IsValid( minion ) then return end
                if minion:Health() <= 0 then SafeRemoveEntity( minion ) return end
                minion:Ignite( 999 )
                SafeRemoveEntityDelayed( minion, 60 ) -- BUGS

            end )
        end
    end
end