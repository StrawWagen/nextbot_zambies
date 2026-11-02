-- Orchestrates the horde from hiding, never makes new zambies.
-- Drops far off zambies where its enemy can't see, on every side but its own, and sends them in a group at a time.
-- Lends them brains so they flank on the way in, kill it and they forget their orders.
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiespirit"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Spirit Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiespiritelite", {
    Name     = "Zombie Spirit Elite",
    Class    = "terminator_nextbot_zambiespiritelite",
    Category = "Nextbot Zambies",
} )

ENT.Author = "Octantis Addons + Straw W Wagen"

-- the heartbeat reads these too
local RAGE_TIME = 12 -- each hit keeps it angry this long
ENT.DesperateHealthFrac = 0.25 -- below a quarter health, it gets slippery
ENT.HeartbeatPitch = 30

if CLIENT then
    language.Add( "terminator_nextbot_zambiespiritelite", ENT.PrintName )

    -- A big slow heart. Rage races it, slowing as the rage runs out, and desperation makes it stumble.
    function ENT:NextBeat()
        if self:GetNWBool( "zamb_SpiritEnraged", false ) then
            local rageLeft = math.Clamp( ( self:GetNW2Float( "zamb_RageUntil", 0 ) - CurTime() ) / RAGE_TIME, 0, 1 )
            return Lerp( rageLeft, 2, 5 ), 1.2, 0.8

        end
        if self:GetNW2Float( "zamb_SpiritHealth", 1 ) < self.DesperateHealthFrac then
            if math.random() < 0.25 then return math.Rand( 2, 3 ), 0.3, 0 end -- a flutter
            return math.Rand( 0.5, 1.5 ), 1, 0.6

        end
        return 0.6, 1, 0.6

    end

    function ENT:Think()
        local ret = BaseClass.Think( self ) -- thinks every 1/16th of a second, plenty for jitter
        local jitter = self:GetNWBool( "zamb_SpiritEnraged", false ) and not self:GetIsDying()
        if not jitter and not self.zamb_Jittering then return ret end
        self.zamb_Jittering = jitter

        for i = 0, self:GetBoneCount() - 1 do
            if jitter then
                self:ManipulateBoneAngles( i, Angle( math.Rand( -8, 8 ), math.Rand( -8, 8 ), math.Rand( -8, 8 ) ) )

            else -- calmed down, straighten out once
                self:ManipulateBoneAngles( i, angle_zero )

            end
        end
        return ret

    end
    return

end

ENT.IsFodder = false
ENT.SpawnHealth = 1000
ENT.ExtraSpawnHealthPerPlayer = 250
ENT.HealthRegen = 10
ENT.HealthRegenInterval = 1

ENT.Term_FOV = 120

ENT.TERM_MODELSCALE = 1.15
ENT.term_SoundPitchShift = -30
ENT.term_SoundLevelShift = 20
ENT.JumpHeight = 512

ENT.DeployDistance = 2500
ENT.MaxCarryHealth = 8000 -- a tank, but no elites
ENT.SummonCountMin = 6
ENT.SummonCountMax = 10
ENT.SummonCountBehindWalls = 4 -- squads dropped deep behind walls shrink down to this
ENT.SummonsOnDeath = false -- dying cuts the strings instead
ENT.OneHitFreebie = true
ENT.UsesScoutIntel = true

local ENTRY_DIST      = 1200 -- entries are looked for this far out from the enemy
local ENTRY_SEARCH    = 500
local ENTRY_MIN_DIST  = 400 -- any closer and they'd be on top of them before the group arrives
local ENTRY_SPACING   = 400
local MAX_VIS_CHECKS  = 16 -- per entry, IsVisible traces
local GROUP_STAGGER   = 0.5
local ORDERS_TIME     = 60 -- lent brains are returned after this long
local FLANK_YAW       = 110

