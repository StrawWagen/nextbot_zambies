-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local genericZambieCounter = "terminator_nextbot_zambie*"

local zambieSpawnSet = {
    name = "zambies_glee_simplified", -- unique name
    prettyName = "The \"Boring\" Infected",
    description = "For when you want to kill zombies, but not be killed yourself!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 1 },
    startingSpawnCount = { 4, 7 },
    maxSpawnCount = 20,
    roundEndSound = "music/ravenholm_1.mp3",
    roundStartSound = "ambient/creatures/town_zombie_call1.wav",
    chanceToBeVotable = 15,
    spawns = {
        {
            name = "zambie_slow",
            prettyName = "A Slow Zombie",
            class = "terminator_nextbot_zambie_slow",
            spawnType = "hunter",
            difficultyCost = { 1 },
            difficultyStopAfter = { 20, 30 },
            countClass = genericZambieCounter,
            minCount = { 4 },
            postSpawnedFuncs = nil,
        },
        {
            name = "zambie_normal",
            prettyName = "A Zombie",
            class = "terminator_nextbot_zambie",
            spawnType = "hunter",
            difficultyCost = { 2, 4 },
            countClass = genericZambieCounter,
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 1.5 },
            name = "zambie_flaming_RARE", -- spawns early with a max count
            prettyName = "A Flaming Zombie",
            class = "terminator_nextbot_zambieflame",
            spawnType = "hunter",
            difficultyCost = { 4, 8 },
            countClass = "terminator_nextbot_zambieflame",
            maxCount = { 4 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 1 },
            name = "zambie_acid_RARE", -- spawns early with a max count
            prettyName = "An Acid Zombie",
            class = "terminator_nextbot_zambieacid",
            spawnType = "hunter",
            difficultyCost = { 4, 8 },
            countClass = "terminator_nextbot_zambieacid",
            maxCount = { 4 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 1.5, 4 },
            name = "zambie_grunt_RARE",
            prettyName = "A Zombie Grunt",
            class = "terminator_nextbot_zambiegrunt",
            spawnType = "hunter",
            difficultyCost = { 25, 50 },
            difficultyNeeded = { 25, 100 },
            countClass = "terminator_nextbot_zambiegrunt",
            maxCount = 1,
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 10, 25 },
            name = "zambie_fast",
            prettyName = "A Fast Zombie",
            class = "terminator_nextbot_zambiefast",
            spawnType = "hunter",
            difficultyCost = { 8, 12 },
            difficultyStopAfter = { 125, 250 },
            countClass = genericZambieCounter,
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 2 },
            name = "zambie_torso",
            prettyName = "A Zombie Torso",
            class = "terminator_nextbot_zambietorso",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorso",
            maxCount = { 1, 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 2 },
            name = "zambie_fast_torso",
            prettyName = "A Fast Zombie Torso",
            class = "terminator_nextbot_zambietorsofast",
            spawnType = "hunter",
            difficultyCost = { 4 },
            countClass = "terminator_nextbot_zambietorsofast",
            maxCount = { 1, 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 1 },
            name = "zambie_wraith_torso",
            prettyName = "A Wraith Torso",
            class = "terminator_nextbot_zambietorsowraith",
            spawnType = "hunter",
            difficultyCost = { 10 },
            difficultyNeeded = { 15, 50 },
            countClass = "terminator_nextbot_zambietorsowraith",
            maxCount = { 1, 2 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 0, 1 },
            name = "zambie_wraith_rare",
            prettyName = "A Wraith",
            class = "terminator_nextbot_zambiewraith",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            difficultyNeeded = { 10, 75 },
            countClass = "terminator_nextbot_zambiewraith",
            maxCount = { 1 },
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
