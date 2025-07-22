-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local nextScream = 0

local function screamAfterSpawning( _, crab )
    if nextScream > CurTime() then return end
    nextScream = CurTime() + math.random( 120, 240 )

    timer.Simple( math.random( 5, 30 ), function()
        if not IsValid( crab ) then return end
        crab:ZAMB_AngeringCall()

    end )
end

local zambieSpawnSet = {
    name = "zambies_glee_godcrabs", -- unique name
    prettyName = "Oops! All God Crabs!",
    description = "Brings a bit of god, to your crab.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 8,
    maxSpawnDist = { 8500, 10500 },
    roundEndSound = "music/ravenholm_1.mp3",
    roundStartSound = "music/hl2_song11.mp3",
    chanceToBeVotable = 10,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_godcrab",
            prettyName = "A Demigod Crab",
            class = "terminator_nextbot_zambiebigheadcrab",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambiebigheadcrab",
            postSpawnedFuncs = { screamAfterSpawning },
        },
        {
            hardRandomChance = nil,
            name = "zambie_godcrab",
            prettyName = "The God Crab",
            class = "terminator_nextbot_zambiebiggerheadcrab",
            spawnType = "hunter",
            difficultyCost = 100,
            countClass = "terminator_nextbot_zambiebiggerheadcrab",
            maxCount = { 1 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
