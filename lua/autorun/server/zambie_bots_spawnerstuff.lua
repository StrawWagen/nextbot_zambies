
terminator_Extras = terminator_Extras or {}

terminator_Extras.zamb_PotentialSpawnPositions = terminator_Extras.zamb_PotentialSpawnPositions or {}
terminator_Extras.zamb_SpawnOverrideQueue = terminator_Extras.zamb_SpawnOverrideQueue or {}

terminator_Extras.zamb_Spawnpoints = terminator_Extras.zamb_Spawnpoints or nil
terminator_Extras.zamb_PlayerParticipatingFor = terminator_Extras.zamb_PlayerParticipatingFor or nil
terminator_Extras.zamb_EntsParticipatingFor = terminator_Extras.zamb_EntsParticipatingFor or nil
terminator_Extras.zamb_OccupiedSpawnSlots = terminator_Extras.zamb_OccupiedSpawnSlots or nil

maxDifficulty = 9999999 -- just a big number thats not math.huge


local defaultMaxZambs = 30
local maxZambsVar = CreateConVar( "zambie_director_maxzambs", -1, FCVAR_ARCHIVE, "Max zombies the ai \"Director\" will spawn. -1 for default, " .. defaultMaxZambs, -1, 999 )
local maxZambs

local function doMaxZambs()
    local var = maxZambsVar:GetInt()
    if var <= -1 then
        maxZambs = defaultMaxZambs

    else
        maxZambs = var

    end
end

doMaxZambs()
cvars.AddChangeCallback( "zambie_director_maxzambs", function() doMaxZambs() end, "updatelocal" )


local defaultDifficultyMul = 1
local difficultyMulVar = CreateConVar( "zambie_director_difficultymul", -1, FCVAR_ARCHIVE, "Difficulty multiplier for the ai \"Director\". -1 for default, " .. defaultDifficultyMul, -1, 99 )
local difficultyMul

local function doDifficultyMul()
    local var = difficultyMulVar:GetInt()
    if var <= -1 then
        difficultyMul = defaultDifficultyMul

    else
        difficultyMul = var

    end
end

doDifficultyMul()
cvars.AddChangeCallback( "zambie_director_difficultymul", function() doDifficultyMul() end, "updatelocal" )

local debuggingVar = CreateConVar( "zambie_director_debug", 0, FCVAR_ARCHIVE, "enable/disable debug prints", 0, 1 )
local debugging = debuggingVar:GetBool()
cvars.AddChangeCallback( "zambie_director_debug", function( _, _, new ) debugging = tobool( new ) end, "updatelocal" )

local function debugPrint( ... )
    if not debugging then return end
    print( ... )

end

local difficultyBeingExperienced
local targetDifficulty
local difference
local zamCount
local participators
local noPlayerParticipators
local participatingCount
local gettingHandsDirty
local nextGlobalThink

local ease = math.ease

local curves = {
    calm = {
        { timing = 20, ease = ease.InOutSine, steps = { 5, 10, 5 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 12, 15, 5 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 18, 10, 10 } },
        { timing = 20, ease = ease.InOutSine, steps = { 3, 3, 5, 6 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 6, 4 } },
    },

    rampup = {
        { timing = 20, ease = ease.InOutSine, steps = { 10, 20, 30, 40 } },
        { timing = 20, ease = ease.InOutSine, steps = { 20, 30, 35, 40 } },
        { timing = 20, ease = ease.InOutSine, steps = { 10, 11, 35, 45 } },
        { timing = 20, ease = ease.InOutSine, steps = { 25, 30, 40 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 30, 20, 5, 40 } },
        { timing = 10, ease = ease.InOutSine, steps = { 20, 20, 25, 40 } },
        { timing = 10, ease = ease.InOutSine, steps = { 5, 10, 15, 20, 25, 30 } },
    },

    peak = {
        { timing = 20, ease = ease.InOutSine, steps = { 40, 50, 60, 70, 80 } },
        { timing = 20, ease = ease.InOutSine, steps = { 90, 80, 90, 100, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 70, 80, 90, 100, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 75, 85, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 80, 80, 5, 80, 90, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 50, 60, 70, 80, 100, 100 } },
        { timing = 20, ease = ease.InOutSine, steps = { 5, 90, 80, 80, 100 } },
    }
}

