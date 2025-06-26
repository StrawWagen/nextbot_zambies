
-- CREDIT MEMEMAN -- https://steamcommunity.com/id/blahaj1337/

local function givePistol( _, hunter )
    hunter:Give( "weapon_pistol" )
end

local function giveSMG( _, hunter )
    hunter:Give( "weapon_smg1" )
end

local function giveAR2( _, hunter )
    hunter:Give( "weapon_ar2" )
end

local function giveRPG( _, hunter )
    hunter:Give( "weapon_rpg" )
end

local function give357( _, hunter )
    hunter:Give( "weapon_357" )
end

local function giveXBOW( _, hunter )
    hunter:Give( "weapon_crossbow" )
end

local genericZambieCounter = "terminator_nextbot_zambie*"

local set = {
    name = "zambies_glee_allguns", -- unique name
    prettyName = "The American Undead",
    description = "Not even death can depart an American from the 2nd amendment.",
    difficultyPerMin = "default*5", -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = { 15, 25 }, -- when there's <= 1 hunter left, the difficulty is permanently bumped by this amount
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 1 }, -- go up to 20 fast pls
    startingSpawnCount = { 4, 7 },
    maxSpawnCount = { 30 }, -- hard cap on count
    maxSpawnDist = "default",
    roundEndSound = "music/hl1_song25_remix3.mp3",
    roundStartSound = "music/hl2_song32.mp3",
    chanceToBeVotable = 1,
    spawns = {
        {
            hardRandomChance = nil,
            name = "zambie_pistol", -- unique name
            prettyName = "A Barely Armed American",
            class = "terminator_nextbot_zambie_slow", -- class spawned
            spawnType = "hunter",
            difficultyCost = 1,
            countClass = genericZambieCounter, -- class COUNTED, uses findbyclass
            minCount = { 1 }, -- will ALWAYS maintain this count
            postSpawnedFuncs =  { givePistol },
        },
        {
            hardRandomChance = nil,
            name = "zambie_normal_smg", -- unique name
            prettyName = "A Lightly Armed American",
            class = "terminator_nextbot_zambie", -- class spawned
            spawnType = "hunter",
            difficultyCost = 6,
            countClass = genericZambieCounter, -- class COUNTED, uses findbyclass
            minCount = { 1 }, -- will ALWAYS maintain this count
            postSpawnedFuncs =  { giveSMG },
        },
        {
            hardRandomChance = nil,
            name = "zambie_shitter_rpg", -- it's accura
            prettyName = "A Well Armed Diarrhea American",
            class = "terminator_nextbot_zambieacid", -- class spawned
            spawnType = "hunter",
            difficultyCost = 150,
            countClass = "terminator_nextbot_zambieacid", -- class COUNTED, uses findbyclass
            maxCount = { 3 }, -- will never exceed this count, uses findbycount
            postSpawnedFuncs =  { giveRPG },
        },
        {
            hardRandomChance = nil,
            name = "zambie_shitter_rpg", -- it's accura
            prettyName = "A Well Armed Diarrhea American",
            class = "terminator_nextbot_zambieacid", -- class spawned
            spawnType = "hunter",
            difficultyCost = 150,
            countClass = "terminator_nextbot_zambieacid", -- class COUNTED, uses findbyclass
            maxCount = { 3 }, -- will never exceed this count, uses findbycount
            postSpawnedFuncs =  { giveRPG },
        },
        {
            hardRandomChance = nil,
            name = "zambie_normal_rifle", -- unique name
            prettyName = "A Moderately Armed American",
            class = "terminator_nextbot_zambie", -- class spawned
            spawnType = "hunter",
            difficultyCost = 8,
            countClass = "terminator_nextbot_zambie", -- class COUNTED, uses findbyclass
            maxCount = { 10 }, -- will never exceed this count, uses findbycount
            postSpawnedFuncs =  { giveAR2 },
        },
        {
            hardRandomChance = nil,
            name = "zambie_grunt_ELITE", -- unique name
            prettyName = "A Cowboy American", -- yeeeehaw
            class = "terminator_nextbot_zambiegrunt", -- class spawned
            spawnType = "hunter",
            difficultyCost = { 40, 80 },
            countClass = "terminator_nextbot_zambiegrunt", -- class COUNTED, uses findbyclass
            maxCount = { 5 }, -- will never exceed this count, uses findbycount
            postSpawnedFuncs =  { give357 },
        },
        {
            hardRandomChance = nil,
            name = "zambie_grunt_COMMON", -- unique name
            prettyName = "A Moderately Armed American",
            class = "terminator_nextbot_zambiegrunt", -- class spawned
            spawnType = "hunter",
            difficultyCost = { 20, 40 },
            countClass = "terminator_nextbot_zambiegrunt", -- class COUNTED, uses findbyclass
            minCount = { 0 }, -- will ALWAYS maintain this count
            maxCount = { 15 }, -- will never exceed this count, uses findbycount
            postSpawnedFuncs =  { giveAR2 },
        },
        {
            name = "zambie_tank",
            prettyName = "A Well Armed American",
            class = "terminator_nextbot_zambietank",
            spawnType = "hunter",
            difficultyCost = { 100, 150 },
            difficultyNeeded = { 200, 400 },
            countClass = "terminator_nextbot_zambietank",
            maxCount = { 1 },
            postSpawnedFuncs = { giveRPG },
        },
        -- wraith shit below
        {
            name = "zambie_wraith_drugged",
            prettyName = "A Lightly Armed Drugged American",
            class = "terminator_nextbot_zambiewraith",
            spawnType = "hunter",
            difficultyCost = { 80, 120 },
            difficultyNeeded = { 160, 190 },
            countClass = "terminator_nextbot_zambiewraith",
            maxCount = { 3 },
            postSpawnedFuncs = { giveSMG },
        },
        {
            name = "zambie_wraithelite_drugged",
            prettyName = "A Drugged Average American Sniper",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 120, 180 },
            difficultyNeeded = { 210, 450 },
            countClass = "terminator_nextbot_zambiewraithelite",
            maxCount = { 2 },
            postSpawnedFuncs = { giveXBOW },
        },
        {
            name = "zambie_tank",
            prettyName = "A Well Armed American",
            class = "terminator_nextbot_zambietank",
            spawnType = "hunter",
            difficultyCost = { 100, 150 },
            difficultyNeeded = { 200, 400 },
            countClass = "terminator_nextbot_zambietank",
            maxCount = { 1 },
            postSpawnedFuncs = { giveRPG },
        },
        -- wraith shit below
        {
            name = "zambie_wraith_drugged",
            prettyName = "A Lightly Armed Drugged American",
            class = "terminator_nextbot_zambiewraith",
            spawnType = "hunter",
            difficultyCost = { 80, 120 },
            difficultyNeeded = { 160, 190 },
            countClass = "terminator_nextbot_zambiewraith",
            maxCount = { 3 },
            postSpawnedFuncs = { giveSMG },
        },
        {
            name = "zambie_wraithelite_drugged",
            prettyName = "A Drugged Average American Sniper",
            class = "terminator_nextbot_zambiewraithelite",
            spawnType = "hunter",
            difficultyCost = { 120, 180 },
            difficultyNeeded = { 210, 450 },
            countClass = "terminator_nextbot_zambiewraithelite",
            maxCount = { 2 },
            postSpawnedFuncs = { giveXBOW },
        },
        {
            name = "zambie_tank",
            prettyName = "A Well Armed American",
            class = "terminator_nextbot_zambietank",
            spawnType = "hunter",
            difficultyCost = { 100, 150 },
            difficultyNeeded = { 200, 400 },
            countClass = "terminator_nextbot_zambietank",
            maxCount = { 1 },
            postSpawnedFuncs = { giveRPG },
        },
        {
            name = "zambie_tank",
            prettyName = "An Average American Sniper",
            class = "terminator_nextbot_zambietank",
            spawnType = "hunter",
            difficultyCost = { 100, 150 },
            difficultyNeeded = { 400, 800 },
            countClass = "terminator_nextbot_zambietank",
            maxCount = { 1 },
            postSpawnedFuncs = { giveXBOW },
        },
    }
}

-- put the spawnset IN the global table to be gobbled
table.insert( GLEE_SPAWNSETS, set )
