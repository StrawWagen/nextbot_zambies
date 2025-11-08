AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Mecha"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiemecha", {
    Name = "Zombie Mecha",
    Class = "terminator_nextbot_zambiemecha",
    Category = "Nextbot Zambies",
} )

ENT.SpawnHealth = 500
ENT.WalkSpeed = 120
ENT.MoveSpeed = 350
ENT.RunSpeed = 550
ENT.AccelerationSpeed = 2000
ENT.DecelerationSpeed = 3000
ENT.FistDamageMul = 1.5
ENT.MyPhysicsMass = 1000
ENT.JumpHeight = 200

ENT.DoMetallicDamage = true
ENT.MetallicMoveSounds = true
ENT.ReallyStrong = true
ENT.ReallyHeavy = true

ENT.HasBrains = true
ENT.IsStupid = false
ENT.IsFodder = false

ENT.term_SoundPitchShift = -15
ENT.term_SoundLevelShift = 5

ENT.Mecha_LastShockwave = 0
ENT.Mecha_ShockwaveCooldown = 5

ENT.TERM_MODELSCALE = 1.2
ENT.CollisionBounds = { Vector( -12.5, -12.5, 0 ), Vector( 12.5, 12.5, 57 ) }

ENT.term_LoseEnemySound = "Zombie.Idle"
ENT.term_CallingSound = "npc/zombie/zombie_voice_idle1.wav"
ENT.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
ENT.term_FindEnemySound = "Zombie.Alert"
ENT.term_AttackSound = "npc/zombie/zombie_alert1.wav"
ENT.term_AngerSound = "npc/zombie/zombie_alert2.wav"
ENT.term_DamagedSound = "Zombie.Pain"
ENT.term_DieSound = "Zombie.Die"
ENT.term_JumpSound = "npc/zombie/foot1.wav"

ENT.IdleLoopingSounds = {
    "npc/zombie/moan_loop1.wav",
}
ENT.AngryLoopingSounds = {
    "npc/zombie/moan_loop3.wav",
}

ENT.Mecha_MarchInterval = 4
ENT.Mecha_StopInterval = 4

ENT.Term_FootstepTiming = "perfect"
ENT.PerfectFootsteps_FeetBones = { "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot" }
ENT.PerfectFootsteps_SteppingCriteria = -0.75
ENT.Term_FootstepSoundWalking = {
    {
        path = "npc/zombie/foot2.wav",
        lvl = 78,
        pitch = 80,
    },
    {
        path = "npc/zombie/foot3.wav",
        lvl = 78,
        pitch = 80,
    },
}
ENT.Term_FootstepSound = {
    {
        path = "npc/zombie/foot1.wav",
        lvl = 85,
        pitch = 75,
    },
    {
        path = "npc/zombie/foot2.wav",
        lvl = 85,
        pitch = 75,
    },
}
ENT.Term_FootstepShake = {
    amplitude = 1,
    frequency = 20,
    duration = 0.25,
    radius = 800,
}

if CLIENT then
    language.Add( "terminator_nextbot_zambiemecha", ENT.PrintName )
    return
end

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
        local cycleTime = self.Mecha_MarchInterval + self.Mecha_StopInterval
        local cycleProgress = CurTime() % cycleTime
        
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
    
    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", 90, 70 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 90, 80 )
    
    local rings = 5
    for i = 1, rings do
        timer.Simple( i * 0.1, function()
            if not IsValid( self ) then return end
            
            local ringRadius = ( radius / rings ) * i
            local color = Color( 255, 100, 0 )
            
            effects.BeamRingPoint( pos, 0.3, 10, ringRadius, 16, 0, color, { material = "sprites/physbeam", framerate = 20 } )
        end )
    end
    
    self:DamageAndPushEntities( pos, radius, damage )
    
    util.ScreenShake( pos, 15, 5, 1.5, radius * 1.5 )
end

function ENT:SelfDestruct()
    local pos = self:GetPos()
    local radius = 650
    local damage = 250
    
    sound.Play( "npc/zombie/zombie_die1.wav", pos, 100, 50 )
    sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 100, 70 )
    
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