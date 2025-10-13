AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambiefast"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Glass"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglass", {
    Name = "Zombie Glass",
    Class = "terminator_nextbot_zambieglass",
    Category = "Nextbot Zambies",
} )

function ENT:AdditionalRagdollDeathEffects( ragdoll )
    if not IsValid( ragdoll ) then return end

    ragdoll:SetSubMaterial( 0, "!nextbotZambies_GlassMaterial" )
    ragdoll:SetColor( Color( 255, 255, 255, 255 ) )
end

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

        self:SetSubMaterial( 0, "!" .. mat )

    end
    return

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

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetSubMaterial( 0, "!nextbotZambies_GlassMaterial" )
    self:SetRenderMode( RENDERMODE_TRANSALPHA )
    self:SetColor( Color( 200, 220, 255, 180 ) )

    self.GlassArmsApplied = false

end

function ENT:Think()
    if not self.GlassArmsApplied then
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
                self:ManipulateBoneScale( boneID, Vector( 1.5, 1.5, 1.5 ) )
                self.GlassArmsApplied = true

            end
        end
    end

    BaseClass.Think( self )

end

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "physics/glass/glass_largesheet_break" .. math.random( 1, 3 ) .. ".wav", 85, 100 )
    self:EmitSound( "physics/glass/glass_sheet_break" .. math.random( 1, 3 ) .. ".wav", 80, 110 )

    local glassGibs = {
        "models/gibs/glass_shard01.mdl",
        "models/gibs/glass_shard02.mdl",
        "models/gibs/glass_shard03.mdl",
        "models/gibs/glass_shard04.mdl",
        "models/gibs/glass_shard05.mdl",
        "models/gibs/glass_shard06.mdl",
    }

    for _ = 1, 10 do
        local gib = ents.Create( "prop_physics" )
        if IsValid( gib ) then
            gib:SetModel( table.Random( glassGibs ) )
            gib:SetPos( pos + VectorRand() * 20 )
            gib:SetAngles( AngleRand() )
            gib:SetMaterial( "models/props_windows/window_glass" )
            gib:Spawn()
            gib:Activate()

            gib:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

            local phys = gib:GetPhysicsObject()
            if IsValid( phys ) then
                phys:Wake()
                phys:SetVelocity( VectorRand() * math.Rand( 200, 400 ) )
                phys:AddAngleVelocity( VectorRand() * 500 )

            end

            SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 1.5 ) )

        end
    end
end

ENT.MyClassTask = {
    PreventBecomeRagdollOnKilled = function( self, data )
        self:GlassZambDie()
        SafeRemoveEntityDelayed( self, 0 )
        return true, true

    end
}