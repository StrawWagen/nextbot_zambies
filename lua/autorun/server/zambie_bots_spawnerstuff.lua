
terminator_Extras = terminator_Extras or {}

terminator_Extras.zamb_PotentialSpawnPositions = terminator_Extras.zamb_PotentialSpawnPositions or {}
terminator_Extras.zamb_Spawnpoints = terminator_Extras.zamb_Spawnpoints or nil
terminator_Extras.zamb_SpawnOverrideQueue = terminator_Extras.zamb_SpawnOverrideQueue or {}


local difficultyBeingExperienced
local targetDifficulty
local difference
local maxZambs
local zamCount
local plyCount
local gettingHandsDirty
local nextGlobalThink

local ease = math.ease

local curves = {
    calm = {
        { timing = 20, ease = ease.InOutSine, steps = { 5, 10, 5 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 20, 20, 5 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 18, 10, 10 } },
        { timing = 20, ease = ease.InOutSine, steps = { 3, 3, 5, 6 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 6, 4 } },
    },

    rampup = {
        { timing = 20, ease = ease.InOutSine, steps = { 10, 20, 30, 40 } },
        { timing = 20, ease = ease.InOutSine, steps = { 20, 30, 40, 50 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 11, 35, 45 } },
        { timing = 20, ease = ease.InOutSine, steps = { 25, 30, 40 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 30, 60, 5, 70 } },
        { timing = 10, ease = ease.InOutSine, steps = { 50, 80 } },
    },

    peak = {
        { timing = 20, ease = ease.InOutSine, steps = { 80, 90, 160, 100, 110 } },
        { timing = 20, ease = ease.InOutSine, steps = { 90, 80, 90, 100, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 70, 80, 90, 100, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 75, 85, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 80, 100, 5, 100, 150, 150 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 90, 100, 100, 200 } },
    }
}

local highestSegTime

local sameCurveChainLength
local segmentStack
local lastTypeAdded
local currCurveType

local function easedLerp( fraction, from, to, func )
    return Lerp( func( fraction ), from, to )

end

