
local nextScream = 0

local function screamAfterSpawning( _, spawned )
    if nextScream > CurTime() then return end
    nextScream = CurTime() + math.random( 120, 240 )

    timer.Simple( math.random( 5, 30 ), function()
        if not IsValid( spawned ) then return end
        spawned:ZAMB_AngeringCall()

    end )
end

local function alwaysScreamAfterSpawning( _, spawned )
    timer.Simple( math.random( 5, 30 ), function()
        if not IsValid( spawned ) then return end
        spawned:ZAMB_AngeringCall()

    end )
end

local zambieSpawnSet = {
    name = "zambies_glee_mechanical", -- unique name
    prettyName = "Zambie Mechageddon",
    description = "Mechanical zombies only.",
    difficultyPerMin = "default", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = "default", -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = "default*4", -- so budget isnt 0
    spawnCountPerDifficulty = "default*2",
    startingSpawnCount = 5,
    maxSpawnCount = 50,
    maxSpawnDist = "default",
    roundEndSound = "music/hl2_song6.mp3",
    roundStartSound = "music/stingers/industrial_suspense1.wav",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_mecha",
            prettyName = "A Mecha Zombie",
            class = "terminator_nextbot_zambiemecha",
            spawnType = "hunter",
            difficultyCost = { 10, 25 },
            countClass = "terminator_nextbot_zambiemecha",
            minCount = { 5 },
            postSpawnedFuncs = { screamAfterSpawning },
        },
        {
            hardRandomChance = nil,
            name = "zambie_mecha_elite",
            prettyName = "An Elite Mecha Zombie",
            class = "terminator_nextbot_zambiemechaelite",
            spawnType = "hunter",
            difficultyCost = { 150, 250 },
            countClass = "terminator_nextbot_zambiemechaelite",
            minCount = { 0 },
            maxCount = { 5 },
            postSpawnedFuncs = { alwaysScreamAfterSpawning },
        },
    }
}

table.insert( GLEE_SPAWNSETS, zambieSpawnSet )
