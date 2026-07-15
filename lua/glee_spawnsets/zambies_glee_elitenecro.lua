-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local zambieSpawnSet = {
    name = "zambies_glee_elitenecro", -- unique name
    prettyName = "The Necromancer",
    description = "They, they won't stop coming!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default", -- max of ten at 10 minutes
    startingSpawnCount = 1,
    maxSpawnCount = 1,
    maxSpawnDist = { 2500, 4500 }, -- CLOSE!
    roundEndSound = "music/hl2_song32.mp3",
    roundStartSound = "music/hl2_song8.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableWhenHard = 3,
    spawns = {
        {
            hardRandomChance = nil,
            name = "theNecromancer",
            prettyName = "The Necromancer",
            class = "terminator_nextbot_zambienecroelite",
            spawnType = "hunter",
            difficultyCost = 1,
            countClass = "terminator_nextbot_zambienecroelite",
            maxCount = { 1 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
