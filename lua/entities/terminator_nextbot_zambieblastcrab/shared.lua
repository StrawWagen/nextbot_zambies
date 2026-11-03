-- Thanks to MerekiDor and JonahSoldier the creators of Map Sweepers for allowing this!
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiecrabbaby"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Blastcrab"
ENT.Author    = "Octantis Addons + regunkyle"
ENT.Spawnable = false

if CLIENT then
    language.Add( "terminator_nextbot_zambieblastcrab", ENT.PrintName )
    return
end

local BLAST_MATERIAL = "models/jcmsblastcrab/body"
local BLAST_MODEL    = "models/headcrab.mdl"
local CONTACT_DAMAGE = 65
local CONTACT_RADIUS = 96
-- set off by an explosion, it goes off a moment later, so a pile of crabs ripples instead of popping at once
local CHAIN_DELAY_MIN = 0.1
local CHAIN_DELAY_MAX = 0.35
local LAG_CHECK_INTERVAL = 0.5
local LAG_POP_CHANCE = 0.2 -- per check, so a lagging pile pops over a few seconds, not all at once
local FRIENDLY_BLAST_GRACE = 3 -- seconds a fresh crab shrugs off its own side's blasts, so a burst of them scatters before it chains

-- Triggers the blastcrab's explosion. Defers the actual explosion to the next frame
-- to avoid "tried to die twice" errors when called from within the base's death/damage call stack.
local function DoExplosion( self )
    if self.zamb_BlastCrabDied then return end
    self.zamb_BlastCrabDied = true

    timer.Simple( 0, function()
        if not IsValid( self ) then return end

        local pos = self:WorldSpaceCenter()
        self:EmitSound( "NPC_Headcrab.Die" )
        self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )

        local ed = EffectData()
        ed:SetOrigin( pos )
        ed:SetRadius( CONTACT_RADIUS )
        ed:SetMagnitude( 0.6 )
        util.Effect( "eff_boomer_blast", ed, true, true )

        local dmg = DamageInfo()
        dmg:SetAttacker( self )
        dmg:SetInflictor( self )
        dmg:SetReportedPosition( pos )
        dmg:SetDamageType( DMG_BLAST )
        dmg:SetDamage( CONTACT_DAMAGE )
        self.term_BypassFriendlyFire = true -- same as boomers, popping one in the horde should hurt the horde
        util.BlastDamageInfo( dmg, pos, CONTACT_RADIUS )
        self.term_BypassFriendlyFire = nil

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
    ["Detonate"] = {
        name      = "Detonate",
        desc      = "Triggers the blastcrab explosion",
        inBind    = IN_ATTACK,
        drawHint  = true,
        ratelimit = 0,
        svAction  = function( _driveController, _driver, bot )
            DoExplosion( bot )
        end,
    },
}

ENT.MyClassTask = {
    OnCreated = function( self )
        self.zamb_BlastCrabDied = false
        self:SetMaterial( BLAST_MATERIAL )
    end,

    -- Explode on any damage at all, explosions just take a moment to set us off.
    OnDamaged = function( self, _data, dmg )
        if self.zamb_BlastCrabDied then return true end

        if dmg:IsExplosionDamage() then
            local attacker = dmg:GetAttacker()
            local friendly = IsValid( attacker ) and attacker.isTerminatorHunterChummy == self.isTerminatorHunterChummy
            if friendly and CurTime() - self:GetCreationTime() < FRIENDLY_BLAST_GRACE then return true end

            self.zamb_BlastCrabChainAt = self.zamb_BlastCrabChainAt or CurTime() + math.Rand( CHAIN_DELAY_MIN, CHAIN_DELAY_MAX )
            return true
        end

        DoExplosion( self )
    end,

    Think = function( self )
        local cur = CurTime()
        local chainAt = self.zamb_BlastCrabChainAt
        if chainAt and chainAt <= cur then
            DoExplosion( self )
            return
        end

        -- boomer crabs thin themselves out a few at a time while the server's struggling
        local lagFrac = self.zamb_BlastCrabLagFrac
        if not lagFrac or ( self.zamb_BlastCrabNextLagCheck or 0 ) > cur then return end
        self.zamb_BlastCrabNextLagCheck = cur + LAG_CHECK_INTERVAL
        if math.random() > LAG_POP_CHANCE then return end
        if not terminator_Extras.zamb_IsLagging( lagFrac ) then return end
        DoExplosion( self )
    end,

    BehaveUpdatePriority = function( self )
        if self.zamb_BlastCrabDied then return end
        local enemy = self:GetEnemy()
        if not IsValid( enemy ) then return end
        if self.DistToEnemy and self.DistToEnemy <= 48 then
            DoExplosion( self )
        end
    end,

    OnKilled = function( self )
        DoExplosion( self )
    end,

    PreventBecomeRagdollOnKilled = function()
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
