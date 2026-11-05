
local setHelpers = GAMEMODE.setHelpers
local boomstrike = setHelpers.zamb_PostSpawnedBoomstrike
local mostlySky = setHelpers.zamb_MapIsMostlySky

local zambieSpawnSet = {
    name = "zambies_glee_boomstrikes", -- unique name
    prettyName = "Boomstrikes",
    description = "Incoming!",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default*0.5", -- they don't live long, so the waves come often
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = { 4, 6 },
    maxSpawnCount = 20,
    hordeSpawn = true, -- a carpet, not a drizzle
    maxSpawnDist = { 500, 1000 }, -- close, they're meant to land on you
    roundEndSound = "music/hl2_song6.mp3",
    roundStartSound = "ambient/levels/streetwar/gunship_distant1.wav",
    chanceToBeVotable = 0.1,
    spawns = {
        {
            name = "zambie_boomer",
            prettyName = "A Falling Boomer",
            class = "terminator_nextbot_zambieboomer",
            spawnType = "hunter",
            difficultyCost = { 2, 4 },
            countClass = "terminator_nextbot_zambieboomer",
            preferredEFlags = GAMEMODE.NavEFlags.UNDER_SKY,
            firmPreferredEFlags = true,
            canSpawnOnMap = mostlySky,
            postSpawnedFuncs = { boomstrike },
        },
        {
            hardRandomChance = { 0.01, 2 },
            name = "zambie_boomerelite",
            prettyName = "A Falling Elite Boomer",
            class = "terminator_nextbot_zambieboomerelite",
            spawnType = "hunter",
            difficultyCost = { 50, 300 },
            difficultyNeeded = { 100, 200 },
            countClass = "terminator_nextbot_zambieboomerelite",
            cooldown = { 20, 40 }, -- they die on landing, so maxCount wouldn't hold them back
            preferredEFlags = GAMEMODE.NavEFlags.UNDER_SKY,
            firmPreferredEFlags = true,
            canSpawnOnMap = mostlySky,
            postSpawnedFuncs = { boomstrike },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
