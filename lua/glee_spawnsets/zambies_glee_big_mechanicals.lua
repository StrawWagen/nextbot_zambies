local zambieSpawnSet = {
    name = "zambies_glee_big_mechanicals", -- unique name
    prettyName = "The Mechanical Giants",
    description = "BIG Mechanical zombies only...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default*4", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = 5,
    maxSpawnCount = 50,
    maxSpawnDist = "default",
    roundEndSound = "ambient/materials/shipgroan3.wav",
    roundStartSound = "ambient/machines/floodgate_move_short1.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "aMechanicalGiant",
            prettyName = "A Mechanical Giant",
            class = "terminator_nextbot_zambiemechaelite",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiemechaelite",
            minCount = { 5 },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
