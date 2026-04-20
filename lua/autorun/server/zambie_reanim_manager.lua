
terminator_Extras = terminator_Extras or {}

terminator_Extras.reanim_SpawnTable = {}
terminator_Extras.reanim_DontRevive = {}

local nextDeadCheck = 0
local reanimatorCount = 0

local function termXtras_AddZambieDied( zamb, dontReviveList )
    local isTorso = string.match( zamb:GetClass(), "torso" ) == "torso"
    local class = zamb:GetClass()
    local isMinion -- This is if we were owned by a necromancer, or a crab of the god variety
    local necroMaster = zamb.zamb_NecroMaster
    local masterIsReanim
    local dontRevive = terminator_Extras.reanim_DontRevive

    -- BEHOLD! THE POWER OF LIKE 8 DIFFERENT 'IF' STATEMENTS!
    if necroMaster then
        masterIsReanim = necroMaster.reanim_IsReanimator

    else
        masterIsReanim = false

    end

    if IsValid( necroMaster ) and not masterIsReanim then -- We want dead puppets to override their original entries
        isMinion = true

    else
        isMinion = table.HasValue( dontRevive, zamb )

    end

    if isMinion then
        table.RemoveByValue( dontRevive, zamb )
        return

    end

    if zamb.BecameTorso then -- If our class is not a torso but when we died we became one
        return

    elseif isTorso then
        class = string.gsub( class, "torso", "" )

    end

    if dontReviveList then
        dontRevive = table.Add( dontRevive, dontReviveList )

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
    if reanimatorCount == 0 then return end
    if nextDeadCheck > CurTime() then return end

    local spawnTable = terminator_Extras.reanim_SpawnTable
    local castTable = {}

    for key, info in SortedPairsByMemberValue( spawnTable, "deletion", true ) do
        if info.deletion < CurTime() then break end
        castTable[key] = info

    end

    spawnTable = castTable

    nextDeadCheck = CurTime() + 5 -- No reason to be calling this every frame

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

--[[--------------------------------------------------------------------------
This makes zombies that become torsos not revived so there isn't duplicates.
Instead torsos get revived as full zambies.
--------------------------------------------------------------------------]]--
hook.Add( "zamb_OnBecomeTorso", "termXtras_HandleZambieTorso", function( died, newTorso )
    if reanimatorCount == 0 then return end

    local spawnTable = terminator_Extras.reanim_SpawnTable

    local diedOwner = died:GetOwner()
    died.BecameTorso = true

    if not spawnTable[died.ReferenceKey] then return end

    newTorso:SetOwner( diedOwner )
    newTorso:SetNWBool( "IsZambReanim_Puppet", died:GetNWBool( "IsZambReanim_Puppet" ) )
    newTorso.ReferenceKey = died.ReferenceKey

    spawnTable[died.ReferenceKey] = newTorso

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