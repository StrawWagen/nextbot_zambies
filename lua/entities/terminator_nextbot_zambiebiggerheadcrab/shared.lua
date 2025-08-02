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

ENT.IsEldritch = true -- GLEE

if CLIENT then
    language.Add( "terminator_nextbot_zambiebiggerheadcrab", ENT.PrintName )

    return
end

ENT.IsFodder = nil
ENT.CoroutineThresh = 0.001

ENT.JumpHeight = 3000
ENT.DefaultStepHeight = 50
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.PathGoalToleranceFinal = 175
ENT.SpawnHealth = 100000
ENT.ExtraSpawnHealthPerPlayer = 5000
ENT.HealthRegen = 8
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 300
ENT.CrouchSpeed = 575
ENT.WalkSpeed = 600
ENT.MoveSpeed = 1000
ENT.RunSpeed = 4000
ENT.AccelerationSpeed = 850
ENT.neverManiac = true

ENT.TERM_FOV = 120

ENT.zamb_MeleeAttackSpeed = 2
ENT.zamb_MeleeAttackHitFrameMul = 40
ENT.zamb_AttackAnim = ACT_RANGE_ATTACK1

ENT.FistDamageMul = 100
ENT.FistForceMul = 100
ENT.FistRangeMul = 3
ENT.DuelEnemyDist = 1250
ENT.PrefersVehicleEnemies = true

local GOD_CRAB_MODEL = "models/headcrab.mdl"
ENT.ARNOLD_MODEL = GOD_CRAB_MODEL
ENT.TERM_MODELSCALE = 8
ENT.CollisionBounds = { Vector( -1, -1, 0 ), Vector( 1, 1, 2 ) }
ENT.CrouchCollisionBounds = { Vector( -0.75, -0.75, 0 ), Vector( 0.75, 0.75, 1.75 ) }
ENT.MyPhysicsMass = 50000
ENT.ReallyHeavy = true

ENT.Term_BaseMsBetweenSteps = 1100
ENT.Term_FootstepMsReductionPerUnitSpeed = 1.05

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

function ENT:AdditionalFootstep( pos, _foot, _sound, volume, _filter )
    local lvl = 83
    local snd = "NPC_Strider.Footstep"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76

    end

    local FilterAllPlayers = RecipientFilter()
    FilterAllPlayers:AddAllPlayers()
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags, 0, FilterAllPlayers )

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

