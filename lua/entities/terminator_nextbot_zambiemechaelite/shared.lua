AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiemecha"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Mecha Elite"
ENT.Spawnable = false
ENT.Author = "regunkyle"
list.Set( "NPC", "terminator_nextbot_zambiemechaelite", {
    Name = "Zombie Mecha Elite",
    Class = "terminator_nextbot_zambiemechaelite",
    Category = "Nextbot Zambies",
} )

ENT.IsFodder = false

ENT.SpawnHealth = 3000
ENT.ExtraSpawnHealthPerPlayer = 500
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 2

ENT.WalkSpeed = 120
ENT.MoveSpeed = 400
ENT.RunSpeed = 600
ENT.AccelerationSpeed = 3000
ENT.DecelerationSpeed = 4000

ENT.FistDamageMul = 2.0
ENT.MyPhysicsMass = 5000
ENT.JumpHeight = 600

ENT.DuelEnemyDist = 500
ENT.CloseEnemyDistance = 600

ENT.HeightToStartTakingDamage = 500
ENT.FallDamagePerHeight = 0.025
ENT.DeathDropHeight = 3000

ENT.term_SoundPitchShift = -30
ENT.term_SoundLevelShift = 40

ENT.Mecha_ShockwaveCooldown = 4
ENT.Mecha_ShockwaveThreshold = 250
ENT.Mecha_CriticalHealth = 0.5

ENT.TERM_MODELSCALE = 2.25
ENT.CollisionBounds = { Vector( -8, -8, 0 ), Vector( 8, 8, 28 ) }
ENT.CrouchCollisionBounds = { Vector( -6, -6, 0 ), Vector( 6, 6, 16 ) }

ENT.Term_FootstepTiming = "perfect"
ENT.PerfectFootsteps_FeetBones = { "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot" }
ENT.PerfectFootsteps_SteppingCriteria = -0.8

ENT.Term_FootstepShake = {
    amplitude = 8,
    frequency = 20,
    duration = 0.4,
    radius = 2000,
}

ENT.FistDamageMul = 15
ENT.FistRangeMul = 2
ENT.FistForceMul = 100

if CLIENT then
    language.Add( "terminator_nextbot_zambiemechaelite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.4, 0.4, 0.6 )
        self:DrawModel()
        render.SetColorModulation( 1, 1, 1 )

    end

    return
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetSubMaterial( 0, "phoenix_storms/cube" )

    self.HasBrains = true
    self.IsStupid = false

    self.Mecha_MarchInterval = 10
    self.Mecha_StopInterval = 5

    self.Mecha_IsEnraged = false
    self.Term_FootstepSoundWalking = {
        {
            path = "npc/dog/dog_footstep_run4.wav",
            lvl = 90,
            pitch = 60,
        },
        {
            path = "npc/dog/dog_footstep_run8.wav",
            lvl = 90,
            pitch = 60,
        },
    }
    self.Term_FootstepSound = {
        {
            path = "NPC_Strider.Footstep",
            lvl = 95,
            pitch = 100,
        },
    }
    self.IdleLoopingSounds = {
        "ambient/machines/train_idle.wav",
    }
    self.AngryLoopingSounds = {
        "ambient/machines/train_freight_loop1.wav",
    }
end

-- makes us wait a second at 0 hp when dying
ENT.Term_DeathAnim = {
    act = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
    rate = 0.75,
}

ENT.MyClassTask = {
    Think = function( self, data )
        if self.Mecha_IsEnraged then return end

        local healthPercent = self:Health() / self:GetMaxHealth()
        if healthPercent >= self.Mecha_CriticalHealth then return end

        self.Mecha_IsEnraged = true

        self.RunSpeed = self.RunSpeed * 1.3
        self.FistDamageMul = self.FistDamageMul * 1.4
        self.Mecha_ShockwaveCooldown = 2.5

        self:EmitSound( "npc/strider/strider_pain" .. math.random( 1, 5 ) .. ".wav", 110, 60 )
        self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 110, 70 )

        util.ScreenShake( self:GetPos(), 25, 10, 2, 3000 )

        for i = 1, 11 do
            timer.Simple( i * 0.1, function()
                if not IsValid( self ) then return end

                local pos = self:WorldSpaceCenter()
                local sparks = EffectData()
                sparks:SetOrigin( pos + VectorRand() * 50 )
                sparks:SetNormal( VectorRand() )
                sparks:SetMagnitude( 10 )
                sparks:SetScale( 5 )
                sparks:SetRadius( 10 )
                util.Effect( "ElectricSpark", sparks )

            end )
        end

        self.AngryLoopingSounds = {
            "npc/dog/dog_angry1.wav",
            "npc/dog/dog_angry2.wav",
            "npc/dog/dog_angry3.wav",

        }

        self:ZAMB_AngeringCall( true, 1, false )

        self:ReallyAnger( 100 )

    end,

    OnLandOnGround = function( self, data, landedOn, height ) -- note, OnLandOnGround in the normal mecha zombie is also being called
        if height < self.Mecha_ShockwaveThreshold then return end
        self:CreateEliteShockwave( height )

    end,

    OnDamaged = function( self, data, damage )
        if damage:IsFallDamage() and damage:GetDamage() < 150 then
            return true

        end
    end,

    OnStartDying = function( self, data )
        local scale = 1
        self:ZAMB_AngeringCall( true, 1, false )

        local timerName = "zamb_elitemecha_warpbonesondeath_" .. self:GetCreationID()
        timer.Create( timerName, 0.1, 0, function()
            if not IsValid( self ) then timer.Remove( timerName ) return end

            scale = scale + 0.01
            -- manupulate our bones's scale, warping them as time goes on
            local bones = self:GetBoneCount()
            for bone = 0, bones - 1 do
                local finalScale = Vector( math.Rand( 0.5, 1.5 ), math.Rand( 0.5, 1.5 ), math.Rand( 0.1, 2 ) ) * scale
                self:ManipulateBoneScale( bone, finalScale )

            end
        end )
    end,

    OnKilled = function( self, data, damage, rag )
        self:EliteSelfDestruct()

    end,
}