function terminator_Extras.zamb_HandleTargetDifficulty()
    local cur = CurTime()

    if #segmentStack <= 3 then
        local toAdd
        if not lastTypeAdded then
            toAdd = "calm"

        elseif lastTypeAdded == "calm" then
            if sameCurveChainLength < 0 then
                toAdd = "calm"

            else
                local calmChance = 25
                local tooDifficult = difficultyBeingExperienced > targetDifficulty
                if tooDifficult and math.abs( difference ) > 25 then
                    calmChance = 75

                elseif tooDifficult and math.abs( difference ) > 60 then
                    calmChance = 90

                end
                if math.random( 1, 100 ) < calmChance then
                    toAdd = "calm"

                else
                    toAdd = "rampup"

                end
            end

        elseif lastTypeAdded == "rampup" then
            toAdd = "peak"

        elseif lastTypeAdded == "peak" then
            if sameCurveChainLength >= 1 then
                toAdd = "calm"

            else
                if difference > 25 or gettingHandsDirty < cur then
                    toAdd = "peak"

                else
                    toAdd = "calm"

                end
            end
        end

        local potentialCurves = curves[toAdd]
        local picked = potentialCurves[math.random( 1, #potentialCurves )]
        local timing = picked.timing
        for _, segDiff in ipairs( picked.steps ) do
            highestSegTime = math.max( highestSegTime, cur ) + timing
            local segment = {
                time = highestSegTime, -- so we can pop this from the list
                segType = toAdd, -- for debugging
                timing = timing, -- time between segments
                ease = picked.ease, -- ease function
                diff = segDiff -- difficulty of segment

            }
            table.insert( segmentStack, segment )

        end

        print( "added ", toAdd )
        print( sameCurveChainLength, lastTypeAdded, toAdd )

        if lastTypeAdded == toAdd then
            sameCurveChainLength = sameCurveChainLength + 1

        else
            sameCurveChainLength = 0

        end
        lastTypeAdded = toAdd

    end

    local currSeg = segmentStack[1]
    local nextSeg = segmentStack[2]

    local currsDoneTime = currSeg.time

    local untilDone = currsDoneTime - cur
    local fraction = untilDone / currSeg.timing
    fraction = 1 - fraction

    local currentEase = currSeg.ease
    targetDifficulty = easedLerp( fraction, currSeg.diff, nextSeg.diff, currentEase )
    targetDifficulty = math.Round( targetDifficulty, 2 )

    currCurveType = currSeg.segType

    if currsDoneTime < cur then
        table.remove( segmentStack, 1 )

    end
end

function terminator_Extras.zamb_HandleDifficultyDecay()
    local averageHealthPercent = 0
    plyCount = 0
    for _, ply in player.Iterator() do
        plyCount = plyCount + 1
        local healthPercent = ply:Health() / ply:GetMaxHealth()
        healthPercent = healthPercent * 100

        averageHealthPercent = averageHealthPercent + healthPercent

    end

    averageHealthPercent = averageHealthPercent / plyCount

    local healthFullnessDecay
    local decay
    if targetDifficulty < 50 then
        healthFullnessDecay = averageHealthPercent / 100
        decay = healthFullnessDecay + 0.5

    else
        healthFullnessDecay = averageHealthPercent / 200
        decay = healthFullnessDecay + 1.5

    end

    if difficultyBeingExperienced > 100 then
        decay = decay * 2
        decay = decay + 1

    end

    if zamCount <= 1 then
        decay = decay * 2
        decay = decay + 1

    end

    difficultyBeingExperienced = difficultyBeingExperienced + -decay
    difficultyBeingExperienced = math.Clamp( difficultyBeingExperienced, zamCount / 2, math.huge )
    zamCount = #ents.FindByClass( "terminator_nextbot_zambie*" )
    difference = targetDifficulty - difficultyBeingExperienced

    print( difficultyBeingExperienced, targetDifficulty, currCurveType )

end

function terminator_Extras.zamb_HandleOnDamaged( target, damage )
    local attacker = damage:GetAttacker()
    if not IsValid( attacker ) then return end

    local damageDealt = damage:GetDamage()
    damageDealt = math.Clamp( damageDealt, 0, target:Health() )

    local difficultyFelt

    local plyGotAttacked = target:IsPlayer()
    local attackerIsZamb = attacker.IsTerminatorZambie

    local zambGotAttacked = target.IsTerminatorZambie
    local attackerIsPlayer = attacker:IsPlayer()

    if plyGotAttacked then
        difficultyFelt = damageDealt * 0.75

        if not attackerIsZamb then
            difficultyFelt = difficultyFelt * 0.25

        else
            local nearbyStuff = ents.FindInSphere( attacker:GetPos(), 175 )
            for _, thing in ipairs( nearbyStuff ) do
                if thing ~= attacker and thing.IsTerminatorZambie and thing.IsSeeEnemy then
                    difficultyFelt = difficultyFelt + ( difficultyFelt * 0.15 )

                end
            end

            local healthAfterDamage = ( target:Health() - damageDealt )
            local maxHp = target:GetMaxHealth()

            if healthAfterDamage <= 15 then
                difficultyFelt = difficultyFelt * 8

            elseif healthAfterDamage <= maxHp * 0.5 then -- this brought us below 50% health!
                difficultyFelt = difficultyFelt * 4

            end
            gettingHandsDirty = math.max( CurTime() + damageDealt, CurTime() + ( gettingHandsDirty * 0.25 ) )

        end
    elseif zambGotAttacked then
        difficultyFelt = damageDealt * 0.05
        local engageDist = attacker:GetPos():Distance( target:GetPos() )

        if attackerIsPlayer and engageDist < 100 and gettingHandsDirty > CurTime() then
            difficultyFelt = difficultyFelt + 1
            difficultyFelt = difficultyFelt * 2

            gettingHandsDirty = math.max( CurTime() + ( damageDealt * 0.25 ), CurTime() + ( gettingHandsDirty * 0.1 ) )

        elseif engageDist > 600 then
            difficultyFelt = -difficultyFelt * 0.5

        elseif engageDist > 1500 then
            difficultyFelt = -difficultyFelt * 1.5

        elseif engageDist > 2500 then
            difficultyFelt = -difficultyFelt * 2.5

        end
        if not attackerIsPlayer then
            local attackersCreator = attacker:GetCreator()
            if attackersCreator and IsValid( attackersCreator ) and attackersCreator:IsPlayer() then
                difficultyFelt = difficultyFelt * 0.5

            else
                difficultyFelt = difficultyFelt * 0.05

            end
            if gettingHandsDirty < CurTime() then
                difficultyFelt = difficultyFelt * 0.25

            end
        end
        if attacker.IsTerminatorZambie then
            difficultyFelt = 0

        end
        if not target:primaryPathIsValid() and target.loco:GetVelocity():Length() < 5 then
            difficultyFelt = difficultyFelt * 0.1

        end
    end

    if difficultyFelt then
        difficultyBeingExperienced = math.Clamp( difficultyBeingExperienced + difficultyFelt, 0, math.huge )

    end
end

function terminator_Extras.zamb_SetupManager()
    if not terminator_Extras.zamb_Spawnpoints then
        terminator_Extras.zamb_Spawnpoints = {}

    end

    maxZambs = 35
    difficultyBeingExperienced = 0
    zamCount = 0
    plyCount = 0
    gettingHandsDirty = 0
    targetDifficulty = 0

    curveStartTime = 0
    currentCurveStep = 0
    oldCurveStep = 0

    sameCurveChainLength = 0
    segmentStack = {}
    highestSegTime = CurTime()
    nextGlobalThink = 0

    terminator_Extras.zamb_PotentialSpawnPositions = {}

    hook.Add( "Think", "zambies_nextbot_spawningmanager", function()
        if nextGlobalThink > CurTime() then return end
        nextGlobalThink = CurTime() + 1

        terminator_Extras.zamb_HandleTargetDifficulty()

        terminator_Extras.zamb_HandleSpawning()

        terminator_Extras.zamb_HandleDifficultyDecay()

    end )

    hook.Add( "PostEntityTakeDamage", "zambies_manager_damaged", function( target, damage )
        terminator_Extras.zamb_HandleOnDamaged( target, damage )

    end )
end

if terminator_Extras.zamb_Spawnpoints and #terminator_Extras.zamb_Spawnpoints >= 1 then -- autorefresh
    terminator_Extras.zamb_SetupManager()

end

function terminator_Extras.zamb_TearDownManager()
    terminator_Extras.zamb_Spawnpoints = nil

    zamCount = nil
    plyCount = nil
    maxZambs = nil
    difficultyBeingExperienced = nil
    targetDifficulty = nil

    sameCurveChainLength = nil
    segmentStack = nil
    lastTypeAdded = nil
    highestSegTime = nil
    currCurveType = nil

    nextGlobalThink = nil

    hook.Remove( "PostEntityTakeDamage", "zambies_manager_damaged" )

    hook.Remove( "Think", "zambies_nextbot_spawningmanager" )

end

terminator_Extras.zamb_SpawnData = {
    { class = "terminator_nextbot_zambie",              diffAdded = 3, diffNeeded = 0, passChance = 0 },

    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 0, passChance = 90 },
    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 10 },
    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 99, batchSize = 8 },

    { class = "terminator_nextbot_zambieacid",         diffAdded = 6, diffNeeded = 0, passChance = 95 },
    { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 20 },
    { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 99, batchSize = 8 },

    { class = "terminator_nextbot_zambiefast",          diffAdded = 6, diffNeeded = 25, passChance = 25, randomSpawnAnyway = 5 },
    { class = "terminator_nextbot_zambiefastgrunt",     diffAdded = 12, diffNeeded = 75, passChance = 95 },

    { class = "terminator_nextbot_zambiegrunt",         diffAdded = 10, diffNeeded = 50, passChance = 95 },

    { class = "terminator_nextbot_zambieberserk",       diffAdded = 20, diffNeeded = 90, passChance = 85, maxAtOnce = 1 },
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 100, diffNeeded = 120, maxDiff = 90, passChance = 99, batchSize = 10 },

    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 90, passChance = 92 },
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, maxDiff = 10, passChance = 99, batchSize = 10 },
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, maxDiff = 10, passChance = 95 },

    { class = "terminator_nextbot_zambietank",          diffAdded = 20, diffNeeded = 90, passChance = 50, maxAtOnce = 1 },
    { class = "terminator_nextbot_zambienecro",         diffAdded = 20, diffNeeded = 90, passChance = 50, maxAtOnce = 1 },

}

