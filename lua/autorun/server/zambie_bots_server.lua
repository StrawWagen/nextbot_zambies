--CREDITS
-- zombine pm with headcrab https://steamcommunity.com/sharedfiles/filedetails/?id=265424952

resource.AddWorkshop( "3385851087" )

local nextThink = 10
local math_rand = math.Rand
local up = Vector( 0, 0, 1 )
local CurTime = CurTime
local table_count = table.Count

terminator_Extras = terminator_Extras or {}

terminator_Extras.zamb_AreasLastRot = {}
terminator_Extras.zamb_RottingAreas = {}
terminator_Extras.zamb_SmelliestRottingArea = nil

hook.Add( "Think", "zambnextbots_rottingareasthink", function()
    local cur = CurTime()
    if nextThink > cur then return end
    nextThink = cur + 3

    local rotting = terminator_Extras.zamb_RottingAreas or {}
    if table_count( rotting ) <= 0 then
        terminator_Extras.zamb_IndexedRottingAreas = nil
        terminator_Extras.zamb_SmelliestRottingArea = nil
        nextThink = cur + 10

    end
    terminator_Extras.zamb_RottingAreas = rotting

    local lastRot = terminator_Extras.zamb_AreasLastRot or {}

    local indexed = {}

    local bestRotArea
    local bestRot = 0
    for area, currRot in pairs( rotting ) do
        if IsValid( area ) then
            local since = cur - lastRot[area]
            local mul = since^1.11 / 10
            mul = mul + 1
            local bite = math_rand( -0.1, -0.05 ) * mul
            local newRot = currRot + bite
            if newRot <= 0 then
                rotting[area] = nil

            else
                rotting[area] = newRot
                indexed[#indexed + 1] = area
                if newRot > bestRot and math.random( 1, 100 ) > 50 then
                    bestRotArea = area
                    bestRot = newRot

                end
            end
        else
            rotting[area] = nil
            continue

        end
    end

    terminator_Extras.zamb_IndexedRottingAreas = indexed
    terminator_Extras.zamb_SmelliestRottingArea = bestRotArea

    if IsValid( bestRotArea ) then
        local sndPos = bestRotArea:GetRandomPoint()
        sndPos = sndPos + up * math.random( 5, 25 )

        local lvl = 75 + bestRot / 8
        sound.Play( "ambient/creatures/flies" .. math.random( 1, 5 ) .. ".wav", sndPos, lvl, bestRot / 5, math.random( 95, 105 ) )

    end
end )


hook.Add( "PostCleanupMap", "zamb_clear_rottingsmell", function()
    terminator_Extras.zamb_IndexedRottingAreas = nil
    terminator_Extras.zamb_RottingAreas = {}
    terminator_Extras.zamb_AreasLastRot = {}
    terminator_Extras.zamb_SmelliestRottingArea = nil

end )


terminator_Extras.zamb_TorsoZombieClasses = {
    ["terminator_nextbot_zambie"] = { class = "terminator_nextbot_zambietorso", legs = "models/zombie/classic_legs.mdl" },
    ["terminator_nextbot_zambiefast"] = { class = "terminator_nextbot_zambietorsofast", legs = "models/gibs/fast_zombie_legs.mdl" },
}

terminator_Extras.zamb_TorsoDensityNum = 0