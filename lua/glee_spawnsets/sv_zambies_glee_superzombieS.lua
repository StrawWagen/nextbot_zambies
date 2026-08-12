local zambieSpawnSet = {
    name = "zambies_glee_superzombies", -- unique name
    prettyName = "Necrotic Justice",
    description = "Too many Fallen Supercops!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 20,
    maxSpawnDist = "default",
    roundEndSound = "ambient/alarms/citadel_alert_loop2.wav",
    roundStartSound = "music/stingers/hl1_stinger_song27.mp3",
    chanceToBeVotable = 10,
    spawns = {
        {
            hardRandomChance = nil,
            name = "aFallenSupercop",
            prettyName = "A Fallen Supercop",
            class = "terminator_nextbot_zambiecop",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambie*",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
