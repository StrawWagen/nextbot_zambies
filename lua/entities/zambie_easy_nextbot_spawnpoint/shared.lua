AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "zambie_nextbot_spawnpoint"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName   = "( Easy ) AI \"Directed\" Zambie Spawnpoint"
ENT.Purpose     = "Spawns zombies when nobody's near to it, or looking at it!\nOnly spawns weak zambies!"
ENT.Information = ENT.Purpose

ENT.Category    = "Other"
ENT.Author      = "StrawWagen"
ENT.Spawnable    = true
ENT.AdminOnly    = true

ENT.IconOverride = "entities/zambie_nextbot_spawnpoint.png"

function ENT:DoSpawnPool()
    self.SpawnPool = {
        { class = "terminator_nextbot_zambie",              diffAdded = 8, diffNeeded = 0, passChance = 0 },
        { class = "terminator_nextbot_zambietorso",         diffAdded = 4, diffNeeded = 0, passChance = 75, spawnSlot = "torso" },
        { class = "terminator_nextbot_zambie_slow",         diffAdded = 2, diffNeeded = 0, diffMax = 5, passChance = 25 },
        { class = "terminator_nextbot_zambie_slow",         diffAdded = 2, diffNeeded = 0, diffMax = 15, passChance = 50 },

        { class = "terminator_nextbot_zambieflame",         diffAdded = 6, diffNeeded = 0, passChance = 98 },

        { class = "terminator_nextbot_zambiefast",          diffAdded = 8, diffNeeded = 75, passChance = 50, randomSpawnAnyway = 5 },
        { class = "terminator_nextbot_zambietorsofast",     diffAdded = 5, diffNeeded = 35, passChance = 55, spawnSlot = "torsofast" },

        { class = "terminator_nextbot_zambiegrunt",         diffAdded = 10, diffNeeded = 70, passChance = 92 },

        { class = "terminator_nextbot_zambiewraith",        diffAdded = 20, diffNeeded = 90, passChance = 98 },
    }
end