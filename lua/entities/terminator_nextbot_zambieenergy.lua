AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Energy"
ENT.Author = "Regunkyle"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieenergy", {
    Name = "Zombie Energy",
    Class = "terminator_nextbot_zambieenergy",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergy", ENT.PrintName )

    local setup
    function ENT:AdditionalClientInitialize()
        if not setup then
            setup = true
            -- electric/purple skin based on PCB blue texture but purple tint on entity color
            CreateMaterial( "nextbotZambies_EnergyFlesh", "VertexLitGeneric", {
                ["$basetexture"] = "phoenix_storms/wire/pcb_blue",
                ["$treesway"] = 1
            } )
        end
        self:SetSubMaterial( 0, "!nextbotZambies_EnergyFlesh" )
    end

    return
end

-- cached sound table
local ElectricSfx = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav",
    "ambient/energy/zap5.wav",
}

ENT.SpawnHealth = 125
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1

ENT.FistDamageMul = 1
ENT.FistDamageType = bit.bor( DMG_GENERIC, DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE )

function ENT:IsImmuneToDmg( dmg )
    if dmg:IsDamageType( DMG_SHOCK ) or
       dmg:IsDamageType( DMG_ENERGYBEAM ) or
       dmg:IsDamageType( DMG_PLASMA ) or
       dmg:IsDamageType( DMG_DISSOLVE ) then
        return true
    end
end

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

ENT.TERM_MODELSCALE = function() return math.Rand( 1.08, 1.10 ) end
ENT.MyPhysicsMass = 85

-- purple color
local ENERGY_COLOR = Color( 160, 40, 200 )

-- helpers ------------------------------------------------------------------------
local UP = Vector(0,0,1)

local function safeEnergyPuff(pos, scale)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetScale( math.max((scale or 1), 0.1) )
    ed:SetNormal(UP)
    util.Effect("effects/fluttercore_gmod", ed, true, true)
end

local function smallPurpleBloodSpray(pos, scale)
    if not pos then return end
    local ed = EffectData()
    ed:SetOrigin(pos)
    ed:SetScale( math.Clamp((scale or 6), 1, 12) ) -- clamped sensible range
    ed:SetNormal(UP)
    ed:SetFlags(4)
    ed:SetColor(7) -- index 7 produced the purple tint you saw
    util.Effect("bloodspray", ed, true, true)
end

-- dissolve helper: dissolves a target entity (ragdoll or the entity itself)
local function dissolveEntitySafely(target, delay)
    if not IsValid(target) then return end

    -- env_entity_dissolver is a safe way to dissolve entities (map entity)
    local dissolver = ents.Create("env_entity_dissolver")
    if not IsValid(dissolver) then
        -- fallback: just remove the entity cleanly
        SafeRemoveEntityDelayed(target, delay or 0.1)
        return
    end

    dissolver:SetPos(target:GetPos())
    dissolver:Spawn()
    dissolver:Activate()
    dissolver:SetKeyValue("dissolvetype", 0) -- 0 is default dissolve; change if you want different visuals
    dissolver:Fire("Dissolve", target, 0)
    -- ensure the dissolver doesn't linger
    timer.Simple(1.5, function()
        if IsValid(dissolver) then dissolver:Remove() end
    end)
end