local highestSegTime

local sameCurveChainLength
local segmentStack
local lastTypeAdded
local currCurveType -- for debug

local function easedLerp( fraction, from, to, func )
    return Lerp( func( fraction ), from, to )

end

function terminator_Extras.zamb_HandleTargetDifficulty()
    local cur = CurTime()

    if #segmentStack <= 2 then
        local toAdd
        if not lastTypeAdded or participatingCount <= 0 then -- start as calm, or if no enemies, force calm to save session resources
            toAdd = "calm"

        elseif lastTypeAdded == "calm" then
            if sameCurveChainLength < 0 then -- always at least two calms in a row please 
                toAdd = "calm"

            else
                local calmChance = 25
                local tooDifficult = difficultyBeingExperienced > targetDifficulty
                if tooDifficult and math.abs( difference ) > 100 * difficultyMul then -- we probably are dealing with the wake of a peak segment, or they just died
                    calmChance = 101

                elseif tooDifficult and math.abs( difference ) > 70 * difficultyMul then
                    calmChance = 80

                elseif tooDifficult and math.abs( difference ) > 25 * difficultyMul then
                    calmChance = 50

                end

                if math.random( 1, 100 ) < calmChance then
                    toAdd = "calm"

                else
                    toAdd = "rampup"

                end
            end

        elseif lastTypeAdded == "rampup" then
            if sameCurveChainLength < 0 then
                toAdd = "rampup"

            elseif sameCurveChainLength < 1 then
                local tooDifficult = difficultyBeingExperienced > targetDifficulty
                if tooDifficult and math.abs( difference ) > 100 * difficultyMul then -- they died or something?
                    toAdd = "calm"

                else
                    toAdd = "rampup"

                end
            else
                local tooDifficult = difficultyBeingExperienced > targetDifficulty
                if tooDifficult and math.abs( difference ) > math.random( 40, 60 ) * difficultyMul then -- they aren't ready!
                    toAdd = "rampup"

                else
                    toAdd = "peak"

                end
            end
        elseif lastTypeAdded == "peak" then
            if sameCurveChainLength > 1 then -- always end after 2
                toAdd = "calm"

            else
                local tooEasy = difficultyBeingExperienced < targetDifficulty and math.abs( difference ) > 25 * difficultyMul
                if tooEasy or gettingHandsDirty < cur then -- end early if we got em
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

        debugPrint( "added ", toAdd )
        debugPrint( sameCurveChainLength, lastTypeAdded, toAdd )

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
    targetDifficulty = targetDifficulty * difficultyMul

    currCurveType = currSeg.segType

    if currsDoneTime < cur then
        table.remove( segmentStack, 1 )

    end
end

function terminator_Extras.zamb_HandleDifficultyDecay()
    local cur = CurTime()
    local plyCount = 0
    local averageHealthPercent = 0
    for ply, _ in pairs( terminator_Extras.zamb_PlayerParticipatingFor ) do
        plyCount = plyCount + 1
        local healthPercent = ply:Health() / ply:GetMaxHealth()
        healthPercent = healthPercent * 100

        averageHealthPercent = averageHealthPercent + healthPercent

    end
    if plyCount <= 0 then
        averageHealthPercent = 100

    else
        averageHealthPercent = averageHealthPercent / plyCount

    end

    local healthFullnessDecay
    local decay
    local minDifficulty = zamCount / 2

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

    if gettingHandsDirty < ( cur + -30 ) then
        decay = decay * 2
        minDifficulty = 0

    else
        minDifficulty = zamCount / 4

    end

    if zamCount <= 1 then
        if difficultyBeingExperienced > math.max( targetDifficulty * 10, 1000 ) then -- dont blow up pls
            decay = decay + difficultyBeingExperienced / 5
            debugPrint( "difficulty has blown up, reeling in!" )

        elseif difficultyBeingExperienced > targetDifficulty then
            decay = decay + difficultyBeingExperienced / 20

        end
        if gettingHandsDirty < CurTime() then -- dont decay as fast if they have taken damage up close
            decay = decay * 3

        end
        decay = decay + 1

    end

    difficultyBeingExperienced = difficultyBeingExperienced + -decay
    difficultyBeingExperienced = math.Clamp( difficultyBeingExperienced, minDifficulty, maxDifficulty )
    difficultyBeingExperienced = math.Round( difficultyBeingExperienced, 2 )
    difference = targetDifficulty - difficultyBeingExperienced

    debugPrint( difficultyBeingExperienced, targetDifficulty, currCurveType )

