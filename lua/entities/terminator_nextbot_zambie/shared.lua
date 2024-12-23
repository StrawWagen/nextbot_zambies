AddCSLuaFile()

ENT.Base = "terminator_nextbot"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambie", {
    Name = "Zombie",
    Class = "terminator_nextbot_zambie",
    Category = "Nexbot Zambies",
} )

local function copyMatsOver( from, to )
    for ind = 0, #from:GetMaterials() do
        local mat = from:GetSubMaterial( ind )
        if mat and mat ~= "" then
            to:SetSubMaterial( ind, mat )

        end
    end
    local myMat = from:GetMaterial()
    if myMat and myMat ~= "" then
        to:SetMaterial( myMat )

    end
end

if CLIENT then
    language.Add( "terminator_nextbot_zambie", ENT.PrintName )

    hook.Add( "CreateClientsideRagdoll", "zambie_fixcorpsemats", function( ent, newRagdoll )
        if not string.find( ent:GetClass(), "zambie" ) then return end
        copyMatsOver( ent, newRagdoll )

        -- tried setting mdlscale here too, didnt work

    end )

    function ENT:AdditionalClientInitialize()
        local myColor = Vector( math.Rand( 0.1, 1 ), math.Rand( 0, 0.5 ), math.Rand( 0, 0.1 ) )
        --https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/matproxy/player_color.lua
        self.GetPlayerColor = function()
            return myColor

        end
    end

    return

end

local coroutine_yield = coroutine.yield

ENT.CoroutineThresh = 0.0001
ENT.MaxPathingIterations = 5000

ENT.JumpHeight = 80
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.PathGoalToleranceFinal = 50
ENT.SpawnHealth = 100
ENT.AimSpeed = 300
ENT.WalkSpeed = 50
ENT.MoveSpeed = 150
ENT.RunSpeed = 250
ENT.AccelerationSpeed = 750
ENT.InformRadius = 20000

ENT.CanUseStuff = nil

ENT.FistDamageMul = 0.35
ENT.NoAnimLayering = nil -- this is what makes it stop moving forward when attacking
ENT.DuelEnemyDist = 350
ENT.CloseEnemyDistance = 500

ENT.DoMetallicDamage = false -- metallic fx like bullet ricochet sounds
ENT.MetallicMoveSounds = false
ENT.ReallyStrong = false
ENT.ReallyHeavy = false
ENT.DontDropPrimary = true

ENT.LookAheadOnlyWhenBlocked = nil
ENT.alwaysManiac = nil -- always create feuds between us and other terms/supercops, when they damage us
ENT.HasFists = true
ENT.IsTerminatorZambie = true

ENT.frenzyBoredomEnts = {}
ENT.zamb_nextRandomFrenzy = 0

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

local ZAMBIE_MODEL = "models/player/zombie_classic.mdl"
ENT.ARNOLD_MODEL = ZAMBIE_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 0.95, 1.05 ) end
ENT.MyPhysicsMass = 80

ENT.TERM_FISTS = "weapon_term_zombieclaws"

CreateConVar( "zambie_nextbot_forcedmodel", ZAMBIE_MODEL, bit.bor( FCVAR_ARCHIVE ), "Override the supercop nextbot's spawned-in model. Model needs to be rigged for player movement" )

local function zambieModel()
    local convar = GetConVar( "zambie_nextbot_forcedmodel" )
    local model = ZAMBIE_MODEL
    if convar then
        local varModel = convar:GetString()
        if varModel and util.IsValidModel( varModel ) then
            model = varModel

        end
    end
    return model

end

if not zambieModel() then
    RunConsoleCommand( "zambie_nextbot_forcedmodel", ZAMBIE_MODEL )

end

ENT.Models = { ZAMBIE_MODEL }

function ENT:canDoRun()
    if self.forcedShouldWalk and self.forcedShouldWalk > CurTime() then return end
    if self.isInTheMiddleOfJump then return end
    local nearObstacleBlockRunning = self.nearObstacleBlockRunning or 0
    if nearObstacleBlockRunning > CurTime() and not self.IsSeeEnemy then return end
    local area = self:GetCurrentNavArea()
    if not IsValid( area ) then return end
    if area:HasAttributes( NAV_MESH_CLIFF ) then return end
    if area:HasAttributes( NAV_MESH_CROUCH ) then return end
    local nextArea = self:GetNextPathArea()
    if self:getMaxPathCurvature( area, self.MoveSpeed ) > 0.45 then return end
    if self:confinedSlope( area, nextArea ) == true then return end
    if not IsValid( nextArea ) then return true end
    local myPos = self:GetPos()
    if myPos:DistToSqr( nextArea:GetClosestPointOnArea( myPos ) ) > ( self.MoveSpeed * 1.25 ) ^ 2 then return true end
    if nextArea:HasAttributes( NAV_MESH_CLIFF ) then return end
    if nextArea:HasAttributes( NAV_MESH_CROUCH ) then return end
    local minSizeNext = math.min( nextArea:GetSizeX(), nextArea:GetSizeY() )
    if minSizeNext < 25 then return end
    return true