function ENT:CreateEliteShockwave( height )
    local cur = CurTime()
    if self.Mecha_LastShockwave + self.Mecha_ShockwaveCooldown > cur then return end
    self.Mecha_LastShockwave = cur

    local pos = self:GetPos()
    local radius = math.Clamp( height * 3, 400, 1200 )
    local damage = math.Clamp( height * 0.8, 60, 300 )

    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", 115, 50 )
    self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 115, 60 )
    self:EmitSound( "npc/strider/fire.wav", 110, 80 )

    local rings = 8
    for i = 1, rings do
        timer.Simple( i * 0.07, function()
            if not IsValid( self ) then return end

            local ringRadius = ( radius / rings ) * i

            local color1 = Color( 255, 120, 20 )
            effects.BeamRingPoint( pos, 0.5, 20, ringRadius, 24, 0, color1, { material = "sprites/physbeam", framerate = 20 } )

            timer.Simple( 0.04, function()
                local color2 = Color( 80, 120, 255 )
                effects.BeamRingPoint( pos, 0.4, 15, ringRadius * 0.8, 20, 0, color2, { material = "sprites/physbeam", framerate = 20 } )

            end )
        end )
    end

    for _ = 1, 12 do
        timer.Simple( math.Rand( 0, 0.3 ), function()
            local dustPos = pos + VectorRand() * ( radius * 0.5 )
            dustPos.z = pos.z

            local dust = EffectData()
            dust:SetOrigin( dustPos )
            dust:SetScale( 10 )
            dust:SetMagnitude( 5 )
            util.Effect( "ThumperDust", dust )
        end )
    end

    self:DamageAndPushEntities( pos, radius, damage )

    util.ScreenShake( pos, 25, 10, 2.5, radius * 2 )

end

function ENT:EliteSelfDestruct()
    local pos = self:GetPos()
    local radius = 1000
    local damage = 500

    timer.Simple( 0.15, function()
        sound.Play( "npc/strider/strider_die1.wav", pos, 140, 50 )
        sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 140, 50 )
        sound.Play( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav", pos, 140, 70 )
        sound.Play( "ambient/levels/labs/electric_explosion1.wav", pos, 140, 60 )

        local explode = EffectData()
        explode:SetOrigin( pos )
        explode:SetMagnitude( 25 )
        explode:SetScale( 15 )
        explode:SetRadius( radius )
        util.Effect( "Explosion", explode )

        for i = 1, 12 do
            timer.Simple( i * 0.05, function()
                local bombPos = pos + VectorRand() * 150
                local bomb = EffectData()
                bomb:SetOrigin( bombPos )
                bomb:SetMagnitude( 18 )
                bomb:SetScale( 8 )
                util.Effect( "HelicopterMegaBomb", bomb )

            end )
        end

        for _ = 1, 40 do
            timer.Simple( math.Rand( 0, 0.8 ), function()
                local sparkPos = pos + VectorRand() * 250
                local sparks = EffectData()
                sparks:SetOrigin( sparkPos )
                sparks:SetNormal( VectorRand() )
                sparks:SetMagnitude( 18 )
                sparks:SetScale( 12 )
                sparks:SetRadius( 15 )
                util.Effect( "MetalSpark", sparks )

            end )
        end

        for _ = 1, 20 do
            timer.Simple( math.Rand( 0, 0.6 ), function()
                local arcPos = pos + VectorRand() * 300
                local arc = EffectData()
                arc:SetOrigin( arcPos )
                arc:SetMagnitude( 12 )
                arc:SetScale( 5 )
                util.Effect( "ElectricSpark", arc )

            end )
        end

        self:DamageAndPushEntities( pos, radius, damage, radius * 0.5 )

        util.ScreenShake( pos, 50, 25, 5, radius * 3 )

        local sprite = EffectData()
        sprite:SetOrigin( pos )
        sprite:SetScale( 30 )
        sprite:SetMagnitude( 8 )
        util.Effect( "cball_explode", sprite )

    end )
end