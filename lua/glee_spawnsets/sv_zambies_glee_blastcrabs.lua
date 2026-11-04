
local zambieSpawnSet = {
    name = "zambies_glee_blastcrabs", -- unique name
    prettyName = "Crabbing a Blast!",
    description = "They're crabbing and blasting all over the place!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default*0.5", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 0.2 },
    startingSpawnCount = { 15, 20 },
    maxSpawnCount = 40,
    hordeSpawn = true,
    roundEndSound = "music/stingers/industrial_suspense1.wav",
    roundStartSound = "music/hl1_song6.mp3",
    chanceToBeVotable = 0.5,
    chanceToBeVotableWhenHard = 1,
    spawns = {
        {
            name = "zambie_blastcrab",
            prettyName = "A Blastcrab",
            class = "terminator_nextbot_zambieblastcrab",
            spawnType = "hunter",
            difficultyCost = 0.5,
            countClass = "terminator_nextbot_zambieblastcrab",
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
