AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambietank"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Tank Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambietankelite", {
    Name = "Zombie Tank Elite",
    Class = "terminator_nextbot_zambietankelite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambietankelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.5, 0.5, 0.3 )
        self:DrawModel()

    end

    return
end

ENT.IsFodder = false
ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 10

ENT.JumpHeight = 120
ENT.DefaultStepHeight = 20
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 20000
ENT.ExtraSpawnHealthPerPlayer = 2500
ENT.AimSpeed = 400
ENT.WalkSpeed = 80
ENT.MoveSpeed = 400
ENT.RunSpeed = 1000
ENT.AccelerationSpeed = 1000

ENT.FistDamageMul = 25
ENT.FistForceMul = 20
ENT.DuelEnemyDist = 700
ENT.PrefersVehicleEnemies = true
ENT.FistRangeMul = 1.5

ENT.TERM_MODELSCALE = 2
ENT.CollisionBounds = { Vector( -8, -8, 0 ), Vector( 8, 8, 25 ) }
ENT.CrouchCollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 20 ) }
ENT.MyPhysicsMass = 5000

ENT.TERM_FISTS = "weapon_term_zombieclaws"


-- tanks dont care about body smell
function ENT:AdditionalAvoidAreas()
end


function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self.HasBrains = true

    self.term_SoundPitchShift = -55
    self.term_SoundLevelShift = 25

    self.HeightToStartTakingDamage = 800
    self.DeathDropHeight = 3000

    self.zamb_HasArmor = true
    self.zamb_LoseCoolRatio = 0.75
    self.zamb_UnderArmorMat = "models/flesh"

end

function ENT:BreakArmor()
    BaseClass.BreakArmor( self )

    self.Term_BaseMsBetweenSteps = 400
    self.Term_FootstepMsReductionPerUnitSpeed = 0.6

    self.JumpHeight = 600
    self.FistRangeMul = 2.5

    self.AccelerationSpeed = 450
    self.loco:SetAcceleration( self.AccelerationSpeed )

    self.loco:SetJumpHeight( self.JumpHeight )

end

ENT.Term_FootstepTiming = "perfect"
ENT.PerfectFootsteps_FeetBones = { "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot" }
ENT.PerfectFootsteps_SteppingCriteria = -0.7

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:AdditionalFootstep( pos, foot, _sound, volume, _filter )
    local lvl = 83
    local snd = foot and "npc/antlion_guard/foot_heavy1.wav" or "npc/antlion_guard/foot_light2.wav"
    if self:GetVelocity():LengthSqr() <= self.MoveSpeed^2 then
        lvl = 76

    else
        self:EmitSound( "npc/antlion_guard/shove1.wav", math.random( 75, 79 ), math.random( 70, 80 ), 1, CHAN_STATIC )
        util.ScreenShake( pos, 5, 5, 0.5, 500 + self:GetVelocity():Length() )

    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    return true

end

function ENT:IsImmuneToDmg( dmg )
    if not self.zamb_HasArmor then return end
    if dmg:GetDamage() <= math.Rand( 12, 20 ) then
        self:SetBloodColor( DONT_BLEED )
        self:EmitSound( "npc/antlion/shell_impact" .. math.random( 1, 4 ) .. ".wav", math.random( 75, 79 ), math.random( 120, 140 ), 1, CHAN_ITEM )
        return true

    end
end
