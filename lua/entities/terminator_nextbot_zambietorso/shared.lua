AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Torso"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambietorso", {
    Name = "Zombie Torso",
    Class = "terminator_nextbot_zambietorso",
    Category = "Nexbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambietorso", ENT.PrintName )
    return

end

ENT.CoroutineThresh = 0.0000025

ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 16, 16, 15 ) }
ENT.AlwaysCrouching = true

ENT.WalkSpeed = 25
ENT.MoveSpeed = 40
ENT.RunSpeed = 50
ENT.JumpHeight = 20
ENT.StepHeight = 15

ENT.SpawnHealth = 50
ENT.FistDamageMul = 0.55
ENT.NoAnimLayering = true
ENT.zamb_MeleeAttackAdditionalDelay = 1
ENT.zamb_MeleeAttackHitFrameMul = 4
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

ENT.zamb_LookAheadWhenRunning = true -- mdl doesnt support different move/look angles
local TORSO_MDL = "models/zombie/classic_torso.mdl"
ENT.ARNOLD_MODEL = TORSO_MDL
ENT.MyPhysicsMass = 35

ENT.Models = { TORSO_MDL }

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
    self:SetModel( TORSO_MDL )
    BaseClass.AdditionalInitialize( self )
    self:SetModel( TORSO_MDL )

end