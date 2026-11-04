
local setHelpers = ( GM or GAMEMODE ).setHelpers

-- makes a .postSpawnedFuncs entry, the spawned zambie calls the horde in a few seconds after it arrives
-- at most one call every 2-4 minutes, so a big wave doesn't scream all at once
-- call once per misery, each call gets its own cooldown
function setHelpers.zamb_ScreamAfterSpawning( delayMin, delayMax )
    delayMin = delayMin or 5
    delayMax = delayMax or 30
    local nextScream = 0

    return function( _, spawned )
        if nextScream > CurTime() then return end
        nextScream = CurTime() + math.random( 120, 240 )

        timer.Simple( math.random( delayMin, delayMax ), function()
            if not IsValid( spawned ) then return end
            spawned:ZAMB_AngeringCall()

        end )
    end
end

local STRIKE_HEIGHT_MIN = 1500
local STRIKE_HEIGHT_MAX = 6000
local STRIKE_SPREAD = 400 -- how far off the player's head they can land, so a wave isn't one stack

-- boomers already go off when killed, this just kills them on the first landing
local boomstrikeTask = {
    StartsOnInitialize = true,
    OnLandOnGround = function( self )
        if self:Health() <= 0 then return end -- the fall already did it

        local dmg = DamageInfo()
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetDamageType( DMG_GENERIC )
        dmg:SetDamage( self:Health() )
        self:TakeDamageInfo( dmg )

    end,
}

-- a .postSpawnedFuncs entry for boomers, lifts them into the sky and over the nearest player, they go off the moment they land
-- pair with preferredEFlags = UNDER_SKY and firmPreferredEFlags, or most of them land on a ceiling
function setHelpers.zamb_PostSpawnedBoomstrike( _, spawned )
    local pos = spawned:GetPos()
    local mins, maxs = spawned:GetCollisionBounds()
    local trDat = {
        start = pos + vector_up * 10,
        endpos = pos + vector_up * math.random( STRIKE_HEIGHT_MIN, STRIKE_HEIGHT_MAX ),
        mins = mins,
        maxs = maxs,
        mask = MASK_NPCSOLID,
        filter = spawned,
    }
    local top = util.TraceHull( trDat ).HitPos

    -- then flat across, until it's over them, or something's in the way
    local ply = GAMEMODE:nearestAlivePlayer( pos )
    if IsValid( ply ) then
        local over = ply:GetPos()
        over.x = over.x + math.Rand( -STRIKE_SPREAD, STRIKE_SPREAD )
        over.y = over.y + math.Rand( -STRIKE_SPREAD, STRIKE_SPREAD )
        over.z = top.z

        trDat.start = top
        trDat.endpos = over
        top = util.TraceHull( trDat ).HitPos

    end
    spawned:SetPosNoTeleport( top )

    spawned.zamb_BoomerPrimed = true -- unprimed, a normal boomer's blast does 1
    spawned:AddTaskLazy( "zamb_boomstrike", boomstrikeTask )

end

-- a .canSpawnOnMap, true when most of the navmesh, by surface area, is under open sky
-- miseries using it drop out of the vote on mostly indoor maps
function setHelpers.zamb_MapIsMostlySky()
    local total = GAMEMODE.navmeshTotalSurfaceArea
    if not total or total <= 0 then return false end

    return GAMEMODE.navmeshUnderSkySurfaceArea / total > 0.5

end

-- a .postSpawnedFuncs entry, like zamb_ScreamAfterSpawning but every one screams
function setHelpers.zamb_AlwaysScreamAfterSpawning( _, spawned )
    timer.Simple( math.random( 5, 30 ), function()
        if not IsValid( spawned ) then return end
        spawned:ZAMB_AngeringCall()

    end )
end
