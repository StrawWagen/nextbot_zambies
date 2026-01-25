-- credit to https://steamcommunity.com/id/TakeTheBeansIDontCare/

local zambieSpawnSet = {
    name = "zambies_glee_phantoms", -- unique name
    prettyName = "Phantom's Glee",
    description = "Hide yo props! Hide yo sanity!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 2 },
    startingSpawnCount = "default",
    maxSpawnCount = 40,
    maxSpawnDist = "default",
    roundEndSound = "music/ravenholm_1.mp3",
    roundStartSound = "ambient/levels/citadel/portal_beam_shoot5.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_phantom",
            prettyName = "A Phantom",
            class = "terminator_nextbot_zambiephantom",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiephantom",
            minCount = { 5 },
            postSpawnedFuncs = nil,
        },
        {
            hardRandomChance = nil,
            name = "zambie_phantom_elite",
            prettyName = "An Elite Phantom",
            class = "terminator_nextbot_zambiephantomelite",
            spawnType = "hunter",
            difficultyCost = { 50, 75 },
            countClass = "terminator_nextbot_zambiephantomelite",
            postSpawnedFuncs = nil,
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
