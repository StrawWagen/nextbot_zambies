AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Mecha Zombie"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiemecha", {
    Name = "Mecha Zombie",
    Class = "terminator_nextbot_zambiemecha",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 1500
ENT.WalkSpeed = 70
ENT.MoveSpeed = 180
ENT.RunSpeed = 300
ENT.AccelerationSpeed = 1000
ENT.FistDamageMul = 1.5
ENT.MyPhysicsMass = 200
ENT.JumpHeight = 200

ENT.DoMetallicDamage = true
ENT.MetallicMoveSounds = true
ENT.ReallyStrong = true
ENT.ReallyHeavy = true

ENT.HasBrains = true
ENT.IsStupid = false
ENT.IsFodder = false

ENT.term_SoundPitchShift = -30
ENT.term_SoundLevelShift = 10

ENT.Mecha_LastShockwave = 0
ENT.Mecha_ShockwaveCooldown = 5

ENT.TERM_MODELSCALE = 1.5

ENT.term_LoseEnemySound = "npc/strider/strider_alert2.wav"
ENT.term_CallingSound = "npc/strider/strider_alert5.wav"
ENT.term_CallingSmallSound = "npc/strider/strider_alert6.wav"
ENT.term_FindEnemySound = "npc/attack_helicopter/aheli_charge_up.wav"
ENT.term_AttackSound = "npc/strider/strider_step5.wav"
ENT.term_AngerSound = "npc/strider/strider_pain5.wav"
ENT.term_DamagedSound = "npc/strider/strider_pain1.wav"
ENT.term_DieSound = "npc/strider/strider_die1.wav"
ENT.term_JumpSound = "npc/strider/strider_step6.wav"

ENT.IdleLoopingSounds = {
    "npc/strider/strider_ambient01.wav",
}
ENT.AngryLoopingSounds = {
    "npc/attack_helicopter/aheli_rotor_loop1.wav",
}

ENT.Mecha_MarchInterval = 4
ENT.Mecha_StopInterval = 4

if CLIENT then
    language.Add( "terminator_nextbot_zambiemecha", ENT.PrintName )
    return
end

terminator_Extras.Mecha_GlobalClock = terminator_Extras.Mecha_GlobalClock or CurTime()

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )
    
    self:SetSubMaterial( 0, "phoenix_storms/cube" )
    self:SetColor( Color( 60, 60, 80 ) )
    
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.05
    self.DeathDropHeight = 2000
    
    self.HasBrains = true
    self.IsStupid = false
end

ENT.MyClassTask = {
    DisableBehaviour = function( self, data )
        local clockTime = CurTime() - terminator_Extras.Mecha_GlobalClock
        local cycleTime = self.Mecha_MarchInterval + self.Mecha_StopInterval
        local cycleProgress = clockTime % cycleTime
        
        if cycleProgress > self.Mecha_MarchInterval then
            return true
        end
        
        return false
    end,
    
    OnLandOnGround = function( self, data, landedOn, height )
        if height > 350 then
            self:CreateShockwave( height )
        end
    end,
    
    OnKilled = function( self, data, damage, rag )
        self:SelfDestruct()
    end,
    
    OnDamaged = function( self, data, damage )
        if damage:IsFallDamage() and damage:GetDamage() < 50 then
            return true
        end
    end,
}

function ENT:DamageAndPushEntities( pos, radius, damage, igniteRadius )
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self then continue end
        if not IsValid( ent ) then continue end
        
        local entPos = ent:GetPos()
        local dir = ( entPos - pos ):GetNormalized()
        local dist = entPos:Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        if ent:Health() and ent:Health() > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage( damage * distFrac )
            dmg:SetAttacker( game.GetWorld() )
            dmg:SetInflictor( game.GetWorld() )
            dmg:SetDamageType( DMG_BLAST )
            dmg:SetDamageForce( dir * 25000 * distFrac )
            ent:TakeDamageInfo( dmg )
        end
        
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 2000 * distFrac + Vector( 0, 0, 800 * distFrac ) )
        elseif IsValid( ent:GetPhysicsObject() ) then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 1500 * distFrac + Vector( 0, 0, phys:GetMass() * 600 * distFrac ) )
        end
        
        if igniteRadius and dist < igniteRadius and ent:IsPlayer() then
            local burnTime = math.min( 5 * distFrac, 3 )
            if burnTime > 0.5 then
                ent:Ignite( burnTime )
            end
        end
    end