end

function terminator_Extras.zamb_HandleParticipation()
    noPlayerParticipators = false

    local plyParticipators = terminator_Extras.zamb_PlayerParticipatingFor
    participatingCount = 0
    local cur = CurTime()
    for ply, whenStop in pairs( plyParticipators ) do
        if not IsValid( ply ) or whenStop < cur then
            terminator_Extras.zamb_PlayerParticipatingFor[ply] = nil
            return

        end

        if ply:Health() > 0 then
            participatingCount = participatingCount + 1

        end
    end

    if participatingCount > 0 then return end -- there are players participating, focus on them!

    noPlayerParticipators = true

    local entParticipators = terminator_Extras.zamb_EntsParticipatingFor
    for ent, whenStop in pairs( entParticipators ) do
        if not IsValid( ent ) or whenStop < cur or ent.IsTerminatorZambie then
            terminator_Extras.zamb_EntsParticipatingFor[ent] = nil
            return

        end

        if ent:Health() > 0 then
            participatingCount = participatingCount + 1

        end
    end
end

function terminator_Extras.zamb_HandleOnDamaged( target, damage )
    local attacker = damage:GetAttacker()
    if not IsValid( attacker ) then return end

    local damageDealt = damage:GetDamage()
    damageDealt = math.Clamp( damageDealt, 0, target:GetMaxHealth() ) -- this was blowing up using ent:Health(), since we're in post took damage

    local clampedParticipating = math.Clamp( participatingCount, 1, maxDifficulty )
    local cur = CurTime()
    local difficultyFelt

    local participatorGotAttacked = participators[target] -- players if a player is fighting them, npcs if there's no players and npcs are fighting them
    local attackerIsZamb = attacker.IsTerminatorZambie

    local zambGotAttacked = target.IsTerminatorZambie
    local attackerIsParticipator = participators[attacker]
    local attackerIsPlayer = attacker:IsPlayer()

    if participatorGotAttacked then
        difficultyFelt = damageDealt * 0.75

        if not attackerIsZamb then
            difficultyFelt = difficultyFelt * 0.25

        else
            local nearbyStuff = ents.FindInSphere( attacker:GetPos(), 175 )
            for _, thing in ipairs( nearbyStuff ) do
                if thing ~= attacker and thing.IsTerminatorZambie and thing.IsSeeEnemy then
                    difficultyFelt = difficultyFelt + ( difficultyFelt * 0.18 )

                end
            end

            local healthAfterDamage = ( target:Health() - damageDealt )
            local maxHp = target:GetMaxHealth()

            if healthAfterDamage <= 15 then
                difficultyFelt = difficultyFelt * 8

            elseif healthAfterDamage <= maxHp * 0.5 then -- this brought us below 50% health!
                difficultyFelt = difficultyFelt * 4

            end
            gettingHandsDirty = math.max( cur + ( damageDealt * 0.25 / clampedParticipating ), gettingHandsDirty + ( damageDealt * 0.5 / clampedParticipating ) )
            debugPrint( "dirtyhands1", gettingHandsDirty - cur )

        end
    elseif zambGotAttacked then
        difficultyFelt = damageDealt * 0.05
        local engageDist = attacker:GetPos():Distance( target:GetPos() )

        if attackerIsParticipator and engageDist < 120 then
            if gettingHandsDirty > cur then -- they were damaged up close earlier
                difficultyFelt = difficultyFelt + 1
                difficultyFelt = difficultyFelt * 2

                gettingHandsDirty = math.max( cur + ( damageDealt * 0.15 / clampedParticipating ), gettingHandsDirty + ( damageDealt * 0.05 / clampedParticipating ) )
                debugPrint( "dirtyhands2", gettingHandsDirty - cur )

            else -- they were NOT damaged up close earlier, this guy is good!
                difficultyFelt = -difficultyFelt * 0.15 -- negative

            end
        elseif engageDist > 4000 then -- sniping from a distance feels easy, negate it to remove difficulty,
            difficultyFelt = -difficultyFelt * 2.5

        elseif engageDist > 2500 then -- negative!
            difficultyFelt = -difficultyFelt * 1.5

        elseif engageDist > 1500 then -- negative!
            difficultyFelt = -difficultyFelt * 0.75

        elseif engageDist > 1000 then -- negative!
            difficultyFelt = -difficultyFelt * 0.15

        elseif engageDist > 500 then -- positive!
            difficultyFelt = difficultyFelt * 0.75

        end
        if not attackerIsPlayer then
            local attackersCreator = attacker:GetCreator()
            if attackersCreator and IsValid( attackersCreator ) and attackersCreator:IsPlayer() then
                difficultyFelt = difficultyFelt * 0.5

            else
                difficultyFelt = difficultyFelt * 0.05

            end
            if gettingHandsDirty < cur then
                difficultyFelt = difficultyFelt * 0.25

            end
            if not attacker.IsTerminatorZambie and attacker.GetShootPos and attacker:GetShootPos() ~= nil then
                terminator_Extras.zamb_EntsParticipatingFor[attacker] = cur + 190

            end
        else
            if gettingHandsDirty < cur then
                difficultyFelt = difficultyFelt * 0.75

            end
            local oldParticipating = terminator_Extras.zamb_PlayerParticipatingFor[attacker]
            terminator_Extras.zamb_PlayerParticipatingFor[attacker] = cur + 190
            if not oldParticipating then
                participatingCount = participatingCount + 1

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
        difficultyFelt = difficultyFelt / clampedParticipating
        difficultyBeingExperienced = math.Clamp( difficultyBeingExperienced + difficultyFelt, 0, maxDifficulty )

    end
