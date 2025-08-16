AddCSLuaFile( )

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Energy"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieenergy", {
    Name = "Zombie Energy",
    Class = "terminator_nextbot_zambieenergy",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieenergy", ENT.PrintName )

    local MAT = "nextbotZambies_EnergyFlesh"
    function ENT:AdditionalClientInitialize( )
        if self._energySetup then return end
        self._energySetup = true

        CreateMaterial( MAT, "VertexLitGeneric", {
            ["$basetexture"] = "phoenix_storms/wire/pcb_blue",
            ["$treesway"]    = 1,
        } )

        self:SetSubMaterial( 0, "!" .. MAT )
    end

    return
end

-- stats
ENT.SpawnHealth = 125
ENT.HealthRegen = 2
ENT.HealthRegenInterval = 1

ENT.FistDamageMul = 1
ENT.FistDamageType = bit.bor( DMG_GENERIC, DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE )

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

ENT.TERM_MODELSCALE = function( ) return math.Rand( 1.08, 1.10 ) end
ENT.MyPhysicsMass = 85

-- visuals / damage
ENT.ENERGY_COLOR = Color( 160, 40, 200 )
ENT.DMG_MASK = bit.bor( DMG_GENERIC, DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE )
ENT.IMMUNE_MASK = bit.bor( DMG_SHOCK, DMG_ENERGYBEAM, DMG_PLASMA, DMG_DISSOLVE, DMG_RADIATION )

-- arc FX
ENT.ArcEnabled = true
ENT.ArcIntervalMin = 0.50
ENT.ArcIntervalMax = 1.20
ENT.ArcRadius = 160
ENT.ArcMagnitude = 6
ENT.ArcScale = 1

-- sfx
ENT.ELECT_SFX = {
    "ambient/energy/zap1.wav",
    "ambient/energy/zap2.wav",
    "ambient/energy/zap3.wav",
    "ambient/energy/zap5.wav",
}

function ENT:IsImmuneToDmg( dmg )
    if dmg:IsDamageType( DMG_SHOCK )
    or dmg:IsDamageType( DMG_ENERGYBEAM )
    or dmg:IsDamageType( DMG_PLASMA )
    or dmg:IsDamageType( DMG_DISSOLVE ) then
        return true
    end

end

function ENT:AdditionalInitialize( )
    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "!nextbotZambies_EnergyFlesh" )
    self:SetColor( self.ENERGY_COLOR )

    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false

    if math.random( 1, 100 ) < 30 then
        self.HasBrains = true
        self.CanHearStuff = true

    end

    self.term_DMG_ImmunityMask = self.IMMUNE_MASK
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

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
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

    self._nextArc = CurTime() + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )
end

-- helpers
function ENT:DoEffect( name, pos, scale, normal, flags, color )
    if not pos then return end

    local d = EffectData()
    d:SetOrigin( pos )
    if scale  then d:SetScale( scale ) end
    if normal then d:SetNormal( normal ) end
    if flags  then d:SetFlags( flags ) end
    if color  then d:SetColor( color ) end
    util.Effect( name, d, true, true )
end

function ENT:DoSelfArcFX( )
    if not self.ArcEnabled then return end

    local d = EffectData()
    d:SetOrigin( self:WorldSpaceCenter() )
    d:SetEntity( self )
    d:SetMagnitude( self.ArcMagnitude )
    d:SetScale( self.ArcScale )
    d:SetRadius( self.ArcRadius )
    util.Effect( "TeslaHitBoxes", d, true, true )
end

function ENT:DissolveTarget( t )
    if not IsValid( t ) then return end

    local dis = ents.Create( "env_entity_dissolver" )
    if not IsValid( dis ) then
        SafeRemoveEntityDelayed( t, 0.1 )
        return
    end

    dis:SetPos( t:GetPos() )
    dis:Spawn()
    dis:Activate()
    dis:SetKeyValue( "dissolvetype", "0" )
    dis:Fire( "Dissolve", t, 0 )

    timer.Simple( 1.2, function()
        if IsValid( dis ) then dis:Remove() end
    end )
end

function ENT:DealEnergyDamageTo( ent, dmg, pos )
    if not IsValid( ent ) then return end

    local di = DamageInfo()
    di:SetDamage( dmg )
    di:SetDamageType( self.DMG_MASK )
    di:SetAttacker( self )
    di:SetInflictor( self )
    di:SetDamagePosition( pos or self:WorldSpaceCenter() )
    ent:TakeDamageInfo( di )

    ent:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 60 + ( dmg / 40 ), 120 + ( -dmg / 10 ) )
end

function ENT:DoAoeEnergyDamage( ent, rad )
    if not IsValid( ent ) then return end

    rad = rad or 200
    local pos = ent:NearestPoint( self:WorldSpaceCenter() )

    self:DoEffect( "effects/fluttercore_gmod", pos, math.Clamp( rad / 200, 0.5, 3 ), vector_up )

    local r2 = rad * rad
    for _, e in ipairs( ents.FindInSphere( pos, rad ) ) do
        if e == ent or e == self then continue end
        if IsValid( e:GetParent() ) then continue end
        if e:GetMaxHealth() > 1 and e:Health() <= 0 then continue end

        local d2 = e:NearestPoint( pos ):DistToSqr( pos )
        if d2 > r2 then continue end

        local dmg = ( rad - math.sqrt( d2 ) ) * 4
        if e:IsNPC() or e:IsPlayer() then dmg = dmg / 100 end

        if dmg > 0 then
            self:DealEnergyDamageTo( e, dmg, pos )

        end
    end
end

function ENT:AdditionalFootstep( pos )
    local g = self:GetGroundEntity()

    if math.random( 0, 100 ) < 25 then
        if IsValid( g ) then
            self:DealEnergyDamageTo( g, 100, self:GetPos() )
            self:DoAoeEnergyDamage( g, 200 )
        end
    else
        if IsValid( g ) then
            self:DealEnergyDamageTo( g, 10, self:GetPos() )
        end
    end

    local spd = self:GetVelocity():Length()
    self:DoEffect( "effects/fluttercore_gmod", pos, math.Clamp( spd / 100, 0.5, 3 ), vector_up )
    self:DoEffect( "bloodspray", pos, 6, vector_up, 4, 7 )
end

function ENT:PostHitObject( hit )
    self:DoAoeEnergyDamage( hit, 200 )
end

function ENT:AdditionalOnKilled( )
    self:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 80, 120 )
    self:EmitSound( self.ELECT_SFX[ math.random( 1, #self.ELECT_SFX ) ], 90, 60 )

    local p = self:GetPos()
    timer.Simple( 0.06, function()
        local rag
        for _, e in ipairs( ents.FindInSphere( p, 120 ) ) do
            if IsValid( e ) and e:GetClass():find( "prop_ragdoll" ) then rag = e break end
        end

        if IsValid( rag ) then
            self:DissolveTarget( rag )
        else
            if IsValid( self ) then self:DissolveTarget( self ) end

        end
    end )
end

function ENT:OnRemove( )
    for _, s in ipairs( self.ELECT_SFX ) do
        self:StopSound( s )

    end
end

function ENT:AdditionalThink( )
    if self.ArcEnabled then
        local now = CurTime()
        if now >= ( self._nextArc or 0 ) then
            self._nextArc = now + math.Rand( self.ArcIntervalMin, self.ArcIntervalMax )
            self:DoSelfArcFX()

        end
    end

    BaseClass.AdditionalThink( self )
end

function ENT:HandleFlinching( ) end