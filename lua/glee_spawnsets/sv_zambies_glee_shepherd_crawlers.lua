
local zambieSpawnSet = {
    name = "zambies_glee_shepherd_crawlers", -- unique name
    prettyName = "The Crawling Shepherd",
    description = "It brings them to your ankles...",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 1 },
    startingSpawnCount = { 5, 8 },
    maxSpawnCount = 41,
    hordeSpawn = true,
    roundEndSound = "music/hl2_song7.mp3",
    roundStartSound = "ambient/creatures/town_zombie_call1.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            name = "zambie_spiritelite",
            prettyName = "The Crawling Shepherd",
            class = "terminator_nextbot_zambiespiritelite",
            spawnType = "hunter",
            difficultyCost = 1000, -- the priciest, so it's picked first, minCount makes it free
            countClass = "terminator_nextbot_zambiespiritelite",
            minCount = { 1 },
            maxCount = { 1 },
            isBoss = true,
        },
        {
            name = "zambie_torso",
            prettyName = "A Zombie Torso",
            class = "terminator_nextbot_zambietorso",
            spawnType = "hunter",
            difficultyCost = { 1 },
            countClass = "terminator_nextbot_zambietorso",
        },
        {
            hardRandomChance = { 15, 25 },
            name = "zambie_fast_torso",
            prettyName = "A Fast Zombie Torso",
            class = "terminator_nextbot_zambietorsofast",
            spawnType = "hunter",
            difficultyCost = { 4 },
            countClass = "terminator_nextbot_zambietorsofast",
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
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