-- damage helpers ----------------------------------------------------------------
function ENT:DealEnergyDamageTo( ent, dmg, pos )
    if not IsValid( ent ) then return end
    local di = DamageInfo()
    di:SetDamage( dmg )
    di:SetDamageType( bit.bor( DMG_GENERIC, DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE ) )
    di:SetAttacker( self )
    di:SetInflictor( self )
    di:SetDamagePosition( pos or self:WorldSpaceCenter() )
    ent:TakeDamageInfo( di )

    local pitch = 120 + ( -dmg / 10 )
    local level = 60 + ( dmg / 40 )
    ent:EmitSound( ElectricSfx[ math.random(1, #ElectricSfx) ], level, pitch )
end

function ENT:DoAoeEnergyDamage( ent, rad )
    rad = rad or 200
    local areaDamagePos = ent:NearestPoint( self:WorldSpaceCenter() )
    safeEnergyPuff( areaDamagePos, math.Clamp( rad / 200, 0.5, 3 ) )

    for _, aoeEnt in ipairs( ents.FindInSphere( areaDamagePos, rad ) ) do
        if IsValid( aoeEnt:GetParent() ) then continue end
        if aoeEnt == ent then continue end
        if aoeEnt == self then continue end
        if aoeEnt:GetMaxHealth() > 1 and aoeEnt:Health() <= 0 then continue end

        local isSignificant = aoeEnt:IsNPC() or aoeEnt:IsPlayer()
        local dmg = rad - aoeEnt:NearestPoint( areaDamagePos ):Distance( areaDamagePos )
        dmg = dmg * 4
        if isSignificant then dmg = dmg / 100 end
        self:DealEnergyDamageTo( aoeEnt, dmg, areaDamagePos )
    end
end

-- initialization ----------------------------------------------------------------
function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_EnergyFlesh" )
    self:SetColor( ENERGY_COLOR )
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false

    if math.random(1,100) < 30 then
        self.HasBrains = true
        self.CanHearStuff = true
    end

    self.term_DMG_ImmunityMask = bit.bor( DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE, DMG_RADIATION )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    -- sound tuning
    self.term_SoundPitchShift = 5
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/energy/zap1.wav"
    self.term_CallingSmallSound = "ambient/energy/zap2.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = "ambient/energy/zap3.wav"
    self.term_AngerSound = "ambient/energy/spark4.wav"
    self.term_DamagedSound = "ambient/energy/zap4.wav"
    self.term_DieSound = "ambient/energy/weld1.wav"
    self.term_JumpSound = "ambient/energy/spark6.wav"

    self.IdleLoopingSounds = { "ambient/machines/combine_shield_loop3.wav" }
    self.AngryLoopingSounds = { "ambient/energy/force_field_loop1.wav" }
    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.03
    self.DeathDropHeight = 1500
end

-- footsteps & walking effects ---------------------------------------------------
function ENT:AdditionalFootstep( pos )
    local groundEnt = self:GetGroundEntity()

    if math.random(0,100) < 25 then
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 100, self:GetPos() )
            self:DoAoeEnergyDamage( groundEnt, 200 )
        end
    else
        if IsValid( groundEnt ) then
            self:DealEnergyDamageTo( groundEnt, 10, self:GetPos() )
        end
    end

    -- visual: fluttercore puff + small purple bloodspray
    local speed = self:GetVelocity():Length()
    local puffScale = math.Clamp( speed / 100, 0.5, 3 )
    safeEnergyPuff( pos, puffScale )
    smallPurpleBloodSpray( pos, 6 )
end

-- when we hit objects
function ENT:PostHitObject( hit )
    self:DoAoeEnergyDamage( hit, 200 )
end

-- QoL: try to stop any looping sounds / clean on remove
function ENT:OnRemove()
    -- best-effort stop sounds
    for _, s in ipairs(ElectricSfx) do
        self:StopSound(s)
    end
end

-- DEATH: dissolve body/ragdoll instead of AoE damage
function ENT:AdditionalOnKilled()
    -- small death sounds
    self:EmitSound( ElectricSfx[ math.random(1,#ElectricSfx) ], 80, 120 )
    self:EmitSound( ElectricSfx[ math.random(1,#ElectricSfx) ], 90, 60 )

    -- try to dissolve the ragdoll when it appears (or the entity itself)
    local myPos = self:GetPos()
    timer.Simple(0.08, function()
        -- try to find a nearby ragdoll (spawned by the NPC death)
        local found = false
        for _, e in ipairs( ents.FindInSphere( myPos, 160 ) ) do
            if IsValid(e) and e:GetClass():find("prop_ragdoll") then
                dissolveEntitySafely(e)
                found = true
            end
        end
        -- if no ragdoll found, try dissolving this entity (fallback)
        if not found and IsValid(self) then
            dissolveEntitySafely(self)
        end
    end)
end

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )
end

-- don't flinch
function ENT:HandleFlinching() end
