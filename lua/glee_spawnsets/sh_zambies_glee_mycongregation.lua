-- Mend your ways, before it is too late!
local set = {
    name = "zambies_glee_mycongregation",
}

if SERVER then
    local setSv = {
        prettyName = "My Congregation",
        description = "A shepherd must tend to his flock, especially when they have grown... unruly.",
        waveInterval = "zambies_glee_thehorde",
        startingBudget = "zambies_glee_thehorde",
        spawnCountPerDifficulty = "zambies_glee_thehorde",
        startingSpawnCount = "zambies_glee_thehorde",
        maxSpawnCount = "zambies_glee_thehorde",
        maxSpawnDist = "zambies_glee_thehorde",
        hordeSpawn = true,
        roundEndSound = "music/ravenholm_1.mp3",
        roundStartSound = "music/hl2_song7.mp3",
        chanceToBeVotable = 1,
        defaultWeapons = { "gmod_camera", "termhunt_radio" }, -- no crowbar, the grigori role brings their weapons
        importedMiserySpawns = {
            { name = "zambies_glee_thehorde" },
        },
    }
    table.Merge( set, setSv )

end

function set:Activate()
    local setHelpers = GAMEMODE.setHelpers
    setHelpers.makeHardcore( self )

    if CLIENT then return end

    setHelpers.setBaseRole( self, "grigori" )

end

table.insert( GLEE_SPAWNSETS, set )
