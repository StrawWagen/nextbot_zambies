AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambie_slow", {
    Name = "Zombie Snail",
    Class = "terminator_nextbot_zambie_slow",
    Category = "Nexbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambie_slow", ENT.PrintName )
    return

end

-- cheap asf
ENT.CoroutineThresh = 0.000005
ENT.MaxPathingIterations = 2500

ENT.JumpHeight = 64
ENT.SpawnHealth = 75
ENT.WalkSpeed = 50
ENT.MoveSpeed = 50
ENT.RunSpeed = 75
ENT.AccelerationSpeed = 750

ENT.FistDamageMul = 0.55

ENT.IsFodder = true
ENT.IsStupid = true
ENT.zamb_BrainsChance = 0

ENT.MyPhysicsMass = 78

local walkStart = ACT_HL2MP_WALK_ZOMBIE_01
local function randomWalk( ent )
    return walkStart + ( ent:GetCreationID() % 4 )

end

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = randomWalk,
    [ACT_MP_RUN]                        = randomWalk,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_HL2MP_SWIM,
    [ACT_LAND]                          = ACT_LAND,
}

function ENT:shouldDoWalk()
    return true

end

function ENT:canDoRun()
    return false

end