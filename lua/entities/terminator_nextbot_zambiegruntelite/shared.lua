AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiegrunt"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Grunt Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiegruntelite", {
    Name = "Zombie Grunt Elite",
    Class = "terminator_nextbot_zambiegruntelite",
    Category = "Nextbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambiegruntelite", ENT.PrintName )
    return

end

ENT.SpawnHealth = 2000
ENT.ExtraSpawnHealthPerPlayer = 50
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 1
ENT.WalkSpeed = 40
ENT.MoveSpeed = 150
ENT.RunSpeed = 425
ENT.AccelerationSpeed = 350

ENT.FistDamageMul = 1.5
ENT.zamb_MeleeAttackSpeed = 1.25

ENT.TERM_MODELSCALE = function() return math.Rand( 1.15, 1.2 ) end
ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 60 ) } -- this is then scaled by modelscale
ENT.MyPhysicsMass = 250

ENT.zambGrunt_HasArmor = true

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self.term_SoundPitchShift = -35
    self.term_SoundLevelShift = 15

end

function ENT:AdditionalThink( myTbl )
    local doAltRun = false
    if self:Health() <= self:GetMaxHealth() * 0.5 then
        doAltRun = true

    end

    local cur = CurTime() + self:GetCreationID()

    if not doAltRun then
        doAltRun = cur % 8 < 2.5

    end

    if doAltRun then
        if cur % 2 < 1.5 then
            myTbl.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_PROTECTED

        else
            myTbl.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_CHARGING

        end
    else
        myTbl.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE

    end
end
