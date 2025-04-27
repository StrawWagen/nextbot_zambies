AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Fast Acid"
ENT.Author = "Broadcloth0"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieacidfast", {
    Name = "Zombie Fast Acid",
    Class = "terminator_nextbot_zambieacidfast",
    Category = "Nextbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambieacidfast", ENT.PrintName )

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

ENT.JumpHeight = 150
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 20
ENT.ExtraSpawnHealthPerPlayer = 750
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 400
ENT.WalkSpeed = 360
ENT.MoveSpeed = 360
ENT.RunSpeed = 360
ENT.neverManiac = true

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
ENT.NoAnimLayering = true

ENT.TERM_MODELSCALE = function() return math.Rand( 1.08, 1.10 ) end
ENT.MyPhysicsMass = 85
local ACID_ZAMBIE_FASTMODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = ACID_ZAMBIE_FASTMODEL
ENT.Models = { ACID_ZAMBIE_FASTMODEL }
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1
ENT.zamb_LookAheadWhenRunning = true
ENT.zamb_MeleeAttackSpeed = 1.1

local IdleActivity = ACT_IDLE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_IDLE,
    [ACT_MP_CROUCHWALK]                 =  ACT_WALK,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_MP_SWIM]                       = ACT_HL2MP_SWIM,
    [ACT_LAND]                          = ACT_LAND,
}

local ACIDIC_COLOR = Color( 10, 250, 0 )

function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_AcidFlesh" )
    self:SetColor( ACIDIC_COLOR )
    self:SetModel(  ACID_ZAMBIE_FASTMODEL )
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

    self.term_SoundPitchShift = -3
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "NPC_FastZombie.Idle"
    self.term_CallingSound = "npc/fast_zombie/fz_alert_far1.wav"
    self.term_CallingSmallSound = "npc/fast_zombie/fz_scream1.wav"
    self.term_FindEnemySound = "NPC_FastZombie.AlertNear"
    self.term_AttackSound = { "NPC_FastZombie.Scream", "NPC_FastZombie.Frenzy" }
    self.term_AngerSound = "NPC_FastZombie.AlertNear"
    self.term_DamagedSound = "NPC_FastZombie.Pain"
    self.term_DieSound = "NPC_FastZombie.Die"
    self.term_JumpSound = "NPC_FastZombie.LeapAttack"
    self.IdleLoopingSounds = {
        "npc/fast_zombie/breathe_loop1.wav",

    }
    self.AngryLoopingSounds = {
        "npc/fast_zombie/gurgle_loop1.wav",

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

        if aoeEnt:GetMaxHealth() > 1 and aoeEnt:Health() <= 0 then return end

        local isSignificant = aoeEnt:IsNPC() or aoeEnt:IsPlayer()
        local dmg = rad - aoeEnt:NearestPoint( areaDamagePos ):Distance( areaDamagePos )
        dmg = dmg * 4
        if isSignificant then -- deal crazy damage to props, not much damage to players/npcs
            dmg = dmg / 100

        end
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

function ENT:OnFootstep( pos, foot, _sound, volume, _filter )
    local lvl = 85
    local pit = 100
    local snd = foot and "Zombie.FootstepRight" or "Zombie.FootstepLeft"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76
        snd = foot and "Zombie.ScuffRight" or "Zombie.ScuffLeft"

    end
    if math.random( 0, 100 ) < 25 then
        snd = "ambient/levels/canals/toxic_slime_gurgle" .. math.random( 2, 8 ) .. ".wav"
        pit = math.random( 140, 140 )
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
    acidPuff( pos, lvl / 10 )
    self:EmitSound( snd, lvl, pit, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

function ENT:AdditionalOnKilled()

    self:EmitSound( sizzles[math.random( 1, #sizzles )], 80, 120 )
    self:EmitSound( sizzles[math.random( 1, #sizzles )], 90, 60 )

    local timerName = "zambieacid_deathacid_" .. self:GetCreationID()
    local rad = 400
    timer.Create( timerName, 0.1, 5, function()
        if not IsValid( self ) then return end

        acidPuff( self:GetPos(), rad / 4 )
        self:DoAoeAcidDamage( self, rad )
        rad = rad * 0.45

    end )

end