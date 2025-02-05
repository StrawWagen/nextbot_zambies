local zambieSpawnSet = {
    name = "zambies_glee_fastzombies", -- unique name
    prettyName = "Gotta Go Moderately Quick",
    description = "You only gotta deal with Fast Zombies here.",
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
            name = "zambie_fast_torso",
            prettyName = "A Fast Zombie Torso",
            class = "terminator_nextbot_zambietorsofast",
            spawnType = "hunter",
            difficultyCost = { 5 },
            countClass = "terminator_nextbot_zambietorsofast",
            minCount = { 0 },
            maxCount = { 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_fast",
            prettyName = "A Fast Zombie",
            class = "terminator_nextbot_zambiefast",
            spawnType = "hunter",
            difficultyCost = { 10, 35 },
            countClass = "terminator_nextbot_zambiefast",
            minCount = { 0 },
            maxCount = { 10 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_fast_elite",
            prettyName = "An Elite Fast Zombie",
            class = "terminator_nextbot_zambiefastgrunt",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            countClass = "terminator_nextbot_zambiefastgrunt",
            minCount = { 0 },
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
