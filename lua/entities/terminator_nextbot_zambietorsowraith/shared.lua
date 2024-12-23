AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiewraith"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Torso Wraith"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambietorsowraith", {
    Name = "Zombie Torso Wraith",
    Class = "terminator_nextbot_zambietorsowraith",
    Category = "Nexbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambietorsowraith", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.0001

ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 16, 16, 15 ) }
ENT.AlwaysCrouching = true

ENT.WalkSpeed = 100
ENT.MoveSpeed = 125
ENT.RunSpeed = 250
ENT.JumpHeight = 30
ENT.StepHeight = 20

ENT.SpawnHealth = 25
ENT.FistDamageMul = 1
ENT.zamb_MeleeAttackHitFrameMul = 4
ENT.zamb_MeleeAttackSpeed = 1.75
ENT.FistDamageMul = 0.1
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

ENT.zamb_LookAheadWhenRunning = true -- mdl doesnt support different move/look angles
local FAST_TORSO_MDL = "models/zombie/fast_torso.mdl"
ENT.ARNOLD_MODEL = FAST_TORSO_MDL
ENT.MyPhysicsMass = 30

ENT.Models = { FAST_TORSO_MDL }

ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_WALK,
    [ACT_MP_CROUCH_IDLE]                = ACT_WALK,
    [ACT_MP_CROUCHWALK]                 = ACT_WALK,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = ACT_INVALID,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = ACT_INVALID,
    [ACT_MP_RELOAD_STAND]               = ACT_INVALID,
    [ACT_MP_RELOAD_CROUCH]              = ACT_INVALID,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CantCall = true

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( FAST_TORSO_MDL )

end