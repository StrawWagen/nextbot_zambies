AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambietemporal"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Temporal Elite"
ENT.Spawnable = true

list.Set( "NPC", "terminator_nextbot_zambietemporalelite", {
    Name = "Zombie Temporal Elite",
    Class = "terminator_nextbot_zambietemporalelite",
    Category = "Nextbot Zambies",
} )

ENT.TERM_MODELSCALE = 1.4
ENT.SpawnHealth = 900
ENT.FistDamageMul = 1.2

ENT.TemporalEffectColor = 255 + 50 * 256 + 50 * 65536

ENT.TemporalTrailColor = Color(255, 50, 50, 255)
ENT.TemporalTrailMat = "sprites/tp_beam001.vmt"

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Temporal Warp",
        desc = "Teleport near your target.",
        ratelimit = 4, 
        svAction = function( driveController, driver, bot )
            bot:TEMPORAL_TryWarp(driver)
        end,
    },
    ["temporalize"] = {
        inBind = IN_ATTACK2, -- Mouse 2
        drawHint = true,
        name = "Temporalize",
        desc = "Temporarily temporalize a nearby zambie.",
        ratelimit = 15,
        svAction = function( driveController, driver, bot )
            bot:TEMPORAL_TryTemporalize()
        end,
    }
}

-- Automatically temporalize nearby zambies when an enemy is present
ENT.MyClassTask = {
    BehaveUpdatePriority = function( self, data )
        -- Throttle the check to optimize performance
        if (self.NextTemporalizeCheck or 0) > CurTime() then return end
        self.NextTemporalizeCheck = CurTime() + 0.5

        if not self:CanTakeAction( "temporalize" ) then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        
        -- Only take action if there's actually someone valid to temporalize
        if IsValid( self:FindValidTemporalizeTarget() ) then
            self:TakeAction( "temporalize" )
        end
    end
}

if CLIENT then
    language.Add( "terminator_nextbot_zambietemporalelite", ENT.PrintName )

    local nullMat = Material("null")
    local matCache = {}

    local function GetMat(path)
        if not path or path == "" then return nullMat end
        if not matCache[path] then
            matCache[path] = Material(path)
        end
        return matCache[path]
    end

    function ENT:Draw()
        local mats = self:GetMaterials()
        local numMats = #mats

        -- Cache the isCrab check and material objects on the first draw to optimize
        if not self.TemporalDrawInfo then
            self.TemporalDrawInfo = {}
            for i = 0, numMats - 1 do
                local sub = self:GetSubMaterial(i)
                local matStr = sub ~= "" and sub or (mats[i+1] or "")
                self.TemporalDrawInfo[i] = {
                    isCrab = string.find(string.lower(matStr), "crab") ~= nil,
                    mat = GetMat(matStr)
                }
            end
        end

        local drawInfo = self.TemporalDrawInfo

        -- 1. Draw body normally, hide ALL headcrabs completely
        render.MaterialOverride(nullMat)
        for i = 0, numMats - 1 do
            if not drawInfo[i].isCrab then
                render.MaterialOverrideByIndex(i, drawInfo[i].mat)
            else
                render.MaterialOverrideByIndex(i, nullMat)
            end
        end
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        self:DrawModel()

        -- 2. Draw headcrabs red, hide ALL body parts completely
        for i = 0, numMats - 1 do
            if drawInfo[i].isCrab then
                render.MaterialOverrideByIndex(i, drawInfo[i].mat)
            else
                render.MaterialOverrideByIndex(i, nullMat)
            end
        end
        render.SetColorModulation(1.0, 50/255, 50/255) -- Red Color (255, 50, 50)
        render.SetBlend(1)
        self:DrawModel()

        -- 3. Cleanup rendering state
        render.MaterialOverride(nil)
        for i = 0, numMats - 1 do
            render.MaterialOverrideByIndex(i, nil)
        end
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
    end

    return
end

local function TemporalFindTeleportPosForAlly( ally, enemy )
    local myPos = ally:GetPos()
    local enemyPos = enemy:GetPos()

    local areas = navmesh.Find( enemyPos, 500, 100, 100 )
    for i = #areas, 2, -1 do 
        local j = math.random(i)
        areas[i], areas[j] = areas[j], areas[i]
    end

    for _, area in ipairs( areas ) do
        local testPos = area:GetRandomPoint()
        local dist = myPos:Distance( testPos )
        local zDiffEnemy = math.abs(testPos.z - enemyPos.z)
        local zDiffSelf = math.abs(testPos.z - myPos.z)
        if dist > 10 and zDiffEnemy < 80 and zDiffSelf < 300 and enemyPos:Distance( testPos ) < 350 then
            return testPos
        end
    end

    local tr = util.TraceLine({
        start = enemyPos + Vector(0, 0, 10),
        endpos = enemyPos - Vector(0, 0, 1000),
        filter = { ally, enemy },
        mask = MASK_NPCWORLDSTATIC
    })
    if tr.Hit then return tr.HitPos end

    return myPos
end

-- Helper to find a valid target without wasting the ability cooldown
function ENT:FindValidTemporalizeTarget()
    local allies = self:GetNearbyAllies( 600 )
    local bestAlly
    local bestDist = 600^2
    
    for _, ally in ipairs( allies ) do
        if IsValid( ally ) and ally.isTerminatorHunterChummy == "zambies" and ally ~= self and not ally.IsTemporalized then
            local class = ally:GetClass()
            -- QOL: Cannot temporalize other temporals
            if class == "terminator_nextbot_zambietemporal" or class == "terminator_nextbot_zambietemporalelite" then
                continue
            end
            
            -- QOL: Max 2.5K health limit
            if ally:Health() > 2500 then
                continue
            end
            
            local dist = self:GetPos():DistToSqr( ally:GetPos() )
            if dist < bestDist then
                bestDist = dist
                bestAlly = ally
            end
        end
    end
    return bestAlly
