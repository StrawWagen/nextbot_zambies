-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local nextScream = 0

local function screamAfterSpawning( _, crab )
    if nextScream > CurTime() then return end
    nextScream = CurTime() + math.random( 120, 240 )

    timer.Simple( math.random( 30, 60 ), function()
        if not IsValid( crab ) then return end
        crab:ZAMB_AngeringCall()

    end )
end

local zambieSpawnSet = {
    name = "zambies_glee_godcrab", -- unique name
    prettyName = "God is coming",
    description = "GOD IS HERE, GOD IS HERE",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 8500, 10500 }, -- far
    roundEndSound = "music/hl2_song27_trainstation2.mp3",
    roundStartSound = "",
    roundEarlyStartSound = "nextbot_zambies/music/god_is_coming.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableWhenHard = 3,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theOneGodCrab",
            prettyName = "The God Crab",
            class = "terminator_nextbot_zambiebiggerheadcrab",
            spawnType = "hunter",
            difficultyCost = 1,
            countClass = "terminator_nextbot_zambiebiggerheadcrab",
            maxCount = { 1 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
