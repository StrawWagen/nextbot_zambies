
terminator_Extras = terminator_Extras or {}

terminator_Extras.reanim_SpawnTable = {}
terminator_Extras.reanim_DontRevive = {}

local reanimatorCount = 0
local termXtras_BadParents = { -- A blacklist of things basically, also the reason reanimators aren't here is because they're already handeled
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
        isEldritch = zamb.IsEldritch
    }

    local key = zamb.ReferenceKey or tostring( zamb:GetCreationID() )
    terminator_Extras.reanim_SpawnTable[key] = zambInfo

end

hook.Add( "OnEntityCreated", "termXtras_IncrementReanimCount", function( ent )
    timer.Simple( 0, function()
        local isReanimator = ent.reanim_IsReanimator

        if not isReanimator then return end

        reanimatorCount = reanimatorCount + 1

    end )
end )

hook.Add( "EntityRemoved", "termXtras_CheckReanimCount", function( ent )
    local isReanimator = ent.reanim_IsReanimator
    
    if not isReanimator then return end
    
    reanimatorCount = math.Clamp( reanimatorCount - 1, 0, 10000 )
    
    if reanimatorCount > 0 then return end
    
    terminator_Extras.reanim_SpawnTable = {}
    terminator_Extras.reanim_DontRevive = {}
    
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
    if not npc.IsTerminatorZambie or reanimatorCount == 0 then return end

    local hasMinions = npc.ZAMBIE_MINIONS
    local dontReviveThese = nil

    if hasMinions then
        dontReviveThese = hasMinions

    end

    termXtras_AddZambieDied( npc, dontReviveThese )

end )