end

function ENT:shouldDoWalk()
    if self.forcedShouldWalk and self.forcedShouldWalk > CurTime() then return true end

    local area = self:GetCurrentNavArea()
    if not area then return end
    if not area:IsValid() then return end
    local minSize = math.min( area:GetSizeX(), area:GetSizeY() )
    if minSize < 45 then return true end
    local nextArea = self:GetNextPathArea()
    if self:confinedSlope( area, nextArea ) then return true end
    if self:getMaxPathCurvature( area, self.WalkSpeed, true ) > 0.85 then return true end
    if not nextArea then return end
    if not nextArea:IsValid() then return end
    return true

end

function ENT:AdditionalAvoidAreas( costs )

    if not self.HasBrains then return end

    if not terminator_Extras.zamb_IndexedRottingAreas then return end
    costs = costs or {}

    local scale = self:GetCreationID() % 10
    scale = scale / 10

    local rotAmounts = terminator_Extras.zamb_RottingAreas
    for _, area in ipairs( terminator_Extras.zamb_IndexedRottingAreas ) do
        if not IsValid( area ) then continue end
        local oldMul = costs[ area:GetID() ] or 0
        costs[ area:GetID() ] = oldMul + rotAmounts[ area ] * scale

    end
    return costs

end

local walkStart = ACT_HL2MP_WALK_ZOMBIE_01
local function randomWalk( ent )
    return walkStart + ( ent:GetCreationID() % 4 )

end

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = randomWalk,
    [ACT_MP_RUN]                        = IdleActivity + 2,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = IdleActivity + 9,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = nil
ENT.zamb_AttackAnim = nil
ENT.zamb_CantCall = nil

function ENT:DoHardcodedRelations()
    self.term_HardCodedRelations = {
        ["npc_zombie"] = { D_LI, D_LI, 1000 },
        ["npc_zombie_torso"] = { D_LI, D_LI, 1000 },
        ["npc_headcrab"] = { D_LI, D_LI, 1000 },
        ["npc_fastzombie"] = { D_LI, D_LI, 1000 },
        ["npc_fastzombie_torso"] = { D_LI, D_LI, 1000 },
        ["npc_headcrab_fast"] = { D_LI, D_LI, 1000 },
        ["npc_poisonzombie"] = { D_LI, D_LI, 1000 },
        ["npc_headcrab_black"] = { D_LI, D_LI, 1000 },
        ["npc_zombine"] = { D_LI, D_LI, 1000 },
    }
end

function ENT:AdditionalInitialize()
    self:SetModel( zambieModel() )
    self:SetBodygroup( 1, 1 )

    self.isTerminatorHunterChummy = "zambies"
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4
    local hasBrains = math.random( 1, 100 ) < 20
    if hasBrains then
        self.HasBrains = true
        terminator_Extras.RegisterListener( self )

    end

    self.TakesFallDamage = true
    self.HeightToStartTakingDamage = 200
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1000
    self.walkedAreas = nil -- disables walked area logic, we're fodder, we dont need that

end

local cutoff = 35^2

