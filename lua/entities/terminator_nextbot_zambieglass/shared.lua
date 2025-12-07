AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Glass"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglass", {
    Name = "Glass Zombie",
    Class = "terminator_nextbot_zambieglass",
    Category = "Nextbot Zambies",
} )

ENT.Author = "regunkyle"
ENT.zamb_isGlassZamb = true

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "Shards", { KeyName = "ishards", Edit = { type = "Int", min = 0, max = 100, order = 1 } } )

end

local ragColor = Color( 255, 255, 255, 255 )

function ENT:AdditionalRagdollDeathEffects( ragdoll )
    if not IsValid( ragdoll ) then return end

    ragdoll:SetSubMaterial( 0, "!nextbotZambies_GlassMaterial" )
    ragdoll:SetColor( ragColor )

end

ENT.SpawnHealth = 20
ENT.AimSpeed = 800
ENT.WalkSpeed = 200
ENT.MoveSpeed = 600
ENT.RunSpeed = 800
ENT.AccelerationSpeed = 900

ENT.FistDamageMul = 1.25
ENT.zamb_MeleeAttackSpeed = 1.4

ENT.HeightToStartTakingDamage = 10
ENT.FallDamagePerHeight = 1
ENT.DeathDropHeight = 100

ENT.DefaultShards = 10

if CLIENT then
    language.Add( "terminator_nextbot_zambieglass", ENT.PrintName )

    local setupMat
    local desiredBaseTexture = "glass/glasswindow007a"
    local mat = "nextbotZambies_GlassMaterial"
    function ENT:AdditionalClientInitialize()
        if setupMat then return end
        setupMat = true

        local newMat = CreateMaterial( mat, "VertexLitGeneric", {
            ["$basetexture"] = desiredBaseTexture,
            ["$envmap"] = "env_cubemap",
            ["$envmaptint"] = "[.6 .6 .7]",
            ["$translucent"] = 1,
        } )

        if newMat and newMat:GetKeyValues()["$basetexture"] then
            newMat:SetTexture( "$basetexture", desiredBaseTexture )

        end

    end
    return

end

local scalar = Vector( 1.5, 1.5, 1.5 )
local glassColor = Color( 200, 220, 255, 180 )

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetSubMaterial( 0, "!nextbotZambies_GlassMaterial" )
    timer.Simple( 0, function()
        if not IsValid( self ) then return end
        self:SetSubMaterial( 0, "!nextbotZambies_GlassMaterial" )

    end )
    self:SetRenderMode( RENDERMODE_TRANSALPHA )
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
    name = "nextbotZambies_GlassBreakA",
    level = 85,
    sound = {
        "physics/glass/glass_largesheet_break1.wav",
        "physics/glass/glass_largesheet_break2.wav",
        "physics/glass/glass_largesheet_break3.wav"
    }
}
sound.Add {
    name = "nextbotZambies_GlassBreakB",
    level = 80,
    pitch = 110,
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

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "nextbotZambies_GlassBreakA" )
    self:EmitSound( "nextbotZambies_GlassBreakB" )

    local iShards = self:GetShards()
    if iShards <= 0 then return end

    local flAngularVelocity = iShards * 50
    local flVelocityMin, flVelocityMax = iShards * 30, iShards * 60
    for _ = 1, iShards do
        local gib = ents.Create( "prop_physics" )
        if not IsValid( gib ) then continue end

        SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 1.5 ) )

        gib:SetModel( SHARD_MODELS[ math.random( 1, #SHARD_MODELS ) ] )
        gib:SetPos( pos + VectorRand() * 20 )
        gib:SetAngles( AngleRand() )
        gib:SetMaterial( "models/props_windows/window_glass" )
        gib:Spawn()
        gib:Activate()

        gib:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

        local phys = gib:GetPhysicsObject()
        if not IsValid( phys ) then continue end

        phys:Wake()
        phys:SetVelocity( VectorRand() * math.Rand( flVelocityMin, flVelocityMax ) )
        phys:AddAngleVelocity( VectorRand() * flAngularVelocity )

    end
end

ENT.MyClassTask = {
    PreventBecomeRagdollOnKilled = function( self, data )
        self:GlassZambDie()
        SafeRemoveEntityDelayed( self, 0 )
        return true, true
    end
}