local BODYGUARD_DIST     = 1200
local BODYGUARD_COOLDOWN = 15
local BODYGUARD_COUNT    = 5

-- Rage is for whoever's actively hurting it, once they back off it slinks back to summoning.
local RAGE_NEAR_DIST = 1000 -- hits from closer always enrage it, from farther only once it's below half health
local RAGE_LOST_TIME = 6 -- calms once it hasn't seen its enemy for this long
local RAGE_RETREAT_GRACE = 2.5 -- calms once they've turned and run, and haven't hit it for this long
local RAGE_ACT_COOLDOWN  = 15 -- re-enraging sooner than this after calming skips the scream and blast

ENT.EnragedSpeedMult = 2
ENT.EnragedFistDamageMul = 2.5

ENT.DesperateRunSpeedMult = 1.5
ENT.DesperateAccelMult = 2

local function ReturnBrains( ally )
    if ally.zamb_SpiritLentBrains then
        ally.HasBrains = false
        ally.zamb_SpiritLentBrains = nil

    end
    if ally.zamb_SpiritLentFlank then
        ally.zamb_AlwaysFlank = nil -- back to the class's value
        ally.zamb_SpiritLentFlank = nil

    end
end

-- Which ways to come at them from, the same read terminator-hunter's InformReceive makes.
-- A runner gets cut off ahead, anyone else gets the far side.
-- Never from our side, that's the gap they can run for, and it leads to us.
function ENT:GetEntryDirs( targetPos, enemy )
    local main
    local vel = IsValid( enemy ) and enemy:GetVelocity() or Vector( 0, 0, 0 )
    vel.z = 0
    if vel:LengthSqr() > 50 ^ 2 then
        main = vel:GetNormalized()

    else
        main = targetPos - self:GetPos()
        main.z = 0
        main:Normalize()

    end

    local left = Vector( main )
    left:Rotate( Angle( 0, FLANK_YAW, 0 ) )
    local right = Vector( main )
    right:Rotate( Angle( 0, -FLANK_YAW, 0 ) )
    return { main, left, right }

end

-- A spot out along dir, as close to the enemy as it can be while they can't see it.
-- Falls back to a spot they can see, so open maps still get ambushed, just less sneakily.
function ENT:FindEntrySpot( targetPos, targetEyes, dir, taken )
    local tr = util.TraceLine( {
        start  = targetEyes,
        endpos = targetEyes + dir * ENTRY_DIST,
        mask   = MASK_SOLID_BRUSHONLY,
    } )

    local minDistSqr = ENTRY_MIN_DIST ^ 2
    local spacingSqr = ENTRY_SPACING ^ 2
    local bestHidden, bestHiddenDist
    local bestSeen, bestSeenDist
    local checks = 0
    for _, area in ipairs( navmesh.Find( tr.HitPos, ENTRY_SEARCH, 200, 200 ) ) do
        local center = area:GetCenter()
        local distSqr = center:DistToSqr( targetPos )
        if distSqr < minDistSqr then continue end
        if area:IsUnderwater() then continue end -- most of what we summon breathes

        local tooClose = false
        for _, other in ipairs( taken ) do
            if other:DistToSqr( center ) < spacingSqr then
                tooClose = true
                break

            end
        end
        if tooClose then continue end
        if not self:areaIsReachable( area ) then continue end

        if checks < MAX_VIS_CHECKS and ( not bestHiddenDist or distSqr < bestHiddenDist ) then
            checks = checks + 1
            if not area:IsVisible( targetEyes ) then
                bestHidden, bestHiddenDist = center, distSqr

            end
            self.YieldIfWeCan()

        end
        if not bestSeenDist or distSqr > bestSeenDist then -- farthest, at least
            bestSeen, bestSeenDist = center, distSqr

        end
    end
    return bestHidden or bestSeen

end

