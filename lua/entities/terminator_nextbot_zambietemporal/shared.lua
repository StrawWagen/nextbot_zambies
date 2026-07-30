AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Temporal"
ENT.Spawnable = true

list.Set( "NPC", "terminator_nextbot_zambietemporal", {
    Name = "Zombie Temporal",
    Class = "terminator_nextbot_zambietemporal",
    Category = "Nextbot Zambies",
} )

local TEMPORAL_MODEL = "models/Zombie/Poison.mdl"
ENT.ARNOLD_MODEL = TEMPORAL_MODEL
ENT.Models = { TEMPORAL_MODEL }

ENT.NoAnimLayering = true 

local IdleActivity = ACT_IDLE
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

ENT.zamb_CallAnim = "releasecrab"
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

ENT.SpawnHealth = 350
ENT.WalkSpeed = 55
ENT.MoveSpeed = 165
ENT.RunSpeed = 275
ENT.FistDamageMul = 0.55 
ENT.DuelEnemyDist = 450
ENT.CloseEnemyDistance = 500

ENT.TemporalEffectColor = 0 + 114 * 256 + 255 * 65536

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Temporal Warp",
        desc = "Teleport near your target.",
        ratelimit = 4, 
        svAction = function( driveController, driver, bot )
            bot:TEMPORAL_TryWarp(driver)
        end,
    }
}

-- Replaced ezt sounds with standard Poison Zombie sounds
ENT.term_LoseEnemySound = "NPC_PoisonZombie.Idle"
ENT.term_CallingSound = "NPC_PoisonZombie.Call"
ENT.term_CallingSmallSound = "NPC_PoisonZombie.Call"
ENT.term_FindEnemySound = "NPC_PoisonZombie.Alert"
ENT.term_AttackSound = "NPC_PoisonZombie.Attack"
ENT.term_AngerSound = "NPC_PoisonZombie.Alert"
ENT.term_DamagedSound = "NPC_PoisonZombie.Pain"
ENT.term_DieSound = "NPC_PoisonZombie.Die"
ENT.term_JumpSound = "npc/zombie/foot1.wav"

if CLIENT then
    language.Add( "terminator_nextbot_zambietemporal", ENT.PrintName )

    function ENT:AdditionalClientInitialize()
        local myColor = Vector( math.Rand( 0.1, 1 ), math.Rand( 0, 0.5 ), math.Rand( 0, 0.1 ) )
        self.GetPlayerColor = function()
            return myColor
        end
    end

    return
end

function ENT:Temporal_FindTeleportPos( enemy )
    local myPos = self:GetPos()
    local enemyPos = enemy:GetPos()

    local areas = navmesh.Find( enemyPos, 500, 100, 100 )
    for i = #areas, 2, -1 do 
        local j = math.random(i)
        areas[i], areas[j] = areas[j], areas[i]
    end

    for _, area in ipairs( areas ) do
        local testPos = area:GetRandomPoint()
        local dist = myPos:Distance( testPos )
        local zDiffEnemy = math.abs(testPos.z - enemyPos.z)
        local zDiffSelf = math.abs(testPos.z - myPos.z)

        if dist > 10 and zDiffEnemy < 80 and zDiffSelf < 300 and enemyPos:Distance( testPos ) < 350 then
            return testPos
        end
    end

    local tr = util.TraceLine({
        start = enemyPos + Vector(0, 0, 10),
        endpos = enemyPos - Vector(0, 0, 1000),
        filter = { self, enemy },
        mask = MASK_NPCWORLDSTATIC
    })
    if tr.Hit then
        return tr.HitPos
    end

    return myPos
end

function ENT:Temporal_SpawnVanishCorpse( posOverride )
    local pos = posOverride or self:GetPos()
    local corpse = ents.Create( "prop_ragdoll" )
    if not IsValid( corpse ) then return end

    corpse:SetPos( pos )
    corpse:SetAngles( self:GetAngles() )
    corpse:SetModel( self:GetModel() )
    corpse:SetModelScale( self:GetModelScale(), 0 )
    corpse:SetOwner( self )
    corpse:Spawn()
    corpse:Activate()
    corpse:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    corpse:SetSubMaterial( 0, "models/temporal/poisonzombie_sheet.vmt" )
    corpse:SetSubMaterial( 1, "models/temporal/blackcrab_sheet.vmt" )

    timer.Simple( 0.1, function()
        if not IsValid( corpse ) then return end
        for i = 0, corpse:GetPhysicsObjectCount() - 1 do
            local phys = corpse:GetPhysicsObjectNum( i )
            if IsValid( phys ) then
                phys:EnableMotion( false )
            end
        end
    end )

    corpse:Fire( "FadeAndRemove", "", 0.2 )

    local ed = EffectData()
    local scale = self:GetModelScale() or 1
    local chestPos = pos + Vector(0, 0, 40) * scale
    ed:SetOrigin( chestPos )
    ed:SetScale(2)
    ed:SetFlags(2)
    if self.TemporalEffectColor then
        ed:SetColor(self.TemporalEffectColor)
    end
    util.Effect( "eff_temporal_warp_events", ed )

    self:EmitSound( "NPC_PoisonZombie.Pain" ) -- Replaced ezt vanish sound
end

