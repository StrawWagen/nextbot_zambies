
-- CREDIT broadclot zero https://steamcommunity.com/profiles/76561199800411255/

local function giveArmOfTheLaw( _, hunter )
    hunter:Give( "weapon_term_zambstick" )
end

local function giveOlReliable( _, hunter )
    hunter:Give( "weapon_term_zambvolver" )
end

local genericZambieCounter = "terminator_nextbot_zambiecop*" -- its the guy!! 

local set = {
    name = "zambies_glee_superzombieguns", -- unique name
    prettyName = "The Walking Doughnuts",
    description = "No undead cop can resist the urge of a doughnut...",
    difficultyPerMin = { 250 / 10, 500 / 10 }, -- difficulty per minute
    waveInterval = "default", -- time between spawn waves
    diffBumpWhenWaveKilled = { 550, 780 }, -- noones gonna kill a zambcop bro
    startingBudget = { 1, 5 }, -- so budget isnt 0
    spawnCountPerDifficulty = { 1 }, -- go up to 20 fast pls
    startingSpawnCount = { 5, 8 },
    maxSpawnCount = { 30 }, -- hard cap on count
    maxSpawnDist = "default",
    roundEndSound = "music/hl1_song26.mp3",
    roundStartSound = "ambient/intro/logosfx.wav",
    chanceToBeVotable = 1.6,
    spawns = {
        {
            -- dunk em donuts
            hardRandomChance = nil,
            name = "zambie_olreliable", -- unique name
            prettyName = "A O'l Reliable Texan",
            class = "terminator_nextbot_zambiecop", -- class spawned
            spawnType = "hunter",
            difficultyCost = 6,
            countClass = genericZambieCounter, -- class COUNTED, uses findbyclass
            minCount = { 1 }, -- will ALWAYS maintain this count
            postSpawnedFuncs =  { giveOlReliable },
        },
        {
            hardRandomChance = nil,
            name = "zambie_armofthelaw", -- unique name
            prettyName = "A Arm Of The Law Texan",
            class = "terminator_nextbot_zambiecop", -- class spawned
            spawnType = "hunter",
            difficultyCost = 1,
            countClass = genericZambieCounter, -- class COUNTED, uses findbyclass
            minCount = { 1 }, -- will ALWAYS maintain this count
            postSpawnedFuncs =  { giveArmOfTheLaw },
        },
    }
}

-- gobble yummy yummy yum yum GOBBLEGOBBLE
table.insert( GLEE_SPAWNSETS, set )
