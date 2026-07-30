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
local MAX_CARRY_SCALE  = 1.15
local MAX_CARRY_HEALTH = 250

local function PackSquadVectors( center, count, radius )
    local results   = {}
    local attempts  = count * 6
    local angleStep = ( math.pi * 2 ) / attempts
    for i = 0, attempts - 1 do
        if #results >= count then break end
        local angle     = i * angleStep
        local candidate = center + Vector( math.cos( angle ) * radius, math.sin( angle ) * radius, 0 )
        local area = navmesh.GetNearestNavArea( candidate, false, 128 )
        if not area then continue end
        local snapped = area:GetClosestPointOnArea( candidate )
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

local function SafeGoto( bot, pos )
    if not isvector( pos ) then return end
    local area = navmesh.GetNearestNavArea( pos, false, 512 )
    if not area then return end
    local snapped = area:GetClosestPointOnArea( pos )
    if not isvector( snapped ) then return end
    pcall( bot.GotoPosSimple, bot, snapped )
end

-- Network string for the summon origin effect (where the zambie WAS)
if SERVER then
    util.AddNetworkString( "zambspirit_summoneffect" )
end

-- Fires the shrinking red texture at the zambie's old position
local function FireSummonEffectAt( ent )
    if not SERVER then return end
    if not IsValid( ent ) then return end

    local pos = ent:WorldSpaceCenter()
    local mins, maxs = ent:GetCollisionBounds()
    local height = maxs.z - mins.z
    local startSize = math.Clamp( height * 1.5, 40, 300 )

    net.Start( "zambspirit_summoneffect" )
        net.WriteVector( pos )
        net.WriteFloat( startSize )
    net.Broadcast()
end

-- Fires the rays beam effect from the spirit's chest to the target position
local function FireDeployEffectAt( spirit, targetPos )
    if not SERVER then return end
    if not IsValid( spirit ) or not isvector( targetPos ) then return end

    local chestBone = spirit:LookupBone( "ValveBiped.Bip01_Spine4" ) or spirit:LookupBone( "ValveBiped.Bip01_Spine2" )
    local origin = spirit:WorldSpaceCenter()
    if chestBone and chestBone ~= -1 then
        origin = spirit:GetBonePosition( chestBone )
    end

    local ed = EffectData()
    ed:SetOrigin( targetPos )
    ed:SetStart( origin )
    util.Effect( "eff_zambspirit_rays", ed, true, true )
end

-- Teleports a zambie from its current position to a target deploy position.
local function TeleportZambieTo( ent, targetPos, enemy, spirit )
    if not IsValid( ent ) then return end

    -- Effect at where it WAS
    FireSummonEffectAt( ent )

    ent:SetVelocity( Vector( 0, 0, 0 ) )
    ent.TakesFallDamage           = false
    ent.HeightToStartTakingDamage = 99999
    ent.FallDamagePerHeight       = 0
    ent.DeathDropHeight           = 99999
    ent:SetPos( targetPos )
    if ent.loco and ent.loco.SetGroundEntity then
        ent.loco:SetGroundEntity( Entity( 0 ) )
    end
    if IsValid( enemy ) then
        local faceAngle = ( enemy:GetPos() - targetPos ):Angle()
        faceAngle.p = 0
        faceAngle.r = 0
        ent:SetAngles( faceAngle )
    end
    ent:ReallyAnger( 60 )

    -- Effect at where it WILL BE
    FireDeployEffectAt( spirit, targetPos )

    timer.Simple( 0.5, function()
        if not IsValid( ent ) then return end
        ent.TakesFallDamage           = true
        ent.HeightToStartTakingDamage = 200
        ent.FallDamagePerHeight       = 0.15
        ent.DeathDropHeight           = 1000
    end )
end

function ENT:SetupDataTables()
    if BaseClass.SetupDataTables then
        BaseClass.SetupDataTables( self )
    end
    self:NetworkVar( "Bool",  10, "IsDying" )
    self:NetworkVar( "Float", 10, "DeathTime" )
    self:NetworkVar( "Int",   10, "SummonCount" )
end

if SERVER then
    function ENT:AdditionalInitialize()
        BaseClass.AdditionalInitialize( self )
        self:SetBodygroup( 1, 0 )
    end
end

ENT.DeployDistance       = 1000
ENT.GrabDistance         = 666
ENT.MinGrabDist          = 1500

