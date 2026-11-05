local screamAfterSpawning = GAMEMODE.setHelpers.zamb_ScreamAfterSpawning()
local alwaysScreamAfterSpawning = GAMEMODE.setHelpers.zamb_AlwaysScreamAfterSpawning

local zambieSpawnSet = {
    name = "zambies_glee_glass",
    prettyName = "Fragile Nightmares.",
    description = "Glass zombies only. Shatter them before they shatter you.",
    difficultyPerMin = "default",
    waveInterval = "default",
    diffBumpWhenWaveKilled = "default",
    startingBudget = "default*2",
    spawnCountPerDifficulty = "default*3",
    startingSpawnCount = 8,
    maxSpawnCount = 60,
    hordeSpawn = true,
    maxSpawnDist = "default",
    roundEndSound = "music/hl2_song6.mp3",
    roundStartSound = "music/stingers/industrial_suspense1.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_glass",
            prettyName = "A Glass Zombie",
            class = "terminator_nextbot_zambieglass",
            spawnType = "hunter",
            difficultyCost = { 10, 20 },
            countClass = "terminator_nextbot_zambieglass",
            minCount = { 5 },
            maxCount = { 15 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
        {
            hardRandomChance = nil,
            name = "zambie_glass_elite",
            prettyName = "An Elite Glass Zombie",
            class = "terminator_nextbot_zambieglasselite",
            spawnType = "hunter",
            difficultyCost = { 30, 50 },
            countClass = "terminator_nextbot_zambieglasselite",
            minCount = { 0 },
            maxCount = { 12 },
            postSpawnedFuncs = { alwaysScreamAfterSpawning },
        },
        {
            hardRandomChance = nil,
            name = "zambie_glass_apex",
            prettyName = "An Apex Glass Zombie",
            class = "terminator_nextbot_zambieglassapex",
            spawnType = "hunter",
            difficultyCost = { 100, 150 },
            countClass = "terminator_nextbot_zambieglassapex",
            minCount = { 0 },
            maxCount = { 3 },
            postSpawnedFuncs = { alwaysScreamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
