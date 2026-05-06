AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Spirit"
ENT.Author    = "Octantis Addons"
ENT.Category  = "Map Sweepers"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

list.Set( "NPC", "terminator_nextbot_zambiespirit", {
    Name     = "Zombie Spirit",
    Class    = "terminator_nextbot_zambiespirit",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiespirit", ENT.PrintName )
end

local ZOMBIE_COLOR      = Color( 100, 180, 100 )
local ZAMBIE_PREFIX     = "terminator_nextbot_zambie"
local ZAMBIE_PREFIX_LEN = #ZAMBIE_PREFIX

-- Maximum model scale a target zambie may have to be eligible for carrying. Entities scaled above 1.15 are excluded so the spirit targets only roughly human-scale or smaller zambies.
local MAX_CARRY_SCALE  = 1.15

-- Maximum *max* health a target may have to be eligible for carrying. Checked via GetMaxHealth() rather than Health(), so a heavily damaged elite is still excluded. Keeps the spirit from carrying boss-tier zambies.
local MAX_CARRY_HEALTH = 250

-- Finds up to `count` valid nav positions distributed around a circle of `radius` units centred on `center`. Candidates are snapped to the nav mesh and must be at least 40% of `radius` apart from any already accepted position. Returns (positions, filled) where filled is true when `count` positions were successfully placed (not a guarantee of good spread).
local function PackSquadVectors( center, count, radius )
    local results   = {}
    -- Six attempts per slot provides slack for nav-mesh misses and spacing rejections. On very sparse nav meshes fewer than `count` may still be placed even with this headroom.
    local attempts  = count * 6
    local angleStep = ( math.pi * 2 ) / attempts

    for i = 0, attempts - 1 do
        if #results >= count then break end

        -- Candidate position on the perimeter of the circle
        local angle     = i * angleStep
        local candidate = center + Vector( math.cos( angle ) * radius, math.sin( angle ) * radius, 0 )

        -- Snap to the nearest nav area within 128 units; skip if none found.
        -- The 128 unit radius limits how far a candidate can drift from the circle.
        local area = navmesh.GetNearestNavArea( candidate, false, 128 )
        if not area then continue end

        local snapped = area:GetClosestPointOnArea( candidate )

        -- Reject positions that are too close to one already accepted,
        -- so the squad spreads out rather than bunching at one spot
        local tooClose = false
        for _, v in ipairs( results ) do
            if v:DistToSqr( snapped ) < ( radius * 0.4 ) ^ 2 then
                tooClose = true
                break
            end
        end

        if not tooClose then
            table.insert( results, snapped )
        end
    end

    return results, #results >= count
end

local function GetFPSEstimate()
    local ft = FrameTime()
    if ft <= 0 then return 60 end
    return 1 / ft
end

-- Wraps GotoPosSimple with a nav area pre-check and pcall. The pre-check
-- handles the common case; pcall guards against the base's internal
-- NearestPoint error when an area becomes invalid between the check and
-- the call.
local function SafeGoto( bot, pos )
    if not isvector( pos ) then return end
    local area = navmesh.GetNearestNavArea( pos, false, 512 )
    if not area then return end
    local snapped = area:GetClosestPointOnArea( pos )
    if not isvector( snapped ) then return end
    pcall( bot.GotoPosSimple, bot, snapped )
end

function ENT:SetupDataTables()
    if BaseClass.SetupDataTables then
        BaseClass.SetupDataTables( self )
    end
    self:NetworkVar( "Bool",  10, "IsDying" )
    self:NetworkVar( "Float", 10, "DeathTime" )
    self:NetworkVar( "Int",   10, "CarriedNPCCount" )
end

if SERVER then
    function ENT:AdditionalInitialize()
        BaseClass.AdditionalInitialize( self )
        self:SetBodygroup( 1, 0 )
    end
end

ENT.GiveShieldRegen      = 7
ENT.GiveShieldRegenDelay = 3
ENT.DeployDistance       = 1000
ENT.GrabDistance         = 666
ENT.GiveShieldDistance   = 666
ENT.MinGrabDist          = 1500

ENT.MyClassTask = {

    OnCreated = function( self, data )
        data.npcCarryGoal  = math.random( 3, 5 )
        data.wantToCarry   = true
        data.carryCooldown = 0
        data.nextMove      = 0
    end,

    OnDamaged = function( self, data, dmg )
        if self:GetIsDying() then return true end

        local melee  = bit.band( dmg:GetDamageType(), bit.bor( DMG_SLASH, DMG_CLUB ) ) > 0
        local damage = dmg:GetDamage()

        if melee then
            damage = damage * 2.2
        elseif damage < 25 then
            damage = damage * 0.2
        end

        self:SetHealth( self:Health() - damage )

        if self:Health() <= 0 then
            self:SetHealth( 1 )
            local v   = dmg:GetDamageForce()
            local len = v:Length()
            if len > 0 then
                v:Div( len )
                v:Mul( 120 )
            end
            self:SpiritDeath( dmg:GetAttacker(), dmg:GetInflictor(), v )
        else
            local v = self:GetVelocity()
            v.z = v.z + 2
            v:Mul( 2.5 )
            self:SetVelocity( v )
        end

        return true
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        if IsValid( ragdoll ) then ragdoll:Remove() end
    end,

    PreventBecomeRagdollOnKilled = function( self, data, dmg )
        return true, true
    end,

    DisableBehaviour = function( self, data )
        return self:GetIsDying()
    end,

    BehaveUpdatePriority = function( self, data )
        if self:GetIsDying() then return end

        -- If carrying NPCs and close enough to the enemy, stop looking for more
        if data.wantToCarry and self:GetCarriedNPCCount() > 0 then
            local enemy = self:GetEnemy()
            if IsValid( enemy ) then
                local enemyPos = enemy:GetPos()
                if isvector( enemyPos ) and enemyPos:DistToSqr( self:GetPos() ) < self.GrabDistance ^ 2 then
                    data.wantToCarry = false
                end
            end
        end

        local enemy = self:GetEnemy()
        if IsValid( enemy ) then
            local selfPos  = self:GetPos()
            local enemyPos = enemy:GetPos()

            if not isvector( selfPos ) or not isvector( enemyPos ) then return end

            local dist2 = enemyPos:DistToSqr( selfPos )

            -- Too close to the enemy: flee rather than carry
            if dist2 < ( self.DeployDistance / 2 ) ^ 2 then
                local diff    = selfPos - enemyPos
                local diffLen = diff:Length()
                if diffLen > 1 then
                    diff:Div( diffLen )
                    diff:Mul( 512 )
                    local fleeTarget = selfPos + diff
                    local fleeArea   = navmesh.GetNearestNavArea( fleeTarget, false, 512 )
                    if fleeArea then
                        SafeGoto( self, fleeArea:GetClosestPointOnArea( fleeTarget ) )
                    end
                end
                return
            end

            -- Within deploy range, enemy visible (IsSeeEnemy encodes recency;
            -- GetEnemyLastTimeSeen is not provided by the base): deploy carried zambies.
            if self:GetCarriedNPCCount() > 0 then
                if self.IsSeeEnemy and dist2 < self.DeployDistance ^ 2 then
                    if not data.carryCooldown or CurTime() > data.carryCooldown then
                        self:DeployNPCs( enemyPos )
                        data.carryCooldown = CurTime() + 5
                        data.wantToCarry   = true
                    end
                end
            end
        end

        -- Grab nearby eligible zambies while under the carry goal
        if data.wantToCarry and ( not data.carryCooldown or CurTime() > data.carryCooldown ) then
            -- GetNearbyAllies is assumed cheaper than ents.FindInSphere + faction
            -- filter; the base maintains ally lists internally.
            for _, npc in ipairs( self:GetNearbyAllies( self.GrabDistance ) ) do
                if not self:IsGoodGrabTarget( npc ) then continue end
                if not self:Visible( npc ) then continue end

                local npcEnemy     = npc:GetEnemy()
                local farFromEnemy = not IsValid( npcEnemy )
                    or npcEnemy:GetPos():DistToSqr( npc:GetPos() ) > self.MinGrabDist ^ 2
                if not farFromEnemy then continue end

                self:CarryNPC( npc )
                data.carryCooldown = CurTime() + 0.25
                break
            end

            if self:GetCarriedNPCCount() >= data.npcCarryGoal then
                data.wantToCarry   = false
                data.carryCooldown = CurTime() + 1
            end
        end
    end,

    BehaveUpdateMotion = function( self, data )
        if self:GetIsDying() then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then
            data.wantToCarry = true
            return
        end

        local enemyPos = enemy:GetPos()
        local selfPos  = self:GetPos()

        if not isvector( enemyPos ) or not isvector( selfPos ) then return end
        if selfPos:DistToSqr( enemyPos ) < ( self.DeployDistance / 2 ) ^ 2 then return end

        if not data.wantToCarry then
            if self:GetCarriedNPCCount() <= 0 then
                data.wantToCarry = true
            end
            return
        end

        local canMove   = CurTime() > ( data.nextMove or 0 )
        local bestDist2 = self.MinGrabDist ^ 2
        local furthest
        local furthestPos

        for _, npc in ipairs( ents.FindByClass( "terminator_nextbot_zambie*" ) ) do
            if not self:IsGoodGrabTarget_Optimised( npc ) then continue end
            local npcPos = npc:GetPos()
            if not isvector( npcPos ) then continue end
            local dist2 = npcPos:DistToSqr( enemyPos )
            if dist2 > bestDist2 then
                furthest    = npc
                furthestPos = npcPos
                bestDist2   = dist2
            end
        end

        if IsValid( furthest ) and isvector( furthestPos ) then
            if canMove or furthestPos:DistToSqr( selfPos ) >= ( self.GrabDistance / 2 ) ^ 2 then
                local gotoPos = furthest:GetPos()
                if isvector( gotoPos ) then
                    SafeGoto( self, gotoPos )
                    data.nextMove = CurTime() + 5
                end
            end
        else
            data.wantToCarry = false
        end
    end,

    -- Called by DeployNPCs when all carried zambies are released. Re-randomises
    -- the carry goal (3–6, vs. the initial 3–5) so subsequent carry runs vary
    -- slightly in squad size.
    OnDeployComplete = function( self, data )
        data.npcCarryGoal = math.random( 3, 6 )
    end,

}

ENT.MySpecialActions = {
    [ "call" ] = {
        name      = "Pick Up Zambie",
        desc      = "Grabs a nearby eligible zambie and carries it",
        inBind    = IN_RELOAD,
        drawHint  = true,
        ratelimit = 0.5,
        svAction  = function( driveController, driver, bot )
            -- Search for the closest eligible zambie within grab range
            local bestNPC  = nil
            local bestDist = bot.GrabDistance ^ 2
            local botPos   = bot:GetPos()

            for _, npc in ipairs( bot:GetNearbyAllies( bot.GrabDistance ) ) do
                if not bot:IsGoodGrabTarget( npc ) then continue end
                local d = npc:GetPos():DistToSqr( botPos )
                if d < bestDist then
                    bestDist = d
                    bestNPC  = npc
                end
            end

            if IsValid( bestNPC ) then
                bot:CarryNPC( bestNPC )
            end
        end,
    },

    -- Releases all carried zambies toward the current enemy.
    -- IN_ATTACK2 so it doesn't conflict with any inherited primary-fire action.
    [ "Deploy" ] = {
        name      = "Deploy Carried",
        desc      = "Releases all carried zambies toward the current enemy",
        inBind    = IN_ATTACK2,
        drawHint  = true,
        ratelimit = 3,
        svAction  = function( driveController, driver, bot )
            local enemy = bot:GetEnemy()
            bot:DeployNPCs( IsValid( enemy ) and enemy:GetPos() or nil )
        end,
    },
}

-- Returns true if `target` is a zambie the spirit may carry.
-- Uses guard clauses (early returns) rather than a single nested condition.
-- Exclusion of large/boss zambies is dynamic via scale and max-health checks
-- rather than a hardcoded class list cause straw didnt like it so new zambie types are handled automatically.
function ENT:IsGoodGrabTarget( target )
    if not IsValid( target ) then return false end
    if string.sub( target:GetClass(), 1, ZAMBIE_PREFIX_LEN ) ~= ZAMBIE_PREFIX then return false end
    if target == self then return false end
    if target:Health() <= 0 then return false end
    if IsValid( target:GetParent() ) then return false end
    if target:GetMoveType() <= MOVETYPE_NONE then return false end
    if ( target:GetModelScale() or 1 ) > MAX_CARRY_SCALE then return false end
    if target:GetMaxHealth() > MAX_CARRY_HEALTH then return false end
    return true
end

function ENT:IsGoodGrabTarget_Optimised( target )
    if not IsValid( target ) then return false end
    if target == self then return false end
    if target:Health() <= 0 then return false end
    if IsValid( target:GetParent() ) then return false end
    if ( target:GetModelScale() or 1 ) > MAX_CARRY_SCALE then return false end
    if target:GetMaxHealth() > MAX_CARRY_HEALTH then return false end
    return true
end

function ENT:SpiritDeath( attacker, inflictor, forceVec )
    if self:GetIsDying() then return end

    -- Set dying immediately so nothing else can re-trigger this
    self:SetIsDying( true )
    self:SetDeathTime( CurTime() )

    self:DeployNPCs()

    local ed = EffectData()
    ed:SetMagnitude( 1.5 )
    ed:SetOrigin( self:WorldSpaceCenter() )
    ed:SetRadius( 78 )
    ed:SetNormal( self:GetAngles():Up() )
    ed:SetFlags( 2 )
    util.Effect( "eff_zambspirit_blast", ed )

    self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 170, 1 )

    hook.Call( "OnNPCKilled", GAMEMODE, self, attacker, inflictor )

    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    self:SetMoveType( MOVETYPE_FLY )
    self:SetVelocity( Vector( 0, 0, 0 ) )
    self:SetNoDraw( true )

    if isvector( forceVec ) then
        self:SetVelocity( forceVec )
    end

    local ent = self
    timer.Simple( 0.1, function()
        if IsValid( ent ) then ent:Remove() end
    end )
end

function ENT:CarryNPC( npc )
    local ed = EffectData()
    ed:SetFlags( 2 )
    ed:SetEntity( self )
    ed:SetOrigin( npc:WorldSpaceCenter() )
    util.Effect( "eff_zambspirit_rays", ed )

    -- NOTE: parenting is load-bearing; DeployNPCs enumerates carried zambies
    -- via self:GetChildren(), which only works because of this SetParent call.
    -- CarriedNPCCount tracks the count separately for networking but is not
    -- the source of truth for which entities to deploy.
    npc:SetParent( self )
    npc:SetPos( self:GetPos() )
    npc:SetNoDraw( true )
    self:SetCarriedNPCCount( self:GetCarriedNPCCount() + 1 )
    self:EmitSound( "npc/advisor/advisor_blast1.wav", 100, 100, 1 )
end

function ENT:DeployNPCs( pos )
    -- Collect all valid children (the carried zambies)
    local toDeploy = {}
    for _, ent in ipairs( self:GetChildren() ) do
        if IsValid( ent ) and ent:Health() > 0 then
            table.insert( toDeploy, ent )
        end
    end

    if #toDeploy == 0 then return end

    -- When a target position is provided we try to find the best cluster of nav
    -- positions along the path between us and that target. We attempt four
    -- interpolation fractions and keep whichever attempt fits the most zambies.
    -- When no position is given (spirit died away from combat) we scatter nearby.
    local mostVectors

    if isvector( pos ) then
        for i = 1, 4 do
            local lerpFrac     = math.Remap( i, 1, 4, 0.5, 0.2 )
            local deployCenter = LerpVector( lerpFrac, self:WorldSpaceCenter(), pos )
            local radius       = math.random( 75, 125 )

            local vectors, fully = PackSquadVectors( deployCenter, #toDeploy, radius )

            if fully or not mostVectors or #vectors > #mostVectors then
                mostVectors = vectors
                if fully then break end
            end
        end
    else
        local vectors = PackSquadVectors( self:WorldSpaceCenter(), #toDeploy, math.random( 150, 200 ) )
        mostVectors   = vectors
    end

    if not mostVectors or #mostVectors == 0 then return end

    local upVec    = Vector( 0, 0, 10 )
    local deployed = 0

    for i, v in ipairs( mostVectors ) do
        deployed = deployed + 1

        local ent = toDeploy[ i ]
        ent:SetParent()
        ent:SetPos( v + upVec )
        ent:SetNoDraw( false )

        -- Face the deployed zambie toward the known enemy if we have one,
        -- then anger it so it immediately starts pursuing on its own.
        local foe = self:GetEnemy()
        if IsValid( foe ) then
            local foePos    = foe:GetPos()
            local faceAngle = ( foePos - v ):Angle()
            faceAngle.p = 0
            faceAngle.r = 0
            ent:SetAngles( faceAngle )
        end

        ent:ReallyAnger( 30 )

        local filter = RecipientFilter()
        filter:AddPVS( self:WorldSpaceCenter() )
        filter:AddPVS( ent:WorldSpaceCenter() )

        local ed = EffectData()
        ed:SetFlags( 2 )
        ed:SetEntity( self )
        ed:SetOrigin( ent:WorldSpaceCenter() )
        util.Effect( "eff_zambspirit_rays", ed, true, filter )
    end

    self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 100, 1 )

    local remaining = #toDeploy - deployed
    self:SetCarriedNPCCount( remaining )

    -- Notify the class task so it can reset the carry goal for the next run
    if remaining == 0 then
        local taskData = self:GetTable().MyClassTask
        if taskData and taskData.OnDeployComplete then
            taskData.OnDeployComplete( self, taskData )
        end
    end
end

if CLIENT then
    ENT.mat       = Material( "effects/strider_muzzle" )
    ENT.mat_trail = Material( "trails/plasma" )

    function ENT:Initialize()
        BaseClass.Initialize( self )

        self.trailLength = 16
        self.trailBones  = {
            self:LookupBone( "ValveBiped.Bip01_L_Calf" ),
            self:LookupBone( "ValveBiped.Bip01_R_Calf" ),
            self:LookupBone( "ValveBiped.Bip01_L_Hand" ),
            self:LookupBone( "ValveBiped.Bip01_R_Hand" ),
        }

        self.trails = {}
        for i = 1, #self.trailBones do
            self.trails[ i ] = {}
        end
    end

    function ENT:Think()
        BaseClass.Think( self )

        -- Keep the entity clean; decals accumulate on translucent models
        self:RemoveAllDecals()

        if FrameTime() > 0 then
            local mypos     = self:WorldSpaceCenter()
            local dying     = self:GetIsDying()
            local elapsed   = CurTime() - self:GetDeathTime()
            -- deathfrac drives the trail collapse animation when dying
            local deathfrac = dying and math.ease.InCubic( math.max( 0, 1 - elapsed / 1.5 ) ) or 1
            local myX, myY, myZ = mypos:Unpack()

            for i, bid in ipairs( self.trailBones ) do
                local tt      = self.trails[ i ]
                local bonePos = self:GetBonePosition( bid )
                local bx, by, bz = bonePos:Unpack()
                -- Lerp the trail point toward the body centre when dying
                bonePos:SetUnpacked(
                    Lerp( 1 - deathfrac, bx, myX ),
                    Lerp( 1 - deathfrac, by, myY ),
                    Lerp( 1 - deathfrac, bz, myZ )
                )

                table.insert( tt, 1, bonePos )
                if tt[ self.trailLength ] then
                    tt[ self.trailLength ] = nil
                end
            end
        end

        self:SetNextClientThink( CurTime() + 1 / self.trailLength )
        return true
    end

    function ENT:DrawTranslucent( flags )
        if render.GetRenderTarget() then return end

        local mypos      = self:WorldSpaceCenter()
        local eyePos     = EyePos()
        local distToEyes = eyePos:DistToSqr( mypos )

        local time      = CurTime()
        local dying     = self:GetIsDying()
        local elapsed   = time - self:GetDeathTime()
        local deathfrac = dying and math.ease.InCubic( math.max( 0, 1 - elapsed / 1.5 ) ) or 1
        local blastfrac = dying and math.max( 0, 1 - elapsed * 5 ) or 0

        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        -- Limb trails: four smoky plasma beams that follow the hands and feet.
        -- Skipped on low-end hardware to save beam overhead.
        if GetFPSEstimate() > 30 then
            render.SetMaterial( self.mat_trail )
            for i, trailVectors in ipairs( self.trails ) do
                local n = #trailVectors
                if n < 2 then continue end
                render.StartBeam( n )
                for j, v in ipairs( trailVectors ) do
                    local f = ( j - 1 ) / ( n - 1 )
                    render.AddBeam( v, 7 * deathfrac * ( 1 - f ), f * 4, Color( 255 * ( 1 - f ), 0, 0 ) )
                end
                render.EndBeam()
            end
        end

        -- Body: the spirit model with a colour-shift flicker to give it an ethereal feel.
        -- Hidden once the dying animation begins since the body has already been SetNoDraw.
        if not dying then
            local colormod = math.sin( time * 4 + self:EntIndex() ) * 0.5 + 700
            render.SetColorModulation( colormod, 1, 1 )
            self:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        end

        -- Energy rings: rotating sprite quads near the spirit, visible within ~3250 units.
        -- Expand outward on death via blastfrac.
        if distToEyes < 3250 ^ 2 then
            surface.SetMaterial( self.mat )
            surface.SetAlphaMultiplier( 1 )
            surface.SetDrawColor( 255 * deathfrac, 0, 0, 255 * deathfrac )
            local a = ( mypos - eyePos ):Angle()
            a:RotateAroundAxis( a:Right(), 90 )
            for i = 1, 4 do
                cam.Start3D2D( mypos, a, 1 + blastfrac * i )
                local ti   = ( time + i / 4 ) % 1
                local size = ( 72 - ti * 32 ) * deathfrac
                surface.DrawTexturedRectRotated( 0, 0, size, size, ti / 4 * i * 360 )
                cam.End3D2D()
            end
        end

        -- Carried-NPC orbs: one glowing sprite per carried zambie, orbiting the spirit.
        -- Visible within ~2000 units.
        if distToEyes < 2000 ^ 2 then
            local orbcount = self:GetCarriedNPCCount()
            if orbcount > 0 then
                local angShift = math.pi * 2 / orbcount
                for i = 1, orbcount do
                    local a    = ( i + time % 1 ) * angShift
                    local orbV = mypos + Vector( math.cos( a ) * 32, math.sin( a ) * 32, -8 )
                    local size = 64 * deathfrac + blastfrac * 4
                    render.DrawSprite( orbV, size, size, ZOMBIE_COLOR )
                end
            end
        end

        render.OverrideBlend( false )
    end
end