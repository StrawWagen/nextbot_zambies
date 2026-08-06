
local zambieSpawnSet = {
    name = "zambies_glee_thecrawlers", -- unique name
    prettyName = "The Crawlers",
    description = "Oh god, they're coming for our ankles!!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 1 },
    startingSpawnCount = { 4, 7 },
    maxSpawnCount = 30,
    roundEndSound = "music/hl2_song7.mp3",
    roundStartSound = "ambient/creatures/town_zombie_call1.wav",
    chanceToBeVotable = 0.5,
    chanceToBeVotableIfHard = 15,
    easy = true,
    spawns = {
        {
            name = "zambie_torso",
            prettyName = "A Zombie Torso",
            class = "terminator_nextbot_zambietorso",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorso",
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 15, 25 },
            name = "zambie_fast_torso",
            prettyName = "A Fast Zombie Torso",
            class = "terminator_nextbot_zambietorsofast",
            spawnType = "hunter",
            difficultyCost = { 4 },
            countClass = "terminator_nextbot_zambietorsofast",
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = { 5, 10 },
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
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
