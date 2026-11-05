
local zambieSpawnSet = {
    name = "zambies_glee_shepherd_boomers", -- unique name
    prettyName = "Surprise! Boomers!",
    description = "Special delivery!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 0.1 },
    startingSpawnCount = { 7, 11 },
    maxSpawnCount = 31,
    roundEndSound = "music/hl1_song26.mp3",
    roundStartSound = "music/hl2_song26.mp3",
    chanceToBeVotable = 1,
    spawns = {
        {
            name = "zambie_spiritelite",
            prettyName = "The Booming Shepherd",
            class = "terminator_nextbot_zambiespiritelite",
            spawnType = "hunter",
            difficultyCost = 1000, -- the priciest, so it's picked first, minCount makes it free
            countClass = "terminator_nextbot_zambiespiritelite",
            minCount = { 1 },
            maxCount = { 1 },
            isBoss = true,
        },
        {
            name = "zambie_boomer",
            prettyName = "A Boomer",
            class = "terminator_nextbot_zambieboomer",
            spawnType = "hunter",
            difficultyCost = { 3, 6 },
            countClass = "terminator_nextbot_zambieboomer",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
