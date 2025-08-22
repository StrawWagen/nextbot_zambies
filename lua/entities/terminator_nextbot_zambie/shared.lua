AddCSLuaFile()

ENT.Base = "terminator_nextbot"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambie", {
    Name = "Zombie",
    Class = "terminator_nextbot_zambie",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambie", ENT.PrintName )

    function ENT:AdditionalClientInitialize()
        local myColor = Vector( math.Rand( 0.1, 1 ), math.Rand( 0, 0.5 ), math.Rand( 0, 0.1 ) )
        --https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/matproxy/player_color.lua
        self.GetPlayerColor = function()
            return myColor

        end
    end

    return

end

local entMeta = FindMetaTable( "Entity" )

local coroutine_yield = coroutine.yield

ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 40
ENT.ThreshMulIfDueling = 4 -- thresh is multiplied by this amount if we're closer than DuelEnemyDist
ENT.ThreshMulIfClose = 2 -- if we're closer than DuelEnemyDist * 2
ENT.MaxPathingIterations = 2500

ENT.JumpHeight = 80
ENT.Term_Leaps = false
ENT.Term_LeapMinimizesHeight = true -- zombies should always leap as low as possible
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
ENT.DuelEnemyDist = 450
ENT.CloseEnemyDistance = 500

ENT.DoMetallicDamage = false -- metallic fx like bullet ricochet sounds
ENT.MetallicMoveSounds = false
ENT.ReallyStrong = false
ENT.ReallyHeavy = false
ENT.DontDropPrimary = true
ENT.CanSwim = true
ENT.BreathesAir = true

ENT.LookAheadOnlyWhenBlocked = nil
ENT.alwaysManiac = nil -- always create feuds between us and other terms/supercops, when they damage us
ENT.HasFists = true
ENT.IsTerminatorZambie = true

ENT.frenzyBoredomEnts = {}
ENT.zamb_nextRandomFrenzy = 0
ENT.zamb_BrainsChance = 20
ENT.zamb_NextPathAttempt = 0

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true -- enable speaking thinker
ENT.HasBrains = false -- default to no brains

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
    if self:getMaxPathCurvature( nil, area, self.MoveSpeed ) > 0.45 then return end
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
    if self:getMaxPathCurvature( nil, area, self.WalkSpeed, true ) > 0.85 then return true end
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
        local cost = oldMul + rotAmounts[ area ] * scale
        cost = math.Clamp( cost, 0, 500 )
        costs[ area:GetID() ] = cost

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
    [ACT_MP_SWIM]                       = ACT_HL2MP_SWIM,
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
    self.term_NextIdleTaunt = CurTime() + 2
    self.CanHearStuff = false
    local hasBrains = math.random( 1, 100 ) < self.zamb_BrainsChance
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true

    end

    self.TakesFallDamage = true
    self.HeightToStartTakingDamage = 200
    self.FallDamagePerHeight = 0.15
    self.DeathDropHeight = 1000
    self.zamb_IdleTauntInterval = nil -- overrides the taunt interval below
    self.walkedAreas = nil -- disables walked area logic, we're fodder, we dont need that

end

local cutoff = 35^2

function ENT:AdditionalThink()
    local cur = CurTime()
    if self.loco:GetVelocity():LengthSqr() > cutoff then
        self.term_NextIdleTaunt = cur + math.Rand( 0.25, 0.5 )
        return

    end
    if self.term_NextIdleTaunt > cur then return end

    local add = self.zamb_IdleTauntInterval or math.Rand( 1, 2 )
    self.term_NextIdleTaunt = cur + add

    self:RunTask( "ZambOnGrumpy" )

end

ENT.FootstepClomping = false
ENT.Term_FootstepMode = "custom"
ENT.Term_FootstepSoundWalking = {
    {
        path = "Zombie.ScuffLeft",
        lvl = 76,
    },
    {
        path = "Zombie.ScuffRight",
        lvl = 76,
    },
}
ENT.Term_FootstepSound = { -- running sounds
    {
        path = "Zombie.FootstepLeft",
        lvl = 85,
    },
    {
        path = "Zombie.FootstepRight",
        lvl = 85,
    },
}

