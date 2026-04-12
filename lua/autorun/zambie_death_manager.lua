
terminator_Extras = terminator_Extras or {}

terminator_Extras.reanim_SpawnTable = {}
terminator_Extras.reanim_DontRevive = {}

local nextDeadCheck = 0
local reanimatorCount = 0
local termXtras_BadParents = { -- A blacklist of things basically, also the reason reanimators aren't here is because they're already handled
    "terminator_nextbot_zambienecro",
    "terminator_nextbot_zambienecroelite",
    "terminator_nextbot_zambiebigheadcrab",
    "terminator_nextbot_zambiebiggerheadcrab",
}

local function termXtras_AddZambieDied( zamb, dontReviveList )
    local isTorso = string.match( zamb:GetClass(), "torso" ) == "torso"
    local class = zamb:GetClass()
    local isMinion -- This is if we were owned by a necromancer, or a crab of the god variety

    -- BEHOLD! THE POWER OF LIKE 8 DIFFERENT 'IF' STATEMENTS!
    if IsValid( zamb:GetOwner() ) then
        isMinion = table.HasValue( termXtras_BadParents, zamb:GetOwner():GetClass() )

    else
        isMinion = table.HasValue( terminator_Extras.reanim_DontRevive, zamb )

    end

    if isMinion then
        table.RemoveByValue( terminator_Extras.reanim_DontRevive, zamb )
        return

    end

    if zamb.BecameTorso then -- If our class is not a torso but when we died we became one
        return

    elseif isTorso then
        class = string.gsub( class, "torso", "" )

    end

    if dontReviveList then
        terminator_Extras.reanim_DontRevive = table.Add( terminator_Extras.reanim_DontRevive, dontReviveList )

    end

    local zambInfo = {
        diedPos = zamb:GetPos(),
        class = class,
        currentRevivedZamb = nil,
        isEldritch = zamb.IsEldritch,
        deletion = CurTime() + 120,
    }

    local key = zamb.ReferenceKey or tostring( zamb:GetCreationID() )
    terminator_Extras.reanim_SpawnTable[key] = zambInfo

end

hook.Add( "Think", "termXtras_CheckForDeadInfo", function()
    if nextDeadCheck > CurTime() or reanimatorCount == 0 then return end

    local castTable = {}

    for key, info in SortedPairsByMemberValue( terminator_Extras.reanim_SpawnTable, "deletion", true ) do
        if info.deletion < CurTime() then break end
        castTable[key] = info

    end

    terminator_Extras.reanim_SpawnTable = castTable

    nextDeadCheck = CurTime() + 5

end )

hook.Add( "reanim_AliveCountUpdated", "termXtras_UpdateReanimCount", function( increment )
    if increment then
        reanimatorCount = reanimatorCount + 1

    else
        reanimatorCount = math.Clamp( reanimatorCount - 1, 0, 10000 ) -- Just in case

        if reanimatorCount > 0 then return end

        terminator_Extras.reanim_SpawnTable = {}
        terminator_Extras.reanim_DontRevive = {}

    end
end )

hook.Add( "zamb_OnBecomeTorso", "termXtras_HandleZambieTorso", function( died, newTorso )
    if reanimatorCount == 0 then return end

    local diedOwner = died:GetOwner()
    died.BecameTorso = true

    if not terminator_Extras.reanim_SpawnTable[died.ReferenceKey] then return end

    newTorso:SetOwner( diedOwner )
    newTorso:SetNWBool( "IsZambReanim_Puppet", died:GetNWBool( "IsZambReanim_Puppet" ) )
    newTorso.ReferenceKey = died.ReferenceKey

    terminator_Extras.reanim_SpawnTable[died.ReferenceKey] = newTorso

end )

hook.Add( "OnNPCKilled", "termXtras_HandleNPCDeath", function( npc )
    if reanimatorCount == 0 or not npc.IsTerminatorZambie then return end

    local hasMinions = npc.ZAMBIE_MINIONS
    local dontReviveThese = nil

    if hasMinions then
        dontReviveThese = hasMinions

    end

    termXtras_AddZambieDied( npc, dontReviveThese )

end )