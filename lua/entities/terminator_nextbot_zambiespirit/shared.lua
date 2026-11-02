-- Thanks to MerekiDor and JonahSoldier the creators of Map Sweepers for allowing this!
-- Teleports far off zambies in between itself and its enemy, then hides, and peeks back out to do it again.
-- Needs terminator-hunter's movement_gotoarea task.
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Spirit"
ENT.Author    = "Octantis Addons + regunkyle + straw w wagen"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.HasBrains = true

ENT.SpawnHealth = 100
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 1

list.Set( "NPC", "terminator_nextbot_zambiespirit", {
    Name     = "Zombie Spirit",
    Class    = "terminator_nextbot_zambiespirit",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiespirit", ENT.PrintName )
end

ENT.zamb_IsSpirit = true -- spirits never summon each other
ENT.zamb_StayOutOfMeleeRange = true -- also what makes it hide and flee, clear it and it fights like a normal zambie

ENT.MaxCarryHeight = 80 -- a plain zambie is 72 tall, up to 76 once modelscale is in
ENT.MaxCarryHealth = 250
ENT.SummonCountMin = 3
ENT.SummonCountMax = 5
ENT.SummonCountBehindWalls = 1 -- squads dropped deep behind walls shrink down to this
ENT.SummonsOnDeath = true
ENT.OneHitFreebie = false -- the first hit worth half its health or more only does a tenth, once per life

-- Zambies it teleported report back where its enemy is, so it keeps the pressure on when it can't see them.
ENT.UsesScoutIntel = false
ENT.IntelTimeout = 90 -- sieges run minutes long, a report stays good this long
ENT.RemoteSummonInterval = 15 -- summoning off a report is slower than off its own eyes

local DEATH_FADE_TIME = 1.5 -- the client's dying trails and sprite fade over this long
local SEEN_SUMMON_INTERVAL = 5 -- same as the call action's ratelimit, so driven and AI spirits pace alike
local SUMMON_ARRIVE_DELAY  = 0.5 -- the call gets a moment to play before they arrive, the heartbeat winds up over it

ENT.HeartbeatPitch = 50

-- the base uses DT slots directly, low slot numbers are taken
function ENT:SetupDataTables()
    self:NetworkVar( "Bool",  10, "IsDying" )
    self:NetworkVar( "Float", 10, "DeathTime" )

end

ENT.DeployDistance = 2000 -- summons when its enemy is closer than this, backs off when they're closer than half

if SERVER then
    local HIDE_RANGE_MUL  = 1.5 -- hiding spots stay within this many DeployDistances of the enemy, so peeking out is quick
    local HIDE_RETRY_TIME = 4
    local LURK_MIN_TIME   = 2 -- stays hidden at least this long before peeking out again
    local LURK_MAX_TIME   = 10 -- never sits still longer than this, even with nothing to summon
    local INTEL_LOS_GRACE = 10 -- a report this fresh survives us seeing the spot empty, they've likely just stepped out of view

    local coroutine_yield = coroutine.yield
    local coroutine_isyieldable = coroutine.isyieldable -- missing on some branches

    -- Yields inside the bot's threads, runs straight through from hooks and timers.
    local function YieldIfWeCan()
        if coroutine_isyieldable and coroutine_isyieldable() then
            coroutine_yield()

        end
    end
    ENT.YieldIfWeCan = YieldIfWeCan

    -- Finds up to count spots on the navmesh, spaced around a circle.
    -- Returns the spots, and whether it found all of them.
    local function PackSquadVectors( center, count, radius )
        local results   = {}
        local attempts  = count * 6
        local angleStep = ( math.pi * 2 ) / attempts
        local minSpacingSqr = ( radius * 0.4 ) ^ 2

        for i = 0, attempts - 1 do
            if #results >= count then break end
            if i % 6 == 5 then YieldIfWeCan() end

            local angle     = i * angleStep
            local candidate = center + Vector( math.cos( angle ) * radius, math.sin( angle ) * radius, 0 )
            local area = navmesh.GetNearestNavArea( candidate, false, 128 )
            if not area then continue end

            local snapped = area:GetClosestPointOnArea( candidate )
            local tooClose = false
            for _, taken in ipairs( results ) do
                if taken:DistToSqr( snapped ) < minSpacingSqr then
                    tooClose = true
                    break

                end
            end
            if not tooClose then
                table.insert( results, snapped )

            end
        end
        return results, #results >= count

    end
    ENT.PackSquadVectors = PackSquadVectors

    local function FireSummonEffectAt( ent )
        local mins, maxs = ent:GetCollisionBounds()
        local height = maxs.z - mins.z

        local ed = EffectData()
        ed:SetOrigin( ent:WorldSpaceCenter() )
        ed:SetRadius( math.Clamp( height * 1.5, 40, 300 ) )
        util.Effect( "eff_zambspirit_summon", ed, true, true )

    end

    -- Rays from the spirit's chest to where the zambie lands
    local function FireDeployEffectAt( spirit, targetPos )
        local chestBone = spirit:LookupBone( "ValveBiped.Bip01_Spine4" ) or spirit:LookupBone( "ValveBiped.Bip01_Spine2" )
        local origin = spirit:WorldSpaceCenter()
        if chestBone then
            origin = spirit:GetBonePosition( chestBone )

        end

        local ed = EffectData()
        ed:SetOrigin( targetPos )
        ed:SetStart( origin )
        util.Effect( "eff_zambspirit_rays", ed, true, true )

    end

    function ENT:TeleportZambieTo( ent, targetPos, faceTowards )
        FireSummonEffectAt( ent )

        terminator_Extras.TeleportTermTo( ent, targetPos )

        if faceTowards then
            local faceAngle = ( faceTowards - targetPos ):Angle()
            faceAngle.p = 0
            faceAngle.r = 0
            ent:SetAngles( faceAngle )
        end
        ent:ReallyAnger( 60 )
        ent.zamb_ScoutFor = self -- see SpiritInformReceive
        ent:SetNW2Entity( "zamb_PulseSpirit", self ) -- glows in time with our heartbeat

        FireDeployEffectAt( self, targetPos )

    end

    function ENT:CanSummon( ally )
        if not IsValid( ally ) then return false end
        if ally.zamb_IsSpirit then return false end
        if ally:Health() <= 0 then return false end
        if ally.IsSeeEnemy then return false end -- already in a fight, yanking them out wastes them
        if IsValid( ally:GetParent() ) then return false end
        -- standing bounds, the live OBB shrinks while crouched
        local bounds = ally.CollisionBounds
        if bounds and bounds[2].z - bounds[1].z > self.MaxCarryHeight then return false end
        if ally:GetMaxHealth() > self.MaxCarryHealth then return false end
        return true

    end

    -- Every ally in InformRadius we could summon, farthest from targetPos first.
    -- Zambies inform across 20000 units, so that's most maps.
    function ENT:FindSummonableZambies( targetPos )
        local found = {}
        local distsSqr = {}
        for _, ent in ipairs( self:GetNearbyAllies() ) do -- a cache, don't touch it
            if not self:CanSummon( ent ) then continue end

            table.insert( found, ent )
            distsSqr[ent] = ent:GetPos():DistToSqr( targetPos )

        end
        table.sort( found, function( a, b ) return distsSqr[a] > distsSqr[b] end )
        return found

    end

    local eyeHeight = Vector( 0, 0, 50 )

    local SQUAD_SLIM_START = 150 -- this far behind the first wall, a squad's still full size
    local SQUAD_SLIM_END   = 500 -- this far behind, it's down to SummonCountBehindWalls

    local SQUAD_SLIM_MIN_HEALTH = 100 -- that far behind, only fodder gets sent

    -- How many zambies, and how tough each can be, for a squad dropped at spawnPos.
    -- Slimmer the deeper spawnPos is behind the first wall from our eyes, down to SummonCountBehindWalls fodder zambies.
    -- The less of a spot we can see, the less we trust a big squad, or a heavy, to get anywhere useful from it.
    function ENT:SquadLimitsThrough( spawnPos, count )
        local spawnEyes = spawnPos + eyeHeight
        local clear, tr = terminator_Extras.PosCanSee( self:GetShootPos(), spawnEyes )
        if clear then return count, self.MaxCarryHealth end

        local depth = tr.HitPos:Distance( spawnEyes )
        local frac = math.Clamp( ( depth - SQUAD_SLIM_START ) / ( SQUAD_SLIM_END - SQUAD_SLIM_START ), 0, 1 )
        local minSize = math.min( self.SummonCountBehindWalls, count ) -- never more than asked for
        local size = math.max( minSize, math.Round( Lerp( frac, count, minSize ) ) )
        local maxHealth = Lerp( frac, self.MaxCarryHealth, math.min( SQUAD_SLIM_MIN_HEALTH, self.MaxCarryHealth ) )
        return size, maxHealth

    end

    -- Spots between us and targetPos, and the far off allies to drop on them, paired by index.
    -- Returns nil and why, if there's no room, or nobody to summon.
    function ENT:PlanSummon( targetPos, count )
        local myCenter = self:WorldSpaceCenter()

        -- deploy spots start halfway to the target, and creep back towards us if there's no room there
        local positions = {}
        local deployCenter
        for i = 1, 4 do
            local lerpFrac = 0.5 - ( ( i - 1 ) / 3 ) * 0.3
            local center = LerpVector( lerpFrac, myCenter, targetPos )
            local spots, gotAll = PackSquadVectors( center, count, math.random( 75, 125 ) )
            if #spots > #positions then
                positions = spots
                deployCenter = center

            end
            if gotAll then break end

        end
        if #positions == 0 then return nil, "no room on the navmesh between us" end

        local size, maxHealth = self:SquadLimitsThrough( deployCenter, #positions )
        for i = #positions, size + 1, -1 do
            positions[i] = nil

        end

        local candidates, pickedFrom = self:PickSummonCandidates( targetPos, #positions, deployCenter, maxHealth )
        if #candidates == 0 then return nil, "nobody to summon, " .. pickedFrom end
        return positions, candidates

    end

    -- Up to count far off allies, farthest first.
    -- Zambies that can already see targetPos, or deployCenter if given, are on their way, so they're left be.
    -- maxHealth, if given, leaves out anyone tougher.
    -- Second return says what they were picked from, for when there's nobody.
    function ENT:PickSummonCandidates( targetPos, count, deployCenter, maxHealth )
        local deployEyes = deployCenter and deployCenter + eyeHeight
        local targetEyes = targetPos + eyeHeight
        local posCanSee = terminator_Extras.PosCanSee
        local candidates = {}
        local summonable = self:FindSummonableZambies( targetPos )
        local alreadyLooking = 0
        for _, ally in ipairs( summonable ) do
            YieldIfWeCan()
            if not IsValid( ally ) then continue end
            if maxHealth and ally:GetMaxHealth() > maxHealth then continue end
            local allyEyes = ally:GetShootPos()
            if posCanSee( allyEyes, targetEyes ) or ( deployEyes and posCanSee( allyEyes, deployEyes ) ) then
                alreadyLooking = alreadyLooking + 1
                continue

            end

            table.insert( candidates, ally )
            if #candidates >= count then break end

        end
        local pickedFrom = #self:GetNearbyAllies() .. " allies, " .. #summonable .. " summonable, " .. alreadyLooking .. " already looking"
        return candidates, pickedFrom

    end

    local SUMMON_RETRY = 1 -- planning scans every zambie, so a miss waits this long before planning again

    -- A plan is what PlanSummon found, ready for SendSummon.
    local function MakePlan( targetPos, positions, candidates, extra )
        return { targetPos = targetPos, positions = positions, candidates = candidates, extra = extra }

    end

    -- Teleports the plan's allies to its spots, subclasses override to send them differently.
    function ENT:SendSummon( plan )
        local liftOffGround = Vector( 0, 0, 10 )
        for i, ally in ipairs( plan.candidates ) do
            if not self:CanSummon( ally ) then continue end -- plans go stale, they could be gone
            self:TeleportZambieTo( ally, plan.positions[i] + liftOffGround, plan.targetPos )

        end

        self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 100, 1 )

    end

    -- Plans and sends right away, no call. Returns true if anyone was sent.
    function ENT:SummonZambies( targetPos, count )
        local positions, candidates, extra = self:PlanSummon( targetPos, count )
        if not positions then return false end
        self:SendSummon( MakePlan( targetPos, positions, candidates, extra ) )
        return true

    end

    -- Plans now and plays the call, SpiritThink sends them once it's had a moment.
    -- Returns true if anyone's coming, or false and why not.
    function ENT:QueueSummon( targetPos, count )
        local positions, candidates, extra = self:PlanSummon( targetPos, count )
        if not positions then return false, candidates end

        local plan = MakePlan( targetPos, positions, candidates, extra )
        plan.at = CurTime() + SUMMON_ARRIVE_DELAY
        self.zamb_SummonRequest = plan
        self:SetNW2Float( "zamb_SummonAt", plan.at )
        self:RunTask( "ZambOnGrumpy" )
        return true

    end

    function ENT:SummonOffCooldown()
        return CurTime() - ( self.zamb_LastSummon or -math.huge ) >= SEEN_SUMMON_INTERVAL

    end

    -- The one place the AI decides to summon, drivers ask through the call action instead.
    -- Every SEEN_SUMMON_INTERVAL while we see them in range or just got hurt, every RemoteSummonInterval off a report.
    -- The clock only advances when someone's actually coming, a miss retries after SUMMON_RETRY.
    function ENT:SummonThink()
        if self.zamb_SummonRequest then return end -- one's already on its way
        local cur = CurTime()
        local count = math.random( self.SummonCountMin, self.SummonCountMax )

        if self:IsControlledByPlayer() then
            local driver = self.zamb_DriverSummonFor
            self.zamb_DriverSummonFor = nil
            if IsValid( driver ) then
                self:QueueSummon( self:GetSummonTarget( driver ), count )

            end
            return

        end

        if ( self.zamb_NextSummonAttempt or 0 ) > cur then return end

        local enemy = self:GetEnemy()
        local seenInRange = self.IsSeeEnemy and IsValid( enemy ) and self.DistToEnemy < self.DeployDistance
        local interval
        if seenInRange or self.zamb_SummonHurt then
            interval = SEEN_SUMMON_INTERVAL

        elseif self:GetFreshIntel() then
            interval = self.RemoteSummonInterval

        else
            return

        end
        if cur - ( self.zamb_LastSummon or -math.huge ) < interval then return end

        self.zamb_SummonHurt = nil
        local queued, whyNot = self:QueueSummon( self:GetSummonTarget(), count )
        if queued then
            print( "summon" )
            self.zamb_LastSummon = cur
            self:ReallyAnger( math.random( 1, 10 ) )

        else
            print( "summonfail", whyNot )
            self.zamb_NextSummonAttempt = cur + SUMMON_RETRY

        end
    end

    -- For the driver's call action, whether calling right now would summon anyone.
    function ENT:HasSomeoneToSummon( driver )
        return self:PlanSummon( self:GetSummonTarget( driver ), 1 ) ~= nil

    end

    -- Where to drop summoned zambies.
    -- Our enemy if we can see them, else where our scouts last saw them.
    -- Failing both, our enemy anyway, or the driver's aim if a player is controlling us.
    function ENT:GetSummonTarget( driver )
        local enemy = self:GetEnemy()
        if IsValid( enemy ) and self.IsSeeEnemy then return enemy:GetPos() end

        local intel = self:GetFreshIntel()
        if intel then return intel.pos end

        if IsValid( enemy ) then return enemy:GetPos() end

        if IsValid( driver ) then
            local shootPos = self:GetShootPos()
            local tr = util.TraceLine( {
                start  = shootPos,
                endpos = shootPos + driver:EyeAngles():Forward() * self.DeployDistance,
                mask   = MASK_SOLID_BRUSHONLY,
            } )
            return tr.HitPos

        end

        return self:GetPos()

    end

    -- Where our scouts last reported our enemy, nil once it's stale.
    function ENT:GetFreshIntel()
        local intel = self.zamb_Intel
        if not intel then return end
        if intel.at + self.IntelTimeout < CurTime() or not IsValid( intel.enemy ) then
            self.zamb_Intel = nil
            return

        end
        return intel

    end

    -- Keeps the report fresh off our own eyes, and drops scout reports we can see are wrong.
    -- SummonThink does the summoning off it.
    function ENT:IntelThink()
        if not self.UsesScoutIntel then return end
        local cur = CurTime()

        if self.IsSeeEnemy then
            -- our own eyes count too, so losing sight of them keeps the pressure on
            local enemy = self:GetEnemy()
            if not IsValid( enemy ) then return end
            local own = self.zamb_Intel
            if not own or own.fromScout then
                own = {}
                self.zamb_Intel = own

            end
            own.enemy, own.pos, own.at = enemy, enemy:GetPos(), cur
            return

        end

        -- where we last saw them is always in view right after they slip out of it, so only scout reports get checked
        local intel = self:GetFreshIntel()
        if not intel or not intel.fromScout then return end
        if cur - intel.at < INTEL_LOS_GRACE then return end

        if ( self.zamb_NextIntelCheck or 0 ) > cur then return end
        self.zamb_NextIntelCheck = cur + 0.5

        if terminator_Extras.PosCanSee( self:GetShootPos(), intel.pos + eyeHeight ) then
            self.zamb_Intel = nil

        end
    end

    -- Only zambies we teleported count, they're our eyes.
    function ENT:SpiritInformReceive( informData )
        if not self.UsesScoutIntel then return end
        local sender = informData.sender
        if not IsValid( sender ) or sender.zamb_ScoutFor ~= self then return end
        if not IsValid( informData.enemy ) or not informData.pos then return end

        -- reports carry their shoot pos, summoning wants the floor under it
        local onNav = terminator_Extras.getNearestPosOnNav( informData.pos ).pos
        self.zamb_Intel = {
            enemy     = informData.enemy,
            pos       = onNav or informData.pos,
            at        = CurTime(),
            fromScout = true,
        }
    end

    -- Out past where we'd hide from the reported spot.
    function ENT:IsFarFromIntel( intel )
        return self:GetPos():DistToSqr( intel.pos ) > ( self.DeployDistance * HIDE_RANGE_MUL ) ^ 2

    end

    -- Heads back to within hiding range of the reported spot, after drifting off.
    -- Returns true if we're on our way.
    function ENT:ApproachIntel( intel )
        if ( self.zamb_NextIntelApproach or 0 ) > CurTime() then return false end
        self.zamb_NextIntelApproach = CurTime() + 5

        local toMe = self:GetPos() - intel.pos
        toMe.z = 0
        toMe:Normalize()
        local area = navmesh.GetNearestNavArea( intel.pos + toMe * self.DeployDistance, false, 512 )
        if not area or not self:areaIsReachable( area ) then return false end

        self:StartTask( "movement_gotoarea", {
            Area = area,
            GiveUpAfter = 10,
            LookAhead = true,
            LeapAlongPath = true,
            AfterwardsTask = "movement_handler",
            OnFailTask = "movement_handler",
        }, "drifted too far from my scouts" )
        return true

    end

    -- straight away first, then angled off if that's a wall
    local FLEE_YAWS = { 0, 45, -45, 90, -90 }

    -- Paths to an area farther from the enemy than we are.
    -- Returns true if we're fleeing, false if there was nowhere better to go.
    function ENT:KeepDistanceFrom( enemyPos )
        if self:IsTaskActive( "movement_gotoarea" ) then return true end
        if ( self.zamb_NextFleeCheck or 0 ) > CurTime() then return false end
        self.zamb_NextFleeCheck = CurTime() + 0.5

        local myPos = self:GetPos()
        local myDistSqr = myPos:DistToSqr( enemyPos )
        local away = myPos - enemyPos
        away.z = 0
        away:Normalize()
        local fleeDist = self.DeployDistance * 0.5

        for _, yaw in ipairs( FLEE_YAWS ) do
            local dir = Vector( away )
            dir:Rotate( Angle( 0, yaw, 0 ) )

            -- the nearest area to a spot behind us can be on the enemy's side of a wall
            local fleeArea = navmesh.GetNearestNavArea( myPos + dir * fleeDist, false, 512 )
            local drowns = fleeArea and self.BreathesAir and fleeArea:IsUnderwater()
            if fleeArea and not drowns and fleeArea:GetCenter():DistToSqr( enemyPos ) > myDistSqr and self:areaIsReachable( fleeArea ) then
                self:KillAllTasksWith( "movement" )
                self:StartTask( "movement_gotoarea", { Area = fleeArea, GiveUpAfter = 5, LookAhead = true, LeapAlongPath = true }, "they're too close, i need to keep my distance" )
                self:RestartMotionCoroutine()
                return true

            end
        end
        return false

    end

    function ENT:ShouldHoldDistance()
        if not self.zamb_StayOutOfMeleeRange then return false end
        if not self.IsSeeEnemy then return false end
        if not IsValid( self:GetEnemy() ) then return false end
        return self.DistToEnemy < self.DeployDistance

    end

    local ESCAPE_YAWS = { 0, 45, -45, 90, -90 }

    -- Leaps somewhere farther from threat than we are, then goes looking for somewhere to hide.
    -- Returns true if we leapt.
    function ENT:EscapeFrom( threat )
        if not self.loco:IsOnGround() then return end
        if ( self.zamb_NextEscape or 0 ) > CurTime() then return end

        local myPos = self:GetPos()
        local threatPos = threat:GetPos()
        local myDistSqr = myPos:DistToSqr( threatPos )
        local away = myPos - threatPos
        away.z = 0
        away:Normalize()
        local leapDist = self.JumpHeight * 1.5 -- CanJumpToPos refuses past 2x
        local myTbl = self:GetTable()

        self:ReallyAnger( 30 )

        for _, yaw in ipairs( ESCAPE_YAWS ) do
            local dir = Vector( away )
            dir:Rotate( Angle( 0, yaw, 0 ) )

            local landing = terminator_Extras.getNearestPosOnNav( myPos + dir * leapDist ).pos
            if landing and landing:DistToSqr( threatPos ) > myDistSqr and self:CanJumpToPos( myTbl, landing ) then
                self.zamb_NextEscape = CurTime() + 1.5

                -- kill movement first, a running path would steer us out of the leap
                self:KillAllTasksWith( "movement" )
                self:JumpToPos( landing )
                self:StartTask( "movement_spirit_hide", { EnemyPos = threatPos, EnemyEyes = threat:EyePos() }, "that hurt, time to get out of here" )
                self:RestartMotionCoroutine()
                return true

            end
        end
    end

    -- A nearby area the enemy can't see, farther from them than we are, but still in summon range.
    -- Yields, so call it from a motion task.
    function ENT:FindHidingArea( enemyPos, enemyEyes )
        local myPos = self:GetPos()
        local searchRadius = self.DeployDistance
        local searchRadiusSqr = searchRadius ^ 2
        local minDistSqr = math.max( myPos:DistToSqr( enemyPos ), ( self.DeployDistance * 0.5 ) ^ 2 )
        local maxDistSqr = ( self.DeployDistance * HIDE_RANGE_MUL ) ^ 2
        local hidden = {} -- IsVisible traces, so each area only gets checked once

        -- areas scoring 0 are never walked through, so only rule out what we'd never path across
        local function scoreFunc( _, _, area )
            local center = area:GetCenter()
            if center:DistToSqr( myPos ) > searchRadiusSqr then return 0 end

            local distSqr = center:DistToSqr( enemyPos )
            if distSqr > maxDistSqr then return 0 end
            if not self:areaIsReachable( area ) then return 0 end
            if distSqr < minDistSqr then return 1 end
            if self.BreathesAir and area:IsUnderwater() then return 1 end -- fine to swim through, not to lurk in

            local id = area:GetID()
            if hidden[id] == nil then
                hidden[id] = not area:IsVisible( enemyEyes )

            end
            if hidden[id] then return math.huge end
            return distSqr -- keep heading away from them

        end

        local _, area = self:findValidNavResult( { blockRadiusEnd = true }, myPos, searchRadius, scoreFunc )
        -- the search falls back to its best area when it runs out, which might not be hidden
        if not IsValid( area ) or not hidden[area:GetID()] then return end
        return area

    end

    function ENT:DoCustomTasks( defaultTasks )
        BaseClass.DoCustomTasks( self, defaultTasks )
        local taskList = self.TaskList
        taskList["movement_gotoarea"] = defaultTasks["movement_gotoarea"]

        -- stand back and let the summons do the fighting
        taskList["movement_spirit_hold"] = {
            OnStart = function( self )
                self:InvalidatePath( "holding my distance" )

            end,
            BehaveUpdateMotion = function( self )
                if self:ShouldHoldDistance() then return end
                self:TaskComplete( "movement_spirit_hold" )
                self:StartTask( "movement_handler", "they're out of range" )

            end,
        }

        taskList["movement_spirit_hide"] = {
            OnStart = function( self )
                self.zamb_NextHideAttempt = CurTime() + HIDE_RETRY_TIME

            end,
            BehaveUpdateMotion = function( self, data )
                local area = self:FindHidingArea( data.EnemyPos, data.EnemyEyes )
                if not area then
                    self:TaskFail( "movement_spirit_hide" )
                    self:StartTask( "movement_spirit_hold", "nowhere to hide" )
                    return

                end
                self:TaskComplete( "movement_spirit_hide" )
                self:StartTask( "movement_gotoarea", {
                    Area = area,
                    GiveUpAfter = 6,
                    LookAhead = true,
                    LeapAlongPath = true,
                    AfterwardsTask = "movement_spirit_lurk",
                    OnFailTask = "movement_handler",
                }, "found somewhere they can't see me" )

            end,
        }

        -- wait out of sight, then peek out once we can summon again
        taskList["movement_spirit_lurk"] = {
            OnStart = function( self, data )
                self:InvalidatePath( "lurking" )
                data.peekAfter = CurTime() + LURK_MIN_TIME
                data.giveUpAt = CurTime() + LURK_MAX_TIME

            end,
            BehaveUpdateMotion = function( self, data )
                -- peeking waits on having someone to summon, which can take minutes mid siege, so move on regardless
                if data.giveUpAt < CurTime() and not self.IsSeeEnemy then
                    self:TaskComplete( "movement_spirit_lurk" )
                    self:StartTask( "movement_handler", "been still too long" )
                    return

                end

                if not IsValid( self:GetEnemy() ) then
                    -- our scouts still have them, IntelThink keeps summoning, the handler pulls us back in if we've drifted
                    local intel = self:GetFreshIntel()
                    if intel and ( data.peekAfter > CurTime() or not self:IsFarFromIntel( intel ) ) then return end
                    self:TaskComplete( "movement_spirit_lurk" )
                    self:StartTask( "movement_handler", "lost track of them" )
                    return

                end
                if self.IsSeeEnemy then
                    if self:ShouldHoldDistance() then return end -- BehaveUpdatePriority finds us a new spot
                    self:TaskComplete( "movement_spirit_lurk" )
                    self:StartTask( "movement_handler", "i can see them, but they're too far" )
                    return

                end
                if data.peekAfter > CurTime() then return end
                if not self:SummonOffCooldown() then return end

                self:TaskComplete( "movement_spirit_lurk" )
                self:StartTask( "movement_followenemy", "peeking out to summon" )

            end,
        }

        local baseHandler = taskList["movement_handler"]
        taskList["movement_handler"] = {
            StartsOnInitialize = baseHandler.StartsOnInitialize,
            BehaveUpdateMotion = function( self, data )
                if self:ShouldHoldDistance() then
                    self:TaskComplete( "movement_handler" )
                    self:StartTask( "movement_spirit_hold", "they're in range" )
                    return

                end

                -- can't see them but our scouts can, stay close instead of wandering off
                local intel = not self.IsSeeEnemy and self:GetFreshIntel()
                if intel then
                    local tooFar = self:IsFarFromIntel( intel )
                    self:TaskComplete( "movement_handler" )
                    if tooFar and self:ApproachIntel( intel ) then return end

                    -- hiding only ever moves us away from EnemyPos, so it can't bring us back from too far
                    if not tooFar and ( self.zamb_NextHideAttempt or 0 ) < CurTime() then
                        self:StartTask( "movement_spirit_hide", { EnemyPos = intel.pos, EnemyEyes = intel.pos + eyeHeight }, "my scouts know where they are" )

                    else
                        self:StartTask( "movement_spirit_lurk", "waiting on my scouts" )

                    end
                    return

                end
                return baseHandler.BehaveUpdateMotion( self, data )

            end,
        }
    end

    function ENT:AdditionalInitialize()
        BaseClass.AdditionalInitialize( self )
        self:SetBodygroup( 1, 0 )
    end

    function ENT:SpiritDeath()
        if self:GetIsDying() then return end
        self:SetIsDying( true )
        self:SetDeathTime( CurTime() )

        self:StopMoving()
        self:SetSolid( SOLID_NONE )
        self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        self:SetMoveType( MOVETYPE_FLY ) -- hang in the air while the fade plays

        if self.SummonsOnDeath then -- one last pull as it goes
            self:SummonZambies( self:GetSummonTarget(), math.random( 2, 4 ) )

        end

        local ed = EffectData()
        ed:SetMagnitude( 1.5 )
        ed:SetOrigin( self:WorldSpaceCenter() )
        ed:SetRadius( 78 )
        ed:SetNormal( self:GetAngles():Up() )
        util.Effect( "eff_zambspirit_blast", ed, true, true )
        self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 170, 1 )

        -- FinishDying hid us, but the dying trails and sprite are drawn by us
        self:SetNoDraw( false )
        SafeRemoveEntityDelayed( self, DEATH_FADE_TIME )

    end

    -- MyClassTask hands off to these, subclasses override them.
    -- Hooks and actions queue work instead of doing it, SpiritThink runs it inside our thread where it can yield.

    function ENT:SpiritOnDamaged( dmg )
        local melee = bit.band( dmg:GetDamageType(), bit.bor( DMG_SLASH, DMG_CLUB ) ) > 0
        if melee then
            dmg:ScaleDamage( 2.2 )

        elseif dmg:GetDamage() < 25 then
            dmg:ScaleDamage( 0.2 )

        end

        -- after the scaling above, so a melee hit it doubles into a one shot still counts
        if self.OneHitFreebie and not self.zamb_UsedFreebie and dmg:GetDamage() >= self:GetMaxHealth() * 0.5 then
            self.zamb_UsedFreebie = true
            dmg:ScaleDamage( 0.1 )
            self:SetNW2Float( "zamb_FreebieAt", CurTime() )

        end

        -- a driver picks their own moments
        if self:IsControlledByPlayer() then return end
        self.zamb_SummonHurt = true -- SummonThink answers it

        if dmg:GetDamage() >= self:Health() then return end -- dying anyway
        if not self.zamb_StayOutOfMeleeRange then return end
        local threat = self:GetEnemy()
        if not IsValid( threat ) then
            threat = dmg:GetAttacker()

        end
        if IsValid( threat ) and threat ~= self then
            self:EscapeFrom( threat )

        end
    end

    function ENT:SpiritThink()
        local request = self.zamb_SummonRequest
        if request and request.at <= CurTime() then
            self.zamb_SummonRequest = nil
            self:SendSummon( request )

        end

        self:IntelThink()
        self:SummonThink()

        -- for the heartbeat, NW2 only sends what changed
        self:SetNW2Float( "zamb_SpiritHealth", math.Round( self:Health() / self:GetMaxHealth(), 2 ) )
        self:SetNW2Bool( "zamb_SpiritLurking", self:IsTaskActive( "movement_spirit_lurk" ) )

    end

    function ENT:SpiritBehavePriority()
        if not self.IsSeeEnemy then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end

        local dist = self.DistToEnemy
        if dist >= self.DeployDistance then return end
        if not self.zamb_StayOutOfMeleeRange then return end

        -- already on our way somewhere
        if self:IsTaskActive( "movement_spirit_hide" ) or self:IsTaskActive( "movement_gotoarea" ) then return end

        if ( self.zamb_NextHideAttempt or 0 ) < CurTime() then
            self:KillAllTasksWith( "movement" )
            self:StartTask( "movement_spirit_hide", { EnemyPos = enemy:GetPos(), EnemyEyes = enemy:EyePos() }, "they can see me, time to hide" )
            self:RestartMotionCoroutine()
            return

        end

        -- couldn't find anywhere to hide lately
        if dist < self.DeployDistance / 2 and self:KeepDistanceFrom( enemy:GetPos() ) then return end

        if self:IsTaskActive( "movement_followenemy" ) then
            self:KillAllTasksWith( "movement" )
            self:StartTask( "movement_spirit_hold", "close enough, time to summon" )
            self:RestartMotionCoroutine()

        end
    end

    function ENT:SpiritDealtFistDamage( _target, _dmg )
    end
end

ENT.MySpecialActions = {
    ["call"] = {
        inBind    = IN_RELOAD,
        drawHint  = true,
        name      = "Summon Zambies",
        desc      = "Pull far off zambies in front of you",
        ratelimit = 5,
        svCanAct  = function( bot, driver )
            return bot:HasSomeoneToSummon( driver )

        end,
        svAction  = function( _driveController, driver, bot )
            bot.zamb_DriverSummonFor = driver -- SummonThink plans and calls

        end,
    },
}

ENT.MyClassTask = {
    OnDamaged = function( self, _data, dmg )
        if self:GetIsDying() then return true end
        return self:SpiritOnDamaged( dmg )

    end,
    Think = function( self )
        if self:GetIsDying() then return end -- still called while behaviour is disabled
        self:SpiritThink()

    end,
    BehaveUpdatePriority = function( self )
        if self:GetIsDying() then return end
        self:SpiritBehavePriority()

    end,
    OnDealtFistDamage = function( self, _data, target, dmg )
        self:SpiritDealtFistDamage( target, dmg )

    end,
    InformReceive = function( self, _data, informData )
        self:SpiritInformReceive( informData )

    end,
    PreventBecomeRagdollOnKilled = function()
        return true, true

    end,
    OnKilledDmg = function( self )
        self:SpiritDeath()

    end,
    DisableBehaviour = function( self )
        return self:GetIsDying()

    end,
}

if CLIENT then
    ENT.mat       = Material( "effects/strider_muzzle" )
    ENT.mat_trail = Material( "trails/plasma" )

    local function GetFPSEstimate()
        local ft = FrameTime()
        if ft <= 0 then return 60 end
        return 1 / ft

    end

    local TRAIL_BONE_NAMES = {
        "ValveBiped.Bip01_L_Calf",
        "ValveBiped.Bip01_R_Calf",
        "ValveBiped.Bip01_L_Hand",
        "ValveBiped.Bip01_R_Hand",
    }

    function ENT:AdditionalClientInitialize()
        BaseClass.AdditionalClientInitialize( self )
        self.trailLength = 16
        self.trailBones  = {}
        self.trails      = {}
        for _, boneName in ipairs( TRAIL_BONE_NAMES ) do
            local bone = self:LookupBone( boneName )
            if not bone then continue end

            table.insert( self.trailBones, bone )
            table.insert( self.trails, {} )

        end

        self.zamb_PulseThinkAt = CurTime()
        self.zamb_BeatPhase = 0
        self.zamb_BeatRate = 1
        self.zamb_BeatAmp = 0
        self.zamb_DubAmp = 0
        self.zamb_Echoes = {}
        self.zamb_SkipOffset = vector_origin
    end

    -- 1 while alive, eases to 0 over the death fade
    local function DeathFrac( self )
        if not self:GetIsDying() then return 1 end
        local elapsed = CurTime() - self:GetDeathTime()
        return math.ease.InCubic( math.max( 0, 1 - elapsed / DEATH_FADE_TIME ) )

    end

    -- The heartbeat. Phase runs 0 to 1 over a beat, lub at 0, dub at DUB_AT.
    -- Each beat's rate and strength are picked as it starts, so a change shows on the next beat, not mid thud.
    local DUB_AT       = 0.2
    local THUMP_LENGTH = 1 / 6 -- of a beat, slow beats get a long silence after
    local THUMP_MIN_TIME = 0.1 -- seconds, any shorter and fast beats are a frame or two, invisible
    local HEARTBEAT_SOUND = "npc/vort/vort_foot1.wav"
    local MAX_ECHOES  = 3 -- each is another DrawModel
    local ECHO_LIFE   = 0.6
    local SKIP_DIST   = 12 -- times the beat's strength, rage and summons skip farther
    local SKIP_FRAC   = 0.4 -- of a thump, then it snaps back

    -- of a beat
    local function ThumpLength( rate )
        return math.max( THUMP_LENGTH, THUMP_MIN_TIME * rate )

    end

    local function Thump( phase, length )
        if phase < 0 then return 0 end
        return math.max( 0, 1 - phase / length ) ^ 2

    end

    -- Hz, lub strength, dub strength, for the beat that's starting. Subclasses override.
    function ENT:NextBeat()
        return Lerp( self:GetNW2Float( "zamb_SpiritHealth", 1 ), 2.5, 0.8 ), 1, 0.6

    end

    -- slowBy stretches this one beat out, deeper and longer
    function ENT:StartBeat( amp, dubAmp, slowBy )
        local rate, beatAmp, beatDub = self:NextBeat()
        amp, dubAmp, slowBy = amp or beatAmp, dubAmp or beatDub, slowBy or 1

        if self:GetNW2Bool( "zamb_SpiritLurking", false ) then
            rate, amp, dubAmp = rate * 0.75, amp * 0.6, dubAmp * 0.6

        end
        if CurTime() - self:GetNW2Float( "zamb_SummonAt", -math.huge ) < SEEN_SUMMON_INTERVAL then -- spent, until it can summon again
            amp, dubAmp = amp * 0.6, dubAmp * 0.6

        end

        self.zamb_BeatPhase = 0
        self.zamb_BeatRate = rate / slowBy
        self.zamb_BeatAmp, self.zamb_DubAmp = amp, dubAmp

        -- leaves a ghost where it stood, and almost blinks away
        local echoes = self.zamb_Echoes
        table.insert( echoes, 1, { pos = self:GetPos(), at = CurTime() } )
        echoes[MAX_ECHOES + 1] = nil
        local skipDir = VectorRand()
        skipDir.z = 0
        skipDir:Normalize()
        self.zamb_SkipOffset = skipDir * SKIP_DIST * amp
        -- heard through walls, so it can be hunted by ear
        self:EmitSound( HEARTBEAT_SOUND, 80 + amp * 5, self.HeartbeatPitch / slowBy, math.min( 1, amp * 0.5 ) )

    end

    local function Crossed( self, name, from, to )
        local at = self:GetNW2Float( name, 0 )
        return at > from and at <= to

    end

    function ENT:PulseThink()
        local now = CurTime()
        local last = self.zamb_PulseThinkAt
        self.zamb_PulseThinkAt = now
        -- slows to a stop as it dies
        local phase = self.zamb_BeatPhase + ( now - last ) * self.zamb_BeatRate * DeathFrac( self )

        if Crossed( self, "zamb_SummonAt", last, now ) then
            self:StartBeat( 2.5, 0.3, 2 )

        elseif Crossed( self, "zamb_BodyguardAt", last, now ) then
            self:StartBeat( 1.8, 1.8 ) -- two even thuds

        elseif Crossed( self, "zamb_FreebieAt", last, now ) then
            self.zamb_BeatPhase = -0.6 -- skips a beat

        elseif phase >= 1 then
            -- keep what we overshot, Think's too coarse to drop it at fast rates
            local overshootTime = ( phase - 1 ) / self.zamb_BeatRate
            self:StartBeat()
            self.zamb_BeatPhase = math.min( overshootTime * self.zamb_BeatRate, 0.5 )

        else
            self.zamb_BeatPhase = phase

        end
    end

    -- Think only runs 16 times a second, so this carries the phase on to the frame.
    local function CurrentPhase( self, now )
        return self.zamb_BeatPhase + ( now - self.zamb_PulseThinkAt ) * self.zamb_BeatRate * DeathFrac( self )

    end

    -- How hard the heart's thudding right now, 0 between beats, can go past 1.
    function ENT:GetPulse()
        if not self.zamb_PulseThinkAt then return 0 end -- the link hook can find us before we've initialized
        local now = CurTime()
        local phase = CurrentPhase( self, now )
        local length = ThumpLength( self.zamb_BeatRate )
        local pulse = self.zamb_BeatAmp * Thump( phase, length ) + self.zamb_DubAmp * Thump( phase - DUB_AT, length )

        -- swells into the summon's thud
        local windup = 1 - ( self:GetNW2Float( "zamb_SummonAt", 0 ) - now ) / SUMMON_ARRIVE_DELAY
        if windup > 0 and windup < 1 then
            pulse = pulse + windup ^ 2 * 1.5

        end
        return pulse

    end

    local bodyMatrix = Matrix() -- reused, EnableMatrix copies it

    -- Draws the model offset and scaled, render only, the hitbox stays put.
    -- The bone cache holds last draw's matrix, so drawing more than once a frame needs it rebuilt.
    local function DrawModelAt( self, localOffset, scale )
        bodyMatrix:Identity()
        bodyMatrix:Translate( localOffset )
        bodyMatrix:Scale( Vector( scale, scale, scale ) )
        self:EnableMatrix( "RenderMultiply", bodyMatrix )
        self:InvalidateBoneCache()
        self:DrawModel()

    end

    -- Zambies a spirit sent glow in time with it, until it dies.
    local pulseLinks = {}
    local linkGlow = Material( "sprites/light_glow02_add" )

    hook.Add( "EntityNetworkedVarChanged", "zamb_SpiritPulseLinks", function( ent, name, _, spirit )
        if name ~= "zamb_PulseSpirit" then return end
        pulseLinks[ent] = IsValid( spirit ) and spirit or nil

    end )

    hook.Add( "PostDrawTranslucentRenderables", "zamb_SpiritPulseLinks", function( depth, skybox )
        if depth or skybox or next( pulseLinks ) == nil then return end

        render.SetMaterial( linkGlow )
        for ally, spirit in pairs( pulseLinks ) do
            if not IsValid( ally ) or not IsValid( spirit ) or spirit:GetIsDying() then
                pulseLinks[ally] = nil
                continue

            end
            if ally:IsDormant() or spirit:IsDormant() then continue end

            local pulse = spirit:GetPulse()
            if pulse < 0.05 then continue end
            local size = 40 * pulse * ally:GetModelScale()
            render.DrawSprite( ally:WorldSpaceCenter(), size, size, Color( 255, 0, 0, 255 * math.min( 1, pulse ) ) )

        end
    end )

    function ENT:Think()
        BaseClass.Think( self )
        self:RemoveAllDecals()
        self:PulseThink()

        if FrameTime() > 0 and self.trailBones then
            -- while dying the trails pull in to our center
            local pullIn = 1 - DeathFrac( self )
            local myX, myY, myZ = self:WorldSpaceCenter():Unpack()
            for i, bone in ipairs( self.trailBones ) do
                local trail   = self.trails[i]
                local bonePos = self:GetBonePosition( bone )
                local boneX, boneY, boneZ = bonePos:Unpack()
                bonePos:SetUnpacked(
                    Lerp( pullIn, boneX, myX ),
                    Lerp( pullIn, boneY, myY ),
                    Lerp( pullIn, boneZ, myZ )
                )
                table.insert( trail, 1, bonePos )
                trail[self.trailLength] = nil

            end
        end
        self:SetNextClientThink( CurTime() + 1 / self.trailLength )

        return true

    end

    function ENT:DrawTranslucent()
        if render.GetRenderTarget() then return end

        local myPos     = self:WorldSpaceCenter()
        local eyePos    = EyePos()
        local time      = CurTime()
        local dying     = self:GetIsDying()
        local deathFrac = DeathFrac( self )
        -- the sprite layers spread out right as it dies
        local blastFrac = dying and math.max( 0, 1 - ( time - self:GetDeathTime() ) * 5 ) or 0
        local pulse     = self:GetPulse()
        local swell     = 1 + pulse * 0.35

        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        if self.trails and GetFPSEstimate() > 30 then
            render.SetMaterial( self.mat_trail )
            for _, trail in ipairs( self.trails ) do
                local count = #trail
                if count < 2 then continue end

                render.StartBeam( count )
                for j, point in ipairs( trail ) do
                    local alongTrail = ( j - 1 ) / ( count - 1 )
                    render.AddBeam( point, 7 * swell * deathFrac * ( 1 - alongTrail ), alongTrail * 4, Color( 255 * ( 1 - alongTrail ), 0, 0 ) )
                end
                render.EndBeam()

            end
        end

        if not dying then
            -- ghosts of where it stood on recent beats, fading out
            -- no depth writes, or a ghost in front cuts a hole in the body
            -- drawn before the body, so the bone cache ends on the body's matrix, the trails read it
            render.OverrideDepthEnable( true, false )
            for _, echo in ipairs( self.zamb_Echoes ) do
                local fade = 1 - ( time - echo.at ) / ECHO_LIFE
                if fade <= 0 then continue end
                render.SetColorModulation( fade ^ 2 * 3, 0, 0 )
                DrawModelAt( self, self:WorldToLocal( echo.pos ), 1 )

            end
            render.OverrideDepthEnable( false )

            render.SetColorModulation( 700, 1, 1 ) -- blows the red channel out, the model glows solid red under the additive blend
            -- swells on each beat, and for the start of the thud, skips aside like it nearly teleported
            local bodySwell = 1 + math.min( pulse, 2.5 ) * 0.1
            local skipping = CurrentPhase( self, time ) < ThumpLength( self.zamb_BeatRate ) * SKIP_FRAC
            DrawModelAt( self, skipping and self.zamb_SkipOffset or vector_origin, bodySwell )
            render.SetColorModulation( 1, 1, 1 )

        end

        if eyePos:DistToSqr( myPos ) < 3250 ^ 2 then
            surface.SetMaterial( self.mat )
            surface.SetAlphaMultiplier( 1 )
            surface.SetDrawColor( 255 * deathFrac, 0, 0, 255 * deathFrac )
            local angle = ( myPos - eyePos ):Angle()
            angle:RotateAroundAxis( angle:Right(), 90 )
            local scale = self:GetModelScale()
            local spriteSwell = 1 + pulse * 0.6 -- harder than the trails, the spin and shrink hide a small one

            -- four spinning layers, each a quarter cycle out of step
            for layer = 1, 4 do
                cam.Start3D2D( myPos, angle, scale * ( 1 + blastFrac * layer ) )
                local cycle = ( time + layer / 4 ) % 1
                local size  = ( 72 - cycle * 32 ) * spriteSwell * deathFrac
                surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * layer * 360 )
                cam.End3D2D()

            end
        end

        render.OverrideBlend( false )

    end
end
