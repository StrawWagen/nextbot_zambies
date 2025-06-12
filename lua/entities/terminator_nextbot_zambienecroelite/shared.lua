AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambienecro"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Necromancer Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambienecroelite", {
    Name = "Zombie Necromancer Elite",
    Class = "terminator_nextbot_zambienecroelite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambienecroelite", ENT.PrintName )
    return

end

ENT.IsFodder = false
ENT.CoroutineThresh = 0.0001

ENT.JumpHeight = 40
ENT.DefaultStepHeight = 20
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 25000
ENT.ExtraSpawnHealthPerPlayer = 2500
ENT.HealthRegen = 25
ENT.HealthRegenInterval = 1
ENT.WalkSpeed = 100
ENT.MoveSpeed = 150
ENT.RunSpeed = 300
ENT.neverManiac = true

ENT.FistDamageMul = 25
ENT.FistForceMul = 20
ENT.FistRangeMul = 2
ENT.zamb_MeleeAttackHitFrameMul = 0.5

ENT.PrefersVehicleEnemies = true

ENT.TERM_MODELSCALE = 2.5
ENT.CollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 22 ) }
ENT.MyPhysicsMass = 5000


function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self.term_SoundPitchShift = -40
    self.term_SoundLevelShift = 20

    self.HeightToStartTakingDamage = 600
    self.DeathDropHeight = 3000

    self.zamb_LoseCoolRatio = 0.75

    self.necro_MinionCountMul = 2
    self.necro_MinMinionCount = 2
    self.necro_MaxMinionCount = 24
    self.necro_NormalMinionClass = {
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambie",
        "terminator_nextbot_zambiegrunt",

    }

    self.necro_ReachableFastMinionChance = 40
    self.necro_UnReachableFastMinionChance = 90
    self.necro_UnreachableCountAdd = 4
    self.necro_FastMinionClass = "terminator_nextbot_zambiefast"

    self.necro_NearDeathClassChance = 10
    self.necro_NearDeathMinionClass = "terminator_nextbot_zambieberserk"

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl = 93
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 78

    end
    self:EmitSound( "NPC_Strider.Footstep", lvl, 80, volume + 1, CHAN_STATIC, sndFlags )
    return true

end


local dotVec = Vector( 0,0,1 )

function ENT:AdditionalThink( myTbl )
    BaseClass.AdditionalThink( self, myTbl )

    if not myTbl.loco:IsOnGround() then return end

    local leftFoot = self:LookupBone( "ValveBiped.Bip01_L_Foot" )
    local leftFootPos, leftFootAng = self:GetBonePosition( leftFoot )

    local rightFoot = self:LookupBone( "ValveBiped.Bip01_R_Foot" )
    local rightFootPos, rightFootAng = self:GetBonePosition( rightFoot )

    local currStepping = { left = false, right = false }
    local oldStepping = myTbl.custom_OldStepping or currStepping
    local feet = { left = { pos = leftFootPos, ang = leftFootAng }, right = { pos = rightFootPos, ang = rightFootAng } }

    for curr, foot in pairs( feet ) do
        local dot = foot.ang:Forward():Dot( dotVec )
        currStepping[curr] = dot < -0.75

        if currStepping[curr] and not oldStepping[curr] then
            myTbl.NeedsAStep = true

        end
    end

    myTbl.custom_OldStepping = currStepping

end

-- yuck!
function ENT:GetFootstepSoundTime()
    if self.NeedsAStep then
        self.NeedsAStep = nil
        return 0

    end
    return math.huge

end