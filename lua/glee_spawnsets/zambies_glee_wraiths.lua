local zambieSpawnSet = {
    name = "zambies_glee_wraiths", -- unique name
    prettyName = "A Flicker In The Light",
    description = "Zombie Wraiths only.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = "default",
    maxSpawnCount = "default",
    maxSpawnDist = "default",
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_wraith_torso",
            prettyName = "A Wraith Torso",
            class = "terminator_nextbot_zambietorsowraith",
            spawnType = "hunter",
            difficultyCost = { 5 },
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
            difficultyCost = { 10, 35 },
            countClass = "terminator_nextbot_zambiewraith",
            minCount = { 5 },
            maxCount = { 10 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_wraith_elite",
            prettyName = "An Elite Wraith",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 75, 100 },
            countClass = "terminator_nextbot_zambiewraithelite",
            minCount = { 0 },
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
