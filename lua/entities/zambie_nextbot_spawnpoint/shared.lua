AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category    = "Other"
ENT.PrintName   = "( Hard )AI \"Directed\" Zambie Spawnpoint"
ENT.Author      = "StrawWagen"
ENT.Purpose     = "Spawns zombies when nobody's near to it, or looking at it!"
ENT.Information = ENT.Purpose
ENT.Spawnable    = true
ENT.AdminOnly    = true
ENT.Model = "models/props_junk/sawblade001a.mdl"


--[[

diffAdded, difficulty added when this is spawned, prevents it from spawning 300 tanks at once, getting ahead of itself
diffNeeded, target difficulty neeeded, only spawn this when its supposed to be difficult, or easy
diffMax, dont spawn this when target difficulty is above this.
passChance, kinda unintitive, the code goes thru this table in a loop, so stuff at the bottom will override stuff at the top,
            basically this is the chance to NOT override what came before
batchSize, makes this into a batch spawn, so like 6 of one thing
randomSpawnAnyway,   randomly spawn this even if none of the conditions are met
maxAtOnce, max count of this on the field at once, checks class

--]]

function ENT:DoSpawnPool()
    self.SpawnPool = {
        { class = "terminator_nextbot_zambie",              diffAdded = 3, diffNeeded = 0, passChance = 0 },
        { class = "terminator_nextbot_zambie_slow",         diffAdded = 3, diffNeeded = 0, diffMax = 5, passChance = 25 },
        { class = "terminator_nextbot_zambie_slow",         diffAdded = 3, diffNeeded = 0, diffMax = 15, passChance = 50 },

        { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 0, passChance = 92 },
        { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 30 },
        { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 90, passChance = 99, batchSize = 8 },

        { class = "terminator_nextbot_zambieacid",         diffAdded = 6, diffNeeded = 0, passChance = 95 },
        { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 45 },
        { class = "terminator_nextbot_zambieacid",         diffAdded = 3, diffNeeded = 90, passChance = 99, batchSize = 8 },

        { class = "terminator_nextbot_zambiefast",          diffAdded = 6, diffNeeded = 25, passChance = 25, randomSpawnAnyway = 5 },
        { class = "terminator_nextbot_zambietorsofast",     diffAdded = 3, diffNeeded = 25, passChance = 45, spawnSlot = "torsofast" },
        { class = "terminator_nextbot_zambiefastgrunt",     diffAdded = 12, diffNeeded = 75, passChance = 95 },

        { class = "terminator_nextbot_zambiegrunt",         diffAdded = 10, diffNeeded = 50, passChance = 95 },
        { class = "terminator_nextbot_zambiegruntelite",    diffAdded = 30, diffNeeded = 90, passChance = 98 },

        { class = "terminator_nextbot_zambieberserk",       diffAdded = 30, diffNeeded = 90, passChance = 85, maxAtOnce = 1 },

        { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 90, passChance = 92 },
        { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, diffMax = 10, passChance = 99, batchSize = 10 },
        { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 0, diffMax = 10, passChance = 95 },

        { class = "terminator_nextbot_zambietank",          diffAdded = 40, diffNeeded = 90, passChance = 75, spawnSlot = "miniboss" },
        { class = "terminator_nextbot_zambienecro",         diffAdded = 40, diffNeeded = 90, passChance = 75, spawnSlot = "miniboss" },
        { class = "terminator_nextbot_zambiewraithelite",   diffAdded = 100, diffNeeded = 90, passChance = 99.5, spawnSlot = "miniboss" }, -- rare elite wraith duo

        { class = "terminator_nextbot_zambiewraith",        diffAdded = 25, diffNeeded = 99, passChance = 99, batchSize = 5, spawnSlot = "miniboss" }, -- smallish wraith wave
        { class = "terminator_nextbot_zambiewraith",        diffAdded = 30, diffNeeded = 99, passChance = 99.5, batchSize = 20, spawnSlot = "miniboss" }, -- rare hell wraith wave
        { class = "terminator_nextbot_zambiewraithelite",   diffAdded = 50, diffNeeded = 99, passChance = 99.9, batchSize = 3, spawnSlot = "miniboss" }, -- rare elite wraith duo
        { class = "terminator_nextbot_zambieberserk",       diffAdded = 30, diffNeeded = 99, passChance = 99.5, batchSize = 5, spawnSlot = "miniboss" }, -- rare berserk wave
        { class = "terminator_nextbot_zambietank",          diffAdded = 60, diffNeeded = 99, passChance = 99.5, batchSize = 2, spawnSlot = "miniboss" }, -- rare 2 tank spawn
    }
end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "On" )

    if not SERVER then return end
    self:SetOn( true )

end

if CLIENT then
    -- copied from campaign entities...
    local cachedIsEditing = nil
    local nextCache = 0
    local CurTime = CurTime
    local LocalPlayer = LocalPlayer

    local function zambs_CanBeUgly()
        local ply = LocalPlayer()
        if IsValid( ply:GetActiveWeapon() ) and string.find( LocalPlayer():GetActiveWeapon():GetClass(), "camera" ) then return false end
        return true

    end

    local function zambs_IsEditing()
        if nextCache > CurTime() then return cachedIsEditing end
        nextCache = CurTime() + 0.01

        local ply = LocalPlayer()
        local moveType = ply:GetMoveType()
        if moveType ~= MOVETYPE_NOCLIP then     cachedIsEditing = nil return end
        if ply:InVehicle() then                 cachedIsEditing = nil return end
        if not zambs_CanBeUgly() then        cachedIsEditing = nil return end

        cachedIsEditing = true
        return true

    end

    function ENT:Draw()
        if zambs_IsEditing() then
            self:DrawModel()

        end
    end

    return

end

function ENT:Initialize()
    self:SetModel( self.Model )
    self:SetNoDraw( false )
    self:DrawShadow( false )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    self:DoSpawnPool()

    local configData = {
        spawnsOnlyIfHidden = true,
        spawnPool = self.SpawnPool

    }

    terminator_Extras.zamb_RegisterSpawner( self, configData )

end

function ENT:Zamb_OnZambSpawned( spawnedZamb )
    self:DeleteOnRemove( spawnedZamb )
    local creator = self:GetCreator()
    if IsValid( creator ) and creator:IsPlayer() then
        cleanup.Add( creator, "NPC", spawnedZamb )

    end
end

function ENT:ACF_PreDamage()
    -- can't be broken by ACF
    return false

end