local function angeringCallFunc( me, rate )

    me:RunTask( "ZambAngeringCall" )

    rate = rate or 1

    me:StopMoving()
    me:InvalidatePath( "angeringcall" )
    me.nextNewPath = CurTime() + 2 * rate

    me.term_NextIdleTaunt = CurTime() + 8

    local callAnim = me.zamb_CallAnim or ACT_GMOD_GESTURE_TAUNT_ZOMBIE
    me:DoGesture( callAnim, 0.8 * rate, true )

    local filterAllPlayers = RecipientFilter()
    filterAllPlayers:AddAllPlayers()
    me:EmitSound( me.term_CallingSound, 120 + me.term_SoundLevelShift, math.random( 95, 105 ) + me.term_SoundPitchShift, 0.5, CHAN_STATIC, sndFlags, nil, filterAllPlayers )
    me:EmitSound( me.term_CallingSmallSound, 85 + me.term_SoundLevelShift, math.random( 75, 85 ) + me.term_SoundPitchShift, 1, CHAN_STATIC, sndFlags, nil )

    local myCallId = me.zamb_CallId
    local myHealth = me:Health()

    for _, ally in ipairs( me:GetNearbyAllies() ) do
        if not IsValid( ally ) then continue end
        local time = math.Rand( 1, 3 )
        if ally.HasBrains then
            time = 0.5

        end
        timer.Simple( time, function()
            if not IsValid( ally ) then return end
            local chainCall = ( not ally.HasBrains and ally:Health() > myHealth and math.random( 0, 100 ) < 55 ) or math.random( 0, 100 ) < 15
            if chainCall and myCallId and ( not ally.zamb_CallId or ally.zamb_CallId < myCallId ) then
                ally:ZAMB_AngeringCall( true, 1, false )
                ally.zamb_CallId = myCallId

            else
                ally:Anger( math.random( 55, 75 ) )

            end
        end )
    end

    return true
end

function ENT:ZAMB_AngeringCall( doNow, rate, newCall )
    if newCall then
        self.zamb_CallId = CurTime()

    end
    if doNow then
        angeringCallFunc( self, rate )

    else
        self:Term_SpeakSound( "blarg", function( me ) angeringCallFunc( me, rate ) end )

    end
end

function ENT:ZAMB_NormalCall()
    local callAnim = self.zamb_CallAnim or ACT_GMOD_GESTURE_TAUNT_ZOMBIE
    if math.random( 1, 100 ) > 75 then
        self:DoGesture( callAnim, 1.1, true )

    else
        self:DoGesture( callAnim, 1.4, self.NoAnimLayering or false )

    end
    self:RejectPathUpdates( entMeta.GetTable( self ) )
    self:Term_SpeakSound( self.term_FindEnemySound )

end

function ENT:TryAndLeapTo( myTbl, leapPos )
    local cur = CurTime()
    if myTbl.Zamb_NextLeap and myTbl.Zamb_NextLeap > cur then
        return

    end
    local blockLeap = myTbl.RunTask( self, "ZambBlockJumpToPos" )
    if blockLeap then return end

    local canLeap = myTbl.loco:IsOnGround()
    local addMul = 1
    if myTbl.IsReallyAngry( self ) then
        addMul = 0.25

    end

    if canLeap and myTbl.Zamb_LeapingPrepare then
        if myTbl.Zamb_LeapingPrepare > cur or myTbl.IsGestureActive( self ) then
            return true

        end

        myTbl.JumpToPos( self, leapPos, math.min( myTbl.DistToEnemy, myTbl.JumpHeight ) )
        myTbl.Zamb_NextTryAndLeap = cur + math.Rand( 0, 20 ) * addMul

        myTbl.Zamb_LeapingPrepare = nil
        return true

    end

    if not myTbl.Zamb_NextTryAndLeap then
        myTbl.Zamb_NextTryAndLeap = cur + math.Rand( 0, 10 ) * addMul

    end

    local wantsToLeap = canLeap and ( myTbl.IsAngry( self ) and myTbl.DistToEnemy < myTbl.JumpHeight * 2 ) and ( myTbl.Unreachable or myTbl.Zamb_NextTryAndLeap < cur )
    if wantsToLeap then
        myTbl.Zamb_NextTryAndLeap = cur + math.Rand( 0, 10 ) * addMul
        local leapable = myTbl.CanJumpToPos( self, myTbl, leapPos, myTbl.DistToEnemy )
        if leapable then
            local add = math.Rand( 0.1, 0.25 )
            myTbl.Zamb_LeapingPrepare = cur + add
            myTbl.overrideCrouch = cur + add
            if not myTbl.IsReallyAngry( self ) then
                myTbl.ZAMB_NormalCall( self )

            end
            return true

        end
    end
