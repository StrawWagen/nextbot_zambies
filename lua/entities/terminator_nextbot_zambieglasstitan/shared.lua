AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieglasselite"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Glass Titan"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglasstitan", {
    Name = "Zombie Glass Titan",
    Class = "terminator_nextbot_zambieglasstitan",
    Category = "Nextbot Zambies",
} )

ENT.CoroutineThresh = terminator_Extras.baseCoroutineThresh / 15

ENT.TERM_MODELSCALE = 1.75
ENT.CollisionBounds = { Vector( -9, -9, 0 ), Vector( 9, 9, 30 ) }
ENT.CrouchCollisionBounds = { Vector( -7, -7, 0 ), Vector( 7, 7, 25 ) }
ENT.MyPhysicsMass = 2500

ENT.SpawnHealth = 2000
ENT.ExtraSpawnHealthPerPlayer = 500
ENT.JumpHeight = 1000
ENT.AimSpeed = 500
ENT.CrouchSpeed = 300
ENT.WalkSpeed = 300
ENT.MoveSpeed = 1000
ENT.RunSpeed = 2500
ENT.AccelerationSpeed = 750

ENT.FistDamageMul = 4.0
ENT.FistRangeMul = 2.5 -- bigger zombs need bigger range, cause they cant get as close to enemy
ENT.zamb_MeleeAttackSpeed = 3

ENT.HeightToStartTakingDamage = 4000
ENT.FallDamagePerHeight = 0.3
ENT.DeathDropHeight = 1000

ENT.DefaultShards = 55

ENT.term_SoundLevelShift = 20
ENT.term_SoundPitchShift = -20

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Shoot Shards", -- diff name
        ratelimit = 3, -- seconds between uses
        svAction = function( _drive, _driver, bot )
            bot:ZAMB_AngeringCall( true, 4, true )
            timer.Simple( 0.3, function()
                if not IsValid( bot ) then return end
                bot:ShootGlassShards()

            end )
        end,
    }
}

if CLIENT then
    language.Add( "terminator_nextbot_zambieglasstitan", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.3, 0.5, 1.0 )
        self:DrawModel()

    end
    return

end

ENT.MyClassTask = {
    OnDamaged = function( self, data, dmginfo )
        if dmginfo:GetDamage() > self:Health() then return end
        if not self:CanTakeAction( "call" ) then return end
        if self.DistToEnemy > self.DuelEnemyDist and math.random( 0, 100 ) < 90 then return end
        self:TakeAction( "call" )

    end,
    OnLandOnGround = function( self, data )
        if not self:CanTakeAction( "call" ) then return end
        if self.DistToEnemy > self.DuelEnemyDist and math.random( 0, 100 ) < 50 then return end
        self:TakeAction( "call" )

    end,
}

-- does not flinch
function ENT:HandleFlinching()
end

sound.Add {
    name = "nextbotZambies_GlassBreakTitanA",
    level = 100,
    pitch = 80,
    sound = {
        "physics/glass/glass_largesheet_break1.wav",
        "physics/glass/glass_largesheet_break2.wav",
        "physics/glass/glass_largesheet_break3.wav"
    }
}
sound.Add {
    name = "nextbotZambies_GlassBreakTitanB",
    level = 95,
    pitch = 90,
    sound = {
        "physics/glass/glass_sheet_break1.wav",
        "physics/glass/glass_sheet_break2.wav",
        "physics/glass/glass_sheet_break3.wav"
    }
}
sound.Add {
    name = "nextbotZambies_GlassShardShoot",
    level = 75,
    pitch = 120,
    sound = {
        "physics/glass/glass_sheet_break1.wav",
        "physics/glass/glass_sheet_break2.wav",
        "physics/glass/glass_sheet_break3.wav"
    }
}

