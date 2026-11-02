-- Thanks to MerekiDor and JonahSoldier the creators of Map Sweepers for allowing this!
-- Keeps its distance, and teleports far off zambies in between itself and its enemy.
-- Needs terminator-hunter's movement_gotoarea task.
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Spirit"
ENT.Author    = "Map Sweepers + regunkyle"
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

ENT.zamb_IsSpirit = true -- spirits never summon each other

local MAX_CARRY_HEIGHT = 75 -- a grunt is 65 tall
local MAX_CARRY_HEALTH = 250
local DEATH_FADE_TIME  = 1.5 -- the client's dying trails and sprite fade over this long

-- the base uses DT slots directly, low slot numbers are taken
function ENT:SetupDataTables()
    self:NetworkVar( "Bool",  10, "IsDying" )
    self:NetworkVar( "Float", 10, "DeathTime" )

end

ENT.DeployDistance = 1000 -- summons when its enemy is closer than this, backs off when they're closer than half

if SERVER then
    -- Finds up to count spots on the navmesh, spaced around a circle.
    -- Returns the spots, and whether it found all of them.
    local function PackSquadVectors( center, count, radius )
        local results   = {}
        local attempts  = count * 6
        local angleStep = ( math.pi * 2 ) / attempts
        local minSpacingSqr = ( radius * 0.4 ) ^ 2

        for i = 0, attempts - 1 do
            if #results >= count then break end

            local angle     = i * angleStep
            local candidate = center + Vector( math.cos( angle ) * radius, math.sin( angle ) * radius, 0 )
            local area = navmesh.GetNearestNavArea( candidate, false, 128 )
            if not area then continue end

            local snapped = area:GetClosestPointOnArea( candidate )
            local tooClose = false
            for _, taken in ipairs( results ) do
                if taken:DistToSqr( snapped ) < minSpacingSqr then
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

    local function FireSummonEffectAt( ent )
        local mins, maxs = ent:GetCollisionBounds()
        local height = maxs.z - mins.z

        local ed = EffectData()
        ed:SetOrigin( ent:WorldSpaceCenter() )
        ed:SetRadius( math.Clamp( height * 1.5, 40, 300 ) )
        util.Effect( "eff_zambspirit_summon", ed, true, true )

    end

    -- Rays from the spirit's chest to where the zambie lands
    local function FireDeployEffectAt( spirit, targetPos )
        local chestBone = spirit:LookupBone( "ValveBiped.Bip01_Spine4" ) or spirit:LookupBone( "ValveBiped.Bip01_Spine2" )
        local origin = spirit:WorldSpaceCenter()
        if chestBone then
            origin = spirit:GetBonePosition( chestBone )

        end

        local ed = EffectData()
        ed:SetOrigin( targetPos )
        ed:SetStart( origin )
        util.Effect( "eff_zambspirit_rays", ed, true, true )

    end

    local function TeleportZambieTo( ent, targetPos, faceTowards, spirit )
        FireSummonEffectAt( ent )

        -- the base measures fall damage from jumpingPeak, so the teleport doesn't count as a fall
        ent.jumpingPeak = targetPos
        ent:SetPosNoTeleport( targetPos )
        ent.loco:SetVelocity( vector_origin )
        ent:InvalidatePath( "a spirit teleported me" )

        if faceTowards then
            local faceAngle = ( faceTowards - targetPos ):Angle()
            faceAngle.p = 0
            faceAngle.r = 0
            ent:SetAngles( faceAngle )
        end
        ent:ReallyAnger( 60 )

        FireDeployEffectAt( spirit, targetPos )

    end

    function ENT:CanSummon( ally )
        if not IsValid( ally ) then return false end
        if ally.zamb_IsSpirit then return false end
        if ally:Health() <= 0 then return false end
        if IsValid( ally:GetParent() ) then return false end
        -- standing bounds, the live OBB shrinks while crouched
        local bounds = ally.CollisionBounds
        if bounds and bounds[2].z - bounds[1].z > MAX_CARRY_HEIGHT then return false end
        if ally:GetMaxHealth() > MAX_CARRY_HEALTH then return false end
        return true

    end

    -- Every zambie on the map we could summon, farthest from targetPos first.
    -- Doesn't use GetNearbyAllies, raising InformRadius to cover the map would also spread our enemy's position map-wide.
    function ENT:FindSummonableZambies( targetPos )
        local myChummy = self.isTerminatorHunterChummy
        local found = {}
        local distsSqr = {}
        for _, ent in ipairs( ents.FindByClass( "terminator_nextbot_zambie*" ) ) do
            if ent == self then continue end
            if ent.isTerminatorHunterChummy ~= myChummy then continue end
            if not self:CanSummon( ent ) then continue end

            table.insert( found, ent )
            distsSqr[ent] = ent:GetPos():DistToSqr( targetPos )

        end
        table.sort( found, function( a, b ) return distsSqr[a] > distsSqr[b] end )
        return found

    end

    -- Teleports up to count far off allies to spots between us and targetPos.
    function ENT:SummonZambies( targetPos, count )
        local myCenter = self:WorldSpaceCenter()

        -- deploy spots start halfway to the target, and creep back towards us if there's no room there
        local positions = {}
        local deployCenter
        for i = 1, 4 do
            local lerpFrac = 0.5 - ( ( i - 1 ) / 3 ) * 0.3
            local center = LerpVector( lerpFrac, myCenter, targetPos )
            local spots, gotAll = PackSquadVectors( center, count, math.random( 75, 125 ) )
            if #spots > #positions then
                positions = spots
                deployCenter = center

            end
            if gotAll then break end

        end
        if #positions == 0 then return end

        -- zambies that can already see the fight are on their way, leave them be
        local eyeHeight = Vector( 0, 0, 50 )
        local deployEyes = deployCenter + eyeHeight
        local targetEyes = targetPos + eyeHeight
        local posCanSee = terminator_Extras.PosCanSee
        local candidates = {}
        for _, ally in ipairs( self:FindSummonableZambies( targetPos ) ) do
            local allyEyes = ally:GetShootPos()
            if posCanSee( allyEyes, deployEyes ) or posCanSee( allyEyes, targetEyes ) then continue end

            table.insert( candidates, ally )
            if #candidates >= #positions then break end

        end
        if #candidates == 0 then return end

        local liftOffGround = Vector( 0, 0, 10 )
        for i, ally in ipairs( candidates ) do
            TeleportZambieTo( ally, positions[i] + liftOffGround, targetPos, self )

        end

        self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 100, 1 )

    end

    -- Where to drop summoned zambies.
    -- Our enemy, or the driver's aim if a player is controlling us and there's no enemy.
    function ENT:GetSummonTarget( driver )
        local enemy = self:GetEnemy()
        if IsValid( enemy ) then return enemy:GetPos() end

        if IsValid( driver ) then
            local shootPos = self:GetShootPos()
            local tr = util.TraceLine( {
                start  = shootPos,
                endpos = shootPos + driver:EyeAngles():Forward() * self.DeployDistance,
                mask   = MASK_SOLID_BRUSHONLY,
            } )
            return tr.HitPos

        end

        return self:GetPos()

    end

    -- Picks an area on the far side of us from the enemy and paths there.
    function ENT:KeepDistanceFrom( enemyPos )
        if self:HasTask( "movement_gotoarea" ) then return end

        local myPos = self:GetPos()
        local away = myPos - enemyPos
        away.z = 0
        away:Normalize()

        local fleeArea = navmesh.GetNearestNavArea( myPos + away * self.DeployDistance * 0.5, false, 512 )
        if not fleeArea then return end
        if not self:areaIsReachable( fleeArea ) then return end

        self:KillAllTasksWith( "movement" )
        self:StartTask( "movement_gotoarea", { Area = fleeArea, GiveUpAfter = 5 }, "they're too close, i need to keep my distance" )
        self:RestartMotionCoroutine()

    end

    function ENT:DoCustomTasks( defaultTasks )
        BaseClass.DoCustomTasks( self, defaultTasks )
        self.TaskList["movement_gotoarea"] = defaultTasks["movement_gotoarea"]

    end

    -- never close in for a melee duel
    function ENT:CanMoveRightUpToEnemy()
        return false

    end

    function ENT:AdditionalInitialize()
        BaseClass.AdditionalInitialize( self )
        self:SetBodygroup( 1, 0 )
    end

    function ENT:SpiritDeath()
        if self:GetIsDying() then return end
        self:SetIsDying( true )
        self:SetDeathTime( CurTime() )

        self:StopMoving()
        self:SetSolid( SOLID_NONE )
        self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        self:SetMoveType( MOVETYPE_FLY ) -- hang in the air while the fade plays

        -- one last pull as it goes
        self:SummonZambies( self:GetSummonTarget(), math.random( 2, 4 ) )

        local ed = EffectData()
        ed:SetMagnitude( 1.5 )
        ed:SetOrigin( self:WorldSpaceCenter() )
        ed:SetRadius( 78 )
        ed:SetNormal( self:GetAngles():Up() )
        util.Effect( "eff_zambspirit_blast", ed, true, true )
        self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 170, 1 )

        -- FinishDying hid us, but the dying trails and sprite are drawn by us
        self:SetNoDraw( false )
        SafeRemoveEntityDelayed( self, DEATH_FADE_TIME )
    end