end

function terminator_Extras.zamb_SetupManager()
    if not terminator_Extras.zamb_Spawnpoints then
        terminator_Extras.zamb_Spawnpoints = {}

    end

    terminator_Extras.zamb_PlayerParticipatingFor = {}
    terminator_Extras.zamb_EntsParticipatingFor = {}
    terminator_Extras.zamb_OccupiedSpawnSlots = {}

    difficultyBeingExperienced = 0
    zamCount = 0
    participators = {}
    noPlayerParticipators = false
    participatingCount = 0
    gettingHandsDirty = CurTime() + 15
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

        terminator_Extras.zamb_HandleParticipation()

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
    terminator_Extras.zamb_PlayerParticipatingFor = nil
    terminator_Extras.zamb_EntsParticipatingFor = nil
    terminator_Extras.zamb_OccupiedSpawnSlots = nil

    zamCount = nil
    participators = nil
    noPlayerParticipators = nil
    participatingCount = nil
    difficultyBeingExperienced = nil
    gettingHandsDirty = nil
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

--[[

diffAdded, difficulty added when this is spawned, prevents it from spawning 300 tanks at once, getting ahead of itself
diffNeeded, target difficulty neeeded, only spawn this when its supposed to be difficult, or easy
diffMax, dont spawn this when target difficulty is above this.
passChance, kinda unintitive, the code goes thru this table in a loop, so stuff at the bottom will override stuff at the top,
            basically this is the chance to NOT override what came before
batchSize, makes this into a batch spawn, so like 6 of one thing
randomSpawnAnyway,   randomly spawn this even if none of the conditions are met
maxAtOnce, max count of this on the field at once, checks class

--]]

