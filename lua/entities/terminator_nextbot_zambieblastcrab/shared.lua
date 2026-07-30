AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiecrabbaby"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Blastcrab"
ENT.Author    = "regunkyle"
ENT.Spawnable = false

list.Set( "NPC", "terminator_nextbot_zambieblastcrab", {
    Name     = "Blastcrab",
    Class    = "terminator_nextbot_zambieblastcrab",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieblastcrab", ENT.PrintName )
    return
end

local BLAST_MATERIAL = "models/jcmsblastcrab/body"
local BLAST_MODEL    = "models/headcrab.mdl"
local CONTACT_DAMAGE = 65
local CONTACT_RADIUS = 96
local BlastCrabClass = "terminator_nextbot_zambieblastcrab"

-- Triggers the blastcrab's explosion. Defers the actual explosion to the next frame 
-- to avoid "tried to die twice" errors when called from within the base's death/damage call stack.
local function DoExplosion( self, attacker )
    if self.zamb_BlastCrabDied then return end
    self.zamb_BlastCrabDied = true

    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        
        local pos = self:WorldSpaceCenter()
        self:EmitSound( "NPC_Headcrab.Die" )
        self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )
        
        local ed = EffectData()
        ed:SetOrigin( pos )
        ed:SetNormal( vector_up )
        ed:SetRadius( CONTACT_RADIUS )
        ed:SetMagnitude( 1.2 )
        ed:SetFlags( 0 )
        util.Effect( "eff_boomer_blast", ed )
        
        local safeAttacker = IsValid( attacker ) and attacker or game.GetWorld()
        local dmg = DamageInfo()
        dmg:SetAttacker( safeAttacker )
        dmg:SetInflictor( self ) -- Set inflictor to self so other blastcrabs can filter it out
        dmg:SetReportedPosition( pos )
        dmg:SetDamageType( DMG_BLAST )
        dmg:SetDamage( CONTACT_DAMAGE )
        util.BlastDamageInfo( dmg, pos, CONTACT_RADIUS )
        
        self:Remove()
    end )
end

ENT.SpawnHealth             = 10
ENT.TERM_MODELSCALE         = 1.5
ENT.CollisionBounds         = { Vector( -8, -8, 0 ),  Vector( 8, 8, 12 ) }
ENT.CrouchCollisionBounds   = { Vector( -2, -2, 0 ),  Vector( 2, 2, 4  ) }
ENT.FistDamageMul = 0

ENT.ARNOLD_MODEL = BLAST_MODEL
ENT.Models       = { BLAST_MODEL }

ENT.MySpecialActions = {
    [ "Detonate" ] = {
        name      = "Detonate",
        desc      = "Triggers the blastcrab explosion",
        inBind    = IN_ATTACK,
        drawHint  = true,
        ratelimit = 0,
        svAction  = function( driveController, driver, bot )
            DoExplosion( bot, driver )
        end,
    },
}

ENT.MyClassTask = {
    OnCreated = function( self, data )
        self.zamb_BlastCrabDied = false
        self:SetMaterial( BLAST_MATERIAL )
    end,

    -- Explode on any damage at all, unless the damage is coming from another blastcrab's explosion.
    OnDamaged = function( self, data, dmg )
        if self.zamb_BlastCrabDied then return true end
        
        local inflictor = dmg:GetInflictor()
        if IsValid( inflictor ) and inflictor:GetClass() == BlastCrabClass then
            return true
        end
        
        local attacker = dmg:GetAttacker()
        local safeAttacker = IsValid( attacker ) and attacker or game.GetWorld()
        DoExplosion( self, safeAttacker )
    end,

    BehaveUpdatePriority = function( self, data )
        if self.zamb_BlastCrabDied then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        if self.DistToEnemy and self.DistToEnemy <= 48 then
            DoExplosion( self, enemy )
        end
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        DoExplosion( self, attacker )
    end,

    PreventBecomeRagdollOnKilled = function( self, data, dmg )
        return true, true
    end,
}

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    self:SetModel( BLAST_MODEL )
    self:SetMaterial( BLAST_MATERIAL )
    
    self.zamb_BlastCrabDied        = false
    self.HeightToStartTakingDamage = 9999
    self.FallDamagePerHeight       = 0
    self.DeathDropHeight           = 9999
end