end

ENT.MySpecialActions = {
    ["call"] = {
        inBind    = IN_RELOAD,
        drawHint  = true,
        name      = "Summon Zambies",
        desc      = "Pull far off zambies in front of you",
        ratelimit = 5,
        svAction  = function( _driveController, driver, bot )
            bot:SummonZambies( bot:GetSummonTarget( driver ), math.random( 3, 5 ) )

        end,
    },
}

ENT.MyClassTask = {
    OnDamaged = function( self, _data, dmg )
        if self:GetIsDying() then return true end

        local melee = bit.band( dmg:GetDamageType(), bit.bor( DMG_SLASH, DMG_CLUB ) ) > 0
        if melee then
            dmg:ScaleDamage( 2.2 )

        elseif dmg:GetDamage() < 25 then
            dmg:ScaleDamage( 0.2 )

        end
    end,
    PreventBecomeRagdollOnKilled = function()
        return true, true

    end,
    OnKilledDmg = function( self )
        self:SpiritDeath()

    end,
    DisableBehaviour = function( self )
        return self:GetIsDying()

    end,
    BehaveUpdatePriority = function( self )
        if self:GetIsDying() then return end
        if not self.IsSeeEnemy then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end

        if self.DistToEnemy < self.DeployDistance / 2 then
            self:KeepDistanceFrom( enemy:GetPos() )
            return

        end

        if self.DistToEnemy < self.DeployDistance then
            self:TakeAction( "call" )

        end
    end,
}

