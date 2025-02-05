local zambieSpawnSet = {
    name = "zambies_glee_simplified", -- unique name
    prettyName = "Simplified Zambies",
    description = "Cut out the fat from Zambie's Glee and reduce the total amount of used zombies.",
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
            name = "zambie_slow",
            prettyName = "A Slow Zombie",
            class = "terminator_nextbot_zambie_slow",
            spawnType = "hunter",
            difficultyCost = { 5 },
            countClass = "terminator_nextbot_zambie_slow",
            minCount = { 2 },
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_normal",
            prettyName = "A Zombie",
            class = "terminator_nextbot_zambie",
            spawnType = "hunter",
            difficultyCost = { 25, 50 },
            countClass = "terminator_nextbot_zambie",
            minCount = { 0 },
            maxCount = { 10 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_grunt",
            prettyName = "A Zombie Grunt",
            class = "terminator_nextbot_zambiegrunt",
            spawnType = "hunter",
            difficultyCost = { 60, 120 },
            countClass = "terminator_nextbot_zambiegrunt",
            minCount = { 0 },
            maxCount = { 4 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_grunt_elite",
            prettyName = "An Elite Zombie Grunt",
            class = "terminator_nextbot_zambiegruntelite",
            spawnType = "hunter",
            difficultyCost = { 145, 150 },
            countClass = "terminator_nextbot_zambiegruntelite",
            minCount = { 0 },
            maxCount = { 2 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
