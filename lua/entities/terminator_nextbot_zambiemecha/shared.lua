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

ENT.HasBrains = true
ENT.IsStupid = false
ENT.IsFodder = true

ENT.SpawnHealth = 500
ENT.ExtraSpawnHealthPerPlayer = 50
ENT.WalkSpeed = 120
ENT.MoveSpeed = 350
ENT.RunSpeed = 550
ENT.AccelerationSpeed = 2000
ENT.DecelerationSpeed = 3000
ENT.MyPhysicsMass = 1000
ENT.JumpHeight = 200

ENT.FistDamageMul = 3
ENT.FistRangeMul = 1.5
ENT.FistForceMul = 5

ENT.DoMetallicDamage = true
ENT.MetallicMoveSounds = true
ENT.ReallyStrong = true
ENT.ReallyHeavy = true

ENT.term_SoundPitchShift = -15
ENT.term_SoundLevelShift = 5

ENT.Mecha_LastShockwave = 0
ENT.Mecha_ShockwaveCooldown = 5

ENT.TERM_MODELSCALE = 1.2
ENT.CollisionBounds = { Vector( -12.5, -12.5, 0 ), Vector( 12.5, 12.5, 58.5 ) }

ENT.term_LoseEnemySound = "Zombie.Idle"
ENT.term_FindEnemySound = "npc/dog/dog_alarmed1.wav"
ENT.term_AttackSound = "npc/dog/dog_angry2.wav"
ENT.term_AngerSound = "npc/dog/dog_alarmed3.wav"
ENT.term_DamagedSound = {
    "npc/dog/dog_growl2.wav",
    "npc/dog/dog_growl1.wav",
    "npc/dog/dog_angry1.wav",
    "npc/dog/dog_angry2.wav",
    "npc/dog/dog_angry3.wav"
}
ENT.term_DieSound = "npc/dog/dog_on_dropship.wav"
ENT.term_JumpSound = "npc/dog/dog_drop_gate1.wav"

ENT.AlwaysPlayLooping = true

ENT.Mecha_MarchInterval = 4
ENT.Mecha_StopInterval = 4

ENT.Term_BaseMsBetweenSteps = 200
ENT.Term_FootstepMsReductionPerUnitSpeed = 1
ENT.Term_FootstepTiming = "timed"
ENT.Term_FootstepSoundWalking = {
    {
        path = "NPC_dog.FootstepLeft",
        lvl = 80,
        pitch = 75,
    },
    {
        path = "NPC_dog.FootstepRight",
        lvl = 80,
        pitch = 75,
    },
}
ENT.Term_FootstepSound = {
    {
        path = "NPC_dog.RunFootstepLeft",
        lvl = 88,
        pitch = 80,
        chan = CHAN_BODY,
    },
    {
        path = "NPC_dog.RunFootstepRight",
        lvl = 88,
        pitch = 85,
        chan = CHAN_BODY,
    },
}
ENT.Term_FootstepShake = {
    amplitude = 5,
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

    -- have to override these in AdditionalInitialize otherwise the base zombie's sounds don't all go away
    self.IdleLoopingSounds = {
        "npc/dog/dog_combatmode_loop1.wav",
    }
    self.AngryLoopingSounds = {
        "plats/squeekmove1.wav",
    }
end

ENT.MyClassTask = {
    Think = function( self, data )
        local wasDisabled = data.WasDisabled
        local cycleTime = self.Mecha_MarchInterval + self.Mecha_StopInterval
        local myPersonalOffset = ( self:GetCreationID() % 1000 ) / 2000
        local cycleProgress = ( CurTime() + myPersonalOffset ) % cycleTime
        local shouldBeDisabled = cycleProgress > self.Mecha_MarchInterval

        self.mechaZamb_IsDisabled = shouldBeDisabled
        data.WasDisabled = shouldBeDisabled

        if shouldBeDisabled then
            self:DoGesture( ACT_HL2MP_IDLE_COWER, 1 ) -- kinda hacky to spam DoGesture this much, but it works

        end

        if shouldBeDisabled and not wasDisabled then
            self:Term_SpeakSoundNow( "npc/dog/dog_straining3.wav", math.random( -5, -15 ) )
            if self:IsAngry() and self:GetIdealMoveSpeed() > self.MoveSpeed then
                self:EmitSound( "npc/dog/car_impact2.wav", 75 + self.term_SoundLevelShift, math.random( 110, 130 ) + self.term_SoundPitchShift, 1, CHAN_STATIC )

            end
        elseif not shouldBeDisabled and wasDisabled then
            if self:IsAngry() and math.random( 1, 100 ) < 25 then
                self:ZAMB_NormalCall()

            else
                self:Term_SpeakSoundNow( "ambient/machines/spinup.wav", -10 )

            end
        end
    end,

    DisableBehaviour = function( self, data )
        return self.mechaZamb_IsDisabled

    end,

    OnLandOnGround = function( self, data, landedOn, height )
        if height < 350 then return end
        self:CreateShockwave( height )

    end,

    OnKilled = function( self, data, damage, rag )
        self:SelfDestruct()

    end,

    OnDamaged = function( self, data, damage )
        if self.mechaZamb_IsDisabled then
            damage:ScaleDamage( 0.25 )

        end
        if damage:IsFallDamage() and damage:GetDamage() < 50 then
            return true -- block damage

        end
    end,

    BlockClawSwipe = function( self, data ) -- claw swipes have a delay, so don't deal unfair damage here pls
        return self.mechaZamb_IsDisabled

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
            local attacker = self
            if not IsValid( attacker ) then
                attacker = game.GetWorld()

            end
            dmg:SetAttacker( attacker )
            dmg:SetInflictor( attacker )
            dmg:SetDamageType( DMG_BLAST )
            dmg:SetDamageForce( dir * 25000 * distFrac )
            ent:TakeDamageInfo( dmg )

        end

        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent:SetVelocity( dir * 1500 * distFrac + Vector( 0, 0, 800 * distFrac ) )

        elseif IsValid( ent:GetPhysicsObject() ) then
            local phys = ent:GetPhysicsObject()
            phys:ApplyForceCenter( dir * phys:GetMass() * 1500 * distFrac + Vector( 0, 0, phys:GetMass() * 600 * distFrac ) )

        end

        if igniteRadius and dist < igniteRadius then
            if IsValid( ent:GetParent() ) then continue end

            local burnTime = math.min( 5 * distFrac, 3 )
            if ent:IsPlayer() then burnTime = burnTime * 0.5 end

            ent:Ignite( burnTime )

        end
    end
end

function ENT:CreateShockwave( height )
    local cur = CurTime()
    if self.Mecha_LastShockwave + self.Mecha_ShockwaveCooldown > cur then return end
    self.Mecha_LastShockwave = cur

    local pos = self:GetPos()
    local radius = math.Clamp( height * 1.15, 100, 400 )
    local damage = math.Clamp( height * 0.15, 1, 100 )

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
    local radius = 500
    local damage = 65

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

    for _ = 1, 20 do
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