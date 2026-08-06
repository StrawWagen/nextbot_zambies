local zambieSpawnSet = {
    name = "zambies_glee_thewraith", -- unique name
    prettyName = "The Wraith.",
    description = "The horrible, horrible wraith.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 4500, 6500 },
    roundEndSound = "music/hl2_song19.mp3",
    roundStartSound = "music/hl2_song17.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableIfHard = 10,
    easy = true,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theWraith",
            prettyName = "The Wraith",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambie*",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
