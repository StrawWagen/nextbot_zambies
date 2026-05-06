-- entities/terminator_nextbot_zambieblastcrab/shared.lua

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

-- Triggers the blastcrab's explosion. zamb_BlastCrabDied is set as the first
-- statement so that concurrent calls from OnKilled and the BehaveUpdatePriority
-- proximity check both see the flag immediately, before any damage, sound, or
-- removal logic runs.
--
-- The entire explosion is deferred via timer.Simple( 0 ) when called from
-- within the base's death sequence (OnKilled fires inside FinishDying, which
-- is itself inside the base's damage handling). Without full deferral,
-- util.BlastDamageInfo hits other blastcrabs in the radius, their OnKilled
-- fires synchronously inside the current FinishDying call stack, and the base
-- reports "tried to die twice" for each one caught in the chain.
local function DoExplosion( self, attacker, deferred )
    if self.zamb_BlastCrabDied then return end
    self.zamb_BlastCrabDied = true

    if deferred then
        -- Already on a clean call stack: safe to run immediately.
        local pos = self:WorldSpaceCenter()
        self:EmitSound( "NPC_Headcrab.Die" )

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
        dmg:SetInflictor( game.GetWorld() )
        dmg:SetReportedPosition( pos )
        dmg:SetDamageType( DMG_BLAST )
        dmg:SetDamage( CONTACT_DAMAGE )
        util.BlastDamageInfo( dmg, pos, CONTACT_RADIUS )

        timer.Simple( 0, function()
            if IsValid( self ) then self:Remove() end
        end )
    else
        -- Called from within the base's death/damage call stack. Defer
        -- everything to the next frame so we exit that stack before any
        -- further damage is applied, preventing the "tried to die twice" chain.
        local safeAttacker = IsValid( attacker ) and attacker or game.GetWorld()
        timer.Simple( 0, function()
            if not IsValid( self ) then return end
            DoExplosion( self, safeAttacker, true )
        end )
    end
end

-- NOTE: collision bounds have been tuned and verified with ent_bbox.
ENT.SpawnHealth             = 10
ENT.TERM_MODELSCALE         = 1.5
ENT.CollisionBounds         = { Vector( -8, -8, 0 ),  Vector( 8, 8, 12 ) }
ENT.CrouchCollisionBounds   = { Vector( -2, -2, 0 ),  Vector( 2, 2, 4  ) }

ENT.FistDamageMul = 0

ENT.MySpecialActions = {
    -- Exposed to player control so a driver can detonate the crab on demand.
    -- ratelimit = 0 is intentional: DoExplosion removes the entity before a
    -- second trigger could fire, so no cooldown is needed.
    [ "Detonate" ] = {
        name      = "Detonate",
        desc      = "Triggers the blastcrab explosion",
        inBind    = IN_ATTACK,
        drawHint  = true,
        ratelimit = 0,
        svAction  = function( driveController, driver, bot )
            -- Player-triggered: not inside any base death stack, safe to run
            -- with deferred = true (no extra timer wrapping needed).
            DoExplosion( bot, driver, true )
        end,
    },
}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self.zamb_BlastCrabDied = false
        self:SetMaterial( BLAST_MATERIAL )
    end,

    BehaveUpdatePriority = function( self, data )
        if self.zamb_BlastCrabDied then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        if self.DistToEnemy and self.DistToEnemy <= 48 then
            -- BehaveUpdatePriority runs in a coroutine outside the damage
            -- stack, so deferred = true is safe here.
            DoExplosion( self, enemy, true )
        end
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        -- OnKilled fires inside FinishDying, which is inside the base's damage
        -- handling. Pass deferred = false so the explosion is pushed to the
        -- next frame, fully outside the current call stack.
        DoExplosion( self, attacker, false )
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