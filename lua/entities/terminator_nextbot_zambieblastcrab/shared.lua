AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiecrabbaby"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Blastcrab"
ENT.Spawnable = true

if CLIENT then
    language.Add( "terminator_nextbot_zambieblastcrab", ENT.PrintName )
    return
end

local BLAST_MATERIAL = "models/jcms/explosiveheadcrab/body"
local BLAST_MODEL    = "models/headcrab.mdl"

local CONTACT_DAMAGE = 65
local CONTACT_RADIUS = 96

local function DoExplosion( self, attacker )
    if self.blastDead then return end
    self.blastDead = true

    local pos = self:WorldSpaceCenter()
    self:EmitSound( "NPC_Headcrab.Die" )

    local ed = EffectData()
    ed:SetOrigin( pos )
    ed:SetNormal( vector_up )
    ed:SetRadius( CONTACT_RADIUS )
    ed:SetMagnitude( 1.2 )
    ed:SetFlags( 0 )
    util.Effect( "eff_boomer_blast", ed )

    local dmg = DamageInfo()
    dmg:SetAttacker( IsValid( attacker ) and attacker or self )
    dmg:SetInflictor( self )
    dmg:SetReportedPosition( pos )
    dmg:SetDamageType( DMG_BLAST )

    for _, ent in ipairs( ents.FindInSphere( pos, CONTACT_RADIUS ) ) do
        if ent == self then continue end
        local phys = ent:GetPhysicsObject()
        if not IsValid( phys ) then continue end

        local epos = ent:WorldSpaceCenter()
        local diff = epos - pos
        local dist = diff:Length()
        if dist == 0 then continue end
        diff:Normalize()

        local falloff = math.Clamp( 1 - dist / CONTACT_RADIUS, 0, 1 )
        dmg:SetDamage( falloff * CONTACT_DAMAGE )
        dmg:SetDamagePosition( epos )
        ent:TakeDamageInfo( dmg )

        local mt = ent:GetMoveType()
        if mt == MOVETYPE_VPHYSICS then
            phys:ApplyForceOffset( diff * falloff * 800 * phys:GetMass(), pos )
        elseif mt == MOVETYPE_WALK then
            ent:SetVelocity( diff * falloff * 480 )
        end
    end

    timer.Simple( 0, function()
        if IsValid( self ) then self:Remove() end
    end )
end

ENT.SpawnHealth   = 10
ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds       = { Vector( -8, -8, 0 ), Vector( 8, 8, 12 ) }
ENT.CrouchCollisionBounds = { Vector( -2, -2, 0 ), Vector( 2, 2, 4 ) }

ENT.FistDamageMul = 0

ENT.MySpecialActions = {}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self.blastDead = false
        self:SetMaterial( BLAST_MATERIAL )
    end,

    BehaveUpdatePriority = function( self, data )
        if self.blastDead then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        if self.DistToEnemy and self.DistToEnemy <= 48 then
            DoExplosion( self, enemy )
        end
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        DoExplosion( self, attacker )
    end,

}

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( BLAST_MODEL )
    self:SetMaterial( BLAST_MATERIAL )
    self.blastDead = false
    self.HeightToStartTakingDamage = 9999
    self.FallDamagePerHeight       = 0
    self.DeathDropHeight           = 9999
end