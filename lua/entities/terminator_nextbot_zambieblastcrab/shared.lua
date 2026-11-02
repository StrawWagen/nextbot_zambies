-- Blastcrab
-- Ported from Map Sweepers. Original blastcrab by MerekiDor and JonahSoldier,
-- used with their permission on the condition that they are credited.

AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiecrabbaby"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Blastcrab"
ENT.Author = "Regun2 (port) - original by MerekiDor and JonahSoldier (Map Sweepers)"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieblastcrab", {
    Name = "Blastcrab",
    Class = "terminator_nextbot_zambieblastcrab",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieblastcrab", ENT.PrintName )
    return
end

local BLAST_MATERIAL = "models/jcmsblastcrab/body"
local BLAST_MODEL = "models/headcrab.mdl"
local BLAST_CLASS = "terminator_nextbot_zambieblastcrab"

local CONTACT_DAMAGE = 65
local CONTACT_RADIUS = 96

-- eff_boomer_blast scales off its magnitude, 0.6 is the small "pop" look
local EFFECT_MAGNITUDE = 0.6

-- How close an enemy has to get before the crab goes off on its own
local TRIGGER_DISTANCE = 48

-- Triggers the blastcrab's explosion.
-- The actual blast is deferred to the next frame, to avoid "tried to die twice" errors
-- when this is called from inside the base's death/damage call stack.
local function DoExplosion( self )
    if self.zamb_BlastCrabDied then return end
    self.zamb_BlastCrabDied = true

    timer.Simple( 0, function()
        if not IsValid( self ) then return end

        local pos = self:WorldSpaceCenter()
        self:EmitSound( "NPC_Headcrab.Die" )
        self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )

        local effectData = EffectData()
        effectData:SetOrigin( pos )
        effectData:SetNormal( vector_up )
        effectData:SetRadius( CONTACT_RADIUS )
        effectData:SetMagnitude( EFFECT_MAGNITUDE )
        effectData:SetFlags( 0 )
        util.Effect( "eff_boomer_blast", effectData )

        -- The crab itself is the attacker, never the enemy or the driver.
        -- Crediting a player would make the blast obey PvP rules, and with PvP off it couldn't hurt players at all.
        -- It's also the inflictor, so other blastcrabs can filter this blast out in OnDamaged and don't chain.
        local damageInfo = DamageInfo()
        damageInfo:SetAttacker( self )
        damageInfo:SetInflictor( self )
        damageInfo:SetReportedPosition( pos )
        damageInfo:SetDamageType( DMG_BLAST )
        damageInfo:SetDamage( CONTACT_DAMAGE )
        util.BlastDamageInfo( damageInfo, pos, CONTACT_RADIUS )

        self:Remove()
    end )
end

ENT.SpawnHealth = 10
ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds = { Vector( -8, -8, 0 ), Vector( 8, 8, 12 ) }
ENT.CrouchCollisionBounds = { Vector( -2, -2, 0 ), Vector( 2, 2, 4 ) }
ENT.FistDamageMul = 0

ENT.ARNOLD_MODEL = BLAST_MODEL
ENT.Models = { BLAST_MODEL }

ENT.MySpecialActions = {
    [ "Detonate" ] = {
        name = "Detonate",
        desc = "Triggers the blastcrab explosion",
        inBind = IN_ATTACK,
        drawHint = true,
        ratelimit = 0,
        svAction = function( _driveController, _driver, bot )
            DoExplosion( bot )
        end,
    },
}

ENT.MyClassTask = {
    -- Explode on any damage at all, unless the damage is coming from another blastcrab's explosion.
    OnDamaged = function( self, _data, damageInfo )
        if self.zamb_BlastCrabDied then return true end

        local inflictor = damageInfo:GetInflictor()
        if IsValid( inflictor ) and inflictor:GetClass() == BLAST_CLASS then
            return true
        end

        DoExplosion( self )
    end,

    -- Not run while a player is driving, they use the Detonate action instead.
    BehaveUpdatePriority = function( self, _data )
        if self.zamb_BlastCrabDied then return end

        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end

        if not self.DistToEnemy then return end
        if self.DistToEnemy > TRIGGER_DISTANCE then return end

        DoExplosion( self )
    end,

    OnKilled = function( self, _data, _attacker, _inflictor, _ragdoll )
        DoExplosion( self )
    end,

    PreventBecomeRagdollOnKilled = function( _self, _data, _damageInfo )
        return true, true
    end,
}

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( BLAST_MODEL )
    self:SetMaterial( BLAST_MATERIAL )

    self.zamb_BlastCrabDied = false

    -- Fall damage would set it off, so turn it off
    self.HeightToStartTakingDamage = 9999
    self.FallDamagePerHeight = 0
    self.DeathDropHeight = 9999
end