-- Spots at each entry, and the far off allies to drop on them, paired by index like the base.
-- The third return is which entry each spot belongs to, so SendSummon can send them in turn.
function ENT:PlanSummon( targetPos, count )
    -- cheapest check first, HasSomeoneToSummon calls this every second when there's nobody
    local candidates, pickedFrom = self:PickSummonCandidates( targetPos, count )
    if #candidates == 0 then return nil, "nobody to summon, " .. pickedFrom end

    -- off a scout report, plan around the reported spot, not where they really are
    local enemy = self.IsSeeEnemy and self:GetEnemy() or nil
    local targetEyes = IsValid( enemy ) and enemy:EyePos() or targetPos + Vector( 0, 0, 64 )
    local entries = {}
    for _, dir in ipairs( self:GetEntryDirs( targetPos, enemy ) ) do
        local spot = self:FindEntrySpot( targetPos, targetEyes, dir, entries )
        if spot then
            table.insert( entries, spot )

        end
    end
    if #entries == 0 then return self:PlanLemmings( candidates ) end

    -- deal candidates out to entries, each entry only takes as many, and as tough, as its depth allows
    local perEntry = math.ceil( #candidates / #entries )
    local dealt = {}
    local positions = {}
    local chosen = {}
    local entryOf = {}
    for entryIndex, entry in ipairs( entries ) do
        local size, maxHealth = self:SquadLimitsThrough( entry, perEntry )
        local squad = {}
        for _, ally in ipairs( candidates ) do
            if #squad >= size then break end
            if dealt[ally] or ally:GetMaxHealth() > maxHealth then continue end
            dealt[ally] = true
            table.insert( squad, ally )

        end

        for i, spot in ipairs( self.PackSquadVectors( entry, #squad, 60 ) ) do
            table.insert( positions, spot )
            table.insert( chosen, squad[i] )
            entryOf[#positions] = entryIndex

        end
    end
    if #positions == 0 then return self:PlanLemmings( candidates ) end
    return positions, chosen, entryOf

end

-- No room around the target, so they arrive at our feet, and their orders walk them the whole way there.
function ENT:PlanLemmings( candidates )
    local positions = self.PackSquadVectors( self:GetPos(), #candidates, 80 )
    if #positions == 0 then return nil, "no room around the target, or us" end

    for i = #candidates, #positions + 1, -1 do
        candidates[i] = nil

    end
    local entryOf = {}
    for i = 1, #positions do
        entryOf[i] = 1 -- one group, they go together

    end
    return positions, candidates, entryOf

end

-- One group per entry, a moment apart, SendDueSummons sends each when it's due.
-- Each group's arrival is heard at its entry, so the pressure comes from one side, then another.
function ENT:SendSummon( plan )
    local liftOffGround = Vector( 0, 0, 10 )
    local announced = {}
    local pending = self.zamb_PendingSends
    local entryOf = plan.extra
    for i, ally in ipairs( plan.candidates ) do
        local entryIndex = entryOf[i]
        table.insert( pending, {
            at        = CurTime() + ( entryIndex - 1 ) * GROUP_STAGGER,
            ally      = ally,
            pos       = plan.positions[i] + liftOffGround,
            targetPos = plan.targetPos,
            announce  = not announced[entryIndex],
        } )
        announced[entryIndex] = true

    end

    self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 80, 1 )

end

function ENT:SendDueSummons()
    local pending = self.zamb_PendingSends
    local cur = CurTime()
    for i = #pending, 1, -1 do
        local send = pending[i]
        if send.at > cur then continue end
        table.remove( pending, i )

        local ally = send.ally
        if not self:CanSummon( ally ) then continue end
        self:TeleportZambieTo( ally, send.pos, send.targetPos )
        self:GiveOrders( ally )
        if send.announce then
            sound.Play( "npc/advisor/advisor_blast6.wav", send.pos, 90, math.random( 90, 110 ), 1 )

        end
        self.YieldIfWeCan()

    end
end

-- Gives ally our enemy through the inform system, and lends it the brains to flank its way in.
function ENT:GiveOrders( ally )
    local enemy = self:GetEnemy()
    if not IsValid( enemy ) then
        local intel = self:GetFreshIntel()
        enemy = intel and intel.enemy

    end
    if not IsValid( enemy ) then return end

    ally:RunTask( "InformReceive", {
        enemy     = enemy,
        pos       = self:GetSummonTarget(), -- where we can see them, or where our scouts last did
        shootPos  = self:EntShootPos( enemy ),
        senderPos = self:GetPos(),
        sender    = self,
    } )

    -- only lend what they don't have, so returning it can't take away their own
    if not ally.HasBrains then
        ally.HasBrains = true
        ally.zamb_SpiritLentBrains = true

    end
    if not ally.zamb_AlwaysFlank then
        ally.zamb_AlwaysFlank = true
        ally.zamb_SpiritLentFlank = true

    end
    ally.zamb_SpiritOrdersUntil = CurTime() + ORDERS_TIME
    self.zamb_Ordered[ally] = true

    if ally:HasTask( "movement_followenemy" ) then
        ally:KillAllTasksWith( "movement" )
        ally:StartTask( "movement_followenemy", "the spirit sent me" )
        ally:RestartMotionCoroutine()

    end
end

-- Hands back lent brains once orders run out.
function ENT:ExpireOrders()
    local cur = CurTime()
    if ( self.zamb_NextOrdersCheck or 0 ) > cur then return end
    self.zamb_NextOrdersCheck = cur + 1

    local ordered = self.zamb_Ordered
    for ally in pairs( ordered ) do
        if not IsValid( ally ) then
            ordered[ally] = nil

        elseif ally.zamb_SpiritOrdersUntil <= cur then -- another spirit may have ordered them since
            ReturnBrains( ally )
            ordered[ally] = nil

        end
    end
end

-- Everyone we sent forgets the plan, and stumbles back to their own ideas.
function ENT:RevokeOrders()
    for ally in pairs( self.zamb_Ordered ) do
        if not IsValid( ally ) or ally:Health() <= 0 then continue end
        ReturnBrains( ally )
        ally.zamb_SpiritOrdersUntil = 0
        if ally:HasTask( "movement_handler" ) then
            ally:KillAllTasksWith( "movement" )
            ally:StartTask( "movement_handler", "the spirit's gone" )
            ally:RestartMotionCoroutine()

        end
    end
    self.zamb_Ordered = {}

end

-- Drops far off zambies all at once in a knot between us and enemy, no stagger, no flanking.
function ENT:SummonBodyguards( enemy )
    local myCenter = self:WorldSpaceCenter()
    local enemyPos = enemy:GetPos()
    local center = LerpVector( 0.2, myCenter, enemyPos )
    local positions = self.PackSquadVectors( center, BODYGUARD_COUNT, 100 )
    if #positions == 0 then return end

    local candidates = self:PickSummonCandidates( enemyPos, #positions, center )
    if #candidates == 0 then return end

    local liftOffGround = Vector( 0, 0, 10 )
    for i, ally in ipairs( candidates ) do
        if not self:CanSummon( ally ) then continue end -- picking yields, they could be gone
        self:TeleportZambieTo( ally, positions[i] + liftOffGround, enemyPos )

    end
    self:ZAMB_AngeringCall()
    self:EmitSound( "npc/advisor/advisor_blast6.wav", 100, 120, 1 )
    self:SetNW2Float( "zamb_BodyguardAt", CurTime() )

end

-- Shot from afar queues a guard, so does them closing in.
function ENT:BodyguardThink()
    if ( self.zamb_NextBodyguards or 0 ) > CurTime() then return end

    local threat = self.zamb_BodyguardsFor
    if not IsValid( threat ) then
        local enemy = self:GetEnemy()
        if not self.IsSeeEnemy or not IsValid( enemy ) or self.DistToEnemy >= BODYGUARD_DIST then return end
        threat = enemy

    end

    self.zamb_BodyguardsFor = nil
    self.zamb_NextBodyguards = CurTime() + BODYGUARD_COOLDOWN
    self:SummonBodyguards( threat )

end

-- Rage and desperation stack, so both rebuild the stats from what we spawned with.
function ENT:ApplyMoveStats()
    local base = self.zamb_SpawnStats
    local enraged = self.zamb_Enraged
    local speedMul = enraged and self.EnragedSpeedMult or 1
    local runMul = speedMul
    local accelMul = 1
    if self.zamb_Desperate then
        runMul = runMul * self.DesperateRunSpeedMult
        accelMul = self.DesperateAccelMult

    end

    self.WalkSpeed = base.walk * speedMul
    self.MoveSpeed = base.move * speedMul
    self.RunSpeed = base.run * runMul
    self.AccelerationSpeed = base.accel * accelMul
    self.DecelerationSpeed = base.decel * accelMul
    self.FistDamageMul = enraged and self.EnragedFistDamageMul or base.fist

end

function ENT:BecomeEnraged()
    if self.zamb_Enraged then return end
    self.zamb_Enraged = true
    self:SetNWBool( "zamb_SpiritEnraged", true )
    self.zamb_RageUntil = CurTime() + RAGE_TIME
    self:SetNW2Float( "zamb_RageUntil", self.zamb_RageUntil )
    self.zamb_RageLastHurt = CurTime()
    self.zamb_RageLastSaw = CurTime()
    self.zamb_RageLandedHit = false

    self.zamb_StayOutOfMeleeRange = false
    self:ApplyMoveStats()
    self:ReallyAnger( 120 )

    if CurTime() - ( self.zamb_LastCalmed or -math.huge ) > RAGE_ACT_COOLDOWN then
        self:ZAMB_AngeringCall( true, 2 )
        self:EmitSound( "npc/advisor/advisor_scream.wav", 100, 70, 1, CHAN_STATIC )
        self:EmitSound( "ambient/levels/citadel/strange_talk" .. math.random( 3, 11 ) .. ".wav", 90, 45, 1, CHAN_STATIC )

        local ed = EffectData()
        ed:SetMagnitude( 1 )
        ed:SetOrigin( self:WorldSpaceCenter() )
        ed:SetRadius( 120 )
        ed:SetNormal( self:GetAngles():Up() )
        util.Effect( "eff_zambspirit_blast", ed, true, true )

    end

    -- drop whatever hiding or fleeing it was doing
    self:KillAllTasksWith( "movement" )
    self:StartTask( "movement_handler", "they found me" )
    self:RestartMotionCoroutine()

end

-- Back to the shadows, staying alive and summoning beats chasing someone who's stopped fighting.
function ENT:CalmDown()
    if not self.zamb_Enraged then return end
    self.zamb_Enraged = false
    self:SetNWBool( "zamb_SpiritEnraged", false )
    self.zamb_LastCalmed = CurTime()

    self.zamb_StayOutOfMeleeRange = nil -- back to the class's
    self:ApplyMoveStats()

    self:EmitSound( "npc/advisor/advisor_speak01.wav", 85, 60, 1, CHAN_STATIC )

    self:KillAllTasksWith( "movement" )
    local enemy = self:GetEnemy()
    if IsValid( enemy ) then
        self:StartTask( "movement_spirit_hide", { EnemyPos = enemy:GetPos(), EnemyEyes = enemy:EyePos() }, "not worth it" )

    else
        self:StartTask( "movement_handler", "they're gone" )

    end
    self:RestartMotionCoroutine()

end

-- Facing away from us, and moving away from us.
function ENT:IsRetreating( enemy )
    local toMe = self:GetPos() - enemy:GetPos()
    toMe.z = 0
    toMe:Normalize()

    local facing = enemy.GetAimVector and enemy:GetAimVector() or enemy:GetForward()
    facing.z = 0
    if facing:Dot( toMe ) > 0 then return false end

    local vel = enemy:GetVelocity()
    vel.z = 0
    return vel:Dot( toMe ) < -50 -- backpedaling slowly while turned around doesn't count

end

function ENT:RageThink()
    local enemy = self:GetEnemy()
    if not IsValid( enemy ) or enemy:Health() <= 0 then self:CalmDown() return end

    local cur = CurTime()
    if self.IsSeeEnemy then
        self.zamb_RageLastSaw = cur

    elseif cur - self.zamb_RageLastSaw > RAGE_LOST_TIME then
        self:CalmDown() -- out of sight, slinking off can't look silly
        return

    end

    -- below half health it holds a grudge, it'll chase them down
    local healthy = self:Health() > self:GetMaxHealth() * 0.5
    if healthy and cur - self.zamb_RageLastHurt > RAGE_RETREAT_GRACE and self:IsRetreating( enemy ) then
        self:CalmDown() -- they learned their lesson
        return

    end

    if self.zamb_RageUntil > cur then return end
    -- they've stopped hitting us, but backing off mid duel looks broken unless we got our hit in, or they ran
    if self.zamb_RageLandedHit or self.DistToEnemy > self.DeployDistance then
        self:CalmDown()

    end
end

function ENT:SpiritThink()
    BaseClass.SpiritThink( self )
    self:SendDueSummons()
    self:ExpireOrders()

    local desperate = self:Health() < self:GetMaxHealth() * self.DesperateHealthFrac
    if desperate ~= self.zamb_Desperate then -- regen can lift it back out
        self.zamb_Desperate = desperate
        self:ApplyMoveStats()

    end

    if self:IsControlledByPlayer() then return end
    if self.zamb_Enraged then
        self:RageThink()

    else
        self:BodyguardThink()

    end
end

-- Decides rage before the base's damage handling, so the hit that enrages it doesn't also make it leap away.
function ENT:SpiritOnDamaged( dmg )
    local attacker = dmg:GetAttacker()
    local hostile = IsValid( attacker ) and attacker ~= self and attacker:GetParent() ~= self -- fire parented to us
    hostile = hostile and self:TERM_GetRelationship( self:GetTable(), attacker ) ~= D_LI
    if hostile and not self:IsControlledByPlayer() then
        if self.zamb_Enraged then
            self.zamb_RageUntil = CurTime() + RAGE_TIME
            self:SetNW2Float( "zamb_RageUntil", self.zamb_RageUntil )
            self.zamb_RageLastHurt = CurTime()

        else
            local near = attacker:GetPos():DistToSqr( self:GetPos() ) < RAGE_NEAR_DIST ^ 2
            local hurt = self:Health() < self:GetMaxHealth() * 0.5
            if near or hurt then
                self:BecomeEnraged()

            else -- BodyguardThink sends them once the cooldown's up
                self.zamb_BodyguardsFor = attacker

            end
        end
    end
    return BaseClass.SpiritOnDamaged( self, dmg )

end

function ENT:SpiritDealtFistDamage( target )
    if self.zamb_Enraged and target == self:GetEnemy() then
        self.zamb_RageLandedHit = true

    end
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self.zamb_Ordered = {}
    self.zamb_PendingSends = {}
    self.zamb_Enraged = false
    self.zamb_Desperate = false
    self.zamb_SpawnStats = {
        walk  = self.WalkSpeed,
        move  = self.MoveSpeed,
        run   = self.RunSpeed,
        accel = self.AccelerationSpeed,
        decel = self.DecelerationSpeed,
        fist  = self.FistDamageMul,
    }
end

function ENT:SpiritDeath()
    if self:GetIsDying() then return end
    self:RevokeOrders()
    BaseClass.SpiritDeath( self )

end