end

local nextZombieCall = 0
local nextLoneZombieCall = 0

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
            StartsOnInitialize = true,
            ZambOnGrumpy = function( self, data )
                if not self.loco:IsOnGround() then return end

                local cur = CurTime()
                if self.HasBrains or self.zamb_CantCall or math.random( 1, 100 ) > 25 then
                    self:Term_SpeakSound( self.term_FindEnemySound )
                    return

                elseif nextZombieCall < cur and self.DistToEnemy > 750 and #self:GetNearbyAllies() >= 8 then
                    nextZombieCall = cur + 40
                    nextLoneZombieCall = cur + 120
                    self:ZAMB_AngeringCall()

                elseif nextLoneZombieCall < CurTime() and self.DistToEnemy > 1000 then
                    nextZombieCall = cur + 40
                    nextLoneZombieCall = cur + 120
                    self:ZAMB_AngeringCall()

                elseif self.DistToEnemy > 750 then
                    self:ZAMB_NormalCall()

                end
            end,
            OnBlockingAlly = function( self, data, theAlly, sinceStarted )
                local myOffset = self:GetCreationID() % 4
                myOffset = myOffset
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
            OnJumpToPos = function( self, data, pos, height )
                self:ReallyAnger( 10 )
                self:Term_SpeakSoundNow( self.term_AttackSound )

            end,
            OnLandOnGround = function( self, data, landedOn, height )
                if not self.Term_Leaps then return end
                local add = ( height / 500 )
                if add <= 0 then return end
                self.Zamb_NextLeap = CurTime() + add

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
                self:Term_ClearStuffToSay()
                self:Term_SpeakSoundNow( self.term_DamagedSound )

            end,
            PreventBecomeRagdollOnKilled = function( self, data, damage ) -- handle becoming zombie torso
                local torsoData = terminator_Extras.zamb_TorsoZombieClasses[self:GetClass()]
                if not torsoData then return end

                local cur = CurTime()
                local oldDensity = terminator_Extras.zamb_TorsoDensityNum
                if oldDensity > math.random( cur, cur + 60 ) then return end

                local becomeTorso
                local sliced
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
                        sliced = true

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
                    terminator_Extras.copyMatsOver( self, torso )

                    terminator_Extras.zamb_TorsoDensityNum = math.max( oldDensity + torso:Health() / 2, cur + torso:Health() / 2 )

                    if sliced then
                        torso:EmitSound( "ambient/machines/slicer" .. math.random( 1, 4 ) .. ".wav", 75, math.random( 95, 105 ) )

                    end

                    local pos = damage:GetDamagePosition()
                    local color = self:GetBloodColor()
                    if pos then
                        timer.Simple( 0, function()
                            local normal = VectorRand()
                            normal.z = math.abs( normal.z )

                            local Data = EffectData()
                            Data:SetOrigin( pos )
                            Data:SetColor( color )
                            Data:SetScale( math.random( 8, 12 ) )
                            Data:SetFlags( 1 )
                            Data:SetNormal( normal )
                            util.Effect( "bloodspray", Data )
                            local toPlay = self
                            if not IsValid( toPlay ) then
                                toPlay = torso

                            end
                            if IsValid( toPlay ) then
                                toPlay:EmitSound( "npc/antlion_grub/squashed.wav", 72, math.random( 150, 200 ), 1, CHAN_STATIC ) -- play in static so it doesnt get overriden

                            end
                        end )
                    end

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
                                terminator_Extras.copyMatsOver( self, legs )
                                legs:SetVelocity( damage:GetDamageForce() )

                            end
                            SafeRemoveEntity( self )
                            return true

                        else
                            self:SetModel( torsoData.legs ) -- this little hack is much better than networking this ragdoll creation imo
                            return

                        end
                    else
                        SafeRemoveEntity( self )
                        SafeRemoveEntityDelayed( self, 5 )
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
            StartsOnInitialize = true,
            BehaveUpdateMotion = function( self, data )
                local myTbl = data.myTbl
                if myTbl.IsSeeEnemy then
                    myTbl.TaskComplete( self, "movement_handler" )
                    myTbl.StartTask( self, "movement_followenemy", nil, "i see an enemy!" )
                    return

                else
                    myTbl.TaskComplete( self, "movement_handler" )
                    myTbl.StartTask( self, "movement_wander", nil, "i need to wander!" )
                    return

                end
            end,
        },
        ["movement_followenemy"] = {
            OnStart = function( self, data )
                if not self.isUnstucking then
                    self:InvalidatePath( "followenemy" )

                end
            end,
            BehaveUpdateMotion = function( self, data )
                local myTbl = data.myTbl
                local enemy = myTbl.GetEnemy( self )
                local validEnemy = IsValid( enemy )
                local enemyPos = myTbl.EnemyLastPos
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp
                local toPos = enemyPos

                if not myTbl.IsSeeEnemy and data.overridePos then
                    toPos = data.overridePos

                end

                local distToExit = myTbl.DuelEnemyDist

                if goodEnemy and myTbl.NothingOrBreakableBetweenEnemy and myTbl.DistToEnemy < distToExit and not myTbl.terminator_HandlingLadder then
                    myTbl.TaskComplete( self, "movement_followenemy" )
                    myTbl.StartTask( self, "movement_duelenemy_near", nil, "i gotta slash em" )
                    return

                end

                local nextPathAttempt = myTbl.zamb_NextPathAttempt

                if nextPathAttempt < CurTime() and toPos and not data.Unreachable and myTbl.primaryPathInvalidOrOutdated( self, toPos ) then
                    self:InvalidatePath( "zamb_followenemy" )
                    coroutine_yield()
                    myTbl.zamb_NextPathAttempt = CurTime() + math.Rand( 0.5, 1 )
                    if myTbl.term_ExpensivePath then
                        myTbl.zamb_NextPathAttempt = CurTime() + math.Rand( 1, 4 )

                    end
                    local result = terminator_Extras.getNearestPosOnNav( toPos )
                    local reachable = myTbl.areaIsReachable( self, result.area )
                    if not reachable then data.Unreachable = true return end

                    data.triedToPath = nil

                    if myTbl.HasBrains and ( myTbl.zamb_AlwaysFlank or math.random( 1, 100 ) > 25 ) then
                        -- split up!
                        local otherHuntersHalfwayPoint = myTbl.GetOtherHuntersProbableEntrance( self )
                        local splitUpResult
                        local splitUpPos
                        local splitUpBubble
                        if otherHuntersHalfwayPoint then
                            splitUpPos = otherHuntersHalfwayPoint
                            splitUpBubble = self:GetPos():Distance( otherHuntersHalfwayPoint ) * 0.7
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        elseif validEnemy and myTbl.zamb_AlwaysFlank then
                            splitUpPos = enemy:GetPos()
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        end

                        if splitUpResult and myTbl.areaIsReachable( self, splitUpResult.area ) then
                            -- flank em!
                            myTbl.SetupFlankingPath( self, enemyPos, splitUpResult.area, splitUpBubble )
                            data.triedToPath = true
                            coroutine_yield()

                        end
                    end
                    -- flank failed or we're not smart enough to flank
                    if not myTbl.primaryPathIsValid( self ) then
                        myTbl.SetupPathShell( self, result.pos )
                        data.triedToPath = true
                        coroutine_yield()

                    end
                    if not myTbl.primaryPathIsValid( self ) then
                        data.overridePos = nil
                        data.Unreachable = true
                        return

                    elseif myTbl.GetPath( self ):GetEnd():Distance( toPos ) > myTbl.DuelEnemyDist then -- path won't get us close, they're unreachable!
                        self:TaskFail( "movement_followenemy" )
                        myTbl.StartTask( self, "movement_duelenemy_near", { overrideDist = myTbl.DistToEnemy + myTbl.DuelEnemyDist }, "i cant get to them" )

                    end
                end

                coroutine_yield()

                local lookAtGoal = myTbl.zamb_LookAheadWhenRunning or not ( myTbl.IsSeeEnemy and myTbl.HasBrains )
                local result = self:ControlPath2( lookAtGoal )
                coroutine_yield()

                if myTbl.Term_Leaps then
                    local leapPreparing = myTbl.TryAndLeapTo( self, myTbl, enemyPos )
                    if leapPreparing then
                        return

                    end
                end

                if lookAtGoal then
                    myTbl.blockAimingAtEnemy = CurTime() + 0.25

                end

                if false and myTbl.CanBashLockedDoor( self, self:GetPos(), 1000 ) then
                    --self:BashLockedDoor( "movement_followenemy" )
                elseif not goodEnemy and not myTbl.primaryPathIsValid( self ) and data.triedToPath then
                    myTbl.TaskFail( self, "movement_followenemy" )
                    myTbl.StartTask( self, "movement_wander", nil, "i cant get to them/no enemy" )
                    data.overridePos = nil
                elseif IsValid( enemy ) and enemy:WaterLevel() >= 1 and not enemy:OnGround() and self:WaterLevel() >= 2 then
                    myTbl.TaskComplete( self, "movement_followenemy" )
                    myTbl.StartTask( self, "movement_duelenemy_near", nil, "they're swimming and im in the water!" )
                elseif not myTbl.primaryPathIsValid( self ) and data.Unreachable then
                    coroutine_yield()
                    data.overridePos = nil
                    local justDuel = myTbl.zamb_JustTryDuelingUnreachable or 0
                    if justDuel > CurTime() then
                        if not myTbl.HasBrains or math.random( 0, 100 ) < 50 then
                            myTbl.ReallyAnger( self, 25 )
                            myTbl.TaskComplete( self, "movement_followenemy" )
                            myTbl.StartTask( self, "movement_duelenemy_near", { overrideDist = myTbl.DistToEnemy + 500 }, "i cant get to them and i tried frenzying" )

                        else
                            myTbl.Anger( self, 25 )
                            myTbl.TaskFail( self, "movement_followenemy" )
                            myTbl.StartTask( self, "movement_wander", nil, "i cant get to them and i tried frenzying" )

                        end
                    elseif math.random( 1, 100 ) < 50 or myTbl.IsReallyAngry( self ) then
                        myTbl.TaskFail( self, "movement_followenemy" )
                        myTbl.StartTask( self, "movement_frenzy", nil, "i cant get to them" )
                        myTbl.zamb_JustTryDuelingUnreachable = CurTime() + math.random( 1, 15 )

                    else
                        myTbl.Anger( self, 5 )
                        myTbl.TaskFail( self, "movement_followenemy" )
                        myTbl.StartTask( self, "movement_wander", nil, "i cant get to them" )

                    end
                elseif result or ( not goodEnemy and self:GetRangeTo( self:GetPath():GetEnd() ) < 300 ) then
                    data.overridePos = nil
                    if not myTbl.IsSeeEnemy then
                        myTbl.TaskFail( self, "movement_followenemy" )
                        myTbl.StartTask( self, "movement_wander", nil, "got there, but no enemy" )

                    end
                end
            end,
        },
        ["movement_duelenemy_near"] = {
            OnStart = function( self, data )
                data.badCount = 0
            end,
            BehaveUpdateMotion = function( self, data )
                local myTbl = data.myTbl
                local enemy = myTbl.GetEnemy( self )
                local validEnemy = IsValid( enemy )
                local enemyPos = myTbl.EnemyLastPos
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp
                local maxDuelDist = data.overrideDist or myTbl.DuelEnemyDist + 100
                local waterFight = validEnemy and self:WaterLevel() >= 3 and enemy:GetPos().z - self:GetPos().z > 0

                local badAdd = 0

                if not myTbl.NothingOrBreakableBetweenEnemy and myTbl.GetCurrentSpeed( self ) <= 5 then
                    badAdd = badAdd + 5

                end
                if not myTbl.IsSeeEnemy and not myTbl.NothingOrBreakableBetweenEnemy then
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
                coroutine_yield()

                if data.badCount > 25 or not aliveOrHp then
                    coroutine_yield()
                    local propInMyWay = ( myTbl.IsSeeEnemy and not myTbl.NothingOrBreakableBetweenEnemy ) and ( math.random( 1, 100 ) < 75 or myTbl.IsReallyAngry( self ) )
                    local propInMyWay2 = IsValid( myTbl.GetCachedDisrespector( self ) ) and myTbl.IsReallyAngry( self )
                    if propInMyWay or propInMyWay2 then
                        myTbl.TaskComplete( self, "movement_duelenemy_near" )
                        myTbl.StartTask( self, "movement_frenzy", nil, "got bored" )

                    else
                        myTbl.TaskComplete( self, "movement_duelenemy_near" )
                        myTbl.StartTask( self, "movement_followenemy", nil, "got bored" )

                    end
                elseif validEnemy then -- the dueling in question
                    if waterFight and self.loco:IsOnGround() then
                        self:StartSwimming()

                    end
                    coroutine_yield()
                    if not IsValid( enemy ) then return end

                    -- default, just run up to enemy
                    local gotoPos = enemyPos
                    local angy = myTbl.IsAngry( self )

                    -- if we mad though, predict where they will go, and surprise them
                    if myTbl.HasBrains and angy and enemy.GetAimVector then
                        local flat = enemy:GetAimVector()
                        flat.z = 0
                        flat:Normalize()
                        gotoPos = enemyPos + -flat

                    elseif angy then
                        local enemVel = enemy:GetVelocity()
                        enemVel.z = enemVel.z * 0.15
                        local velProduct = math.Clamp( enemVel:Length() * 1.4, 0, myTbl.DistToEnemy * 0.8 )
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
                        gotoPos = whereToInterceptTr.HitPos

                    end

                    gotoPos = gotoPos + VectorRand() * 15

                    --debugoverlay.Cross( gotoPos, 10, 1, Color( 255,255,0 ) )
                    coroutine_yield()
                    if myTbl.Term_Leaps and myTbl.DistToEnemy > myTbl.DuelEnemyDist * 0.5 then
                        local leapPos = gotoPos
                        if myTbl.HasBrains then
                            leapPos = enemyPos + enemy:GetVelocity() * 1

                        end
                        local leapPreparing = myTbl.TryAndLeapTo( self, myTbl, leapPos )
                        if leapPreparing then
                            return

                        end
                    end
                    myTbl.GotoPosSimple( self, myTbl, gotoPos, 35 )

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
                data.startedWithEnemy = self.IsSeeEnemy
            end,
            EnemyFound = function( self, data ) -- break our trance
                if data.startedWithEnemy then return end
                if not self.IsSeeEnemy then return end
                if self.DistToEnemy > self.DuelEnemyDist * 2 then return end

                self:TaskComplete( "movement_frenzy" )
                self:StartTask( "movement_handler", "i found an enemy!" )
                self:RestartMotionCoroutine()

            end,
            BehaveUpdateMotion = function( self, data )
                local myTbl = data.myTbl
                local focus = data.currentFrenzyFocus
                local validFocus = IsValid( focus )
                local maxDist = data.maxDist
                if not validFocus then
                    local bestScore = 0
                    for _, curr in ipairs( myTbl.awarenessSubstantialStuff ) do
                        if not IsValid( curr ) then continue end -- this tbl is usually outdated
                        local currsTbl = entMeta.GetTable( curr )
                        if currsTbl.zamb_NeverFrenzyCurious then continue end
                        if currsTbl.isTerminatorHunterChummy and currsTbl.isTerminatorHunterChummy == myTbl.isTerminatorHunterChummy then continue end

                        local range = self:GetRangeTo( curr )
                        if range > maxDist then continue end

                        local currsBoredom = myTbl.frenzyBoredomEnts[ curr ] or 1
                        local entsBoredom = currsTbl.zamb_entsBoredom or 0
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
                        --debugoverlay.Text( data.currentFrenzyFocus, tostring( bestScore ), 5, false )
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
                if myTbl.NothingOrBreakableBetweenEnemy then
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

                    local memory = myTbl.getMemoryOfObject( myTbl, self, focus )
                    if not data.validBeatup then
                        boredAdd = boredAdd + 5

                    elseif memory == MEMORY_BREAKABLE then
                        quitAdd = quitAdd + -1
                        boredAdd = 0.1
                        boredToQuit = boredToQuit + 50

                    elseif memory == MEMORY_VOLATILE and not myTbl.IsReallyAngry( self ) then -- anger clouds "judgement"
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

                    local oldBored = myTbl.frenzyBoredomEnts[ focus ] or 0
                    myTbl.frenzyBoredomEnts[ focus ] = math.Clamp( oldBored + boredAdd, 0, math.huge )
                    if myTbl.frenzyBoredomEnts[ focus ] > boredToQuit then
                        data.currentFrenzyFocus = nil
                        return

                    end
                end

                local enemy = myTbl.GetEnemy( self )
                local validEnemy = IsValid( enemy )
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and entMeta.Health( enemy ) > 0 )
                local goodEnemy = validEnemy and aliveOrHp

                local enemyIsReachable
                if goodEnemy then
                    local result = terminator_Extras.getNearestPosOnNav( enemyPos )
                    enemyIsReachable = myTbl.areaIsReachable( self, result.area )
                end

                if enemyIsReachable then
                    quitAdd = quitAdd + 10

                end

                data.quitCount = math.Clamp( data.quitCount + quitAdd, 0, math.huge )

                if data.quitCount > 100 then
                    if myTbl.IsSeeEnemy then
                        myTbl.TaskComplete( self, "movement_frenzy" )
                        myTbl.StartTask( self, "movement_followenemy", nil, "got bored" )

                    else
                        myTbl.TaskComplete( self, "movement_frenzy" )
                        myTbl.StartTask( self, "movement_wander", nil, "got bored" )

                    end
                else
                    if not myTbl.primaryPathIsValid( self ) and myTbl.zamb_NextPathAttempt > CurTime() then
                        coroutine_yield( "wait" )

                    else
                        data.validBeatup = myTbl.beatUpEnt( self, myTbl, focus )

                    end
                end
            end,
        },

        -- complex wander, preserves areas already explored, makes bot cross entire map pretty much
        ["movement_wander"] = {
            OnStart = function( self, data )
                local myTbl = data.myTbl
                local lastInterceptTry = myTbl.nextInterceptTry or 0
                myTbl.nextInterceptTry = math.max( CurTime() + 1, lastInterceptTry + 1 )
                if not myTbl.isUnstucking then
                    myTbl.InvalidatePath( self, "followenemy" )
                end
            end,
            EnemyFound = function( self, data ) -- break our trance
                if not self.IsSeeEnemy then return end
                if self.DistToEnemy > self.DuelEnemyDist * 4 then return end

                self:TaskComplete( "movement_wander" )
                self:StartTask( "movement_handler", "i found an enemy!" )
                self:RestartMotionCoroutine()

            end,
            BehaveUpdateMotion = function( self, data )
                local myTbl = data.myTbl
                local enemy = myTbl.GetEnemy( self )
                local validEnemy = IsValid( enemy )
                local aliveOrHp = ( validEnemy and enemy.Alive and enemy:Alive() ) or ( validEnemy and enemy.Health and enemy:Health() > 0 )
                local goodEnemy = validEnemy and aliveOrHp

                local enemyIsReachable
                if goodEnemy then
                    local result = terminator_Extras.getNearestPosOnNav( enemy:GetPos() )
                    enemyIsReachable = myTbl.areaIsReachable( self, result.area )

                end
                coroutine_yield()

                local nextPathAttempt = myTbl.zamb_NextPathAttempt

                if not data.toPos and nextPathAttempt < CurTime() then
                    coroutine_yield()
                    myTbl.zamb_NextPathAttempt = CurTime() + math.Rand( 0.5, 1 )
                    if myTbl.term_ExpensivePath then
                        myTbl.zamb_NextPathAttempt = CurTime() + math.Rand( 1, 4 )

                    end
                    local smellySpot = terminator_Extras.zamb_SmelliestRottingArea
                    local foundSomewhereNotBeen = nil
                    if IsValid( smellySpot ) and math.random( 1, 100 ) < 50 and myTbl.areaIsReachable( self, smellySpot ) then
                        data.toPos = smellySpot:GetCenter()

                    else
                        data.beenAreas = data.beenAreas or myTbl.wanderPreserveAreas or {}

                        myTbl.wanderPreserveAreas = nil

                        local canDoUnderWater = self:WaterLevel() > 0
                        local myNavArea = myTbl.GetCurrentNavArea( self )
                        if not IsValid( myNavArea ) then return end

                        local anotherHuntersPos = myTbl.HasBrains and myTbl.GetOtherHuntersProbableEntrance( self ) or nil

                        --normal path
                        local dir = data.dir or self:GetForward()
                        dir = -dir
                        local scoreData = {}
                        local wanderAreasTraversed = {}
                        scoreData.canDoUnderWater = canDoUnderWater
                        scoreData.self = self
                        scoreData.hasBrains = myTbl.HasBrains
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

                            if scoreData.hasBrains and dropToArea > myTbl.loco:GetJumpHeight() then
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

                        coroutine_yield()
                        data.toPos, data.lastToArea = myTbl.findValidNavResult( self, scoreData, self:GetPos(), math.random( 1000, 2000 ), scoreFunction )

                        table.Merge( data.beenAreas, wanderAreasTraversed )

                    end

                    if not data.toPos then
                        myTbl.zamb_NextPathAttempt = CurTime() + 5
                        data.ignoreBearing = true

                    end

                    if not foundSomewhereNotBeen then
                        data.beenAreas = nil
                        data.ignoreBearing = true

                    else
                        myTbl.wanderPreserveAreas = data.beenAreas
                        data.ignoreBearing = nil

                    end
                end
                coroutine_yield()
                if data.toPos and myTbl.primaryPathInvalidOrOutdated( self, data.toPos ) then
                    self:InvalidatePath( "zamb_wander" )
                    local result = terminator_Extras.getNearestPosOnNav( data.toPos )
                    local reachable = myTbl.areaIsReachable( self, result.area )
                    if not reachable then
                        myTbl.zamb_NextPathAttempt = CurTime() + math.random( 1, 5 )
                        data.toPos = nil
                        coroutine_yield( "wait" )
                        return

                    end

                    if myTbl.HasBrains and math.random( 1, 100 ) > 25 then
                        -- split up!
                        local otherHuntersHalfwayPoint = myTbl.GetOtherHuntersProbableEntrance( self )
                        coroutine_yield()
                        local splitUpResult
                        local splitUpPos
                        local splitUpBubble
                        if otherHuntersHalfwayPoint then
                            splitUpPos = otherHuntersHalfwayPoint
                            splitUpBubble = self:GetPos():Distance( otherHuntersHalfwayPoint ) * 0.7
                            splitUpResult = terminator_Extras.getNearestPosOnNav( splitUpPos )

                        end

                        if splitUpResult and myTbl.areaIsReachable( self, splitUpResult.area ) then
                            -- flank em!
                            myTbl.SetupFlankingPath( self, enemyPos, splitUpResult.area, splitUpBubble )
                            coroutine_yield()

                        end
                    end
                    -- cant flank
                    if not myTbl.primaryPathIsValid( self ) then
                        myTbl.SetupPathShell( self, result.pos )
                        coroutine_yield()

                    end
                    if not myTbl.primaryPathIsValid( self ) then
                        myTbl.zamb_NextPathAttempt = CurTime() + 5
                        data.toPos = nil
                        coroutine_yield( "wait" )
                        return

                    end
                end

                local lookAtGoal = myTbl.zamb_LookAheadWhenRunning or not ( myTbl.IsSeeEnemy and myTbl.HasBrains )
                local result = myTbl.ControlPath2( self, lookAtGoal )
                coroutine_yield()

                if lookAtGoal then
                    myTbl.blockAimingAtEnemy = CurTime() + 0.15

                end

                if IsValid( myTbl.GetCachedDisrespector( self ) ) and myTbl.zamb_nextRandomFrenzy < CurTime() then
                    local add = 60
                    if myTbl.IsReallyAngry( self ) then
                        add = 5

                    elseif myTbl.IsAngry( self ) then
                        add = 30

                    end
                    myTbl.zamb_nextRandomFrenzy = CurTime() + add

                    myTbl.TaskComplete( self, "movement_wander" )
                    myTbl.StartTask( self, "movement_frenzy", nil, "i want to attack random stuff" )

                elseif myTbl.nextInterceptTry < CurTime() and myTbl.interceptIfWeCan( self, nil, data ) then
                    coroutine_yield()
                    myTbl.nextInterceptTry = CurTime() + 1
                    if not myTbl.HasBrains then
                        local areasNearby = navmesh.Find( myTbl.lastInterceptPos, 250, 100, 100 )
                        local randomArea = areasNearby[math.random( 1, #areasNearby )]
                        if IsValid( randomArea ) and myTbl.areaIsReachable( self, randomArea ) then
                            myTbl.nextInterceptTry = CurTime() + 5
                            local randomPosNearby = randomArea:GetRandomPoint()
                            myTbl.TaskComplete( self, "movement_wander" )
                            myTbl.StartTask( self, "movement_followenemy", { overridePos = randomPosNearby }, "i can intercept someone" )
                            myTbl.lastInterceptPos = nil

                        end
                    else
                        local nearestArea = terminator_Extras.getNearestNav( myTbl.lastInterceptPos )
                        if IsValid( nearestArea ) and myTbl.areaIsReachable( self, nearestArea ) then
                            myTbl.nextInterceptTry = CurTime() + 15
                            local pos = nearestArea:GetRandomPoint()
                            myTbl.TaskComplete( self, "movement_wander" )
                            myTbl.StartTask( self, "movement_followenemy", { overridePos = pos }, "i can intercept someone" )
                            myTbl.lastInterceptPos = nil

                        end
                    end
                elseif goodEnemy and enemyIsReachable then
                    myTbl.TaskFail( self, "movement_wander" )
                    myTbl.StartTask( self, "movement_followenemy", nil, "new enemy!" )
                elseif result then
                    data.toPos = nil
                    myTbl.zamb_NextPathAttempt = CurTime() + 1
                    coroutine_yield( "wait" )
                end
            end,
        },
    }
end