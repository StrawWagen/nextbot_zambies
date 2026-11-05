
local zambieSpawnSet = {
    name = "zambies_glee_boomorbust", -- unique name
    prettyName = "Boom.. Or Bust....",
    description = "They're here, they're mean, they're booming...",
    difficultyPerMin = "default*2", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default*2", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 0.04, 0.05 },
    startingSpawnCount = 3,
    maxSpawnCount = 16, -- the filler, and 15 elites
    maxSpawnDist = "default", -- not close, they sprint at you from 3000 out
    roundEndSound = "music/hl1_song14.mp3",
    roundStartSound = "music/hl2_song8.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableWhenHard = 1,
    spawns = {
        {
            hardRandomChance = 50,
            name = "zambie_boomer",
            prettyName = "A Tiny Boomer",
            class = "terminator_nextbot_zambieboomer",
            spawnType = "hunter",
            difficultyCost = 4,
            countClass = "terminator_nextbot_zambieboomer",
            maxCount = { 1 },
        },
        {
            name = "zambie_boomerelite_EARLY",
            prettyName = "An Elite Boomer",
            class = "terminator_nextbot_zambieboomerelite",
            spawnType = "hunter",
            difficultyCost = { 15, 25 },
            countClass = "terminator_nextbot_zambieboomerelite",
            minCount = { 2 },
            maxCount = { 4 },
        },
        {
            hardRandomChance = 75,
            name = "zambie_boomerelite",
            prettyName = "An Elite Boomer",
            class = "terminator_nextbot_zambieboomerelite",
            spawnType = "hunter",
            difficultyCost = { 60, 100 },
            countClass = "terminator_nextbot_zambieboomerelite",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
