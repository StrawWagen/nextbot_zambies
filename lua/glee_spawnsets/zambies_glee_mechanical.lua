local zambieSpawnSet = {
    name = "zambies_glee_mechanical", -- unique name
    prettyName = "Zambie Mechageddon",
    description = "Mechanical zombies only.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = "default",
    maxSpawnCount = 50,
    maxSpawnDist = "default",
    roundEndSound = "music/hl2_song6.mp3",
    roundStartSound = "music/hl2_song31.mp3",
    chanceToBeVotable = 15,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_mecha",
            prettyName = "A Mecha Zombie",
            class = "terminator_nextbot_zambiemecha",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiemecha",
            minCount = { 5 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_mecha_elite",
            prettyName = "An Elite Mecha Zombie",
            class = "terminator_nextbot_zambiemechaelite",
            spawnType = "hunter",
            difficultyCost = { 150, 250 },
            countClass = "terminator_nextbot_zambiemechaelite",
            minCount = { 0 },
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
