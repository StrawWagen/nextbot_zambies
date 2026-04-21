
terminator_Extras = terminator_Extras or {}
terminator_Extras.reanim_SpawnEntryDeletionOffset = 120
-- The time it takes for an entry to be removed from the spawn pool after it hasn't been revived
-- The reanimator itself also uses this for some math

local function wipeReviveStuff()
    terminator_Extras.reanim_SpawnTable = {}

end

wipeReviveStuff()

local reanimatorCount = 0

local function reanim_AddZambieDied( zamb )
    local isTorso = string.match( zamb:GetClass(), "torso" ) == "torso"
    local class = zamb:GetClass()
    local necroMaster = zamb.zamb_NecroMaster

    -- If we were owned by a necromancer (alive or dead) that isn't itself a reanimator, skip revival
    if necroMaster and not necroMaster.reanim_IsReanimator then
        return

    end

    if zamb.BecameTorso then -- If our class is not a torso but when we died we became one
        return

    elseif isTorso then
        class = string.gsub( class, "torso", "" )

    end

    local zambInfo = {
        diedPos = zamb:GetPos(),
        class = class,
        currentRevivedZamb = nil,
        isEldritch = zamb.IsEldritch,
        deletion = CurTime() + terminator_Extras.reanim_SpawnEntryDeletionOffset,
    }

    local key = zamb.ReferenceKey or tostring( zamb:GetCreationID() )
    terminator_Extras.reanim_SpawnTable[key] = zambInfo

end

local nextDeadCheck = 0

hook.Add( "Think", "zambies_reanim_cleanupreanimtable", function()
    if reanimatorCount == 0 then return end
    if nextDeadCheck > CurTime() then return end
    nextDeadCheck = CurTime() + 5

    local spawnTable = terminator_Extras.reanim_SpawnTable
    local castTable = {}

    for key, info in SortedPairsByMemberValue( spawnTable, "deletion", true ) do
        if info.deletion < CurTime() then break end
        castTable[key] = info

    end

    terminator_Extras.reanim_SpawnTable = castTable

end )

hook.Add( "reanim_AliveCountUpdated", "zambies_reanim_updatecount", function( increment )
    if increment then
        reanimatorCount = reanimatorCount + 1

    else
        reanimatorCount = math.Clamp( reanimatorCount - 1, 0, 10000 ) -- Just in case

        if reanimatorCount > 0 then return end

        wipeReviveStuff()

    end
end )

--[[--------------------------------------------------------------------------
This makes zombies that become torsos not revived so there isn't duplicates.
Instead torsos get revived as full zambies.
--------------------------------------------------------------------------]]--
hook.Add( "zamb_OnBecomeTorso", "zambies_reanim_handlezombietorso", function( died, newTorso )
    if reanimatorCount == 0 then return end

    local spawnTable = terminator_Extras.reanim_SpawnTable

    local diedOwner = died:GetOwner()
    died.BecameTorso = true

    if not spawnTable[died.ReferenceKey] then return end

    newTorso:SetOwner( diedOwner )
    newTorso:SetNWBool( "IsZambReanim_Puppet", died:GetNWBool( "IsZambReanim_Puppet" ) )
    newTorso.ReferenceKey = died.ReferenceKey

end )

-- add zambs to revive tracker
hook.Add( "OnNPCKilled", "zambies_reanim_handlenpckilled", function( npc )
    if reanimatorCount == 0 then return end
    if not npc.IsTerminatorZambie then return end

    reanim_AddZambieDied( npc )

end )