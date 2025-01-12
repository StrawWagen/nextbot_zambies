AddCSLuaFile()

SWEP.PrintName = "Zombie Claws"
SWEP.Spawnable = false
SWEP.Author = "StrawWagen"
SWEP.Purpose = "Innate weapon that the zombie will use"

SWEP.Range    = 50
SWEP.Weight = 0
SWEP.HitMask = MASK_SOLID

local className = "weapon_terminatorfists_term"
if CLIENT then
    language.Add( className, SWEP.PrintName )
    killicon.Add( className, "vgui/hud/killicon/" .. className .. ".png", color_white )

end

local SwingSound = Sound( "Zombie.AttackMiss" )
local HitSound = Sound( "Zombie.AttackHit" )

SWEP.Primary = {
    Ammo = "None",
    ClipSize = -1,
    DefaultClip = -1,
}

SWEP.Secondary = {
    Ammo = "None",
    ClipSize = -1,
    DefaultClip = -1,
}

local function LockBustSound( ent )
    ent:EmitSound( "doors/vent_open1.wav", 100, 80, 1, CHAN_STATIC )
    ent:EmitSound( "physics/metal/metal_solid_strain3.wav", 100, 200, 1, CHAN_STATIC )

end

local function SparkEffect( SparkPos )
    timer.Simple( 0, function() -- wow wouldnt it be cool if effects worked on the first tick personally i think that would be really cool
        local Sparks = EffectData()
        Sparks:SetOrigin( SparkPos )
        Sparks:SetMagnitude( 2 )
        Sparks:SetScale( 1 )
        Sparks:SetRadius( 6 )
        util.Effect( "Sparks", Sparks )

    end )

end

local function ModelBoundSparks( ent )
    local randpos = ent:WorldSpaceCenter() + VectorRand() * ent:GetModelRadius()
    randpos = ent:NearestPoint( randpos )

    -- move them a bit in from the exact edges of the model
    randpos = ent:WorldToLocal( randpos )
    randpos = randpos * 0.8
    randpos = ent:LocalToWorld( randpos )

    SparkEffect( randpos )

end

local lockOffset = Vector( 0, 42.6, -10 )

local slidingDoors = {
    ["func_movelinear"] = true,
    ["func_door"] = true,

}

function SWEP:HandleDoor( tr, strength )
    if CLIENT or not IsValid( tr.Entity ) then return end
    local door = tr.Entity
    if door.realDoor then
        door = door.realDoor

    end
    local owner = self:GetOwner()
    local class = door:GetClass()

    -- let nails do their thing
    if door.huntersglee_breakablenails then return end

    local doorsLocked = door:GetInternalVariable( "m_bLocked" ) == true

    if doorsLocked then
        terminator_Extras.lockedDoorAttempts = {}

    end

    local doorsObj = door:GetPhysicsObject()
    local isProperDoor = class == "prop_door_rotating"
    local isSlidingDoor = slidingDoors[class]
    local isBashableSlidDoor
    if isSlidingDoor then
        isBashableSlidDoor = doorsObj:GetVolume() < 48880 -- magic number! 10x mass of doors on terrortrain

    end
    if owner.markAsTermUsed then
        owner:markAsTermUsed( door )

    end

    if isSlidingDoor and doorsLocked then
        local lockHealth = door.terminator_lockHealth
        if not door.terminator_lockHealth then
            local initialHealth = 200
            if doorsObj and doorsObj:IsValid() then
                initialHealth = math.max( initialHealth, doorsObj:GetVolume() / 1250 )

            end
            lockHealth = initialHealth
            door.terminator_lockMaxHealth = initialHealth

        end

        local lockDamage = 15 * strength

        lockHealth = lockHealth + -lockDamage

        if lockHealth <= 0 then
            lockHealth = nil
            door:Fire( "unlock", "", .01 )
            terminator_Extras.DoorHitSound( door )
            LockBustSound( door )

            util.ScreenShake( owner:GetPos(), 80, 10, 1, 1500 )

            for _ = 1, 20 do
                ModelBoundSparks( door )

            end

        else
            terminator_Extras.DoorHitSound( door )
            if lockHealth < door.terminator_lockMaxHealth * 0.45 then
                ModelBoundSparks( door )
                util.ScreenShake( owner:GetPos(), 10, 10, 0.5, 600 )
                local pitch = math.random( 175, 200 ) + math.Clamp( -lockHealth, -100, 0 )
                door:EmitSound( "physics/metal/metal_box_break1.wav", 90, pitch, 1, CHAN_STATIC )

            end
        end

        door.terminator_lockHealth = lockHealth

    elseif class == "func_door_rotating" or isProperDoor or isBashableSlidDoor then
        local HitCount = door.term_PunchedCount or 0
        door.term_PunchedCount = HitCount + strength

        if terminator_Extras.CanBashDoor( door ) == false then
            terminator_Extras.DoorHitSound( door )

        else
            if HitCount > 4 then
                terminator_Extras.BreakSound( door )

            end
            if HitCount > 2 then
                terminator_Extras.StrainSound( door )

            end

            if HitCount >= 5 then
                local debris = terminator_Extras.DehingeDoor( self, door )
                if not IsValid( debris ) then return end
                if not owner.markAsTermUsed then return end
                owner:markAsTermUsed( debris )

            elseif HitCount < 5 then
                terminator_Extras.DoorHitSound( door )
                terminator_Extras.StrainSound( door )

                if ( HitCount % 3 ) == 4 then
                    if owner.Use2 then
                        self:Use2( door )

                    else
                        door:Use( self, self )

                    end
                end

                if isProperDoor then
                    self:SoftBashProperDoor( door, owner )

                end
            end

            if doorsLocked and isProperDoor then
                SparkEffect( door:GetPos() + -lockOffset )
                LockBustSound( door )

            end
        end
    end