function ENT:Temporal_DoTeleport( targetPos )
    self:Temporal_SpawnVanishCorpse()

    self:SetPos( targetPos )
    self:InvalidatePath( "temporal_teleport" )

    local ed = EffectData()
    local scale = self:GetModelScale() or 1
    local chestPos = targetPos + Vector(0, 0, 40) * scale
    ed:SetOrigin( chestPos )
    ed:SetScale(1)
    ed:SetFlags(1)
    if self.TemporalEffectColor then
        ed:SetColor(self.TemporalEffectColor)
    end
    util.Effect( "eff_temporal_warp_events", ed )

    self:EmitSound( "NPC_PoisonZombie.Alert" ) -- Replaced ezt appear sound
end

function ENT:TEMPORAL_TryWarp(driver)
    local pos = nil
    local enemy = self:GetEnemy()
    
    if IsValid( enemy ) then
        pos = self:Temporal_FindTeleportPos( enemy )
    end
    
    if not pos and IsValid( driver ) then
        local trace = driver:GetEyeTrace()
        if trace.Hit then
            pos = trace.HitPos
        else
            pos = self:GetPos() + driver:GetAimVector() * 500
        end
    end
    
    if not pos then
        local myPos = self:GetPos()
        local areas = navmesh.Find( myPos, 500, 100, 100 )
        if #areas > 0 then
            local randomArea = areas[math.random(1, #areas)]
            pos = randomArea:GetRandomPoint()
        else
            pos = myPos
        end
    end

    self:Temporal_DoTeleport( pos )
    self.NextTemporalTeleport = CurTime() + math.Rand( 3, 5 )
end

ENT.MyClassTask = {
    StartsOnInitialize = true,

    OnCreated = function( self, data )
        local memEd = EffectData()
        memEd:SetOrigin(self:GetPos())
        memEd:SetEntity(self)
        memEd:SetScale(1)
        util.Effect("eff_temporal_memorycloud", memEd)
        
        local trailColor = self.TemporalTrailColor or Color( 255, 255, 255 )
        local trailMat = self.TemporalTrailMat or "sprites/bluelaser1.vmt"
        
        util.SpriteTrail( self, self:LookupAttachment( "eyes" ), trailColor, true, 1, 2, 2.5, 1 / ( 6 + 6 ) * 10.5, trailMat )
        util.SpriteTrail( self, 9, trailColor, true, 1, 2, 2.5, 1 / ( 6 + 6 ) * 10.5, trailMat )
        util.SpriteTrail( self, 10, trailColor, true, 1, 2, 2.5, 1 / ( 6 + 6 ) * 10.5, trailMat )
        
        self.NextTemporalTeleport = CurTime() + math.Rand( 1, 3 )
    end,

    OnDamaged = function( self, data, dmg )
        self:Term_ClearStuffToSay()
        self:Term_SpeakSoundNow( self.term_DamagedSound )

        if self:IsOnGround() and CurTime() > ( self.NextTemporalTeleport or 0 ) then
            local enemy = self:GetEnemy()
            if not IsValid( enemy ) or self:GetPos():DistToSqr( enemy:GetPos() ) > 120^2 then
                self:TEMPORAL_TryWarp(nil)
            end
        end
    end,

    PreventBecomeRagdollOnKilled = function( self, data, dmg )
        self:Temporal_SpawnVanishCorpse()
        return true, true 
    end,

    OnKilled = function( self, data, dmg, rag )
        self:EmitSound( self.term_DieSound, 80, 100, 1, CHAN_VOICE )
        timer.Simple( 0.1, function()
            if IsValid( self ) then SafeRemoveEntity( self ) end
        end )
    end,

    EnemyFound = function( self, data, newEnemy, secondsSinceLastEnemy )
        self:RunTask( "ZambOnGrumpy" )
        local allies = self:GetNearbyAllies( 1500 )
        if #allies > 0 then
            for _, ally in ipairs( allies ) do
                if ally:GetNPCState() == NPC_STATE_IDLE or ally:GetNPCState() == NPC_STATE_SCRIPT then
                    ally:SetEnemy( newEnemy )
                end
            end
        end
    end,

    EnemyLost = function( self, data )
        self:Term_SpeakSound( self.term_LoseEnemySound )
    end,

    OnAttack = function( self, data )
        self:Term_SpeakSound( self.term_AttackSound )
    end,

    OnAnger = function( self, data )
        if self.term_lastAngerSound and math.random( CurTime() - 10, CurTime() ) < self.term_lastAngerSound then return end
        self.term_lastAngerSound = CurTime()
        self:Term_SpeakSound( self.term_AngerSound )
    end,

    OnJump = function( self, data )
        self:EmitSound( self.term_JumpSound, 75, math.random( 95, 105 ), 1, CHAN_VOICE )
    end,

    OnPathFail = function( self )
        self:ReallyAnger( 20 )
        self:RunTask( "ZambOnGrumpy" )
    end,
}

function ENT:AdditionalInitialize()
    self:SetModel( TEMPORAL_MODEL )
    
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/temporal/poisonzombie_sheet.vmt" )
    self:SetSubMaterial( 1, "models/temporal/blackcrab_sheet.vmt" )

    self.isTerminatorHunterChummy = "zambies"
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 2
    self.CanHearStuff = false

    local hasBrains = math.random( 1, 100 ) < 20
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true
    end

    self.TakesFallDamage = true
    self.HeightToStartTakingDamage = 200
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1000
end