end

function ENT:CreateShockwave( height )
    local cur = CurTime()
    if self.Mecha_LastShockwave + self.Mecha_ShockwaveCooldown > cur then return end
    self.Mecha_LastShockwave = cur
    
    local pos = self:GetPos()
    local radius = math.Clamp( height * 2, 300, 800 )
    local damage = math.Clamp( height * 0.5, 30, 150 )
    
    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", 100, 70 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 100, 80 )
    
    local rings = 5
    for i = 1, rings do
        timer.Simple( i * 0.1, function()
            if not IsValid( self ) then return end
            
            local ringRadius = ( radius / rings ) * i
            local color = Color( 255, 100, 0 )
            
            effects.BeamRingPoint( pos, 0.3, 10, ringRadius, 16, 0, color, { material = "sprites/physbeam", framerate = 20 } )
        end )
    end
    
    for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
        if ent == self then continue end
        if not IsValid( ent ) then continue end
        
        local entPos = ent:GetPos()
        local dir = ( entPos - pos ):GetNormalized()
        local dist = entPos:Distance( pos )
        local distFrac = 1 - ( dist / radius )
        
        if ent:Health() and ent:Health() > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage( damage * distFrac )
            dmg:SetAttacker( self )
            dmg:SetInflictor( self )
            dmg:SetDamageType( DMG_BLAST )
            dmg:SetDamageForce( dir * 10000 * distFrac )
            ent:TakeDamageInfo( dmg )
        end
        
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 1000 * distFrac + Vector( 0, 0, 400 * distFrac ) )
        elseif IsValid( ent:GetPhysicsObject() ) then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 800 * distFrac + Vector( 0, 0, phys:GetMass() * 200 * distFrac ) )
        end
    end
    
    util.ScreenShake( pos, 15, 5, 1.5, radius * 1.5 )
end

function ENT:SelfDestruct()
    local pos = self:GetPos()
    local radius = 650
    local damage = 250
    
    sound.Play( "npc/strider/strider_die1.wav", pos, 120, 70 )
    sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 120, 70 )
    
    local explode = EffectData()
    explode:SetOrigin( pos )
    explode:SetMagnitude( 15 )
    explode:SetScale( 8 )
    explode:SetRadius( radius )
    util.Effect( "Explosion", explode )
    
    for i = 1, 5 do
        timer.Simple( i * 0.08, function()
            local explode2 = EffectData()
            explode2:SetOrigin( pos + VectorRand() * 80 )
            explode2:SetMagnitude( 10 )
            explode2:SetScale( 4 )
            util.Effect( "HelicopterMegaBomb", explode2 )
        end )
    end
    
    for i = 1, 20 do
        timer.Simple( math.Rand( 0, 0.5 ), function()
            local sparkPos = pos + VectorRand() * 150
            local sparks = EffectData()
            sparks:SetOrigin( sparkPos )
            sparks:SetNormal( VectorRand() )
            sparks:SetMagnitude( 12 )
            sparks:SetScale( 8 )
            sparks:SetRadius( 10 )
            util.Effect( "MetalSpark", sparks )
        end )
    end
    
    self:DamageAndPushEntities( pos, radius, damage, radius * 0.4 )
    
    util.ScreenShake( pos, 30, 15, 3, radius * 2.5 )
    
    local sprite = EffectData()
    sprite:SetOrigin( pos )
    sprite:SetScale( 15 )
    sprite:SetMagnitude( 3 )
    util.Effect( "cball_explode", sprite )
end