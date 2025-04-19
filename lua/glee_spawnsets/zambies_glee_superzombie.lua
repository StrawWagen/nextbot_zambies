local zambieSpawnSet = {
    name = "zambies_glee_superzombie", -- unique name
    prettyName = "A Post-Civil Actor.",
    description = "One Fallen Supercop, the rock that traps you against a hard place.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 4500, 6500 },
    roundEndSound = "ambient/alarms/city_siren_loop2.wav",
    roundStartSound = "ambient/alarms/scanner_alert_pass1.wav",
    chanceToBeVotable = 15,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theFallenSupercop",
            prettyName = "The Fallen Supercop",
            class = "terminator_nextbot_zambiecop",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambie*",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
