AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Zombie Poison"
ENT.Spawnable = false
ENT.Author = "Broadcloth0"

list.Set("NPC", "terminator_nextbot_poisonzambie", {
    Name = "Zombie Poison",
    Class = "terminator_nextbot_poisonzambie",
    Category = "Nextbot Zambies",
})

if CLIENT then
    language.Add("terminator_nextbot_poisonzambie", ENT.PrintName)
    return
end

ENT.JumpHeight = 20
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 780 -- chunky boi
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 60
ENT.MoveSpeed = 80
ENT.RunSpeed = 90
ENT.AccelerationSpeed = 1500
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = nil
ENT.zamb_MeleeAttackSpeed = 1.1
ENT.zamb_MeleeAttackHitFrameMul = 0.43

ENT.DuelEnemyDist = 450
ENT.NoAnimLayering = true

local POISON_ZAMBIE_MODEL= "models/Zombie/Poison.mdl"

ENT.ARNOLD_MODEL = POISON_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1
ENT.CollisionBounds = { Vector( -16, -16, 0 ), Vector( 16, 16, 40 ) }
ENT.MyPhysicsMass = 1000
ENT.IsZombieFatSkinned = 0.87 -- i forgot what this does but i'm pretty sure it's like bullet resistance since they are fat
ENT.FistDamageMul = 0.87
ENT.FistForceMul = 14
ENT.FistRangeMul = 2
ENT.ReallyHeavy = true

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Models = { POISON_ZAMBIE_MODEL }
ENT.Term_BaseTimeBetweenSteps = 300

IdleActivity = ACT_IDLE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_WALK,
    [ACT_MP_CROUCH_IDLE]                = ACT_WALK,
    [ACT_MP_CROUCHWALK]                 = ACT_WALK, -- ACT_HL2MP_WALK_CROUCH just slides, changed to act walk
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_WALK,
    [ACT_MP_SWIM]                       = ACT_WALK,
    [ACT_LAND]                          = ACT_LAND,
}

local ACT_ZOM_RELEASECRAB = "releasecrab"

ENT.zamb_CallAnim = ACT_ZOM_RELEASECRAB
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1 -- ACT_RANGE_ATTACK1

function ENT:AdditionalAvoidAreas()
end

function ENT:AdditionalInitialize()
    self:SetModel( POISON_ZAMBIE_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = 0
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
    self.minionsSpawned = 0 -- tracks the minions so it can remove the bodygroup when spawning a minion
    self.allowedminions = 3 -- obvious

    self:SetBodygroup(1, 1)
    self:SetBodygroup(2, 1)
    self:SetBodygroup(3, 1)
    self:SetBodygroup(4, 1)
    self.zamb_LoseCoolRatio = 0.5
end

local sndFlags = bit.bor(SND_CHANGE_VOL)

function ENT:OnFootstep(_pos, foot, _sound, volume, _filter)
    local lvl = 83
    local snd = foot and "npc/zombie_poison/pz_left_foot1.wav" or "npc/zombie_poison/pz_right_foot1.wav"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76
    end
    self:EmitSound(snd, lvl, 100, volume + 1, CHAN_STATIC, sndFlags)
    return true
end

-- does not flinch
function ENT:HandleFlinching()
end

local flattener = Vector(1,1,0.1)

-- copied from necro & modified a tiny bit, too lazy to add a custom one w/e
function ENT:AdditionalThink()
    if self.zamb_NextMinionCheck > CurTime() then return end
    if self:IsGestureActive() then return end

    self.zamb_NextMinionCheck = CurTime() + 1
    
    local aliveCount = 0
    local newTbl = {}
    for _, minion in ipairs(self.ZAMBIE_MINIONS) do
        if IsValid(minion) and minion:Health() > 0 then
            table.insert(newTbl, minion)
            aliveCount = aliveCount + 1
        end
    end
    self.ZAMBIE_MINIONS = newTbl

    if aliveCount == 0 and self.minionsSpawned < self.allowedminions then
        self:Term_ClearStuffToSay()
        self:ZAMB_AngeringCall()
        self.zamb_NextMinionCheck = CurTime() + 2
        
        local spawnPos = self:GetPos() - self:GetForward() * 50
        spawnPos.z = self:GetPos().z 
        
        local class = "terminator_nextbot_zambiepoisonheadcrab"
        local minion = ents.Create(class)
        
        if IsValid(minion) then
            minion:SetOwner(self)
            table.insert(self.ZAMBIE_MINIONS, minion)
            
            minion:SetPos(spawnPos)
            minion:SetAngles(Angle(0, math.random(-180, 180), 0))
            minion:Spawn()
            minion:SetHealth(math.max(minion:GetMaxHealth() / 2, 1))
            
            self.minionsSpawned = self.minionsSpawned + 1
        
            if self.minionsSpawned == 1 then
                self:SetBodygroup(4, 0) 
            elseif self.minionsSpawned == 2 then
                self:SetBodygroup(3, 0) 
            elseif self.minionsSpawned == 3 then
                self:SetBodygroup(2, 0) 
            end
            
            local timerId = "zambie_minionmaintain_" .. minion:GetCreationID()
            timer.Create(timerId, math.Rand(3, 6), 0, function()
                if not IsValid(minion) then timer.Remove(timerId) return end
                if minion:Health() <= 0 then SafeRemoveEntity(minion) timer.Remove(timerId) return end

                local owner = minion:GetOwner()
                if not IsValid(owner) or owner:Health() <= 0 then minion:Ignite(999) return end

                minion:TakeDamage(1, minion, minion) // slowly die
                if not IsValid(minion:GetEnemy()) and IsValid(owner:GetEnemy()) then 
                    minion:SetEnemy(owner:GetEnemy()) 
                end
            end)
        end
    end
end

function ENT:OnRemove()
    for _, minion in ipairs(self.ZAMBIE_MINIONS) do
        if IsValid(minion) then
            minion:SetHealth(math.min(minion:Health(), 10))
            timer.Simple(math.Rand(0, 1), function()
                if not IsValid(minion) then return end
                if minion:Health() <= 0 then SafeRemoveEntity(minion) return end
                minion:Ignite(999)
                SafeRemoveEntityDelayed(minion, 60)
            end)
        end
    end
end

-- copied from wide jerma, this  kinda sounds werid to me but i guess it works.
function ENT:OnTakeDamage(dmg)
    local damage = dmg:GetDamage()

    if dmg:IsBulletDamage() or dmg:IsDamageType( DMG_CLUB ) or dmg:IsDamageType( DMG_SLASH ) then
        damage = damage * ( 4 - self.IsZombieFatSkinned )
        local pitch = math.random(130, 170)
        self:EmitSound( "npc/fast_zombie/claw_strike1.wav", 0, pitch, 1, CHAN_BODY )

    end

    return false

end