function ENT:AdditionalThink()
    if self.loco:GetVelocity():LengthSqr() > cutoff then
        self.term_NextIdleTaunt = CurTime() + math.Rand( 0.5, 1 )
        return

    end
    if self.term_NextIdleTaunt > CurTime() then return end

    self.term_NextIdleTaunt = CurTime() + math.Rand( 3, 7 )

    self:RunTask( "ZambOnGrumpy" )

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl = 85
    local snd = foot and "Zombie.FootstepRight" or "Zombie.FootstepLeft"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76
        snd = foot and "Zombie.ScuffRight" or "Zombie.ScuffLeft"

    end
    self:EmitSound( snd, lvl, 100, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

function ENT:ZAMB_AngeringCall()
    self:StopMoving()
    self:InvalidatePath( "angeringcall" )
    self.nextNewPath = CurTime() + 0.5

    self:Term_SpeakSound( "blarg", function( me )
        local callAnim = me.zamb_CallAnim or ACT_GMOD_GESTURE_TAUNT_ZOMBIE
        me:DoGesture( callAnim, 0.8, true )
        local filterAllPlayers = RecipientFilter()
        filterAllPlayers:AddAllPlayers()
        me:EmitSound( self.term_CallingSound, 120 + self.term_SoundLevelShift, math.random( 95, 105 ) + self.term_SoundPitchShift, 0.5, CHAN_STATIC, sndFlags, nil, filterAllPlayers )
        me:EmitSound( self.term_CallingSmallSound, 85 + self.term_SoundLevelShift, math.random( 75, 85 ) + self.term_SoundPitchShift, 1, CHAN_STATIC, sndFlags, nil )

        for _, ally in ipairs( self:GetNearbyAllies() ) do
            if not IsValid( ally ) then continue end
            local time = math.Rand( 1, 3 )
            if ally.HasBrains then
                time = 0.5

            end
            timer.Simple( time, function()
                if not IsValid( ally ) then return end
                ally:Anger( math.random( 55, 75 ) )

            end )
        end
    end )
end

function ENT:ZAMB_NormalCall()
    local callAnim = self.zamb_CallAnim or ACT_GMOD_GESTURE_TAUNT_ZOMBIE
    if math.random( 1, 100 ) > 75 then
        self:DoGesture( callAnim, 1.1, true )

    else
        self:DoGesture( callAnim, 1.4, self.NoAnimLayering or false )

    end
    self:Term_SpeakSound( self.term_FindEnemySound )

end

local nextZombieCall = 0

ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 1.1
ENT.term_SoundPitchShift = 0
ENT.term_SoundLevelShift = 0

ENT.term_LoseEnemySound = "Zombie.Idle"
ENT.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
ENT.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
ENT.term_FindEnemySound = "Zombie.Alert"
ENT.term_AttackSound = "Zombie.Alert"
ENT.term_AngerSound = "Zombie.Idle"
ENT.term_DamagedSound = "Zombie.Pain"
ENT.term_DieSound = "Zombie.Die"
ENT.term_JumpSound = "npc/zombie/foot1.wav"

ENT.IdleLoopingSounds = {}
ENT.AngryLoopingSounds = {
    "npc/zombie/moan_loop1.wav",
    "npc/zombie/moan_loop2.wav",
    "npc/zombie/moan_loop3.wav",
    "npc/zombie/moan_loop4.wav",

}

local CUTTING_MDLS = {
    ["models/props_junk/sawblade001a.mdl"] = true,
    ["models/props_c17/trappropeller_blade.mdl"] = true,
}

--local MEMORY_MEMORIZING = 1
--local MEMORY_INERT = 2
local MEMORY_BREAKABLE = 4
local MEMORY_VOLATILE = 8
--local MEMORY_THREAT = 16
--local MEMORY_WEAPONIZEDNPC = 32
--local MEMORY_DAMAGING = 64

function ENT:DoCustomTasks( defaultTasks )
    self.TaskList = {
        ["shooting_handler"] = defaultTasks["shooting_handler"],
        ["awareness_handler"] = defaultTasks["awareness_handler"],
        ["enemy_handler"] = defaultTasks["enemy_handler"],
        ["inform_handler"] = defaultTasks["inform_handler"],
        ["reallystuck_handler"] = defaultTasks["reallystuck_handler"],
        ["movement_wait"] = defaultTasks["movement_wait"],
        ["playercontrol_handler"] = defaultTasks["playercontrol_handler"],
        ["zambstuff_handler"] = {
            ZambOnGrumpy = function( self, data )
                if self.HasBrains or self.zamb_CantCall or math.random( 1, 100 ) > 25 then
                    self:Term_SpeakSound( self.term_FindEnemySound )
                    return

                elseif nextZombieCall < CurTime() and self.DistToEnemy > 750 then
                    nextZombieCall = CurTime() + 40
                    self:ZAMB_AngeringCall()

                elseif self.DistToEnemy > 750 then
                    self:ZAMB_NormalCall()

                end
            end,
            OnBlockingAlly = function( self, data, theAlly, sinceStarted )
                local myOffset = self:GetCreationID() % 5
                if self:IsCrouching() and sinceStarted >= myOffset then
                    self:Anger( math.random( 5, 10 ) )

                elseif self.IsSeeEnemy then
                    if self.DistToEnemy < 500 and sinceStarted >= myOffset then
                        self:RunTask( "ZambOnGrumpy" )

                    elseif sinceStarted >= myOffset then
                        self:Anger( math.random( 5, 10 ) )

                    end
                elseif sinceStarted >= myOffset then
                    self:Anger( math.random( 1, 5 ) )

                end
            end,
            EnemyLost = function( self, data )
                self:Term_SpeakSound( self.term_LoseEnemySound )

            end,
            EnemyFound = function( self, data )
                self:RunTask( "ZambOnGrumpy" )

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
                self:EmitSound( self.term_JumpSound, 75 + self.term_SoundLevelShift, math.random( 95, 105 ) + self.term_SoundPitchShift, 1, CHAN_VOICE, sndFlags )

            end,
            OnDamaged = function( self, data, damage )
                self:Term_SpeakSoundNow( self.term_DamagedSound, self.term_SoundPitchShift )

            end,
            PreventBecomeRagdollOnKilled = function( self, data, damage ) -- handle becoming zombie torso
                local torsoData = terminator_Extras.zamb_TorsoZombieClasses[self:GetClass()]
                if not torsoData then return end

                local cur = CurTime()
                local oldDensity = terminator_Extras.zamb_TorsoDensityNum
                if oldDensity > math.random( cur, cur + 60 ) then return end

                local becomeTorso
                local ratio = math.random( 25, 75 )
                if damage:IsExplosionDamage() and damage:GetDamage() < math.min( self:Health() + ratio, ratio ) then
                    becomeTorso = true

                end
                if not becomeTorso then
                    local inflictor = damage:GetInflictor()
                    local dmgPos = damage:GetDamagePosition()
                    local hitDistToHead = dmgPos and self:NearestPoint( dmgPos ):Distance( self:GetShootPos() )
                    if IsValid( inflictor ) and IsValid( inflictor:GetPhysicsObject() ) and inflictor:GetModel() and CUTTING_MDLS[string.lower( inflictor:GetModel() )] and hitDistToHead > 25 then
                        becomeTorso = true

                    elseif damage:IsBulletDamage() and hitDistToHead > 40 then
                        becomeTorso = true

                    end
                end

                if becomeTorso then
                    local torso = ents.Create( torsoData.class )
                    if not IsValid( torso ) then return end
                    local myPos = self:GetPos()

                    local footDistToShoot = self:GetShootPos() - myPos
                    local torsoSpawnPos = myPos + footDistToShoot / 1.75
                    toroSpawnPos = torsoSpawnPos + self:GetForward() * footDistToShoot:Length() / 3
                    torso:SetPos( toroSpawnPos )

                    torso:SetAngles( self:GetAngles() )
                    torso:Spawn()

                    hook.Run( "zamb_OnBecomeTorso", self, torso )
                    undo.ReplaceEntity( self, torso )
                    copyMatsOver( self, torso )

                    terminator_Extras.zamb_TorsoDensityNum = math.max( oldDensity + torso:Health() / 2, cur + torso:Health() / 2 )

                    if torsoData.legs then
                        if self:GetShouldServerRagdoll() then
                            local legs = ents.Create( "prop_ragdoll" )
                            if IsValid( legs ) then
                                SafeRemoveEntityDelayed( legs, 15 )
                                torso:DeleteOnRemove( legs )
                                legs:SetModel( torsoData.legs )
                                legs:SetPos( self:GetPos() )
                                legs:SetAngles( self:GetAngles() )
                                legs:Spawn()
                                copyMatsOver( self, legs )
                                legs:SetVelocity( damage:GetDamageForce() )

                            end
                        else
                            self:SetModel( torsoData.legs ) -- this little hack is much better than networking this ragdoll creation imo
                            return

                        end
                    else
                        SafeRemoveEntity( self )
                        return true

                    end
                end
            end,
            OnKilled = function( self, data, damage, rag )
                self:EmitSound( "common/null.wav", 80 + self.term_SoundLevelShift, 100, 1, CHAN_VOICE )
                self:EmitSound( self.term_DieSound, 80 + self.term_SoundLevelShift, 100 + self.term_SoundPitchShift, 1, CHAN_VOICE, sndFlags )
                local b1, b2 = self:GetCollisionBounds()
                b1 = b1 * 2
                b2 = b2 * 2
                local deadlyAreas = navmesh.FindInBox( self:LocalToWorld( b1 ), self:LocalToWorld( b2 ) )
                if #deadlyAreas > 0 then
                    local rotPunishment = self:GetMaxHealth() / #deadlyAreas
                    rotPunishment = rotPunishment / 100
                    for _, area in ipairs( deadlyAreas ) do
                        local old = terminator_Extras.zamb_RottingAreas[ area ] or 0
                        terminator_Extras.zamb_RottingAreas[ area ] = old + rotPunishment
                        terminator_Extras.zamb_AreasLastRot[ area ] = CurTime()

                    end
                end
            end,
            OnPathFail = function( self )
                self:ReallyAnger( 20 )
                self:RunTask( "ZambOnGrumpy" )

            end,

            ShouldRun = function( self, data )
                local goodToRun = self:IsAngry() and self:canDoRun()
                if not goodToRun then return false end

                local enem = self:GetEnemy()
                if not IsValid( enem ) then
                    local creationId = self:GetCreationID()
                    local fraction = creationId % 5
                    local offsettedCur = CurTime() + creationId
                    local timing = 20 + ( creationId % 20 )
                    return ( offsettedCur % timing ) < ( timing / fraction )
                end
                return goodToRun
            end,
            ShouldWalk = function( self, data )
                return ( not self.HasBrains and not self:IsAngry() ) or self:shouldDoWalk()
            end,
        },
        ["movement_handler"] = {
            OnStart = function( self, data )
                self:StartTask( "zambstuff_handler" )
                self:TaskComplete( "movement_handler" )
                self:StartTask2( "movement_wander", nil, "spawned in!" )

            end,
        },
        ["movement_followenemy"] = {
            OnStart = function( self, data )
                data.nextPathAttempt = 0
                if not self.isUnstucking then
                    self:InvalidatePath( "followenemy" )
                end
            end,
            BehaveUpdateMotion = function( self, data )
                local enemy = self:GetEnemy()
                local validEnemy = IsValid( enemy )
                local enemyPos = self.EnemyLastPos
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp
                local toPos = enemyPos

                if not self.IsSeeEnemy and data.overridePos then
                    toPos = data.overridePos

                end

                local nextPathAttempt = data.nextPathAttempt or 0 -- HACK

                if nextPathAttempt < CurTime() and toPos and not data.Unreachable and self:primaryPathInvalidOrOutdated( toPos ) then
                    data.nextPathAttempt = CurTime() + math.Rand( 0.1, 0.5 )
                    if self.term_ExpensivePath then
                        data.nextPathAttempt = CurTime() + math.Rand( 0.5, 1.5 )

                    end
                    local result = terminator_Extras.getNearestPosOnNav( toPos )
                    local reachable = self:areaIsReachable( result.area )
                    if not reachable then data.Unreachable = true return end

                    data.triedToPath = nil

                    if self.HasBrains and ( self.zamb_AlwaysFlank or math.random( 1, 100 ) > 25 ) then
                        -- split up!
                        local otherHuntersHalfwayPoint = self:GetOtherHuntersProbableEntrance()
                        local splitUpResult
                        local splitUpPos
                        local splitUpBubble
                        if otherHuntersHalfwayPoint then
                            splitUpPos = otherHuntersHalfwayPoint
                            splitUpBubble = self:GetPos():Distance( otherHuntersHalfwayPoint ) * 0.7
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        elseif validEnemy and self.zamb_AlwaysFlank then
                            splitUpPos = enemy:GetPos()
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        end

                        if splitUpResult and self:areaIsReachable( splitUpResult.area ) then
                            -- flank em!
                            self:SetupFlankingPath( enemyPos, splitUpResult.area, splitUpBubble )
                            data.triedToPath = true
                            coroutine_yield()

                        end
                    end
                    -- cant flank
                    if not self:primaryPathIsValid() then
                        self:SetupPathShell( result.pos )
                        data.triedToPath = true
                        coroutine_yield()

                    end
                    if not self:primaryPathIsValid() then
                        data.overridePos = nil
                        data.Unreachable = true
                        return

                    end
                end


                local distToExit = self.DuelEnemyDist

                local lookAtGoal = self.zamb_LookAheadWhenRunning or not ( self.IsSeeEnemy and self.HasBrains )
                local result = self:ControlPath2( lookAtGoal )

                if lookAtGoal then
                    self.blockAimingAtEnemy = CurTime() + 0.15

                end

                if false and self:CanBashLockedDoor( self:GetPos(), 1000 ) then
                    --self:BashLockedDoor( "movement_followenemy" )
                elseif not goodEnemy and not self:primaryPathIsValid() and data.triedToPath then
                    self:TaskFail( "movement_followenemy" )
                    self:StartTask2( "movement_wander", nil, "i cant get to them/no enemy" )
                    data.overridePos = nil
                elseif not self:primaryPathIsValid() and data.Unreachable then
                    data.overridePos = nil
                    if math.random( 1, 100 ) < 50 or self:IsReallyAngry() then
                        self:TaskFail( "movement_followenemy" )
                        self:StartTask2( "movement_frenzy", nil, "i cant get to them" )

                    else
                        self:TaskFail( "movement_followenemy" )
                        self:StartTask2( "movement_wander", nil, "i cant get to them" )

                    end
                elseif goodEnemy and self.NothingOrBreakableBetweenEnemy and self.DistToEnemy < distToExit and not self.terminator_HandlingLadder then
                    self:TaskComplete( "movement_followenemy" )
                    self:StartTask2( "movement_duelenemy_near", nil, "i gotta punch em" )
                elseif result or ( not goodEnemy and self:GetRangeTo( self:GetPath():GetEnd() ) < 300 ) then
                    data.overridePos = nil
                    if not self.IsSeeEnemy then
                        self:TaskFail( "movement_followenemy" )
                        self:StartTask2( "movement_wander", nil, "got there, but no enemy" )
                    end
                end
            end,
        },
        ["movement_duelenemy_near"] = {
            OnStart = function( self, data )
                data.badCount = 0
            end,
            BehaveUpdateMotion = function( self, data )
                local enemy = self:GetEnemy()
                local validEnemy = IsValid( enemy )
                local enemyPos = self.EnemyLastPos
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp
                local maxDuelDist = self.DuelEnemyDist + 100

                local badAdd = 0

                if not self.NothingOrBreakableBetweenEnemy and self:GetCurrentSpeed() <= 5 then
                    badAdd = badAdd + 5

                end
                if not self.IsSeeEnemy and not self.NothingOrBreakableBetweenEnemy then
                    badAdd = badAdd + 1

                end
                if goodEnemy and self:GetRangeTo( enemyPos ) > maxDuelDist then
                    badAdd = badAdd + 2

                end
                if not goodEnemy then
                    badAdd = badAdd + 2

                end

                if badAdd then
                    data.badCount = data.badCount + badAdd

                else
                    data.badCount = 0

                end

                if data.badCount > 25 or not aliveOrHp then
                    local propInMyWay = ( self.IsSeeEnemy and not self.NothingOrBreakableBetweenEnemy ) and ( math.random( 1, 100 ) < 75 or self:IsReallyAngry() )
                    local propInMyWay2 = IsValid( self:GetCachedDisrespector() ) and self:IsReallyAngry()
                    if propInMyWay or propInMyWay2 then
                        self:TaskComplete( "movement_duelenemy_near" )
                        self:StartTask2( "movement_frenzy", nil, "got bored" )

                    else
                        self:TaskComplete( "movement_duelenemy_near" )
                        self:StartTask2( "movement_followenemy", nil, "got bored" )

                    end
                elseif validEnemy then -- the dueling in question
                    local enemVel = enemy:GetVelocity()
                    enemVel.z = enemVel.z * 0.15
                    local velProduct = math.Clamp( enemVel:Length() * 1.4, 0, self.DistToEnemy * 0.8 )
                    local offset = enemVel:GetNormalized() * velProduct

                    -- determine where player CAN go
                    -- dont build path to somewhere behind walls
                    local mymins,mymaxs = self:GetCollisionBounds()
                    mymins = mymins * 0.5
                    mymaxs = mymaxs * 0.5

                    local pathHull = {}
                    pathHull.start = enemyPos
                    pathHull.endpos = enemyPos + offset
                    pathHull.mask = MASK_SOLID_BRUSHONLY
                    pathHull.mins = mymins
                    pathHull.maxs = mymaxs

                    local whereToInterceptTr = util.TraceHull( pathHull )
                    if self:primaryPathIsValid() then
                        self:InvalidatePath( "im closing in on my enemy!" )

                    end

                    -- default, just run up to enemy
                    local gotoPos = enemyPos
                    local angy = self:IsAngry()
                    -- if we mad though, predict where they will go, and surprise them
                    if self.HasBrains and angy and enemy.GetAimVector then
                        local flat = enemy:GetAimVector()
                        flat.z = 0
                        flat:Normalize()
                        gotoPos = enemyPos + -flat

                    elseif angy then
                        gotoPos = whereToInterceptTr.HitPos

                    end

                    gotoPos = gotoPos + VectorRand() * 15

                    --debugoverlay.Cross( gotoPos, 10, 1, Color( 255,255,0 ) )
                    self:GotoPosSimple( gotoPos, 35 )

                end
            end,
        },

        ["movement_frenzy"] = { -- break props!
            OnStart = function( self, data )
                data.quitCount = 0
                data.currentFrenzyFocus = nil
                data.startingBoredom = 0
                data.maxDist = 500
                data.everFocused = nil
                data.validBeatup = nil
            end,
            BehaveUpdateMotion = function( self, data )
                local focus = data.currentFrenzyFocus
                local validFocus = IsValid( focus )
                local maxDist = data.maxDist
                if not validFocus then
                    local bestScore = 0
                    for _, curr in ipairs( self.awarenessSubstantialStuff ) do
                        if not IsValid( curr ) then continue end -- this tbl is usually outdated
                        if not curr:IsSolid() then continue end
                        if curr.zamb_NeverFrenzyCurious then continue end
                        if curr.isTerminatorHunterChummy and curr.isTerminatorHunterChummy == self.isTerminatorHunterChummy then continue end

                        local range = self:GetRangeTo( curr )
                        if range > maxDist then continue end

                        local currsBoredom = self.frenzyBoredomEnts[ curr ] or 1
                        local entsBoredom = curr.zamb_entsBoredom or 0
                        local boredom = currsBoredom + entsBoredom
                        local score = math.max( maxDist - range, 0 )
                        score = score / boredom
                        if score > bestScore then
                            data.currentFrenzyFocus = curr
                            data.startingBoredom = boredom

                        end
                    end
                    if IsValid( data.currentFrenzyFocus ) and bestScore > 10 then
                        data.everFocused = true
                        debugoverlay.Text( data.currentFrenzyFocus, tostring( bestScore ), 5, false )
                        data.maxDist = 500
                        validFocus = true
                        focus = data.currentFrenzyFocus

                    else
                        data.maxDist = data.maxDist + 100

                    end
                end

                local boredToQuit = data.startingBoredom
                local boredAdd = 1
                local quitAdd = 0
                if self.NothingOrBreakableBetweenEnemy then
                    quitAdd = quitAdd + 5

                end
                if not validFocus then
                    if data.everFocused then
                        quitAdd = quitAdd + 10

                    else
                        quitAdd = quitAdd + 50

                    end
                else
                    boredToQuit = boredToQuit + 25

                    local memory = self:getMemoryOfObject( focus )
                    if not data.validBeatup then
                        boredAdd = boredAdd + 5

                    elseif memory == MEMORY_BREAKABLE then
                        quitAdd = quitAdd + -1
                        boredAdd = 0.1
                        boredToQuit = boredToQuit + 50

                    elseif memory == MEMORY_VOLATILE and not self:IsReallyAngry() then -- anger clouds "judgement"
                        boredAdd = boredAdd + 10
                        quitAdd = quitAdd + -1
                        boredToQuit = boredToQuit + 25

                    else
                        quitAdd = quitAdd + 1
                        boredAdd = boredAdd + 1

                    end
                    local obj = focus:GetPhysicsObject()
                    if IsValid( obj ) and not obj:IsMotionEnabled() then
                        boredAdd = boredAdd + 1
                        local old = focus.zamb_entsBoredom or 0
                        focus.zamb_entsBoredom = old + 0.1

                    end

                    local oldBored = self.frenzyBoredomEnts[ focus ] or 0
                    self.frenzyBoredomEnts[ focus ] = math.Clamp( oldBored + boredAdd, 0, math.huge )
                    if self.frenzyBoredomEnts[ focus ] > boredToQuit then
                        data.currentFrenzyFocus = nil
                        return

                    end
                end

                local enemy = self:GetEnemy()
                local validEnemy = IsValid( enemy )
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp

                local enemyIsReachable
                if goodEnemy then
                    local result = terminator_Extras.getNearestPosOnNav( enemyPos )
                    enemyIsReachable = self:areaIsReachable( result.area )
                end

                if enemyIsReachable then
                    quitAdd = quitAdd + 10

                end

                data.quitCount = math.Clamp( data.quitCount + quitAdd, 0, math.huge )

                if data.quitCount > 100 then
                    if self.IsSeeEnemy then
                        self:TaskComplete( "movement_frenzy" )
                        self:StartTask2( "movement_followenemy", nil, "got bored" )

                    else
                        self:TaskComplete( "movement_frenzy" )
                        self:StartTask2( "movement_wander", nil, "got bored" )

                    end
                else
                    data.validBeatup = self:beatUpEnt( focus )

                end
            end,
        },

        -- complex wander, preserves areas already explored, makes bot cross entire map pretty much
        ["movement_wander"] = {
            OnStart = function( self, data )
                self.nextInterceptTry = math.max( CurTime() + 1, self.nextInterceptTry + 1 )
                data.nextWander = CurTime() + math.Rand( 0.05, 0.25 )
                if not self.isUnstucking then
                    self:InvalidatePath( "followenemy" )
                end
            end,
            BehaveUpdateMotion = function( self, data )
                local enemy = self:GetEnemy()
                local validEnemy = IsValid( enemy )
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp

                local enemyIsReachable
                if goodEnemy then
                    local result = terminator_Extras.getNearestPosOnNav( enemy:GetPos() )
                    enemyIsReachable = self:areaIsReachable( result.area )

                end

                if not data.toPos and data.nextWander < CurTime() then
                    data.nextWander = CurTime() + math.Rand( 0.05, 0.25 )
                    local smellySpot = terminator_Extras.zamb_SmelliestRottingArea
                    local foundSomewhereNotBeen = nil
                    if IsValid( smellySpot ) and self:areaIsReachable( smellySpot ) and math.random( 1, 100 ) < 50 then
                        data.toPos = smellySpot:GetCenter()

                    else
                        data.beenAreas = data.beenAreas or self.wanderPreserveAreas or {}

                        self.wanderPreserveAreas = nil

                        local canDoUnderWater = self:WaterLevel() > 0
                        local myNavArea = self:GetCurrentNavArea()
                        if not IsValid( myNavArea ) then return end

                        local anotherHuntersPos = self.HasBrains and self:GetOtherHuntersProbableEntrance() or nil

                        --normal path
                        local dir = data.dir or self:GetForward()
                        dir = -dir
                        local scoreData = {}
                        local wanderAreasTraversed = {}
                        scoreData.canDoUnderWater = canDoUnderWater
                        scoreData.self = self
                        scoreData.hasBrains = self.HasBrains
                        scoreData.forward = dir:Angle()
                        scoreData.startArea = myNavArea
                        scoreData.startPos = scoreData.startArea:GetCenter()
                        scoreData.beenAreas = data.beenAreas
                        scoreData.ignoreBearing = data.ignoreBearing
                        if anotherHuntersPos then
                            scoreData.doSpreadOut = true
                            scoreData.spreadOutAvoidAreas = {}
                            local areasFound = navmesh.Find( anotherHuntersPos, 500, 100, 100 )

                            for _, currArea in ipairs( areasFound ) do
                                scoreData.spreadOutAvoidAreas[currArea:GetID()] = true

                            end
                        end

                        local scoreFunction = function( scoreData, area1, area2 ) -- this is the function that determines the score of a navarea
                            local dropToArea = area2:ComputeAdjacentConnectionHeightChange( area1 )
                            local area2sCenter = area2:GetCenter()
                            local score = area2sCenter:DistToSqr( scoreData.startPos ) * math.Rand( 0.8, 1.4 )

                            if scoreData.hasBrains and dropToArea > self.loco:GetJumpHeight() then
                                return 0

                            end
                            local area2sId = area2:GetID()

                            if scoreData.beenAreas[area2sId] then -- avoid already been areas
                                score = score * 0.0001

                            else
                                foundSomewhereNotBeen = true

                            end
                            -- dont group up!
                            if scoreData.doSpreadOut and scoreData.spreadOutAvoidAreas[area2sId] then
                                score = score * 0.001

                            end
                            -- go forward
                            if not data.ignoreBearing and math.abs( terminator_Extras.BearingToPos( scoreData.startPos, scoreData.forward, area2sCenter, scoreData.forward ) ) < 22.5 then
                                score = score^1.5

                            end
                            if not scoreData.canDoUnderWater and area2:IsUnderwater() then
                                score = score * 0.001

                            end
                            if math.abs( dropToArea ) > 100 then
                                score = score * 0.001

                            end
                            if area2 == data.lastToArea then
                                score = score * 0.001

                            end

                            --debugoverlay.Text( area2sCenter, tostring( math.Round( score ) ), 8, false )

                            wanderAreasTraversed[area2sId] = true

                            return score

                        end

                        data.toPos, data.lastToArea = self:findValidNavResult( scoreData, self:GetPos(), math.random( 1000, 2000 ), scoreFunction )

                        table.Merge( data.beenAreas, wanderAreasTraversed )

                    end

                    if not data.toPos then
                        data.nextWander = CurTime() + 5
                        data.ignoreBearing = true

                    end

                    if not foundSomewhereNotBeen then
                        data.beenAreas = nil
                        data.ignoreBearing = true

                    else
                        self.wanderPreserveAreas = data.beenAreas
                        data.ignoreBearing = nil

                    end
                end
                coroutine_yield()
                if data.toPos and self:primaryPathInvalidOrOutdated( data.toPos ) then
                    local result = terminator_Extras.getNearestPosOnNav( data.toPos )
                    local reachable = self:areaIsReachable( result.area )
                    if not reachable then
                        data.nextWander = CurTime() + math.random( 1, 5 )
                        data.toPos = nil
                        coroutine_yield( "wait" )
                        return

                    end

                    if self.HasBrains and math.random( 1, 100 ) > 25 then
                        -- split up!
                        local otherHuntersHalfwayPoint = self:GetOtherHuntersProbableEntrance()
                        local splitUpResult
                        local splitUpPos
                        local splitUpBubble
                        if otherHuntersHalfwayPoint then
                            splitUpPos = otherHuntersHalfwayPoint
                            splitUpBubble = self:GetPos():Distance( otherHuntersHalfwayPoint ) * 0.7
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        end

                        if splitUpResult and self:areaIsReachable( splitUpResult.area ) then
                            -- flank em!
                            self:SetupFlankingPath( enemyPos, splitUpResult.area, splitUpBubble )
                            coroutine_yield()

                        end
                    end
                    -- cant flank
                    if not self:primaryPathIsValid() then
                        self:SetupPathShell( result.pos )
                        coroutine_yield()

                    end
                    if not self:primaryPathIsValid() then
                        data.nextWander = CurTime() + 5
                        data.toPos = nil
                        coroutine_yield( "wait" )
                        return

                    end
                end

                local lookAtGoal = self.zamb_LookAheadWhenRunning or not ( self.IsSeeEnemy and self.HasBrains )
                local result = self:ControlPath2( lookAtGoal )

                if lookAtGoal then
                    self.blockAimingAtEnemy = CurTime() + 0.15

                end

                if false and self:CanBashLockedDoor( self:GetPos(), 1000 ) then
                    --self:BashLockedDoor( "movement_wander" )
                elseif IsValid( self:GetCachedDisrespector() ) and self.zamb_nextRandomFrenzy < CurTime() then
                    local add = 60
                    if self:IsReallyAngry() then
                        add = 5

                    elseif self:IsAngry() then
                        add = 30

                    end
                    self.zamb_nextRandomFrenzy = CurTime() + add

                    self:TaskComplete( "movement_wander" )
                    self:StartTask2( "movement_frenzy", nil, "i want to attack random stuff" )

                elseif self.HasBrains and self:beatupVehicleIfWeCan( "movement_wander" ) then
                    return

                elseif self.nextInterceptTry < CurTime() and self:interceptIfWeCan( nil, data ) then
                    self.nextInterceptTry = CurTime() + 1
                    if not self.HasBrains then
                        local areasNearby = navmesh.Find( self.lastInterceptPos, 250, 100, 100 )
                        local randomArea = areasNearby[math.random( 1, #areasNearby )]
                        if IsValid( randomArea ) and self:areaIsReachable( randomArea ) then
                            self.nextInterceptTry = CurTime() + 5
                            local randomPosNearby = randomArea:GetRandomPoint()
                            self:TaskComplete( "movement_wander" )
                            self:StartTask2( "movement_followenemy", { overridePos = randomPosNearby }, "i can intercept someone" )
                            self.lastInterceptPos = nil

                        end
                    else
                        local nearestArea = terminator_Extras.getNearestNav( self.lastInterceptPos )
                        if IsValid( nearestArea ) and self:areaIsReachable( nearestArea ) then
                            self.nextInterceptTry = CurTime() + 15
                            local pos = nearestArea:GetRandomPoint()
                            self:TaskComplete( "movement_wander" )
                            self:StartTask2( "movement_followenemy", { overridePos = pos }, "i can intercept someone" )
                            self.lastInterceptPos = nil

                        end
                    end
                elseif goodEnemy and enemyIsReachable then
                    self:TaskFail( "movement_wander" )
                    self:StartTask2( "movement_followenemy", nil, "new enemy!" )
                elseif result then
                    data.toPos = nil
                    data.nextWander = CurTime() + 1
                    coroutine_yield( "wait" )
                end
            end,
        },
    }
end