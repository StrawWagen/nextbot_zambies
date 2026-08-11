local zambieSpawnSet = {
    name = "zambies_glee_thetank", -- unique name
    prettyName = "The Tank.",
    description = "The Tank...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 2500, 4500 }, -- CLOSE!
    roundEndSound = "music/hl2_song13.mp3",
    roundStartSound = "music/hl1_song26.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableIfHard = 10,
    easy = true,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theTank",
            prettyName = "The Tank",
            class = "terminator_nextbot_zambietank",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambie*",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