end

function SWEP:SoftBashProperDoor( door, owner )
    local newname = "TFABash" .. self:EntIndex()
    self.term_PreBashName = self:GetName()
    self:SetName( newname )

    if not door.term_defaultsGrabbed then
        door.term_defaultsGrabbed = true
        local values = door:GetKeyValues()
        door.term_oldBashSpeed = values["speed"]
        door.term_oldOpenDir = values["opendir"]
        door.term_oldOpenDmg = values["dmg"]

    end

    door:SetKeyValue( "speed", "500" )
    door:SetKeyValue( "opendir", 0 )
    door:SetKeyValue( "dmg", 100 )
    door:Fire( "unlock", "", .01 )
    door:Fire( "openawayfrom", newname, .01 )

    timer.Simple( 0.02, function()
        if not IsValid( owner ) or owner:GetName() ~= newname then return end

        owner:SetName( owner.term_PreBashName )

    end )

    timer.Simple( 0.3, function()
        if not IsValid( door ) then return end
        if door.term_oldBashSpeed then
            door:SetKeyValue( "speed", door.term_oldBashSpeed )

        end
        if door.term_oldOpenDir then
            door:SetKeyValue( "opendir", door.term_oldOpenDir )

        end
        if door.term_oldOpenDmg then
            door:SetKeyValue( "dmg", door.term_oldOpenDmg )

        end
    end )
end

function SWEP:Initialize()
    self:SetHoldType( "normal" )
    self:DrawShadow( false )

    if not SERVER then return end
    self.doFistsTime = 0

end

function SWEP:CanPrimaryAttack()
    return CurTime() > self:GetNextPrimaryFire()
end

function SWEP:CanSecondaryAttack()
    return false
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
    seqSpeed = owner.zamb_MeleeAttackSpeed

    local additionalDelay = owner.zamb_MeleeAttackAdditionalDelay or 0
    local meleeTime = owner:SequenceDuration( seq ) / seqSpeed
    local nextMeleeTime = CurTime() + ( ( meleeTime - 0.1 ) * seqSpeed ) + additionalDelay
    self:SetNextPrimaryFire( nextMeleeTime )
    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        if not IsValid( owner ) then return end
        if not owner.DoGesture then return end
        owner:DoGesture( act, seqSpeed, owner.NoAnimLayering or false )

    end )

    local hitframeMul = owner.zamb_MeleeAttackHitFrameMul or 1

    local dmgTime = ( ( meleeTime - 0.7 ) / seqSpeed ) * hitframeMul

    timer.Simple( dmgTime, function()
        if not IsValid( self ) then return end
        if not IsValid( owner ) then return end
        if not owner:IsSolid() then return end
        self:DealDamage()

        self:SetClip1( self:Clip1() - 1 )
        self:SetLastShootTime()
    end )