terminator_Extras.zamb_SpawnData = {
    { class = "terminator_nextbot_zambie",              diffAdded = 3, diffNeeded = 0, passChance = 0 },
    { class = "terminator_nextbot_zambie_slow",         diffAdded = 3, diffNeeded = 0, diffMax = 5, passChance = 25 },
    { class = "terminator_nextbot_zambie_slow",         diffAdded = 3, diffNeeded = 0, diffMax = 15, passChance = 50 },

    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 0, passChance = 92 },
    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 30 },
    { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 99, batchSize = 8 },

    { class = "terminator_nextbot_zambieacid",         diffAdded = 6, diffNeeded = 0, passChance = 95 },
    { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 45 },
    { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 99, batchSize = 8 },

    { class = "terminator_nextbot_zambiefast",          diffAdded = 6, diffNeeded = 25, passChance = 25, randomSpawnAnyway = 5 },
    { class = "terminator_nextbot_zambietorsofast",     diffAdded = 3, diffNeeded = 25, passChance = 45, spawnSlot = "torsofast" },
    { class = "terminator_nextbot_zambiefastgrunt",     diffAdded = 12, diffNeeded = 75, passChance = 95 },

    { class = "terminator_nextbot_zambiegrunt",         diffAdded = 10, diffNeeded = 50, passChance = 95 },

    { class = "terminator_nextbot_zambieberserk",       diffAdded = 30, diffNeeded = 90, passChance = 85, maxAtOnce = 1 },

    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 90, passChance = 92 },
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, diffMax = 10, passChance = 99, batchSize = 10 },
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, diffMax = 10, passChance = 95 },

    { class = "terminator_nextbot_zambietank",          diffAdded = 40, diffNeeded = 90, passChance = 75, spawnSlot = "miniboss" },
    { class = "terminator_nextbot_zambienecro",         diffAdded = 40, diffNeeded = 90, passChance = 75, spawnSlot = "miniboss" },
    { class = "terminator_nextbot_zambiewraithelite",   diffAdded = 100, diffNeeded = 90, passChance = 99.5, spawnSlot = "miniboss" }, -- rare elite wraith duo

    { class = "terminator_nextbot_zambiewraith",        diffAdded = 25, diffNeeded = 99, passChance = 99, batchSize = 5, spawnSlot = "miniboss" }, -- smallish wraith wave
    { class = "terminator_nextbot_zambiewraith",        diffAdded = 30, diffNeeded = 99, passChance = 99.5, batchSize = 20, spawnSlot = "miniboss" }, -- rare hell wraith wave
    { class = "terminator_nextbot_zambiewraithelite",   diffAdded = 50, diffNeeded = 99, passChance = 99.9, batchSize = 3, spawnSlot = "miniboss" }, -- rare elite wraith duo
    { class = "terminator_nextbot_zambieberserk",       diffAdded = 30, diffNeeded = 99, passChance = 99.5, batchSize = 5, spawnSlot = "miniboss" }, -- rare berserk wave
    { class = "terminator_nextbot_zambietank",          diffAdded = 60, diffNeeded = 99, passChance = 99.5, batchSize = 2, spawnSlot = "miniboss" }, -- rare 2 tank spawn

}

function terminator_Extras.zamb_GetSpawnData( targetDifficultyWeighted, _targetDifficultyInt, _differenceInt )

    local bestData
    local myData = terminator_Extras.zamb_SpawnData
    for _, data in ipairs( myData ) do
        local diffMax = data.diffMax or maxDifficulty
        local traditionallyGood = targetDifficultyWeighted >= data.diffNeeded and targetDifficultyWeighted < diffMax and ( data.passChance <= 0 or math.Rand( 0, 100 ) > data.passChance )
        local passAnyway = data.randomSpawnAnyway and math.Rand( 0, 100 ) < data.randomSpawnAnyway
        local wouldBeTooMany = data.maxAtOnce and #ents.FindByClass( data.class ) >= data.maxAtOnce
        if not wouldBeTooMany and data.spawnSlot then
            wouldBeTooMany = IsValid( terminator_Extras.zamb_OccupiedSpawnSlots[data.spawnSlot] )

        end
        if not wouldBeTooMany and ( traditionallyGood or passAnyway ) then
            bestData = data

        end
    end

    if not bestData then return end

    return bestData.class, bestData

end


local hitTooClose = 150^2