function terminator_Extras.zamb_GetSpawnData( targetDifficultyWeighted, targetDifficultyInt, differenceInt )

    local bestData
    local myData = terminator_Extras.zamb_SpawnData
    for _, data in ipairs( myData ) do
        local maxDiff = data.maxDiff or math.huge
        local traditionallyGood = targetDifficultyWeighted >= data.diffNeeded and targetDifficultyWeighted < maxDiff and ( data.passChance <= 0 or math.random( 0, 100 ) > data.passChance )
        local passAnyway = data.randomSpawnAnyway and math.random( 0, 100 ) < data.randomSpawnAnyway
        local wouldBeTooMany = data.maxAtOnce and #ents.FindByClass( data.class ) >= data.maxAtOnce
        if not wouldBeTooMany and ( traditionallyGood or passAnyway ) then
            bestData = data

        end
    end

    if not bestData then return end

    return bestData.class, bestData

end


local hitTooClose = 150^2

local function blockedByPly( checkPos, doSee, tooClose, tooFar )
    local anyWasCloseEnough
    for _, ply in player.Iterator() do
        local plysShoot = ply:GetShootPos()
        local dist = plysShoot:DistToSqr( checkPos )
        if dist > tooFar then continue end
        anyWasCloseEnough = true

        if doSee then
            if dist < tooClose then return true, anyWasCloseEnough end

            local see, trResult = terminator_Extras.PosCanSee( plysShoot, checkPos )
            if see then return true, anyWasCloseEnough end

            if trResult.HitPos:DistToSqr( checkPos ) < hitTooClose then return true, anyWasCloseEnough end

        end

    end
    return nil, anyWasCloseEnough

