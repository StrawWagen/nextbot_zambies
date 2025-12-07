AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieglass"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Elite Glass Zombie"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglasselite", {
    Name = "Glass Zombie Elite",
    Class = "terminator_nextbot_zambieglasselite",
    Category = "Nextbot Zambies",
} )

ENT.TERM_MODELSCALE = 1.25

ENT.SpawnHealth = 60
ENT.JumpHeight = 600
ENT.AimSpeed = 900
ENT.WalkSpeed = 220
ENT.MoveSpeed = 650
ENT.RunSpeed = 850
ENT.AccelerationSpeed = 1000

ENT.FistDamageMul = 1.5
ENT.FistRangeMul = 1.2 -- bigger zombs need bigger range, cause they cant get as close to enemy
ENT.zamb_MeleeAttackSpeed = 1.6

ENT.HeightToStartTakingDamage = 300
ENT.FallDamagePerHeight = 0.5
ENT.DeathDropHeight = 800

ENT.DefaultShards = 25

if CLIENT then
    language.Add( "terminator_nextbot_zambieglasselite", ENT.PrintName )

    local render_SetColorModulation = render.SetColorModulation

    function ENT:Draw()
        render_SetColorModulation( .5, .7, 1.0 )
        self:DrawModel()

    end
    return

end

local scalar = Vector( 2.25, 2.25, 2.25 )
local glassColor = Color( 150, 200, 255, 180 )

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModelScale( self.TERM_MODELSCALE, 0 )
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

sound.Add {
    name = "nextbotZambies_GlassBreakEliteA",
    level = 95,
    pitch = 90,
    sound = {
        "physics/glass/glass_largesheet_break1.wav",
        "physics/glass/glass_largesheet_break2.wav",
        "physics/glass/glass_largesheet_break3.wav"
    }
}
sound.Add {
    name = "nextbotZambies_GlassBreakEliteB",
    level = 90,
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

function ENT:CreateShrapnelCallback( ent, damage )
    ent:SetOwner( self )
    ent.shrapnelDamage = damage
    ent.shrapnelNextDamage = 0

    ent:AddCallback( "PhysicsCollide", function( gib, data )
        if data.PhysObject:GetVelocity():LengthSqr() < 100 then
            SafeRemoveEntity( gib )
            return

        end

        if gib.shrapnelNextDamage > CurTime() then return end
        gib.shrapnelNextDamage = CurTime() + 0.05

        local hitEntity = data.HitEntity
        local goodHitEntity = IsValid( hitEntity ) and ( hitEntity:IsPlayer() or hitEntity:IsNPC() )

        if goodHitEntity and not hitEntity.zamb_isGlassZamb then
            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage( gib.shrapnelDamage )
            dmgInfo:SetDamageType( DMG_SLASH )
            dmgInfo:SetAttacker( IsValid( gib:GetOwner() ) and gib:GetOwner() or gib )
            dmgInfo:SetInflictor( gib )
            dmgInfo:SetDamageForce( data.OurOldVelocity:GetNormalized() * 500 )

            hitEntity:TakeDamageInfo( dmgInfo )

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

local trailColor = Color( 150, 200, 255, 220 )

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassBreakEliteA" )
    self:EmitSound( "nextbotZambies_GlassBreakEliteB" )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 2 )
    util.Effect( "GlassImpact", effectdata )

    local iShards = self:GetShards()
    if iShards <= 0 then return end

    local flAngularVelocity = iShards * 40
    local flVelocityMin, flVelocityMax = iShards * 32, iShards * 48

    for _ = 1, iShards do
        local gib = ents.Create( "prop_physics" )
        if not IsValid( gib ) then continue end

        SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 3 ) )

        pos = pos + VectorRand() * 15
        pos.z = pos.z + math.random( -5, 5 )
        gib:SetModel( SHARD_MODELS[ math.random( 1, #SHARD_MODELS ) ] )
        gib:SetPos( pos )
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

        util.SpriteTrail( gib, 0, trailColor, false, 10, 0, 0.4, 0.08, "trails/laser.vmt" )

        self:CreateShrapnelCallback( gib, 10 )

    end
end