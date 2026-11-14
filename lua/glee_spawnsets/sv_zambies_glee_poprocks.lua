
-- spirits drop blastcrab squads on you, the crabs set each other off
local zambieSpawnSet = {
    name = "zambies_glee_poprocks", -- unique name
    prettyName = "Pop Rocks",
    description = "Snap, crackle, POP!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default*0.5", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = { 0.2 },
    startingSpawnCount = { 14, 18 },
    maxSpawnCount = 43,
    hordeSpawn = true,
    roundEndSound = "music/stingers/industrial_suspense1.wav",
    roundStartSound = "music/hl1_song6.mp3",
    chanceToBeVotable = 0.15,
    chanceToBeVotableWhenHard = 1,
    spawns = {
        {
            name = "zambie_spiritelite",
            prettyName = "The Elite Spirit",
            class = "terminator_nextbot_zambiespiritelite",
            spawnType = "hunter",
            difficultyCost = 1,
            countClass = "terminator_nextbot_zambiespiritelite",
            minCount = { 1 }, -- without one, it's just Crabbing a Blast!
            maxCount = { 1 },
            cooldown = 190,
        },
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