end

function SWEP:DealDamage()

    local owner = self:GetOwner()
    local strength = owner.FistDamageMul or 1
    local rangeMul = owner.FistRangeMul or 1

    local sizeMul = 1 + ( strength / 8 )
    local range = self.Range * rangeMul
    local trDat = {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * range,
        filter = owner,
        mask = bit.bor( self.HitMask ),
    }

    local tr = util.TraceLine( trDat )

    if strength > 10 and not IsValid( tr.Entity ) then -- half sized one
        trDat = {
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * range,
            filter = owner,
            mins = Vector( -10, -10, -8 ) * sizeMul / 2,
            maxs = Vector( 10, 10, 8 ) * sizeMul / 2,
            mask = bit.bor( self.HitMask ),
        }
        tr = util.TraceHull( trDat )
        --debugoverlay.SweptBox( trDat.start, trDat.endpos, trDat.mins, trDat.maxs, Angle( 0,0,0 ), 5 )
    end

    if not IsValid( tr.Entity ) then
        trDat = {
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * range,
            filter = owner,
            mins = Vector( -10, -10, -8 ) * sizeMul,
            maxs = Vector( 10, 10, 8 ) * sizeMul,
            mask = bit.bor( self.HitMask ),
        }
        tr = util.TraceHull( trDat )
        --debugoverlay.SweptBox( trDat.start, trDat.endpos, trDat.mins, trDat.maxs, Angle( 0,0,0 ), 5 )
    end

    local scale = 3
    local hitEnt = tr.Entity

    if SERVER and IsValid( hitEnt ) then
        local class = hitEnt:GetClass()
        local IsGlass = class == "func_breakable_surf"
        -- teamkilling is funny but also stupid
        if IsGlass then
            hitEnt:Fire( "Shatter", tr.HitPos )

        else
            local hittingProp = IsValid( hitEnt ) and not hitEnt:IsPlayer() and not hitEnt:IsNPC()
            local friendly = hitEnt.isTerminatorHunterChummy == owner.isTerminatorHunterChummy and owner:Disposition( hitEnt ) ~= D_HT
            local _, entMemoryKey = owner.getMemoryOfObject and owner:getMemoryOfObject( hitEnt )
            local dmgMul = strength

            if friendly then
                dmgMul = 0.05
                hitEnt.overrideMiniStuck = true

            -- break props really fast
            elseif hittingProp then
                dmgMul = dmgMul * 4

            -- break not player stuff fast
            elseif not hitEnt:IsPlayer() then
                dmgMul = dmgMul + 1

            end

            local damageToDeal = math.random( 15, 25 ) * dmgMul
            local dmginfo = DamageInfo()

            local attacker = owner
            if not IsValid( attacker ) then attacker = self end
            dmginfo:SetAttacker( attacker )

            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( damageToDeal )
            dmginfo:SetDamageType( owner.FistDamageType or DMG_SLASH )
            dmginfo:SetDamagePosition( tr.HitPos )

            local forceMul = 1
            if owner.FistForceMul then
                forceMul = owner.FistForceMul

            end

            if hitEnt:IsPlayer() or hitEnt:IsNextBot() or hitEnt:IsNPC() then
                dmginfo:SetDamageForce( owner:GetAimVector() * 6998 * scale * forceMul )

            else
                dmginfo:SetDamageForce( owner:GetAimVector() * 100 * forceMul )

            end

            SuppressHostEvents( NULL ) -- Let the breakable gibs spawn in multiplayer on client
            hitEnt:TakeDamageInfo( dmginfo )
            SuppressHostEvents( owner )

            if hitEnt:IsPlayer() then
                hitEnt:ViewPunch( Angle( -damageToDeal, damageToDeal * math.Rand( -0.5, 0.5 ), damageToDeal * math.Rand( -0.1, 0.1 ) ) )

            end

            if owner.PostHitObject then
                owner:PostHitObject( hitEnt )

            end

            if owner:IsOnFire() then
                hitEnt:Ignite( damageToDeal / 20 )

            end

            if damageToDeal > 40 or string.find( class, "prop" ) then
                local lvl = 75 + damageToDeal * 0.1
                local pitch = math.Clamp( 120 + -( damageToDeal * 0.25 ), 85, 120 )
                owner:EmitSound( "npc/zombie/zombie_pound_door.wav", lvl, pitch, 1, CHAN_STATIC )
                util.ScreenShake( self:GetPos(), damageToDeal * 0.1, 20, 0.15, damageToDeal * 5 )

            end
            if damageToDeal > 200 then
                local lvl = 80 + damageToDeal * 0.1
                local pitch = math.Clamp( 120 + -( damageToDeal * 0.35 ), 85, 120 )
                owner:EmitSound( "npc/antlion_guard/shove1.wav", lvl, pitch, 1, CHAN_STATIC )
                util.ScreenShake( self:GetPos(), damageToDeal * 0.005, 2, 3, damageToDeal * 5 )

            end

            local MEMORY_BREAKABLE = 4
            local isSignificant = hitEnt:IsNPC() or hitEnt:IsNextBot() or hitEnt:IsPlayer()

            if not isSignificant then
                hitEnt:ForcePlayerDrop()
                local oldHealth = hitEnt:Health()

                timer.Simple( 0.1, function()
                    if not IsValid( self ) then return end
                    -- small things dont take the damage's force when in water????
                    if IsValid( hitEnt ) and hitEnt:GetVelocity():LengthSqr() < 25 ^ 2 and IsValid( hitEnt:GetPhysicsObject() ) then
                        hitEnt:GetPhysicsObject():ApplyForceCenter( owner:GetAimVector() * 9998 )

                    end

                    if owner.memorizeEntAs and not IsValid( hitEnt ) or ( IsValid( hitEnt ) and oldHealth > 0 and hitEnt:Health() <= 0 ) then
                        owner:memorizeEntAs( entMemoryKey, MEMORY_BREAKABLE )

                    end
                end )
            end
        end
        self:HandleDoor( tr, strength )
    end
    if SERVER then
        local pitchShift = owner.term_SoundPitchShift or 0
        if IsValid( hitEnt ) then
            owner:EmitSound( HitSound, 75, 100 + pitchShift )
            local phys = hitEnt:GetPhysicsObject()
            local punchForce = owner:GetAimVector()
            if IsValid( phys ) then
                punchForce = punchForce * math.Clamp( phys:GetMass() / 500, 0.25, 1 )
                punchForce = punchForce * 100000
                phys:ApplyForceOffset( punchForce, tr.HitPos )

            end
        else
            owner:EmitSound( SwingSound, 75, 100 + pitchShift )
        end
    end
    if tr.Hit then
        util.ScreenShake( owner:GetPos(), 10, 10, 0.1, 400 )
        util.ScreenShake( owner:GetPos(), 1, 10, 0.5, 750 )
    end
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end
end

function SWEP:DoMuzzleFlash()
end

function SWEP:Equip()
    if self:GetOwner():IsPlayer() and GetConVar( "sv_cheats" ):GetInt() ~= 1 then SafeRemoveEntity( self ) return end

end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
    SafeRemoveEntity( self )
end

function SWEP:Reload()
end

function SWEP:CanBePickedUpByNPCs()
    return true
end

function SWEP:GetNPCBulletSpread( prof )
    local spread = { 0,0,0,0,0 }
    return spread[ prof + 1 ]
end

function SWEP:ShouldWeaponAttackUseBurst()
    return true
end

function SWEP:GetNPCBurstSettings()
    return 1,4,0.05
end

function SWEP:GetNPCRestTimes()
    return 0.2, 0.4
end

function SWEP:GetCapabilities()
    return CAP_INNATE_MELEE_ATTACK1
end

function SWEP:DrawWorldModel()
end

function SWEP:TranslateActivity()
end