end

function ENT:TEMPORAL_TryTemporalize()
    local bestAlly = self:FindValidTemporalizeTarget()
    if not IsValid( bestAlly ) then return end

    -- Temporalize the ally
    bestAlly.IsTemporalized = CurTime() + math.Rand( 7, 10 )
    bestAlly.TemporalEffectColor = 0 + 114 * 256 + 255 * 65536
    
    -- Store old headcrab material (index 1) and apply temporal headcrab texture
    bestAlly.OldCrabMats = bestAlly.OldCrabMats or {}
    bestAlly.OldCrabMats[1] = bestAlly:GetSubMaterial(1)
    bestAlly:SetSubMaterial( 1, "models/temporal/blackcrab_sheet.vmt" )

    -- Give them the memory cloud effect
    local memEd = EffectData()
    memEd:SetOrigin( bestAlly:GetPos() )
    memEd:SetEntity( bestAlly )
    memEd:SetScale( 1 )
    util.Effect( "eff_temporal_memorycloud", memEd )

    bestAlly.NextTemporalTeleport = CurTime() + math.Rand( 1, 3 )

    local allyIndex = bestAlly:EntIndex()

    -- Timer to handle dynamic teleporting and reversion
    timer.Create( "Temporalized_" .. allyIndex, 1, 0, function()
        if not IsValid( bestAlly ) then return end
        
        -- Revert back to normal after time expires
        if not bestAlly.IsTemporalized or CurTime() > bestAlly.IsTemporalized then
            timer.Remove( "Temporalized_" .. allyIndex )
            if bestAlly.OldCrabMats then
                bestAlly:SetSubMaterial( 1, bestAlly.OldCrabMats[1] or "" )
            end
            bestAlly.TemporalEffectColor = nil
            bestAlly.IsTemporalized = nil
            return
        end

        -- Give them the teleport ability
        local enemy = bestAlly:GetEnemy()
        if IsValid( enemy ) and bestAlly:IsOnGround() and CurTime() > (bestAlly.NextTemporalTeleport or 0) then
            local distToEnemy = bestAlly:GetPos():DistToSqr( enemy:GetPos() )
            if distToEnemy > 200^2 then
                local pos = TemporalFindTeleportPosForAlly( bestAlly, enemy )
                
                if pos then
                    local ed = EffectData()
                    ed:SetOrigin( bestAlly:GetPos() + Vector(0, 0, 40) )
                    ed:SetScale( 2 )
                    ed:SetFlags( 2 )
                    ed:SetColor( bestAlly.TemporalEffectColor )
                    util.Effect( "eff_temporal_warp_events", ed )

                    bestAlly:SetPos( pos )
                    bestAlly:InvalidatePath( "temporalized" )

                    local ed2 = EffectData()
                    ed2:SetOrigin( pos + Vector(0, 0, 40) )
                    ed2:SetScale( 1 )
                    ed2:SetFlags( 1 )
                    ed2:SetColor( bestAlly.TemporalEffectColor )
                    util.Effect( "eff_temporal_warp_events", ed2 )

                    bestAlly:EmitSound( "NPC_PoisonZombie.Alert" ) -- Replaced ezt appear sound
                    bestAlly.NextTemporalTeleport = CurTime() + math.Rand( 3, 5 )
                end
            end
        end
    end )
end

function ENT:Temporal_DoTeleport( targetPos )
    self:Temporal_SpawnVanishCorpse()

    self:SetPos( targetPos )
    self:InvalidatePath( "temporal_teleport" )

    local ed = EffectData()
    local scale = self:GetModelScale() or 1
    local chestPos = targetPos + Vector(0, 0, 40) * scale
    ed:SetOrigin( chestPos )
    ed:SetScale(1)
    ed:SetFlags(1)
    ed:SetColor(self.TemporalEffectColor)
    util.Effect( "eff_temporal_warp_events", ed )

    self:EmitSound( "NPC_PoisonZombie.Alert" ) -- Replaced ezt appear sound
end

function ENT:Temporal_SpawnVanishCorpse( posOverride )
    local pos = posOverride or self:GetPos()
    local corpse = ents.Create( "prop_ragdoll" )
    if not IsValid( corpse ) then return end

    corpse:SetPos( pos )
    corpse:SetAngles( self:GetAngles() )
    corpse:SetModel( self:GetModel() )
    corpse:SetModelScale( self:GetModelScale(), 0 )
    corpse:SetOwner( self )
    corpse:Spawn()
    corpse:Activate()
    corpse:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    corpse:SetSubMaterial( 0, "models/temporal/poisonzombie_sheet.vmt" )

    timer.Simple( 0.1, function()
        if not IsValid( corpse ) then return end
        for i = 0, corpse:GetPhysicsObjectCount() - 1 do
            local phys = corpse:GetPhysicsObjectNum( i )
            if IsValid( phys ) then
                phys:EnableMotion( false )
            end
        end
    end )

    corpse:Fire( "FadeAndRemove", "", 0.2 )

    local ed = EffectData()
    local scale = self:GetModelScale() or 1
    local chestPos = pos + Vector(0, 0, 40) * scale
    ed:SetOrigin( chestPos )
    ed:SetScale(2)
    ed:SetFlags(2)
    ed:SetColor(self.TemporalEffectColor)
    util.Effect( "eff_temporal_warp_events", ed )

    self:EmitSound( "NPC_PoisonZombie.Pain" ) -- Replaced ezt vanish sound
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
end