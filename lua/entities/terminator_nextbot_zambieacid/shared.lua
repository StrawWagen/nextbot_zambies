AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Acid"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieacid", {
    Name = "Zombie Acid",
    Class = "terminator_nextbot_zambieacid",
    Category = "Nextbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambieacid", ENT.PrintName )

    local setup

    function ENT:AdditionalClientInitialize()
        if not setup then
            setup = true
            CreateMaterial( "nextbotZambies_AcidFlesh", "VertexLitGeneric", { ["$basetexture"] = "nature/toxicslime002a", ["$treesway"] = 1 } ) -- this will act weird if players join after the zombie spawns but w/e

        end
        self:SetSubMaterial( 0, "!nextbotZambies_AcidFlesh" )
    end
    return

end

local sizzles = {
    "ambient/levels/canals/toxic_slime_sizzle2.wav",
    "ambient/levels/canals/toxic_slime_sizzle3.wav",
    "ambient/levels/canals/toxic_slime_sizzle4.wav",

}

ENT.SpawnHealth = 125
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1

ENT.FistDamageMul = 1
ENT.FistDamageType = bit.bor( DMG_GENERIC, DMG_ACID )

function ENT:IsImmuneToDmg( dmg )
    if dmg:IsDamageType( DMG_ACID ) then return true end

end

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

ENT.TERM_MODELSCALE = function() return math.Rand( 1.08, 1.10 ) end
ENT.MyPhysicsMass = 85

local ACIDIC_COLOR = Color( 10, 250, 0 )

function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_AcidFlesh" )
    self:SetColor( ACIDIC_COLOR )
    self:SetBloodColor( BLOOD_COLOR_GREEN )
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    local hasBrains = math.random( 1, 100 ) < 30
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true

    end
    self.term_DMG_ImmunityMask = bit.bor( DMG_ACID, DMG_RADIATION )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = 10
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
    self.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = "Zombie.Alert"
    self.term_AngerSound = "Zombie.Idle"
    self.term_DamagedSound = "Zombie.Pain"
    self.term_DieSound = "Zombie.Die"
    self.term_JumpSound = "npc/zombie/foot1.wav"
    self.IdleLoopingSounds = {
        "npc/zombie/moan_loop2.wav",

    }
    self.AngryLoopingSounds = {
        "npc/zombie/moan_loop1.wav",
        "npc/zombie/moan_loop3.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

end

local up = Vector( 0, 0, 1 )

local function acidPuff( pos, scale )
    local effDat = EffectData()
    effDat:SetOrigin( pos )
    effDat:SetScale( scale )
    effDat:SetFlags( 4 )
    effDat:SetColor( 1 )
    effDat:SetNormal( up )
    util.Effect( "bloodspray", effDat )

end

function ENT:DealAcidDamageTo( ent, dmg, pos )
    local dmgInfo = DamageInfo()
    dmgInfo:SetDamage( dmg )
    dmgInfo:SetDamageType( bit.bor( DMG_GENERIC, DMG_ACID ) )
    dmgInfo:SetAttacker( self )
    dmgInfo:SetInflictor( self )
    dmgInfo:SetDamagePosition( pos )
    ent:TakeDamageInfo( dmgInfo )

    local pit = 120 + -( dmg / 10 )
    local lvl = 60 + ( dmg / 40 )
    ent:EmitSound( sizzles[math.random( 1, #sizzles )], lvl, pit )

end

function ENT:DoAoeAcidDamage( ent, rad )
    local areaDamagePos = ent:NearestPoint( self:WorldSpaceCenter() )
    acidPuff( areaDamagePos, 30 )

    rad = rad or 200

    for _, aoeEnt in ipairs( ents.FindInSphere( areaDamagePos, rad ) ) do
        if IsValid( aoeEnt:GetParent() ) then continue end
        if aoeEnt == ent then continue end
        if aoeEnt == self then continue end

        if aoeEnt:GetMaxHealth() > 1 and aoeEnt:Health() <= 0 then continue end

        local isSignificant = aoeEnt:IsNPC() or aoeEnt:IsPlayer()
        local dmg = rad - aoeEnt:NearestPoint( areaDamagePos ):Distance( areaDamagePos )
        dmg = dmg * 4
        if isSignificant then -- deal crazy damage to props, not much damage to players/npcs
            dmg = dmg / 100

        end
        if dmg < 1 then continue end
        self:DealAcidDamageTo( aoeEnt, dmg, areaDamagePos )

    end
end

function ENT:PostHitObject( hit )
    self:DoAoeAcidDamage( hit )

end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )

end

-- does not flinch
function ENT:HandleFlinching()
end

function ENT:AdditionalFootstep( pos )
    if math.random( 0, 100 ) < 25 then
        local snd = "ambient/levels/canals/toxic_slime_gurgle" .. math.random( 2, 8 ) .. ".wav"
        local pit = math.random( 120, 140 )
        self:EmitSound( snd, 75, pit )
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealAcidDamageTo( groundEnt, 100, self:GetPos() )
            self:DoAoeAcidDamage( groundEnt )

        end
    else
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            self:DealAcidDamageTo( groundEnt, 10, self:GetPos() )

        end
    end
    acidPuff( pos, self:GetVelocity():Length() / 25 )

end

function ENT:AdditionalOnKilled()

    self:EmitSound( sizzles[math.random( 1, #sizzles )], 80, 120 )
    self:EmitSound( sizzles[math.random( 1, #sizzles )], 90, 60 )

    local timerName = "zambieacid_deathacid_" .. self:GetCreationID()
    local rad = 400
    timer.Create( timerName, 0.1, 5, function()
        if not IsValid( self ) then timer.Remove( timerName ) return end

        acidPuff( self:GetPos(), rad / 4 )
        self:DoAoeAcidDamage( self, rad )
        rad = rad * 0.45

    end )

end