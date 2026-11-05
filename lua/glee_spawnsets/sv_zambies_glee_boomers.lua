
local zambieSpawnSet = {
    name = "zambies_glee_boomers", -- unique name
    prettyName = "Boomer's Glee",
    description = "POP! Goes the zombie...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 0.1 },
    startingSpawnCount = { 6, 10 },
    maxSpawnCount = 30,
    roundEndSound = "music/hl1_song26.mp3",
    roundStartSound = "music/hl2_song26.mp3",
    chanceToBeVotable = 2.5,
    spawns = {
        {
            name = "zambie_boomer",
            prettyName = "A Boomer",
            class = "terminator_nextbot_zambieboomer",
            spawnType = "hunter",
            difficultyCost = { 3, 6 },
            countClass = "terminator_nextbot_zambieboomer",
        },
        {
            hardRandomChance = { 10, 20 },
            name = "zambie_blastcrab",
            prettyName = "A Blastcrab",
            class = "terminator_nextbot_zambieblastcrab",
            spawnType = "hunter",
            difficultyCost = { 1, 2 },
            countClass = "terminator_nextbot_zambieblastcrab", -- boomers' crabs count too
            maxCount = { 1, 2 },
        },
        {
            name = "zambie_boomerelite",
            prettyName = "An Elite Boomer",
            class = "terminator_nextbot_zambieboomerelite",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            difficultyNeeded = { 75, 100 },
            countClass = "terminator_nextbot_zambieboomerelite",
            maxCount = { 1 },
            cooldown = { 60, 120 },
        },
        {
            hardRandomChance = { 10, 20 },
            name = "zambie_boomerelite_LATE",
            prettyName = "An Elite Boomer",
            class = "terminator_nextbot_zambieboomerelite",
            spawnType = "hunter",
            difficultyCost = { 150, 250 },
            difficultyNeeded = { 300, 500 },
            countClass = "terminator_nextbot_zambieboomerelite",
            maxCount = { 2, 4 },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