-- Overriding the base zambie "call" action to trigger the spirit's summon logic
ENT.MySpecialActions = {
    ["call"] = {
        inBind    = IN_RELOAD,
        drawHint  = true,
        name      = "Summon Zambies",
        desc      = "Pull zambies from afar to deploy near you",
        ratelimit = 5,
        svAction  = function( _driveController, _driver, bot )
            local enemy = bot:GetEnemy()
            local enemyPos = IsValid( enemy ) and enemy:GetPos() or bot:GetPos()
            bot:SummonZambies( enemyPos, { summonGoal = math.random( 3, 5 ), summonedThisWave = 0 } )
        end,
    },
}

ENT.MyClassTask = {
    OnCreated = function( self, data )
        data.summonGoal       = math.random( 3, 5 )
        data.wantToSummon     = true
        data.summonedThisWave = 0
    end,
    OnDamaged = function( self, data, dmg )
        if self:GetIsDying() then return true end
        local melee  = bit.band( dmg:GetDamageType(), bit.bor( DMG_SLASH, DMG_CLUB ) ) > 0
        if melee then
            dmg:ScaleDamage( 2.2 )
        elseif dmg:GetDamage() < 25 then
            dmg:ScaleDamage( 0.2 )
        end
    end,
    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        if IsValid( ragdoll ) then ragdoll:Remove() end
    end,
    PreventBecomeRagdollOnKilled = function( self, data, dmg )
        if not self:GetIsDying() then
            local attacker = dmg:GetAttacker()
            local inflictor = dmg:GetInflictor()
            local v = dmg:GetDamageForce()
            local len = v:Length()
            if len > 0 then
                v:Div( len )
                v:Mul( 120 )
            end
            self:SpiritDeath( attacker, inflictor, v )
        end
        return true, true
    end,
    DisableBehaviour = function( self, data )
        return self:GetIsDying()
    end,
    BehaveUpdatePriority = function( self, data )
        if self:GetIsDying() then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then
            data.wantToSummon = true
            return
        end
        local selfPos  = self:GetPos()
        local enemyPos = enemy:GetPos()
        if not isvector( selfPos ) or not isvector( enemyPos ) then return end
        local dist2 = enemyPos:DistToSqr( selfPos )

        -- Too close to the enemy: flee
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

        -- Within summon range and enemy visible: pull zambies from far away
        if data.wantToSummon and self.IsSeeEnemy and dist2 < self.DeployDistance ^ 2 then
            if self:CanTakeAction( "call" ) then
                self:TakeAction( "call" )
            end
        end
    end,
    BehaveUpdateMotion = function( self, data )
        if self:GetIsDying() then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then
            data.wantToSummon = true
            return
        end
        local enemyPos = enemy:GetPos()
        local selfPos  = self:GetPos()
        if not isvector( enemyPos ) or not isvector( selfPos ) then return end
        if selfPos:DistToSqr( enemyPos ) < ( self.DeployDistance / 2 ) ^ 2 then return end
    end,
}

-- Finds eligible zambies far from the enemy and teleports them to deploy
-- positions near the spirit.
function ENT:SummonZambies( enemyPos, data )
    local searchRadius = self.MinGrabDist
    local summoned = 0
    local targetCount = data.summonGoal or math.random( 3, 5 )
    local positions = {}
    if isvector( enemyPos ) then
        for i = 1, 4 do
            local lerpFrac = 0.5 - ( ( i - 1 ) / 3 ) * 0.3
            local deployCenter = LerpVector( lerpFrac, self:WorldSpaceCenter(), enemyPos )
            local radius       = math.random( 75, 125 )
            local vectors, fully = PackSquadVectors( deployCenter, targetCount, radius )
            if fully or #vectors > #positions then
                positions = vectors
                if fully then break end
            end
        end
    else
        positions = PackSquadVectors( self:WorldSpaceCenter(), targetCount, math.random( 150, 200 ) )
    end
    if #positions == 0 then return end
    local enemy = self:GetEnemy()
    local upVec = Vector( 0, 0, 10 )

    -- Find zambies far from the enemy
    local candidates = {}
    for _, npc in ipairs( ents.FindByClass( "terminator_nextbot_zambie*" ) ) do
        if not self:IsGoodGrabTarget_Optimised( npc ) then continue end
        if not isvector( npc:GetPos() ) then continue end
        if isvector( enemyPos ) and npc:GetPos():DistToSqr( enemyPos ) < searchRadius ^ 2 then continue end
        table.insert( candidates, npc )
        if #candidates >= targetCount then break end
    end
    if #candidates == 0 then return end

    local toSummon = math.min( #candidates, #positions )
    self:SetSummonCount( toSummon )
    for i = 1, toSummon do
        local npc = candidates[i]
        local pos = positions[i] + upVec
        TeleportZambieTo( npc, pos, enemy, self )
        summoned = summoned + 1
    end

    data.summonedThisWave = ( data.summonedThisWave or 0 ) + summoned
    data.summonGoal = math.random( 3, 5 )

    if summoned > 0 then
        self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 100, 1 )
    end