local function blockedByParticipator( checkPos, doSee, tooClose, tooFar )
    local anyWasCloseEnough
    participators = {} -- rebuild this
    if noPlayerParticipators then
        participators = terminator_Extras.zamb_EntsParticipatingFor

    else
        participators = terminator_Extras.zamb_PlayerParticipatingFor

    end
    for ent, _ in pairs( participators ) do
        if not IsValid( ent ) or not ent.GetShootPos then participators[ent] = nil continue end
        local plysShoot = ent:GetShootPos()
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

    zamCount = #ents.FindByClass( "terminator_nextbot_zambie*" )

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
    local maxToDo = 800 / math.Clamp( participatingCount, 40, 800 )
    local expensiveDone = 0

    for ind, currDat in ipairs( spawnPositions ) do -- check/trim positions placed by zombies that were killed by participators!
        if expensiveDone > maxToDo then
            break

        end
        local spawner = currDat.spawnerResponsible
        if not IsValid( spawner ) or not spawner:GetOn() then -- trim, its off!
            table.remove( spawnPositions, ind )
            continue

        end
        local currShoot = currDat.pos + shootPosOffset
        local isBlocked, anyWasCloseEnough = blockedByParticipator( currShoot, true, tooClose, tooFar )
        if isBlocked or not anyWasCloseEnough then -- too far or close, trim!
            expensiveDone = expensiveDone + 1
            table.remove( spawnPositions, ind )

        else
            spawnPos = currDat.pos
            finalSpawner = currDat.spawnerResponsible
            break

        end
    end

    local activeCount = 0
    local badCount = 0

    if not spawnPos then -- no valid zombie placed spawnpoints
        local spawnpoints = {}
        for _, spawner in ipairs( terminator_Extras.zamb_Spawnpoints ) do
            if not IsValid( spawner ) then continue end
            if not spawner:GetOn() then continue end
            table.insert( spawnpoints, spawner )

        end

        for _, spawner in RandomPairs( spawnpoints ) do
            activeCount = activeCount + 1

            if spawner.zamb_NextCanSpawnCheck > cur then badCount = badCount + 1 continue end

            local doSee = spawner.zamb_SpawnerConfig.spawnsOnlyIfHidden

            local myPos = spawner:GetPos()
            local myShootPos = myPos + shootPosOffset
            local isBlocked = blockedByParticipator( myShootPos, doSee, tooClose, tooFar )

            if isBlocked then
                badCount = badCount + 1
                local add = math.random( math.max( 5, player.GetCount() ), math.max( 12, player.GetCount() * 2 ) )
                spawner.zamb_NextCanSpawnCheck = cur + add

            else
                finalSpawner = spawner
                spawnPos = myPos

            end
        end
    end

    if spawnPos then
        local spawned = terminator_Extras.zamb_TryToSpawn( finalSpawner, spawnPos )
        return spawned

    elseif badCount >= activeCount then
        debugPrint( "!!!!All checked spawnpoints are likely exposed!!!!" )

    end
end


local offsetToSpawnAt = Vector( 0,0,5 )

function terminator_Extras.zamb_TryToSpawn( spawner, spawnPos )
    local queue = terminator_Extras.zamb_SpawnOverrideQueue

    if zamCount >= maxZambs then return end

    local tooManySoftCutoff = zamCount >= 1 and math.max( difficultyBeingExperienced, zamCount ) > targetDifficulty
    if #queue <= 0 and tooManySoftCutoff then return end -- queue must be purged

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

    if data.diffAdded then
        difficultyBeingExperienced = difficultyBeingExperienced + data.diffAdded

    end

    if data.spawnSlot then
        terminator_Extras.zamb_OccupiedSpawnSlots[data.spawnSlot] = zamb

    end

    terminator_Extras.zamb_DoForwardSpawnStuff( spawner, zamb )

    spawner:Zamb_OnZambSpawned( zamb )

    debugPrint( "Spawned!", zamb )

    return true

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
        local desiredCount = 15
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

        local enem = zamb:GetEnemy()

        if zamb.IsSeeEnemy and IsValid( enem ) and not enem.IsTerminatorZambie then
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