if CLIENT then
    ENT.mat       = Material( "effects/strider_muzzle" )
    ENT.mat_trail = Material( "trails/plasma" )

    local function GetFPSEstimate()
        local ft = FrameTime()
        if ft <= 0 then return 60 end
        return 1 / ft

    end

    local TRAIL_BONE_NAMES = {
        "ValveBiped.Bip01_L_Calf",
        "ValveBiped.Bip01_R_Calf",
        "ValveBiped.Bip01_L_Hand",
        "ValveBiped.Bip01_R_Hand",
    }

    function ENT:AdditionalClientInitialize()
        BaseClass.AdditionalClientInitialize( self )
        self.trailLength = 16
        self.trailBones  = {}
        self.trails      = {}
        for _, boneName in ipairs( TRAIL_BONE_NAMES ) do
            local bone = self:LookupBone( boneName )
            if not bone then continue end

            table.insert( self.trailBones, bone )
            table.insert( self.trails, {} )

        end
    end

    -- 1 while alive, eases to 0 over the death fade
    local function DeathFrac( self )
        if not self:GetIsDying() then return 1 end
        local elapsed = CurTime() - self:GetDeathTime()
        return math.ease.InCubic( math.max( 0, 1 - elapsed / DEATH_FADE_TIME ) )

    end

    function ENT:Think()
        BaseClass.Think( self )
        self:RemoveAllDecals()

        if FrameTime() > 0 and self.trailBones then
            -- while dying the trails pull in to our center
            local pullIn = 1 - DeathFrac( self )
            local myX, myY, myZ = self:WorldSpaceCenter():Unpack()
            for i, bone in ipairs( self.trailBones ) do
                local trail   = self.trails[i]
                local bonePos = self:GetBonePosition( bone )
                local boneX, boneY, boneZ = bonePos:Unpack()
                bonePos:SetUnpacked(
                    Lerp( pullIn, boneX, myX ),
                    Lerp( pullIn, boneY, myY ),
                    Lerp( pullIn, boneZ, myZ )
                )
                table.insert( trail, 1, bonePos )
                trail[self.trailLength] = nil

            end
        end
        self:SetNextClientThink( CurTime() + 1 / self.trailLength )

        return true

    end

    function ENT:DrawTranslucent()
        if render.GetRenderTarget() then return end

        local myPos     = self:WorldSpaceCenter()
        local eyePos    = EyePos()
        local time      = CurTime()
        local dying     = self:GetIsDying()
        local deathFrac = DeathFrac( self )
        -- the sprite layers spread out right as it dies
        local blastFrac = dying and math.max( 0, 1 - ( time - self:GetDeathTime() ) * 5 ) or 0

        render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )

        if self.trails and GetFPSEstimate() > 30 then
            render.SetMaterial( self.mat_trail )
            for _, trail in ipairs( self.trails ) do
                local count = #trail
                if count < 2 then continue end

                render.StartBeam( count )
                for j, point in ipairs( trail ) do
                    local alongTrail = ( j - 1 ) / ( count - 1 )
                    render.AddBeam( point, 7 * deathFrac * ( 1 - alongTrail ), alongTrail * 4, Color( 255 * ( 1 - alongTrail ), 0, 0 ) )
                end
                render.EndBeam()

            end
        end

        if not dying then
            render.SetColorModulation( 700, 1, 1 ) -- blows the red channel out, the model glows solid red under the additive blend
            self:DrawModel()
            render.SetColorModulation( 1, 1, 1 )

        end

        if eyePos:DistToSqr( myPos ) < 3250 ^ 2 then
            surface.SetMaterial( self.mat )
            surface.SetAlphaMultiplier( 1 )
            surface.SetDrawColor( 255 * deathFrac, 0, 0, 255 * deathFrac )
            local angle = ( myPos - eyePos ):Angle()
            angle:RotateAroundAxis( angle:Right(), 90 )

            -- four spinning layers, each a quarter cycle out of step
            for layer = 1, 4 do
                cam.Start3D2D( myPos, angle, 1 + blastFrac * layer )
                local cycle = ( time + layer / 4 ) % 1
                local size  = ( 72 - cycle * 32 ) * deathFrac
                surface.DrawTexturedRectRotated( 0, 0, size, size, cycle / 4 * layer * 360 )
                cam.End3D2D()

            end
        end

        render.OverrideBlend( false )

    end
end
