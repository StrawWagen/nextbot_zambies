-- Zombie Spirit
-- Ported from Map Sweepers. Original spirit by MerekiDor and JonahSoldier,
-- used with their permission on the condition that they are credited.
--
-- Stays well back from its enemy and teleports far-away zambies in next to it.

AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Spirit"
ENT.Author = "Regun2 (port) - original by MerekiDor and JonahSoldier (Map Sweepers)"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

list.Set( "NPC", "terminator_nextbot_zambiespirit", {
    Name = "Zombie Spirit",
    Class = "terminator_nextbot_zambiespirit",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiespirit", ENT.PrintName )
end

local ZAMBIE_PREFIX = "terminator_nextbot_zambie"
local SPIRIT_CLASS = "terminator_nextbot_zambiespirit"

-- Zambies bigger or tougher than this can't be summoned
local MAX_CARRY_SCALE = 1.15
local MAX_CARRY_HEALTH = 250

-- How long the death visuals play for before the entity is removed. The client's trail and sprite fade last this long.
local DEATH_VISUAL_TIME = 1.5

-- How far the spirit runs from an enemy that gets too close
local FLEE_DISTANCE = 512

-- Teleported zambies take no fall damage for this long
local FALL_PROTECT_TIME = 0.5

local SUMMON_HEIGHT_OFFSET = Vector( 0, 0, 10 )

ENT.DeployDistance = 1000 -- summons when the enemy is closer than this, flees when closer than half of it
ENT.MinGrabDist = 1500 -- only zambies further than this from the enemy get summoned

function ENT:SetupDataTables()
    if BaseClass.SetupDataTables then
        BaseClass.SetupDataTables( self )
    end

    self:NetworkVar( "Bool", 10, "IsDying" )
    self:NetworkVar( "Float", 10, "DeathTime" )
end

-- Never closes in on the enemy for a duel. This is what keeps the spirit from pushing up on players.
function ENT:CanMoveRightUpToEnemy()
    return false
end

-- Overrides the base zambie "call" action. Players use this with reload, the AI takes it when its enemy is in range.
ENT.MySpecialActions = {
    [ "call" ] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Summon Zambies",
        desc = "Pull zambies from afar to deploy near you",
        ratelimit = 5,
        svAction = function( _driveController, _driver, bot )
            local enemy = bot:GetEnemy()
            local summonPos = IsValid( enemy ) and enemy:GetPos() or bot:GetPos()
            bot:SummonZambies( summonPos, math.random( 3, 5 ) )
        end,
    },
}

-- Finds spots on the navmesh in a ring around center, for summoned zambies to land on.
-- Returns the spots, and whether we found as many as we wanted.
local function PackSquadVectors( center, count, radius )
    local results = {}
    local attempts = count * 6
    local angleStep = ( math.pi * 2 ) / attempts
    local minSpacingSqr = ( radius * 0.4 ) ^ 2

    for i = 0, attempts - 1 do
        if #results >= count then break end

        local angle = i * angleStep
        local candidate = center + Vector( math.cos( angle ) * radius, math.sin( angle ) * radius, 0 )

        local area = navmesh.GetNearestNavArea( candidate, false, 128 )
        if not area then continue end

        local snapped = area:GetClosestPointOnArea( candidate )

        -- Keep the spots from stacking on top of each other
        local tooClose = false
        for _, existing in ipairs( results ) do
            if existing:DistToSqr( snapped ) < minSpacingSqr then
                tooClose = true
                break
            end
        end
        if tooClose then continue end

        table.insert( results, snapped )
    end

    return results, #results >= count
end

local function GetFPSEstimate()
    local frameTime = FrameTime()
    if frameTime <= 0 then return 60 end

    return 1 / frameTime
end

-- Runs from threatPos, to a navmesh spot FLEE_DISTANCE away.
local function FleeFrom( self, threatPos )
    local selfPos = self:GetPos()
    local away = selfPos - threatPos
    if away:LengthSqr() < 1 then return end

    away:Normalize()
    away:Mul( FLEE_DISTANCE )
    local fleeTarget = selfPos + away

    local fleeArea = navmesh.GetNearestNavArea( fleeTarget, false, 512 )
    if not fleeArea then return end

    -- GotoPosSimple's signature is ( myTbl, pos, distance ), with self passed by the colon.
    self:GotoPosSimple( self:GetTable(), fleeArea:GetClosestPointOnArea( fleeTarget ), 64 )
end

-- Whether a player is driving this bot. Their summons are their own call.
local function IsPlayerDriven( bot )
    if not bot.IsControlledByPlayer then return false end

    return bot:IsControlledByPlayer() and true or false
end

-- Plays the shrinking red sigil at the zambie's old position.
local function FireSummonEffectAt( bot )
    local mins, maxs = bot:GetCollisionBounds()
    local height = maxs.z - mins.z

    local effectData = EffectData()
    effectData:SetOrigin( bot:WorldSpaceCenter() )
    effectData:SetRadius( math.Clamp( height * 1.5, 40, 300 ) )
    util.Effect( "eff_zambspirit_summon", effectData, true, true )
end

-- Plays the rays beam from the spirit's chest to where the zambie lands.
local function FireDeployEffectAt( spirit, targetPos )
    local chestBone = spirit:LookupBone( "ValveBiped.Bip01_Spine4" ) or spirit:LookupBone( "ValveBiped.Bip01_Spine2" )

    local origin = spirit:WorldSpaceCenter()
    if chestBone and chestBone ~= -1 then
        origin = spirit:GetBonePosition( chestBone )
    end

    local effectData = EffectData()
    effectData:SetOrigin( targetPos )
    effectData:SetStart( origin )
    util.Effect( "eff_zambspirit_rays", effectData, true, true )
end

-- Turns off a bot's fall damage for a moment, then puts back ITS OWN values.
-- Classes differ ( blastcrabs take none at all, for example ), so we can't restore a one-size-fits-all default.
local function ProtectFromFallDamage( bot )
    -- Already protected by an earlier summon, so the values we'd save now are the temporary ones
    if bot.zamb_SpiritSavedFallDamage then return end

    bot.zamb_SpiritSavedFallDamage = {
        takesFallDamage = bot.TakesFallDamage,
        heightToStart = bot.HeightToStartTakingDamage,
        perHeight = bot.FallDamagePerHeight,
        deathDropHeight = bot.DeathDropHeight,
    }

    bot.TakesFallDamage = false
    bot.HeightToStartTakingDamage = 99999
    bot.FallDamagePerHeight = 0
    bot.DeathDropHeight = 99999

    timer.Simple( FALL_PROTECT_TIME, function()
        if not IsValid( bot ) then return end

        local saved = bot.zamb_SpiritSavedFallDamage
        bot.zamb_SpiritSavedFallDamage = nil
        if not saved then return end

        bot.TakesFallDamage = saved.takesFallDamage
        bot.HeightToStartTakingDamage = saved.heightToStart
        bot.FallDamagePerHeight = saved.perHeight
        bot.DeathDropHeight = saved.deathDropHeight
    end )
end

-- Teleports a zambie from where it is to targetPos, next to the spirit.
local function TeleportZambieTo( bot, targetPos, enemy, spirit )
    -- Effect at where it WAS
    FireSummonEffectAt( bot )

    bot:SetVelocity( vector_origin )
    ProtectFromFallDamage( bot )

    bot:SetPos( targetPos )
    if bot.loco and bot.loco.SetGroundEntity then
        bot.loco:SetGroundEntity( Entity( 0 ) )
    end

    -- Land facing the enemy
    if IsValid( enemy ) then
        local faceAngle = ( enemy:GetPos() - targetPos ):Angle()
        faceAngle.p = 0
        faceAngle.r = 0
        bot:SetAngles( faceAngle )
    end

    bot:ReallyAnger( 60 )

    -- Effect at where it WILL BE
    FireDeployEffectAt( spirit, targetPos )
end

ENT.MyClassTask = {
    OnDamaged = function( self, _data, damageInfo )
        if self:GetIsDying() then return true end

        -- Spirits are frail up close, and shrug off weak hits
        local isMelee = bit.band( damageInfo:GetDamageType(), bit.bor( DMG_SLASH, DMG_CLUB ) ) > 0
        if isMelee then
            damageInfo:ScaleDamage( 2.2 )
        elseif damageInfo:GetDamage() < 25 then
            damageInfo:ScaleDamage( 0.2 )
        end
    end,

    PreventBecomeRagdollOnKilled = function( self, _data, damageInfo )
        if self:GetIsDying() then return true, true end

        -- Carry the hit's direction into the death, a gentle shove
        local shove = damageInfo:GetDamageForce():GetNormalized() * 120
        self:SpiritDeath( shove )

        return true, true
    end,

    DisableBehaviour = function( self, _data )
        return self:GetIsDying()
    end,

    -- AI only, the base skips this while a player drives. Players use the "call" action instead.
    BehaveUpdatePriority = function( self, _data )
        if self:GetIsDying() then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end

        local enemyPos = enemy:GetPos()
        local distSqr = enemyPos:DistToSqr( self:GetPos() )

        -- Too close to the enemy, run
        local fleeDistance = self.DeployDistance / 2
        if distSqr < fleeDistance ^ 2 then
            FleeFrom( self, enemyPos )
            return
        end

        -- Within range with the enemy in sight, pull in zambies from afar
        if not self.IsSeeEnemy then return end
        if distSqr >= self.DeployDistance ^ 2 then return end
        if not self:CanTakeAction( "call" ) then return end

        self:TakeAction( "call" )
    end,
}

-- Whether the spirit may teleport this zambie.
function ENT:CanSummonTarget( target )
    if not IsValid( target ) then return false end
    if target == self then return false end
    if target:GetClass() == SPIRIT_CLASS then return false end
    if not string.StartWith( target:GetClass(), ZAMBIE_PREFIX ) then return false end
    if IsPlayerDriven( target ) then return false end
    if target:Health() <= 0 then return false end
    if IsValid( target:GetParent() ) then return false end
    if ( target:GetModelScale() or 1 ) > MAX_CARRY_SCALE then return false end
    if target:GetMaxHealth() > MAX_CARRY_HEALTH then return false end

    return true
end

-- Picks up to count zambies that are far from enemyPos.
function ENT:FindSummonCandidates( enemyPos, count )
    local candidates = {}
    local minDistSqr = self.MinGrabDist ^ 2

    for _, ally in pairs( self:GetNearbyAllies() or {} ) do
        if not self:CanSummonTarget( ally ) then continue end
        if ally:GetPos():DistToSqr( enemyPos ) < minDistSqr then continue end

        table.insert( candidates, ally )
        if #candidates >= count then break end
    end

    return candidates
end

-- Finds spots near the spirit, leaning towards the enemy, for summoned zambies to land on.
function ENT:FindDeployPositions( enemyPos, count )
    local positions = {}

    -- Try a few distances along the line to the enemy, until a ring has room for all of them
    for i = 1, 4 do
        local lerpFrac = 0.5 - ( ( i - 1 ) / 3 ) * 0.3
        local deployCenter = LerpVector( lerpFrac, self:WorldSpaceCenter(), enemyPos )
        local radius = math.random( 75, 125 )

        local vectors, foundAll = PackSquadVectors( deployCenter, count, radius )
        if foundAll then return vectors end

        -- Remember the best attempt so far
        if #vectors > #positions then
            positions = vectors
        end
    end

    return positions
end

-- Teleports up to targetCount zambies, from far away from enemyPos, to next to the spirit.
function ENT:SummonZambies( enemyPos, targetCount )
    local positions = self:FindDeployPositions( enemyPos, targetCount )
    if #positions == 0 then return end

    local candidates = self:FindSummonCandidates( enemyPos, targetCount )
    if #candidates == 0 then return end

    local enemy = self:GetEnemy()
    local toSummon = math.min( #candidates, #positions )

    for i = 1, toSummon do
        TeleportZambieTo( candidates[i], positions[i] + SUMMON_HEIGHT_OFFSET, enemy, self )
    end

    self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 100, 1 )
end

-- The spirit fakes its death.
-- The real death is cancelled ( PreventBecomeRagdollOnKilled ), so there's never a ragdoll or corpse.
-- Instead it goes non-solid, plays the death visuals, and is removed once they're done.
function ENT:SpiritDeath( shove )
    if self:GetIsDying() then return end

    self:SetIsDying( true )
    self:SetDeathTime( CurTime() )

    -- Stop moving, become non-solid and untargetable straight away
    self:StopMoving()
    self:SetSolid( SOLID_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    self:SetMoveType( MOVETYPE_FLY )
    self:AddFlags( FL_NOTARGET )
    self:SetVelocity( vector_origin )

    -- On death, do a final summon burst from far away
    local enemy = self:GetEnemy()
    local summonPos = IsValid( enemy ) and enemy:GetPos() or self:GetPos()
    self:SummonZambies( summonPos, math.random( 2, 4 ) )

    local effectData = EffectData()
    effectData:SetMagnitude( 1.5 )
    effectData:SetOrigin( self:WorldSpaceCenter() )
    effectData:SetRadius( 78 )
    effectData:SetNormal( self:GetAngles():Up() )
    effectData:SetFlags( 2 )
    util.Effect( "eff_zambspirit_blast", effectData )
    self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 170, 1 )

    if isvector( shove ) then
        self:SetVelocity( shove )
    end

    -- Still drawn, the client plays its trail and sprite fade while IsDying is set. The model itself is hidden by then.
    SafeRemoveEntityDelayed( self, DEATH_VISUAL_TIME )
end

if SERVER then
    function ENT:AdditionalInitialize()
        BaseClass.AdditionalInitialize( self )
        self:SetBodygroup( 1, 0 )
    end
end

if CLIENT then
    ENT.mat = Material( "effects/strider_muzzle" )
    ENT.mat_trail = Material( "trails/plasma" )

    local TRAIL_BONE_NAMES = {
        "ValveBiped.Bip01_L_Calf",
        "ValveBiped.Bip01_R_Calf",
        "ValveBiped.Bip01_L_Hand",
        "ValveBiped.Bip01_R_Hand",
    }

    -- Reused for every trail segment, Color() allocates
    local trailColor = Color( 255, 0, 0 )

    local RED_OVERBRIGHT = 700

    function ENT:AdditionalClientInitialize()
        if BaseClass.AdditionalClientInitialize then
            BaseClass.AdditionalClientInitialize( self )
        end

        self.trailLength = 16
        self.trailBones = {}
        self.trails = {}

        -- Skip any bone this model doesn't have
        for _, boneName in ipairs( TRAIL_BONE_NAMES ) do
            local bone = self:LookupBone( boneName )
            if not bone then continue end

            table.insert( self.trailBones, bone )
            self.trails[ #self.trailBones ] = {}
        end
    end

    function ENT:Think()
        BaseClass.Think( self )
        self:RemoveAllDecals()

        -- Not set up yet
        if not self.trailBones then return end

        self:SetNextClientThink( CurTime() + 1 / self.trailLength )

        if FrameTime() <= 0 then return true end

        local myPos = self:WorldSpaceCenter()
        local dying = self:GetIsDying()
        local elapsed = CurTime() - self:GetDeathTime()
        local deathFrac = dying and math.ease.InCubic( math.max( 0, 1 - elapsed / DEATH_VISUAL_TIME ) ) or 1
        local myX, myY, myZ = myPos:Unpack()

        -- Record where each trail bone is, new points at the front. On death the trails pull in to the center.
        for i, bone in ipairs( self.trailBones ) do
            local bonePos = self:GetBonePosition( bone )
            if not bonePos then continue end

            local boneX, boneY, boneZ = bonePos:Unpack()
            bonePos:SetUnpacked(
                Lerp( 1 - deathFrac, boneX, myX ),
                Lerp( 1 - deathFrac, boneY, myY ),
                Lerp( 1 - deathFrac, boneZ, myZ )
            )

            local trail = self.trails[ i ]
            table.insert( trail, 1, bonePos )
            if trail[ self.trailLength ] then
                trail[ self.trailLength ] = nil
            end
        end

        return true
    end

    function ENT:DrawTranslucent( _flags )
        if render.GetRenderTarget() then return end
        if not self.trails then return end

        local myPos = self:WorldSpaceCenter()
        local eyePos = EyePos()
        local distToEyes = eyePos:DistToSqr( myPos )
        local time = CurTime()
        local dying = self:GetIsDying()
        local elapsed = time - self:GetDeathTime()
        local deathFrac = dying and math.ease.InCubic( math.max( 0, 1 - elapsed / DEATH_VISUAL_TIME ) ) or 1
        local blastFrac = dying and math.max( 0, 1 - elapsed * 5 ) or 0

        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        -- Trails, skipped when the framerate is already struggling
        if GetFPSEstimate() > 30 then
            render.SetMaterial( self.mat_trail )

            for _, trailVectors in ipairs( self.trails ) do
                local count = #trailVectors
                if count < 2 then continue end

                render.StartBeam( count )
                for j, point in ipairs( trailVectors ) do
                    local along = ( j - 1 ) / ( count - 1 )
                    trailColor.r = 255 * ( 1 - along )
                    render.AddBeam( point, 7 * deathFrac * ( 1 - along ), along * 4, trailColor )
                end
                render.EndBeam()
            end
        end

        -- The body, hidden once dying so only the trails and sprite are left
        if not dying then
            -- Red is multiplied far past 1 on purpose, so the model saturates to a pure red glow.
            -- Don't "fix" this to 0.7, that drops red below green and blue and the model fades to cyan.
            render.SetColorModulation( RED_OVERBRIGHT, 1, 1 )
            self:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        end

        -- Spinning red sigil, only when close enough to see it
        if distToEyes < 3250 ^ 2 then
            surface.SetMaterial( self.mat )
            surface.SetAlphaMultiplier( 1 )
            surface.SetDrawColor( 255 * deathFrac, 0, 0, 255 * deathFrac )

            local facing = ( myPos - eyePos ):Angle()
            facing:RotateAroundAxis( facing:Right(), 90 )

            for i = 1, 4 do
                local cycle = ( time + i / 4 ) % 1
                local size = ( 72 - cycle * 32 ) * deathFrac

                cam.Start3D2D( myPos, facing, 1 + blastFrac * i )
                surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * i * 360 )
                cam.End3D2D()
            end
        end

        render.OverrideBlend( false )
    end
end
