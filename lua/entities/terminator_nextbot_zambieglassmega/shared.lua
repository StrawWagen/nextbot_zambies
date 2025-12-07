AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieglasselite"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Glass Mega"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglassmega", {
    Name = "Zombie Glass Mega",
    Class = "terminator_nextbot_zambieglassmega",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieglassmega", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.3, 0.5, 1.0 )
        self:DrawModel()
    end
    return
end

ENT.TERM_MODELSCALE = 1.5

ENT.SpawnHealth = 120
ENT.JumpHeight = 700
ENT.AimSpeed = 1000
ENT.WalkSpeed = 250
ENT.MoveSpeed = 700
ENT.RunSpeed = 950
ENT.AccelerationSpeed = 1200

ENT.FistDamageMul = 2.0
ENT.zamb_MeleeAttackSpeed = 1.8

ENT.HeightToStartTakingDamage = 400
ENT.FallDamagePerHeight = 0.3
ENT.DeathDropHeight = 1000

ENT.DefaultShards = 35

sound.Add {
    name = "nextbotZambies_GlassBreakMegaA",
    level = 100,
    pitch = 80,
    sound = {
        "physics/glass/glass_largesheet_break1.wav",
        "physics/glass/glass_largesheet_break2.wav",
        "physics/glass/glass_largesheet_break3.wav"
    }
}
sound.Add {
    name = "nextbotZambies_GlassBreakMegaB",
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

local GLASS_ZOMBIE_CLASSES = {
    ["terminator_nextbot_zambieglass"] = true,
    ["terminator_nextbot_zambieglasselite"] = true,
    ["terminator_nextbot_zambieglassmega"] = true,
}

local function CreateShrapnelCallback( ent, damage )
    ent.IsGlassShrapnel = true
    ent.ShrapnelDamage = damage
    ent.ShrapnelOwner = ent
    ent.DamagedEntities = {}

    ent:AddCallback( "PhysicsCollide", function( gib, data )
        if not IsValid( gib ) or not gib.IsGlassShrapnel then return end
        if data.PhysObject:GetVelocity():LengthSqr() < 100 then
            SafeRemoveEntity( gib )
            return
        end

        local hitEntity = data.HitEntity
        if IsValid( hitEntity ) and ( hitEntity:IsPlayer() or hitEntity:IsNPC() ) and not gib.DamagedEntities[ hitEntity ] then
            if not GLASS_ZOMBIE_CLASSES[ hitEntity:GetClass() ] then
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage( gib.ShrapnelDamage )
                dmgInfo:SetDamageType( DMG_SLASH )
                dmgInfo:SetAttacker( IsValid( gib.ShrapnelOwner ) and gib.ShrapnelOwner or gib )
                dmgInfo:SetInflictor( gib )
                dmgInfo:SetDamageForce( data.OurOldVelocity:GetNormalized() * 500 )

                hitEntity:TakeDamageInfo( dmgInfo )
                gib.DamagedEntities[ hitEntity ] = true
            end
        end

        if data.Speed > 100 then
            gib:EmitSound( "physics/glass/glass_impact_bullet" .. math.random( 1, 4 ) .. ".wav", 70, math.random( 90, 110 ) )

            local impact = EffectData()
            impact:SetOrigin( data.HitPos )
            impact:SetNormal( data.HitNormal )
            impact:SetScale( 0.5 )
            util.Effect( "GlassImpact", impact )
        end
    end )
end

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModelScale( self.TERM_MODELSCALE, 0 )
    self:SetColor( Color( 120, 180, 255, 180 ) )
    self:SetShards( self.DefaultShards )

    self.GlassArmsAppliedMega = false
    self.NextShardShootTime = 0
end

function ENT:Think()
    if not self.GlassArmsAppliedMega then
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
            if boneID then
                self:ManipulateBoneScale( boneID, Vector( 2.5, 2.5, 2.5 ) )
            end
        end

        self.GlassArmsAppliedMega = true
    end

    BaseClass.Think( self )
end

function ENT:OnTakeDamage( dmgInfo )
    BaseClass.OnTakeDamage( self, dmgInfo )

    if CurTime() >= self.NextShardShootTime then
        self:ShootGlassShards( dmgInfo )
        self.NextShardShootTime = CurTime() + 0.3
    end
end

function ENT:ShootGlassShards( dmgInfo )
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassShardShoot" )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 1 )
    util.Effect( "GlassImpact", effectdata )

    for _ = 1, math.random( 5, 8 ) do
        local gib = ents.Create( "prop_physics" )
        if IsValid( gib ) then
            local shootPos = pos + VectorRand() * 10
            gib:SetModel( SHARD_MODELS[ math.random( 1, #SHARD_MODELS ) ] )
            gib:SetPos( shootPos )
            gib:SetAngles( AngleRand() )
            gib:SetMaterial( "models/props_windows/window_glass" )
            gib:Spawn()
            gib:Activate()

            local phys = gib:GetPhysicsObject()
            if IsValid( phys ) then
                local shootDir = VectorRand()
                shootDir.z = math.max( shootDir.z, 0 )
                phys:Wake()
                phys:SetVelocity( shootDir * math.Rand( 600, 1000 ) )
                phys:AddAngleVelocity( VectorRand() * 800 )
            end

            util.SpriteTrail( gib, 0, Color( 120, 180, 255, 200 ), false, 8, 0, 0.3, 0.08, "trails/laser.vmt" )

            gib.ShrapnelOwner = self
            CreateShrapnelCallback( gib, 10 )

            SafeRemoveEntityDelayed( gib, math.Rand( 1, 3 ) )
        end
    end
end

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassBreakMegaA" )
    self:EmitSound( "nextbotZambies_GlassBreakMegaB" )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 3 )
    util.Effect( "GlassImpact", effectdata )

    local iShards = self:GetShards()
    if iShards <= 0 then return end

    local flAngularVelocity = 1200
    local flVelocityMin, flVelocityMax = 1000, 1500

    for _ = 1, iShards do
        local gib = ents.Create( "prop_physics" )
        if IsValid( gib ) then
            local gibPos = pos + VectorRand() * 20
            gibPos.z = gibPos.z + math.random( -10, 10 )
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

            util.SpriteTrail( gib, 0, Color( 120, 180, 255, 220 ), false, 12, 0, 0.5, 0.08, "trails/laser.vmt" )

            gib.ShrapnelOwner = self
            CreateShrapnelCallback( gib, 20 )

            SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 4 ) )
        end
    end
end