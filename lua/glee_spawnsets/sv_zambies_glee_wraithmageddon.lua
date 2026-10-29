
local zambieSpawnSet = {
    name = "zambies_glee_wraithmageddon", -- unique name
    prettyName = "Zambie Wraithmageddon",
    description = "Uncountable hordes of Wraith Zombies. God help you when they all show themselves...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 1 }, -- go up fast pls
    startingSpawnCount = 40,
    maxSpawnCount = 50,
    hordeSpawn = true,
    maxSpawnDist = "default",
    roundEndSound = "music/ravenholm_1.mp3",
    roundEarlyStartSound = "nextbot_zambies/music/MICHGORGEOUS/wraith_wmrs.wav",
    chanceToBeVotable = 2,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_wraith_torso",
            prettyName = "A Wraith Torso",
            class = "terminator_nextbot_zambietorsowraith",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorsowraith",
            minCount = { 0 },
            maxCount = { 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_wraith",
            prettyName = "A Wraith",
            class = "terminator_nextbot_zambiewraith",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiewraith",
            minCount = { 5 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_wraith_elite",
            prettyName = "An Elite Wraith",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            countClass = "terminator_nextbot_zambiewraithelite",
            minCount = { 0 },
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
