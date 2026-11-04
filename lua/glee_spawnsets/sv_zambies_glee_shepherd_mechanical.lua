
local screamAfterSpawning = GAMEMODE.setHelpers.zamb_ScreamAfterSpawning()
local alwaysScreamAfterSpawning = GAMEMODE.setHelpers.zamb_AlwaysScreamAfterSpawning

local zambieSpawnSet = {
    name = "zambies_glee_shepherd_mechanical", -- unique name
    prettyName = "The Mechanic",
    description = "It keeps the machine running...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default*4", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = 6,
    maxSpawnCount = 51,
    maxSpawnDist = "default",
    roundEndSound = "music/hl2_song6.mp3",
    roundStartSound = "music/stingers/industrial_suspense1.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            name = "zambie_spiritelite",
            prettyName = "The Mechanic",
            class = "terminator_nextbot_zambiespiritelite",
            spawnType = "hunter",
            difficultyCost = 1000, -- the priciest, so it's picked first, minCount makes it free
            countClass = "terminator_nextbot_zambiespiritelite",
            minCount = { 1 },
            maxCount = { 1 },
            isBoss = true,
        },
        {
            name = "zambie_mecha",
            prettyName = "A Mecha Zombie",
            class = "terminator_nextbot_zambiemecha",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiemecha",
            minCount = { 5 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
        {
            name = "zambie_mecha_elite",
            prettyName = "An Elite Mecha Zombie",
            class = "terminator_nextbot_zambiemechaelite",
            spawnType = "hunter",
            difficultyCost = { 150, 250 },
            countClass = "terminator_nextbot_zambiemechaelite",
            maxCount = { 5 },
            postSpawnedFuncs = { alwaysScreamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
