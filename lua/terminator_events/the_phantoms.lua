
local newEvent = {
    -- chance for this to happen, rolled every minute
    defaultPercentChancePerMin = 0.0005,

    -- does this event progress through a "dedication" cvar?
    doesDedicationProgression = true,
    -- does this event need a map with a navmesh
    navmeshEvent = true,
    variants = {
        -- event variants are checked in sequential order
        {
            variantName = "chancePhantomMeeting",
            getIsReadyFunc = nil,
            minDedication = 0, -- this event will always happen
            overrideChance = 25, -- chance to override other events
            unspawnedStuff = {
                {
                    class = "terminator_nextbot_zambiephantom",
                    spawnAlgo = "steppedRandomRadius", -- will try to spawn this AS FAR as possible from all players
                    deleteAfterMeet = true, -- deletes the bot after .IsSeeEnemy is true, then not true for a while
                    timeout = true, -- if bot has no enemy for this long, despawns em, true means it sets to the default, 30 min

                }
            },
            thinkInterval = nil, -- makes it default to terminator_Extras.activeEventThinkInterval
            concludeOnMeet = true, -- this is what actually makes the event increase a dedication cvar, if one of the bots see a player
        },
        {
            variantName = "smallScoutedPhantoms",
            getIsReadyFunc = nil,
            minDedication = 2, -- this event will only happen after the player completes 2 other 'example' events
            overrideChance = 25, -- chance for this to override the above event, because it will get picked first
            unspawnedStuff = {
                {
                    class = "terminator_nextbot_zambiephantom",
                    spawnAlgo = "steppedRandomRadius",
                    scout = true, -- halts the spawning until this guy sees an enemy
                    timeout = true,

                },
                {
                    class = "terminator_nextbot_zambiephantom",
                    spawnAlgo = "steppedRandomRadiusNearby", -- spawns it far from players, but within at least 4000 units of them
                    repeats = 2, -- X count of this will exist in the unspawnedStuff list, so 2 will spawn, 3 including the scout

                },
            },
            thinkInterval = nil,
            concludeOnMeet = true,
        },
        {
            variantName = "chanceElitePhantomMeeting",
            getIsReadyFunc = nil,
            minDedication = 4,
            overrideChance = 25, -- chance to override other events
            unspawnedStuff = {
                {
                    class = "terminator_nextbot_zambiephantomelite",
                    spawnAlgo = "steppedRandomRadius", -- will try to spawn this AS FAR as possible from all players
                    deleteAfterMeet = true, -- deletes the bot after .IsSeeEnemy is true, then not true for a while
                    timeout = true, -- if bot has no enemy for this long, despawns em, true means it sets to the default, 30 min

                }
            },
            thinkInterval = nil, -- makes it default to terminator_Extras.activeEventThinkInterval
            concludeOnMeet = true, -- this is what actually makes the event increase a dedication cvar, if one of the bots see a player
        },
        {
            variantName = "largeElitePhantomGroup",
            getIsReadyFunc = nil,
            minDedication = 8, -- only after completing 8 other 'the_phantoms' events
            overrideChance = 25,
            unspawnedStuff = {
                {
                    class = "terminator_nextbot_zambiephantomelite",
                    spawnAlgo = "steppedRandomRadius",
                    scout = true,
                    timeout = true,

                },
                {
                    class = "terminator_nextbot_zambiephantom",
                    spawnAlgo = "steppedRandomRadiusNearby",
                    repeats = 10, -- 11 total will spawn including the scout

                },
            },
            thinkInterval = nil,
            concludeOnMeet = true,
        },
    },
}

terminator_Extras.RegisterEvent( newEvent, "paparazzi_sighting" )