local SHARD_MODELS = {
    "models/gibs/glass_shard01.mdl",
    "models/gibs/glass_shard02.mdl",
    "models/gibs/glass_shard03.mdl",
    "models/gibs/glass_shard04.mdl",
    "models/gibs/glass_shard05.mdl",
    "models/gibs/glass_shard06.mdl",
}

local scalar = Vector( 1.5, 1.5, 1.5 )
local glassColor = Color( 120, 180, 255, 180 )

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetColor( glassColor )
    self:SetShards( self.DefaultShards )

    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        local armBones = {
            "ValveBiped.Bip01_L_UpperArm",
            "ValveBiped.Bip01_L_Forearm",
            "ValveBiped.Bip01_L_Hand",
            "ValveBiped.Bip01_R_UpperArm",
            "ValveBiped.Bip01_R_Forearm",
            "ValveBiped.Bip01_R_Hand",
        }

        for _, boneName in ipairs( armBones ) do
            local boneID = self:LookupBone( boneName )
            if not boneID then continue end
            self:ManipulateBoneScale( boneID, scalar )

        end
    end )
end

local trailColor = Color( 120, 180, 255, 200 )

function ENT:ShootGlassShards()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassShardShoot" )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 1 )
    util.Effect( "GlassImpact", effectdata )

    for _ = 1, math.random( 12, 18 ) do
        local gib = ents.Create( "prop_physics" )
        if not IsValid( gib ) then continue end

        SafeRemoveEntityDelayed( gib, math.Rand( 1, 3 ) )

        local shootPos = pos + VectorRand() * 25
        gib:SetModel( SHARD_MODELS[ math.random( 1, #SHARD_MODELS ) ] )
        gib:SetPos( shootPos )
        gib:SetAngles( AngleRand() )
        gib:SetMaterial( "models/props_windows/window_glass" )
        gib:Spawn()
        gib:Activate()

        local phys = gib:GetPhysicsObject()
        if IsValid( phys ) then
            local shootDir = VectorRand()
            shootDir.z = math.Clamp( shootDir.z, -0.5, 0.5 )
            shootDir:Normalize()
            phys:Wake()
            phys:SetVelocity( shootDir * math.Rand( 5500, 8500 ) )
            phys:AddAngleVelocity( VectorRand() * 800 )

        end

        util.SpriteTrail( gib, 0, trailColor, false, 8, 0, 0.3, 0.08, "trails/laser.vmt" )

        self:CreateShrapnelCallback( gib, 15 )

    end
end

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassBreakTitanA" )
    self:EmitSound( "nextbotZambies_GlassBreakTitanB" )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 3 )
    util.Effect( "GlassImpact", effectdata )

    local iShards = self:GetShards()
    if iShards <= 0 then return end

    local flAngularVelocity = 1200
    local flVelocityMin, flVelocityMax = 10000, 12000

    for _ = 1, iShards do
        local gib = ents.Create( "prop_physics" )
        if not IsValid( gib ) then continue end

        SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 4 ) )

        local gibPos = pos + VectorRand() * 35
        gibPos.z = gibPos.z + math.random( -40, 10 )
        gib:SetModel( SHARD_MODELS[ math.random( 1, #SHARD_MODELS ) ] )
        gib:SetPos( gibPos )
        gib:SetAngles( AngleRand() )
        gib:SetMaterial( "models/props_windows/window_glass" )
        gib:Spawn()
        gib:Activate()

        local phys = gib:GetPhysicsObject()
        if IsValid( phys ) then
            local velDir = VectorRand() + self:GetAimVector() * 0.5
            phys:Wake()
            phys:SetVelocity( velDir * math.Rand( flVelocityMin, flVelocityMax ) )
            phys:AddAngleVelocity( VectorRand() * flAngularVelocity )

        end

        util.SpriteTrail( gib, 0, trailColor, false, 12, 0, 0.5, 0.08, "trails/laser.vmt" )

        self:CreateShrapnelCallback( gib, 25 )

    end
end