-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local zambieSpawnSet = {
    name = "zambies_glee_fastzombies", -- unique name
    prettyName = "Faster than THESE zambies?",
    description = "For the real Fast Zombie Enjoyers.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 0.5 }, -- go up to 20 fast pls
    startingSpawnCount = { 4, 7 },
    maxSpawnCount = 20,
    roundEndSound = "music/ravenholm_1.mp3",
    roundStartSound = "npc/fast_zombie/fz_alert_far1.wav",
    chanceToBeVotable = 25,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_fast_torso",
            prettyName = "A Fast Zombie Torso",
            class = "terminator_nextbot_zambietorsofast",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorsofast",
            maxCount = { 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_fast",
            prettyName = "A Fast Zombie",
            class = "terminator_nextbot_zambiefast",
            spawnType = "hunter",
            difficultyCost = { 1, 5 },
            countClass = "terminator_nextbot_zambiefast",
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_fast_elite",
            prettyName = "An Elite Fast Zombie",
            class = "terminator_nextbot_zambiefastgrunt",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            countClass = "terminator_nextbot_zambiefastgrunt",
            maxCount = { 5 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