end

local shootPosOffset = Vector( 0,0,45 )

function terminator_Extras.zamb_HandleSpawning()
    local cur = CurTime()
    local spawnPositions = terminator_Extras.zamb_PotentialSpawnPositions

    if #spawnPositions > 200 then
        while #spawnPositions > 200 do
            table.remove( spawnPositions, #spawnPositions )

        end
    end

    local spawnPos
    local finalSpawner

    local spawnDist = 750
    local tooClose = spawnDist ^ 2
    local tooFar = ( spawnDist * 10 ) ^ 2
    local maxToDo = 400 / math.Clamp( player.GetCount(), 20, 400 )
    local countDone = 0

    for ind, currDat in ipairs( spawnPositions ) do
        if countDone > maxToDo then
            break

        end
        local spawner = currDat.spawnerResponsible
        if not IsValid( spawner ) or not spawner:GetOn() then
            countDone = countDone + 1
            table.remove( spawnPositions, ind )
            continue

        end
        local currShoot = currDat.pos + shootPosOffset
        local isBlocked, anyWasCloseEnough = blockedByPly( currShoot, true, tooClose, tooFar )
        if isBlocked or not anyWasCloseEnough then
            countDone = countDone + 1
            table.remove( spawnPositions, ind )

        else
            spawnPos = currDat.pos
            finalSpawner = currDat.spawnerResponsible
            break

        end
    end

    if not spawnPos then
        for _, spawner in ipairs( terminator_Extras.zamb_Spawnpoints ) do
            if not spawner:GetOn() then continue end
            if spawner.zamb_NextCanSpawnCheck > cur then continue end

            local doSee = spawner.zamb_SpawnerConfig.spawnsOnlyIfHidden

            local myPos = spawner:GetPos()
            local myShootPos = myPos + shootPosOffset
            local isBlocked = blockedByPly( myShootPos, doSee, tooClose, tooFar )

            if isBlocked then
                spawner.zamb_NextCanSpawnCheck = cur + 10

            else
                finalSpawner = spawner
                spawnPos = myPos

            end
        end
    end

    if spawnPos then
        terminator_Extras.zamb_TryToSpawn( finalSpawner, spawnPos )

    end
end


local offsetToSpawnAt = Vector( 0,0,5 )

function terminator_Extras.zamb_TryToSpawn( spawner, spawnPos )
    local queue = terminator_Extras.zamb_SpawnOverrideQueue
    if zamCount >= 1 and ( #queue >= 1 or math.max( difficultyBeingExperienced, zamCount ) > targetDifficulty ) then return end

    if zamCount >= maxZambs then return end

    difference = targetDifficulty - difficultyBeingExperienced

    local targetDifficultyWeighted = targetDifficulty + ( math.max( difference, 0 ) * 0.5 ) -- bigger number when you're cheesing it!

    local class, data

    if #queue >= 1 then
        data = table.remove( queue, 1 )
        class = data.class

    else
        class, data = terminator_Extras.zamb_GetSpawnData( targetDifficultyWeighted, targetDifficulty, difference )

        if data.batchSize and data.batchSize > 1 then
            for _ = 1, data.batchSize do
                table.insert( terminator_Extras.zamb_SpawnOverrideQueue, table.Copy( data ) )

            end
        end
    end

    local zamb = ents.Create( class )
    if not IsValid( zamb ) then return end

    zamCount = zamCount + 1

    zamb.zamb_SpawnedIn = true
    zamb.zamb_SpawnerThatMadeMe = spawner

    zamb:SetPos( spawnPos + offsetToSpawnAt )
    zamb:SetAngles( Angle( 0, math.random( -180, 180 ), 0 ) )
    zamb:Spawn()
    difficultyBeingExperienced = difficultyBeingExperienced + data.diffAdded

    terminator_Extras.zamb_DoForwardSpawnStuff( spawner, zamb )

    spawner:Zamb_OnZambSpawned( zamb )

end




function terminator_Extras.zamb_RegisterSpawner( spawner, configData )
    local spawnsOnlyIfHidden = configData.spawnsOnlyIfHidden

    if not terminator_Extras.zamb_Spawnpoints then
        terminator_Extras.zamb_SetupManager()

    end

    local myIndex = table.insert( terminator_Extras.zamb_Spawnpoints, spawner )

    spawner:CallOnRemove( "zamb_unregisterspawner", function()
        table.remove( terminator_Extras.zamb_Spawnpoints, myIndex )
        timer.Simple( 0, function()
            if not terminator_Extras.zamb_Spawnpoints then return end
            local newTbl = {}
            for _, curr in ipairs( terminator_Extras.zamb_Spawnpoints ) do
                if IsValid( curr ) then
                    table.insert( newTbl, curr )

                end
            end
            if #newTbl <= 0 then
                terminator_Extras.zamb_TearDownManager()

            else
                terminator_Extras.zamb_Spawnpoints = newTbl

            end
        end )
    end )

    local spawnCount = #terminator_Extras.zamb_Spawnpoints
    local validArea = navmesh.GetNearestNavArea( spawner:GetPos(), true, 100, true, true, nil )

    local creator = spawner:GetCreator()
    if IsValid( creator ) then
        local desiredCount = 20
        local msg
        if not IsValid( validArea ) then
            msg = "Hint: The navmesh doesn't reach here..."
            spawner:SetColor( Color( 255, 0, 0 ) )

        elseif spawnsOnlyIfHidden and spawnCount <= 1 then
            msg = "Not enough spawns\n" .. spawnCount .. "/" .. desiredCount .. "\nMake sure to spread them out!"

        elseif spawnsOnlyIfHidden and spawnCount < desiredCount then
            msg = spawnCount .. "/" .. desiredCount

        elseif spawnsOnlyIfHidden and spawnCount == desiredCount then
            msg = "Make sure most of the spawns are hidden!\nThey don't spawn zombies when visible!\n" .. spawnCount .. "/" .. desiredCount

        end
        if msg then
            creator:PrintMessage( HUD_PRINTTALK, msg )

        end
    end

    spawner:GetPhysicsObject():EnableMotion( false )
    spawner.zamb_NeverFrenzyCurious = true
    spawner.zamb_NextCanSpawnCheck = 0
    spawner.zamb_SpawnerConfig = configData

end


function terminator_Extras.zamb_DoForwardSpawnStuff( spawner, zamb )
    if not spawner.zamb_SpawnerConfig.spawnsOnlyIfHidden then return end

    local data = {
        spawnerAssociated = spawner,
        noEnemCount = 0,
        noEnemTimeout = 90,
        spawnTime = CurTime(),
        sawEnemy = nil,
        nextSave = CurTime() + 5,
        posFound = nil,

    }
    zamb.zamb_ForwardSpawnData = data

    local timerName = "terminator_zamb_forwardspawnmanage_" .. zamb:GetCreationID()
    timer.Create( timerName, math.Rand( 1, 2 ), 0, function()
        if not IsValid( zamb ) then timer.Remove( timerName ) return end
        if not IsValid( data.spawnerAssociated ) then timer.Remove( timerName ) return end

        if zamb.IsSeeEnemy then
            data.sawEnemy = true
            data.noEnemCount = 0

        else
            data.noEnemCount = data.noEnemCount + 1
            if data.noEnemCount > data.noEnemTimeout then
                SafeRemoveEntity( zamb )
                return

            end
            local cur = CurTime()
            if data.nextSave < cur then
                data.posFound = zamb:GetPos()
                data.nextSave = cur + 5

            end
        end
    end )

    -- potential spawn is added when zamb dies
    zamb:CallOnRemove( "term_zamb_saveforwardspawn", function( rZamb ) -- removed zamb
        local rData = rZamb.zamb_ForwardSpawnData
        if not IsValid( rData.spawnerAssociated ) then return end
        if rZamb:Health() >= rZamb:GetMaxHealth() / 10 then return end -- was not killed!

        if rData.sawEnemy and rData.posFound then
            local currAdd = {
                pos = rData.posFound,
                addedTime = CurTime(),
                spawnerResponsible = rData.spawnerAssociated,

            }
            table.insert( terminator_Extras.zamb_PotentialSpawnPositions, 1, currAdd )

        end
    end )
end