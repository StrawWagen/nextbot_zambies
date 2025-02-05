local zambieSpawnSet = {
    name = "zambies_glee_godcrabs", -- unique name
    prettyName = "Oops! All God Crabs!",
    description = "You are dead. Not big soup rice.",
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
            name = "zambie_godcrab",
            prettyName = "A God Crab",
            class = "terminator_nextbot_zambiebigheadcrab",
            spawnType = "hunter",
            difficultyCost = { 5, 10 },
            countClass = "terminator_nextbot_zambiebigheadcrab",
            minCount = { 0 },
            maxCount = { 10 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
