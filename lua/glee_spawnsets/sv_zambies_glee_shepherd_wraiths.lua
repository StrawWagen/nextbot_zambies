
local zambieSpawnSet = {
    name = "zambies_glee_shepherd_wraiths", -- unique name
    prettyName = "The Wraith Shepherd",
    description = "It herds what you can't see...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = "default",
    maxSpawnCount = 31,
    hordeSpawn = true,
    maxSpawnDist = "default",
    roundEndSound = "music/ravenholm_1.mp3",
    roundEarlyStartSound = "nextbot_zambies/music/MICHGORGEOUS/wraith_wmrs.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            name = "zambie_spiritelite",
            prettyName = "The Wraith Shepherd",
            class = "terminator_nextbot_zambiespiritelite",
            spawnType = "hunter",
            difficultyCost = 1000, -- the priciest, so it's picked first, minCount makes it free
            countClass = "terminator_nextbot_zambiespiritelite",
            minCount = { 1 },
            maxCount = { 1 },
            isBoss = true,
        },
        {
            name = "zambie_wraith_torso",
            prettyName = "A Wraith Torso",
            class = "terminator_nextbot_zambietorsowraith",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorsowraith",
            maxCount = { 2 },
        },
        {
            name = "zambie_wraith",
            prettyName = "A Wraith",
            class = "terminator_nextbot_zambiewraith",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiewraith",
            minCount = { 5 },
            maxCount = { 10 },
        },
        {
            name = "zambie_wraith_elite",
            prettyName = "An Elite Wraith",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            countClass = "terminator_nextbot_zambiewraithelite",
            maxCount = { 5 },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
