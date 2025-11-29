local set = {
    name = "zambies_glee_big_mechanical", -- unique name
    prettyName = "The Metal Menace",
    description = "One elite mechanical zombie. Just one.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 2500, 4500 }, -- CLOSE!
    roundEndSound = "default",
    roundStartSound = "default",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theOneMechanicalTitan",
            prettyName = "The Mechanical Titan",
            class = "terminator_nextbot_zambiemechaelite",
            spawnType = "hunter",
            difficultyCost = 1,
            maxCount = 1,
            countClass = "terminator_nextbot_zambiemechaelite",
        },
    }
}

table.insert( GLEE_SPAWNSETS, set )
