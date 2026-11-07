--CREDITS
-- zombine pm with headcrab https://steamcommunity.com/sharedfiles/filedetails/?id=265424952

resource.AddWorkshop( "3385851087" )

terminator_Extras = terminator_Extras or {}

-- is the server ticking slower than tickFrac of its ideal rate, eg 0.5 for half speed
function terminator_Extras.zamb_IsLagging( tickFrac )
    local idealTickrate = 1 / FrameTime()
    local currTickrate = 1 / engine.AbsoluteFrameTime()
    return currTickrate <= math.max( 2.5, idealTickrate * tickFrac )

end

terminator_Extras.zamb_TorsoZombieClasses = {
    ["terminator_nextbot_zambie"] = { class = "terminator_nextbot_zambietorso", legs = "models/zombie/classic_legs.mdl" },
    ["terminator_nextbot_zambie_slow"] = { class = "terminator_nextbot_zambietorso", legs = "models/zombie/classic_legs.mdl" },
    ["terminator_nextbot_zambiefast"] = { class = "terminator_nextbot_zambietorsofast", legs = "models/gibs/fast_zombie_legs.mdl" },
    ["terminator_nextbot_zambiewraith"] = { class = "terminator_nextbot_zambietorsowraith", legs = "models/gibs/fast_zombie_legs.mdl" },
}

terminator_Extras.zamb_TorsoDensityNum = 0