end

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
    self:SetIsDying( true )
    self:SetDeathTime( CurTime() )
    
    -- Stop moving and become non-solid immediately
    self:StopMoving()
    self:SetSolid( SOLID_NONE )
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
    self:SetMoveType( MOVETYPE_FLY )
    self:SetVelocity( Vector( 0, 0, 0 ) )
    self:SetNoDraw( true )

    -- On death, do a final summon burst from far away
    local enemy = self:GetEnemy()
    local summonPos = IsValid( enemy ) and enemy:GetPos() or self:GetPos()
    local fakeData = { summonGoal = math.random( 2, 4 ), summonedThisWave = 0 }
    self:SummonZambies( summonPos, fakeData )

    local ed = EffectData()
    ed:SetMagnitude( 1.5 )
    ed:SetOrigin( self:WorldSpaceCenter() )
    ed:SetRadius( 78 )
    ed:SetNormal( self:GetAngles():Up() )
    ed:SetFlags( 2 )
    util.Effect( "eff_zambspirit_blast", ed )
    self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 170, 1 )

    if isvector( forceVec ) then
        self:SetVelocity( forceVec )
    end

    SafeRemoveEntityDelayed( self, 0.1 )
end

if CLIENT then
    ENT.mat       = Material( "effects/strider_muzzle" )
    ENT.mat_trail = Material( "trails/plasma" )

    -- Summon origin effect: stores positions received from the server
    -- and renders a shrinking, rotating red texture at each one (where the zambie WAS)
    local summonEffects = {}
    local summonMat = ENT.mat

    net.Receive( "zambspirit_summoneffect", function()
        local pos = net.ReadVector()
        local startSize = net.ReadFloat()
        table.insert( summonEffects, {
            pos       = pos,
            startTime = CurTime(),
            startSize = startSize,
        } )
    end )

    hook.Add( "PostDrawTranslucentRenderables", "zambspirit_summoneffects", function( _depth, skybox )
        if skybox then return end
        if render.GetRenderTarget() then return end

        local time       = CurTime()
        local eyePos     = EyePos()
        local maxDuration = 1.0

        for i = #summonEffects, 1, -1 do
            local effect  = summonEffects[i]
            local elapsed = time - effect.startTime

            if elapsed >= maxDuration then
                table.remove( summonEffects, i )
                continue
            end

            local frac = 1 - ( elapsed / maxDuration )
            local pos  = effect.pos
            local a    = ( pos - eyePos ):Angle()
            a:RotateAroundAxis( a:Right(), 90 )

            render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD )
            surface.SetMaterial( summonMat )
            surface.SetDrawColor( 255 * frac, 0, 0, 255 * frac )

            local startSize = effect.startSize or 72

            for j = 1, 4 do
                cam.Start3D2D( pos, a, 1 )
                local ti   = ( elapsed + j / 4 ) % 1
                local size = ( startSize - ti * ( startSize * 0.5 ) ) * frac
                surface.DrawTexturedRectRotated( 0, 0, size, size, ti / 4 * j * 360 )
                cam.End3D2D()
            end

            render.OverrideBlend( false )
        end
    end )

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
        self:RemoveAllDecals()
        if FrameTime() > 0 then
            local mypos     = self:WorldSpaceCenter()
            local dying     = self:GetIsDying()
            local elapsed   = CurTime() - self:GetDeathTime()
            local deathfrac = dying and math.ease.InCubic( math.max( 0, 1 - elapsed / 1.5 ) ) or 1
            local myX, myY, myZ = mypos:Unpack()
            for i, bid in ipairs( self.trailBones ) do
                local tt      = self.trails[ i ]
                local bonePos = self:GetBonePosition( bid )
                local bx, by, bz = bonePos:Unpack()
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

        if not dying then
            local colormod = math.sin( time * 4 + self:EntIndex() ) * 0.5 + 700
            render.SetColorModulation( colormod, 1, 1 )
            self:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        end

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

        render.OverrideBlend( false )
    end
end