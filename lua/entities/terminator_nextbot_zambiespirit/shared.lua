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
ENT.SummonMinPlayerDist = 550 -- never drops a zambie this close to a player, a squad landing on top of you is a cheap hit
ENT.SummonGuardDist = 0 -- except players this close to us, then it's guarding itself
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

-- NW2, not NetworkVar, DT vars misbehave on this base. Set with MarkDying.

-- When SpiritDeath ran, 0 if it hasn't.
function ENT:GetDeathTime()
    return self:GetNW2Float( "zamb_SpiritDeathTime", 0 )

end

function ENT:GetIsDying()
    return self:GetDeathTime() > 0

end

ENT.DeployDistance = 2000 -- summons when its enemy is closer than this, backs off when they're closer than half
-- the eff_zambspirit_blast it bursts into as it dies, visuals only, it deals no damage
ENT.DeathFxSize = 78
ENT.DeathFxDuration = 1.5 -- the effect's magnitude, stretches how long it lasts

if SERVER then
    util.AddNetworkString( "zamb_SpiritIncoming" )

    function ENT:MarkDying()
        self:SetNW2Float( "zamb_SpiritDeathTime", CurTime() )

    end

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

    -- Hidden a moment before it moves and a moment after, so clients never see it slide across the map.
    -- The move happens later, anything that needs it there goes in onArrived( ent ), the teleport stops its movement.
    function ENT:TeleportZambieTo( ent, targetPos, faceTowards, onArrived )
        FireSummonEffectAt( ent )
        local wasHidden = ent:GetNoDraw()
        local fromPos = ent:GetPos()
        local arrived
        ent:SetNoDraw( true )

        timer.Simple( 0.1, function()
            if not IsValid( ent ) then return end
            if ent:Health() > 0 then
                terminator_Extras.TeleportTermTo( ent, targetPos )
                ent:SetNW2Vector( "zamb_SpiritDepartPos", fromPos )
                arrived = true

                if faceTowards then
                    local faceAngle = ( faceTowards - targetPos ):Angle()
                    faceAngle.p = 0
                    faceAngle.r = 0
                    ent:SetAngles( faceAngle )
                end
                ent:ReallyAnger( 60 )
                if IsValid( self ) then
                    ent.zamb_ScoutFor = self -- see SpiritInformReceive
                    ent:SetNW2Entity( "zamb_PulseSpirit", self ) -- glows in time with our heartbeat
                    FireDeployEffectAt( self, targetPos )
                    if onArrived then onArrived( ent ) end

                end
            end

            timer.Simple( 0.1, function()
                if not IsValid( ent ) then return end
                ent:SetNoDraw( wasHidden )
                -- clients draw the arrival off this and zamb_SpiritDepartPos, from the moment it's seen, see the pulse link hook
                if arrived then
                    ent:SetNW2Float( "zamb_SpiritArrivedAt", CurTime() )

                end
            end )
        end )
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

    -- Drops the spots within SummonMinPlayerDist of any living player, but players inside SummonGuardDist of us don't count.
    function ENT:SpotsAwayFromPlayers( spots )
        local minDistSqr = self.SummonMinPlayerDist ^ 2
        local myPos = self:GetPos()
        local guardDistSqr = self.SummonGuardDist ^ 2
        local players = {}
        for _, ply in ipairs( player.GetAll() ) do
            if ply:Alive() and ply:GetPos():DistToSqr( myPos ) >= guardDistSqr then
                table.insert( players, ply )

            end
        end

        local kept = {}
        for _, spot in ipairs( spots ) do
            local tooClose = false
            for _, ply in ipairs( players ) do
                if ply:GetPos():DistToSqr( spot ) < minDistSqr then
                    tooClose = true
                    break

                end
            end
            if not tooClose then
                table.insert( kept, spot )

            end
        end
        return kept

    end

    -- Spots between us and targetPos, and the far off allies to drop on them, paired by index.
    -- Returns nil and why, if there's no room, or nobody to summon.
    function ENT:PlanSummon( targetPos, count )
        local myCenter = self:WorldSpaceCenter()

        -- deploy spots start halfway to the target, and creep back towards us if there's no room there, or it's too near a player
        local positions = {}
        local deployCenter
        for i = 1, 4 do
            local lerpFrac = 0.5 - ( ( i - 1 ) / 3 ) * 0.3
            local center = LerpVector( lerpFrac, myCenter, targetPos )
            local spots = self:SpotsAwayFromPlayers( PackSquadVectors( center, count, math.random( 75, 125 ) ) )
            local gotAll = #spots >= count
            if #spots > #positions then
                positions = spots
                deployCenter = center

            end
            if gotAll then break end

        end
        if #positions == 0 then return nil, "no room on the navmesh between us, away from players" end

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

    -- When the plan's index'th ally lands, subclasses that stagger them override it.
    function ENT:SummonArriveTime( plan, _index )
        return plan.at

    end

    local MAX_WARNINGS = 31 -- fits the 5 bit count

    -- One message for the whole squad, clients mark where each will land until it does.
    function ENT:WarnIncoming( plan )
        local count = math.min( #plan.positions, #plan.candidates, MAX_WARNINGS )
        if count <= 0 then return end

        net.Start( "zamb_SpiritIncoming" )
        net.WriteEntity( self )
        net.WriteUInt( count, 5 )
        for i = 1, count do
            net.WriteVector( plan.positions[i] )
            net.WriteFloat( self:SummonArriveTime( plan, i ) )

        end
        net.Broadcast()

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
        self:WarnIncoming( plan )
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
            --print( "summon" )
            self.zamb_LastSummon = cur
            self:ReallyAnger( math.random( 1, 10 ) )

        else
            --print( "summonfail", whyNot )
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

        taskList["movement_spirit_hide"] = {
            OnStart = function( self )
                self.zamb_NextHideAttempt = CurTime() + HIDE_RETRY_TIME

            end,
            BehaveUpdateMotion = function( self, data )
                local area = self:FindHidingArea( data.EnemyPos, data.EnemyEyes )
                if not area then
                    self:TaskFail( "movement_spirit_hide" )
                    self:StartTask( "movement_holdrange", "nowhere to hide" )
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
                    if self.zamb_StayOutOfMeleeRange and self:ZAMB_CanHoldRangeHere() then return end -- BehaveUpdatePriority finds us a new spot
                    self:TaskComplete( "movement_spirit_lurk" )
                    self:StartTask( "movement_handler", "i can see them, but they're too far" )
                    return

                end
                if data.peekAfter > CurTime() then return end
                if not self:SummonOffCooldown() then return end

                self:TaskComplete( "movement_spirit_lurk" )
                self:StartTask( "movement_holdrange", "peeking out to summon" )

            end,
        }

        local baseHandler = taskList["movement_handler"]
        taskList["movement_handler"] = {
            StartsOnInitialize = baseHandler.StartsOnInitialize,
            BehaveUpdateMotion = function( self, data )
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
        self.zamb_HoldRangeMin = self.DeployDistance * 0.5
        self.zamb_HoldRangeMax = self.DeployDistance
    end

    function ENT:SpiritDeath()
        if self:GetIsDying() then return end
        self:MarkDying()

        self:StopMoving()
        self:SetSolid( SOLID_NONE )
        self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        self:SetMoveType( MOVETYPE_FLY ) -- hang in the air while the fade plays

        if self.SummonsOnDeath then -- one last pull as it goes
            self:SummonZambies( self:GetSummonTarget(), math.random( 2, 4 ) )

        end

        local ed = EffectData()
        ed:SetMagnitude( self.DeathFxDuration )
        ed:SetOrigin( self:WorldSpaceCenter() )
        ed:SetRadius( self.DeathFxSize )
        ed:SetNormal( self:GetAngles():Up() )
        util.Effect( "eff_zambspirit_blast", ed, true, true )
        -- its own channel, so the die sound on CHAN_VOICE plays under it
        self:EmitSound( "npc/advisor/advisor_scream.wav", 100 + self.term_SoundLevelShift, 170 + self.term_SoundPitchShift, 1, CHAN_STATIC )

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

        -- couldn't find anywhere to hide lately, movement_holdrange keeps our distance
        if self:IsTaskActive( "movement_holdrange" ) then return end
        if dist < self.zamb_HoldRangeMin or self:IsTaskActive( "movement_followenemy" ) then
            self:KillAllTasksWith( "movement" )
            self:StartTask( "movement_holdrange", "close enough, time to summon" )
            self:RestartMotionCoroutine()

        end
    end

    function ENT:SpiritDealtFistDamage( _target, _dmg )
    end

    -- Only called for subclasses with a Term_DeathAnim, SpiritDeath comes once it's played.
    function ENT:SpiritStartDying()
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

-- Dying, or playing a Term_DeathAnim on the way there, either way it's done.
local function IsGone( self )
    return self:GetIsDying() or self.term_Dead

end

ENT.MyClassTask = {
    OnDamaged = function( self, _data, dmg )
        if IsGone( self ) then return true end
        return self:SpiritOnDamaged( dmg )

    end,
    Think = function( self )
        if IsGone( self ) then return end -- still called while behaviour is disabled
        self:SpiritThink()

    end,
    BehaveUpdatePriority = function( self )
        if IsGone( self ) then return end
        self:SpiritBehavePriority()

    end,
    OnStartDying = function( self )
        self:SpiritStartDying()

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
        return IsGone( self )

    end,
}

if CLIENT then
    local entMeta = FindMetaTable( "Entity" )

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
    -- every frame, reads GetDeathTime's NW2 straight off entMeta
    local function DeathFrac( self )
        local deathTime = entMeta.GetNW2Float( self, "zamb_SpiritDeathTime", 0 )
        if deathTime <= 0 then return 1 end
        local elapsed = CurTime() - deathTime
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

    -- Leaves a fading copy of us at pos. bright draws it like the living spirit, not a dim echo.
    function ENT:AddEcho( pos, life, bright )
        local echoes = self.zamb_Echoes
        table.insert( echoes, 1, { pos = pos, at = CurTime(), life = life or ECHO_LIFE, bright = bright } )
        echoes[self:MaxEchoes() + 1] = nil

    end

    -- Stubs, subclasses override these to change how it looks.

    -- How many echoes it keeps alive.
    function ENT:MaxEchoes()
        return MAX_ECHOES

    end

    -- A beat's starting. Leaves an echo where we stood, returns how far we skip aside on the thud, skip's the usual.
    function ENT:SpiritBeat( _amp, skip )
        self:AddEcho( self:GetPos() )
        return skip

    end

    -- SpiritDeath just ran. Return true if it started a beat.
    function ENT:SpiritFinalBeat()
        return false

    end

    -- How much of us shows this frame: whether the red body's drawn, how much red's left for the trails and sprites,
    -- and whether the plain body under it is drawn.
    function ENT:SpiritLook( _pulse )
        return true, 1, false

    end

    -- Anything extra to draw while dying, the body, echoes and trails are done by then.
    function ENT:SpiritDrawDying( _time )
    end

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

        self.zamb_LastBeatAt = CurTime() -- subclasses convulse off this

        -- almost blinks away
        local skipDir = VectorRand()
        skipDir.z = 0
        skipDir:Normalize()
        self.zamb_SkipOffset = self:SpiritBeat( amp, skipDir * SKIP_DIST * amp )
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

        if Crossed( self, "zamb_SpiritDeathTime", last, now ) and self:SpiritFinalBeat() then -- DeathFrac drags whatever it starts out
            return

        elseif Crossed( self, "zamb_SummonAt", last, now ) then
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
    local function CurrentPhase( self, myTbl, now )
        return myTbl.zamb_BeatPhase + ( now - myTbl.zamb_PulseThinkAt ) * myTbl.zamb_BeatRate * DeathFrac( self )

    end

    -- How hard the heart's thudding right now, 0 between beats, can go past 1.
    -- Called every frame, by our draw and once for all our links, so myTbl, not self's __index.
    function ENT:GetPulse()
        local myTbl = entMeta.GetTable( self )
        if not myTbl.zamb_PulseThinkAt then return 0 end -- the link hook can find us before we've initialized
        local now = CurTime()
        local phase = CurrentPhase( self, myTbl, now )
        local length = ThumpLength( myTbl.zamb_BeatRate )
        local pulse = myTbl.zamb_BeatAmp * Thump( phase, length ) + myTbl.zamb_DubAmp * Thump( phase - DUB_AT, length )

        -- swells into the summon's thud
        local windup = 1 - ( entMeta.GetNW2Float( self, "zamb_SummonAt", 0 ) - now ) / SUMMON_ARRIVE_DELAY
        if windup > 0 and windup < 1 then
            pulse = pulse + windup ^ 2 * 1.5

        end
        return pulse

    end

    local bodyMatrix = Matrix() -- reused, EnableMatrix copies it
    local bodyScale = Vector()

    -- Draws the model offset and scaled, render only, the hitbox stays put.
    -- The bone cache holds last draw's matrix, so drawing more than once a frame needs it rebuilt.
    -- Runs several times a frame per spirit, so entMeta, not self's __index.
    local function DrawModelAt( self, localOffset, scale )
        bodyMatrix:Identity()
        bodyMatrix:Translate( localOffset )
        bodyScale:SetUnpacked( scale, scale, scale )
        bodyMatrix:Scale( bodyScale )
        entMeta.EnableMatrix( self, "RenderMultiply", bodyMatrix )
        entMeta.InvalidateBoneCache( self )
        entMeta.DrawModel( self )

    end
    ENT.DrawModelAt = DrawModelAt

    -- Zambies a spirit sent glow in time with it, until it dies.
    local pulseLinks = {}
    local linkGlow = Material( "sprites/light_glow02_add" )

    hook.Add( "EntityNetworkedVarChanged", "zamb_SpiritPulseLinks", function( ent, name, _, spirit )
        if name ~= "zamb_PulseSpirit" then return end
        pulseLinks[ent] = IsValid( spirit ) and spirit or nil

    end )

    local ARRIVE_GLOW_TIME  = 0.6 -- lands as solid spirit red, cooling back to skin over this
    local ARRIVE_SKIP_TIME  = 0.15 -- and stutters around its landing spot for the start of it
    local ARRIVE_SKIP_DIST  = 16
    local DEPART_GHOST_TIME = 0.8 -- a red ghost stays where it was pulled from, fading
    local ARRIVE_FX_TIME    = math.max( ARRIVE_GLOW_TIME, DEPART_GHOST_TIME )
    local AFTERGLOW_TIME    = 4 -- fresh arrivals' pulse glow starts this much bigger and settles over AFTERGLOW_TIME
    local AFTERGLOW_BOOST   = 2

    local arriveSkip = Vector()

    -- The extra model draws for a zambie a spirit just sent, the depart ghost and the cooling silhouette.
    local function DrawArrival( ally, sinceArrive )
        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
        render.OverrideDepthEnable( true, false ) -- or the ghost cuts a hole in whatever's behind it

        local departPos = ally:GetNW2Vector( "zamb_SpiritDepartPos", false )
        if departPos and sinceArrive < DEPART_GHOST_TIME then
            local fade = 1 - sinceArrive / DEPART_GHOST_TIME
            render.SetColorModulation( fade ^ 2 * 3, 0, 0 ) -- same as the spirit's own echoes
            DrawModelAt( ally, ally:WorldToLocal( departPos ), 1 )

        end

        if sinceArrive < ARRIVE_GLOW_TIME then
            local fade = 1 - sinceArrive / ARRIVE_GLOW_TIME
            local offset = vector_origin
            if sinceArrive < ARRIVE_SKIP_TIME then
                arriveSkip:SetUnpacked( math.Rand( -ARRIVE_SKIP_DIST, ARRIVE_SKIP_DIST ), math.Rand( -ARRIVE_SKIP_DIST, ARRIVE_SKIP_DIST ), 0 )
                offset = arriveSkip

            end
            render.SetBlend( fade )
            render.SetColorModulation( 700, 1, 1 ) -- the spirit's body trick, solid red under the additive blend
            DrawModelAt( ally, offset, 1 + fade * 0.1 )
            render.SetBlend( 1 )

        end

        render.SetColorModulation( 1, 1, 1 )
        render.OverrideDepthEnable( false )
        render.OverrideBlend( false )
        -- the real draw is the engine's, it can't inherit our matrix or our bones
        ally:DisableMatrix( "RenderMultiply" )
        ally:InvalidateBoneCache()

    end

    local linkColor = Color( 255, 0, 0, 255 )
    local framePulses = {} -- a spirit's pulse, worked out once a frame, not once per zambie it's linked to

    -- every linked zambie, every frame, engine calls go through entMeta, not each entity's __index
    hook.Add( "PostDrawTranslucentRenderables", "zamb_SpiritPulseLinks", function( depth, skybox )
        if depth or skybox or next( pulseLinks ) == nil then return end

        local now = CurTime()
        local drawModels = GetFPSEstimate() > 30 -- the extra draws are the first thing to go
        for spirit in pairs( framePulses ) do
            framePulses[spirit] = nil

        end

        for ally, spirit in pairs( pulseLinks ) do
            if not IsValid( ally ) or not IsValid( spirit ) or spirit:GetIsDying() then
                pulseLinks[ally] = nil
                continue

            end
            if entMeta.IsDormant( ally ) then continue end

            local sinceArrive = now - entMeta.GetNW2Float( ally, "zamb_SpiritArrivedAt", -math.huge )
            if drawModels and sinceArrive < ARRIVE_FX_TIME and not entMeta.GetNoDraw( ally ) then
                DrawArrival( ally, sinceArrive )

            end

            local pulse = framePulses[spirit]
            if not pulse then
                pulse = entMeta.IsDormant( spirit ) and 0 or spirit:GetPulse()
                framePulses[spirit] = pulse

            end
            if pulse < 0.05 then continue end
            local fresh = math.max( 0, 1 - sinceArrive / AFTERGLOW_TIME )
            local size = 40 * pulse * entMeta.GetModelScale( ally ) * ( 1 + fresh * AFTERGLOW_BOOST )
            linkColor.a = 255 * math.min( 1, pulse )
            render.SetMaterial( linkGlow ) -- every time, the arrival draws bind their own
            render.DrawSprite( entMeta.WorldSpaceCenter( ally ), size, size, linkColor )

        end
    end )

    -- Where a spirit's squad is about to land, marked until it does. Sprites only, the zambies are usually far off and dormant.
    local INCOMING_LEAD = 1.5 -- a warning sent earlier than this before landing waits to show
    local INCOMING_HEIGHT = Vector( 0, 0, 36 )
    local incoming = {}

    net.Receive( "zamb_SpiritIncoming", function()
        local spirit = net.ReadEntity()
        for _ = 1, net.ReadUInt( 5 ) do
            table.insert( incoming, { pos = net.ReadVector() + INCOMING_HEIGHT, at = net.ReadFloat(), spirit = spirit } )

        end
    end )

    hook.Add( "PostDrawTranslucentRenderables", "zamb_SpiritIncoming", function( depth, skybox )
        if depth or skybox or #incoming == 0 then return end

        local now = CurTime()
        render.SetMaterial( linkGlow )
        for i = #incoming, 1, -1 do
            local mark = incoming[i]
            local untilLand = mark.at - now
            if untilLand <= 0 then
                table.remove( incoming, i )
                continue

            end
            if untilLand > INCOMING_LEAD then continue end

            -- builds as it nears, and throbs with the spirit's heart if we can see it
            local closeness = 1 - untilLand / INCOMING_LEAD
            local spirit = mark.spirit
            local pulse = IsValid( spirit ) and not spirit:IsDormant() and spirit:GetPulse() or 0
            local size = ( 30 + closeness * 50 ) * ( 1 + pulse * 0.3 )
            render.DrawSprite( mark.pos, size, size * 1.6, Color( 255, 0, 0, 40 + closeness * 120 ) )

        end
    end )

    -- the sprite layers spread out right as it dies, 1 at the moment of death to 0 a fifth of a second later
    local function BlastFrac( self, time )
        if not self:GetIsDying() then return 0 end
        return math.max( 0, 1 - ( time - self:GetDeathTime() ) * 5 )

    end

    local BOUNDS_PAD = 100 -- covers a body standing on an echo, the skip, and the sprite layers at a hard beat
    local BOUNDS_BLAST_PAD = 250 -- and the layers flung out as it dies
    local boundsMins, boundsMaxs = Vector(), Vector()
    local math_min, math_max = math.min, math.max

    -- Everything we draw away from the body, echoes, trails and sprites, or it all culls the moment the body's off screen.
    -- Unpacked, not .x, field access is slow and this runs 16 times a second per spirit.
    local function UpdateRenderBounds( self )
        local minX, minY, minZ = self:WorldSpaceCenter():Unpack()
        local maxX, maxY, maxZ = minX, minY, minZ
        local function Include( pos )
            local x, y, z = pos:Unpack()
            minX, minY, minZ = math_min( minX, x ), math_min( minY, y ), math_min( minZ, z )
            maxX, maxY, maxZ = math_max( maxX, x ), math_max( maxY, y ), math_max( maxZ, z )

        end

        for _, echo in ipairs( self.zamb_Echoes ) do
            Include( echo.pos )

        end
        if self.trails then
            for _, trail in ipairs( self.trails ) do
                for _, point in ipairs( trail ) do
                    Include( point )

                end
            end
        end

        local pad = ( BOUNDS_PAD + BlastFrac( self, CurTime() ) * BOUNDS_BLAST_PAD ) * self:GetModelScale()
        boundsMins:SetUnpacked( minX - pad, minY - pad, minZ - pad )
        boundsMaxs:SetUnpacked( maxX + pad, maxY + pad, maxZ + pad )
        self:SetRenderBoundsWS( boundsMins, boundsMaxs )

    end

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
        UpdateRenderBounds( self )
        self:SetNextClientThink( CurTime() + 1 / self.trailLength )

        return true

    end

    local trailColor = Color( 0, 0, 0 ) -- AddBeam copies it

    -- every frame, so myTbl and entMeta, not self's __index
    function ENT:DrawTranslucent()
        if render.GetRenderTarget() then return end

        local myTbl     = entMeta.GetTable( self )
        local myPos     = entMeta.WorldSpaceCenter( self )
        local eyePos    = EyePos()
        local time      = CurTime()
        local dying     = myTbl.GetIsDying( self )
        local deathFrac = DeathFrac( self )
        local blastFrac = BlastFrac( self, time )
        local pulse     = myTbl.GetPulse( self )
        local swell     = 1 + pulse * 0.35
        local showRed, redLeft, plainBody = myTbl.SpiritLook( self, pulse )
        local spirit    = deathFrac * redLeft -- how much of the red is left in it, for the trails and sprites

        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        local trails = myTbl.trails
        if trails and showRed and spirit > 0 and GetFPSEstimate() > 30 then
            render.SetMaterial( myTbl.mat_trail )
            for _, trail in ipairs( trails ) do
                local count = #trail
                if count < 2 then continue end

                render.StartBeam( count )
                for j, point in ipairs( trail ) do
                    local alongTrail = ( j - 1 ) / ( count - 1 )
                    trailColor.r = 255 * ( 1 - alongTrail )
                    render.AddBeam( point, 7 * swell * spirit * ( 1 - alongTrail ), alongTrail * 4, trailColor )
                end
                render.EndBeam()

            end
        end

        if not dying then
            -- echoes of where it stood on recent beats, fading out
            -- no depth writes, or an echo in front cuts a hole in the body
            -- drawn before the body, so the bone cache ends on the body's matrix, the trails read it
            render.OverrideDepthEnable( true, false )
            for _, echo in ipairs( myTbl.zamb_Echoes ) do
                local fade = 1 - ( time - echo.at ) / echo.life
                if fade <= 0 then continue end
                if echo.bright then
                    render.SetBlend( fade )
                    render.SetColorModulation( 700, 1, 1 )
                    DrawModelAt( self, entMeta.WorldToLocal( self, echo.pos ), 1 )
                    render.SetBlend( 1 )

                else
                    render.SetColorModulation( fade ^ 2 * 3, 0, 0 )
                    DrawModelAt( self, entMeta.WorldToLocal( self, echo.pos ), 1 )

                end

            end
            render.OverrideDepthEnable( false )

            -- swells on each beat, and for the start of the thud, skips aside like it nearly teleported
            local bodySwell = 1 + math.min( pulse, 2.5 ) * 0.1
            local skipping = CurrentPhase( self, myTbl, time ) < ThumpLength( myTbl.zamb_BeatRate ) * SKIP_FRAC
            local bodyOffset = skipping and myTbl.zamb_SkipOffset or vector_origin
            if plainBody then -- drawn normally, under the red
                render.OverrideBlend( false )
                render.SetColorModulation( 1, 1, 1 )
                DrawModelAt( self, vector_origin, 1 )
                render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

            end
            if showRed then
                render.SetColorModulation( 700, 1, 1 ) -- blows the red channel out, the model glows solid red under the additive blend
                DrawModelAt( self, bodyOffset, bodySwell )

            end
            render.SetColorModulation( 1, 1, 1 )

        else
            myTbl.SpiritDrawDying( self, time )

        end

        if eyePos:DistToSqr( myPos ) < 3250 ^ 2 and ( ( showRed and spirit > 0 ) or dying ) then
            surface.SetMaterial( myTbl.mat )
            surface.SetAlphaMultiplier( 1 )
            -- the death burst brings them back, the spirit bursting out
            local spriteAlpha = dying and deathFrac or spirit
            surface.SetDrawColor( 255 * spriteAlpha, 0, 0, 255 * spriteAlpha )
            local angle = ( myPos - eyePos ):Angle()
            angle:RotateAroundAxis( angle:Right(), 90 )
            local scale = entMeta.GetModelScale( self )
            local spriteSwell = 1 + pulse * 0.6 -- harder than the trails, the spin and shrink hide a small one

            -- four spinning layers, each a quarter cycle out of step
            for layer = 1, 4 do
                cam.Start3D2D( myPos, angle, scale * ( 1 + blastFrac * layer ) )
                local cycle = ( time + layer / 4 ) % 1
                local size  = ( 72 - cycle * 32 ) * spriteSwell * spriteAlpha
                surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * layer * 360 )
                cam.End3D2D()

            end
        end

        render.OverrideBlend( false )

    end
end