function ENT:ScreamsOfTheDamned( myTbl )
    self:EmitSound( screamsOfTheDamned[math.random( 1, #screamsOfTheDamned )], 64 + myTbl.term_SoundLevelShift, math.random( 90, 110 ) + myTbl.term_SoundPitchShift, 1, CHAN_STATIC )

end

function ENT:AdditionalThink( myTbl )
    BaseClass.AdditionalThink( self, myTbl )
    local cur = CurTime()
    local nextForced = myTbl.hugeHeadcrabForceScream or 0

    if math.Rand( 0, 100 ) > 3 and nextForced > cur then return end
    local add = math.Rand( 5, 10 )
    if self:IsReallyAngry() then
        add = math.Rand( 0, 2 )

    elseif self:IsAngry() then
        add = math.Rand( 2, 5 )

    end

    myTbl.hugeHeadcrabForceScream = cur + add

    self:ScreamsOfTheDamned( myTbl )

end

-- makes us wait a second at 0 hp when dying
ENT.Term_DeathAnim = {
    act = "rearup",
    rate = 0.15,
}

ENT.MyClassTask = {
    ZambAngeringCall = function( self, data )
        local shock = EffectData()
        shock:SetOrigin( self:WorldSpaceCenter() )
        shock:SetScale( 0.1 )
        util.Effect( "m9k_yoinked_shockwave", shock )

    end,

    DealtGoobmaDamage = function( self, data, damage, fallHeight, _dealtTo )
        if fallHeight <= 250 then return end
        local myPos = self:GetPos()
        local scale = fallHeight / 1500
        scale = math.Clamp( scale, 0, 2.5 )

        local shock = EffectData()
        shock:SetOrigin( myPos )
        shock:SetScale( scale )
        util.Effect( "m9k_yoinked_shockwave", shock )

        if fallHeight < 1000 then return end

        local dmgRad = fallHeight * 0.5
        dmgRad = math.Clamp( dmgRad, 500, 5000 )

        local dmg = 250 * scale
        util.BlastDamage( self, self, self:GetPos(), dmgRad, dmg )

        local splode = EffectData()
        splode:SetOrigin( myPos )
        splode:SetNormal( Vector( 0, 0, 1 ) )
        splode:SetScale( scale * 2 )
        util.Effect( "huge_m9k_yoinked_splode", splode )

    end,

    OnJump = function( self, data, height )
        timer.Simple( 0, function()
            if not IsValid( self ) then return end
            if not self.loco:IsOnGround() then return end
            local myPos = self:GetPos()
            local scale = height / 6000
            scale = math.Clamp( scale, 0, 2.5 )

            local shock = EffectData()
            shock:SetOrigin( myPos )
            shock:SetScale( scale )
            util.Effect( "m9k_yoinked_shockwave", shock )

        end )
    end,

    ZambBlockJumpToPos = function( self, data )
        if self:Health() > self:GetMaxHealth() * 0.5 then
            return true

        end
    end,

    OnStartDying = function( self, data )
        self:ZAMB_AngeringCall( true, 0.1 )
        util.ScreenShake( self:GetPos(), 100, 50, 1, 2000, true )
        local timerName = "thegodcrab_bubbleskin_" .. self:GetCreationID()
        local scale = 1
        timer.Create( timerName, 0.1, 0, function()
            if not IsValid( self ) then timer.Remove( timerName ) return end
            scale = scale + 0.01
            self:ScreamsOfTheDamned( self:GetTable() )
            -- manupulate our bones's scale, warping them as time goes on
            local bones = self:GetBoneCount()
            for bone = 0, bones - 1 do
                local finalScale = Vector( math.Rand( 0.5, 1.5 ), math.Rand( 0.5, 1.5 ), math.Rand( 0.1, 2 ) ) * scale
                self:ManipulateBoneScale( bone, finalScale )

            end
        end )
        local max = 22
        for i = 1, max do
            timer.Simple( i * 0.2, function()
                if not IsValid( self ) then return end
                local offset = VectorRand() * 100
                local explosion = ents.Create( "env_explosion" )
                explosion:SetPos( self:WorldSpaceCenter() + offset )
                explosion:SetOwner( self )
                explosion:Spawn()
                explosion:SetKeyValue( "iMagnitude", 25 * i )
                explosion:Fire( "Explode", 0, 0 )

                if i > max - 2 then
                    local splode = EffectData()
                    splode:SetOrigin( self:WorldSpaceCenter() + offset )
                    splode:SetNormal( Vector( 0, 0, 1 ) )
                    splode:SetScale( i * 0.1 )
                    util.Effect( "huge_m9k_yoinked_splode", splode )

                end
            end )
        end
    end,

    OnKilled = function( self, data )
        local myPos = self:GetPos()

        local filterAllPlayers = RecipientFilter()
        filterAllPlayers:AddAllPlayers()

        local splode = EffectData()
        splode:SetOrigin( myPos )
        splode:SetNormal( Vector( 0, 0, 1 ) )
        splode:SetScale( 8 )
        util.Effect( "huge_m9k_yoinked_splode", splode, true, filterAllPlayers )

        local shock = EffectData()
        shock:SetOrigin( myPos )
        shock:SetScale( 3 )
        util.Effect( "m9k_yoinked_shockwave", shock, true, filterAllPlayers )

        -- lots of striderblood effects
        for _ = 1, 20 do
            local dir = VectorRand()
            local effectdata = EffectData()
            effectdata:SetOrigin( myPos )
            effectdata:SetNormal( dir )
            effectdata:SetScale( math.Rand( 1, 8 ) )
            util.Effect( "StriderBlood", effectdata, true, filterAllPlayers )

        end

        util.BlastDamage( self, self, self:WorldSpaceCenter(), 5000, 50 )
        util.BlastDamage( self, self, self:WorldSpaceCenter(), 1500, 10000 )

        util.ScreenShake( myPos, 100, 50, 5, 2500, true )
        util.ScreenShake( myPos, 10, 50, 5, 8000, true )

        self:EmitSound( "explode_9", 150, 80, 1, CHAN_STATIC, SND_NOFLAGS, 0, filterAllPlayers )
        self:EmitSound( "npc/antlion_guard/antlion_guard_die1.wav", 125, 50, 1, CHAN_STATIC, SND_NOFLAGS, 0, filterAllPlayers )
        self:EmitSound( "npc/stalker/go_alert2a.wav", 150, 25, 0.75, CHAN_STATIC, SND_NOFLAGS, 22, filterAllPlayers )
        self:EmitSound( "ambient/levels/labs/teleport_postblast_thunder1.wav", 150, 15, 0.75, CHAN_STATIC, SND_NOFLAGS, 0, filterAllPlayers )

        local playersDone = self.ExtraSpawnHealthPlayersDone or 0
        local count = math.Clamp( 2 + math.floor( playersDone / 5 ) * 2, 2, 4 )
        timer.Simple( 0, function()
            for _ = 1, count do
                local pos = myPos + Vector( math.random( -50, 50 ), math.random( -50, 50 ), 0 )
                local babby = ents.Create( "terminator_nextbot_zambiebigheadcrab" )
                if not IsValid( babby ) then continue end
                babby:SetPos( pos )
                babby.SpawnHealth = babby.SpawnHealth * 0.5
                babby.ExtraSpawnHealthPerPlayer = babby.ExtraSpawnHealthPerPlayer * 0.1
                babby:Spawn()

            end
        end )
    end,
}