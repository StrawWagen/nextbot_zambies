AddCSLuaFile()

SWEP.Base = "weapon_terminatorfists_term"

SWEP.PrintName = "Zombie Claws"
SWEP.Spawnable = false
SWEP.Author = "StrawWagen"
SWEP.Purpose = "Innate weapon that the zombie will use"

SWEP.Range = 50

SWEP.DamageMin = 15
SWEP.DamageMax = 25
SWEP.DamageType = DMG_SLASH

SWEP.PropDamageBonusMul = 3
SWEP.NPCDamageBonusMul = 1

SWEP.SwingSound = Sound( "Zombie.AttackMiss" )
SWEP.HitSound = Sound( "Zombie.AttackHit" )
SWEP.ViewPunchMul = 4

local className = "weapon_term_zombieclaws"
if CLIENT then
    language.Add( className, SWEP.PrintName )

end

function SWEP:PlayHitSound( owner, pitchShift )
    owner:EmitSound( self.HitSound, 75, 100 + pitchShift )

end

function SWEP:PlaySwingSound( owner, pitchShift )
    owner:EmitSound( self.SwingSound, 75, 100 + pitchShift )

end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    local owner = self:GetOwner()

    local act = owner.zamb_AttackAnim or ACT_GMOD_GESTURE_RANGE_ZOMBIE
    if not act or ( isnumber( act ) and act <= 0 ) then return end
    local seq

    if isstring( act ) then
        seq = owner:LookupSequence( act )

    else
        seq = owner:SelectWeightedSequence( act )

    end
    local seqSpeed = owner.zamb_MeleeAttackSpeed or 1

    local additionalDelay = owner.zamb_MeleeAttackAdditionalDelay or 0
    local meleeTime = owner:SequenceDuration( seq ) / seqSpeed
    local nextMeleeTime = CurTime() + ( ( meleeTime - 0.1 ) * seqSpeed ) + additionalDelay
    self:SetNextPrimaryFire( nextMeleeTime )
    -- play anim next tick
    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        if not IsValid( owner ) then return end
        if not owner.DoGesture then return end
        owner:DoGesture( act, seqSpeed, owner.NoAnimLayering or false )

    end )

    local hitframeMul = owner.zamb_MeleeAttackHitFrameMul or 1

    local dmgTime = ( ( meleeTime - 0.7 ) / seqSpeed ) * hitframeMul

    -- deal damage
    timer.Simple( dmgTime, function()
        if not IsValid( self ) then return end
        if not IsValid( owner ) then return end
        if not owner:IsSolid() then return end
        if owner.RunTask and owner:RunTask( "BlockClawSwipe" ) then return end
        self:DealDamage()

        self:SetClip1( self:Clip1() - 1 )
        self:SetLastShootTime()

    end )
end

-- so our holdtype doesnt override the npc's anim translations
function SWEP:TranslateActivity()
end
