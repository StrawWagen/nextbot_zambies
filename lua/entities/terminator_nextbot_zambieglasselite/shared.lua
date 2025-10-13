AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambieglass"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Glass Elite"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieglasselite", {
    Name = "Zombie Glass Elite",
    Class = "terminator_nextbot_zambieglasselite",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieglasselite", ENT.PrintName )

    function ENT:Draw()
        render.SetColorModulation( 0.5, 0.7, 1.0 )
        self:DrawModel()
    end
    return
end

ENT.TERM_MODELSCALE = 1.25

ENT.SpawnHealth = 60
ENT.JumpHeight = 600
ENT.AimSpeed = 900
ENT.WalkSpeed = 220
ENT.MoveSpeed = 650
ENT.RunSpeed = 850
ENT.AccelerationSpeed = 1000

ENT.FistDamageMul = 1.5
ENT.zamb_MeleeAttackSpeed = 1.6

ENT.HeightToStartTakingDamage = 300
ENT.FallDamagePerHeight = 0.5
ENT.DeathDropHeight = 800

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModelScale( self.TERM_MODELSCALE, 0 )
    self:SetColor( Color( 150, 200, 255, 180 ) )

    self.GlassArmsAppliedElite = false

end

function ENT:Think()
    if not self.GlassArmsAppliedElite then
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
                self:ManipulateBoneScale( boneID, Vector( 2.25, 2.25, 2.25 ) )

            end
        end

        self.GlassArmsAppliedElite = true
    end

    BaseClass.Think( self )

end

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound( "physics/glass/glass_largesheet_break" .. math.random( 1, 3 ) .. ".wav", 95, 90 )
    self:EmitSound( "physics/glass/glass_sheet_break" .. math.random( 1, 3 ) .. ".wav", 90, 100 )

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 2 )
    util.Effect( "GlassImpact", effectdata )

    local glassGibs = {
        "models/gibs/glass_shard01.mdl",
        "models/gibs/glass_shard02.mdl",
        "models/gibs/glass_shard03.mdl",
        "models/gibs/glass_shard04.mdl",
        "models/gibs/glass_shard05.mdl",
        "models/gibs/glass_shard06.mdl",
    }

    for _ = 1, 25 do
        local gib = ents.Create( "prop_physics" )
        if IsValid( gib ) then
            pos = pos + VectorRand() * 15
            pos.z = pos.z + math.random( -5, 5 )
            gib:SetModel( table.Random( glassGibs ) )
            gib:SetPos( pos )
            gib:SetAngles( AngleRand() )
            gib:SetMaterial( "models/props_windows/window_glass" )
            gib:Spawn()
            gib:Activate()

            local phys = gib:GetPhysicsObject()
            if IsValid( phys ) then
                local velDir = VectorRand() + self:GetAimVector() * 0.5 -- bias forward
                phys:Wake()
                phys:SetVelocity( velDir * math.Rand( 800, 1200 ) )
                phys:AddAngleVelocity( VectorRand() * 1000 )

            end

            util.SpriteTrail( gib, 0, Color( 150, 200, 255, 220 ), false, 10, 0, 0.4, 0.08, "trails/laser.vmt" )

            gib.IsGlassShrapnel = true
            gib.ShrapnelDamage = 15
            gib.ShrapnelOwner = self
            gib.DamagedEntities = {}

            gib:AddCallback( "PhysicsCollide", function( ent, data )
                if not IsValid( ent ) or not ent.IsGlassShrapnel then return end
                if data.PhysObject:GetVelocity():LengthSqr() < 10^2 then -- cleanup early if not moving
                    SafeRemoveEntity( self )
                    return

                end

                local hitEntity = data.HitEntity
                if IsValid( hitEntity ) and ( hitEntity:IsPlayer() or hitEntity:IsNPC() ) and not ent.DamagedEntities[ hitEntity ] then
                    -- Don't damage glass zambies
                    local hitClass = hitEntity:GetClass()
                    if hitClass ~= "terminator_nextbot_zambieglass" and hitClass ~= "terminator_nextbot_zambieglasselite" then
                        local dmgInfo = DamageInfo()
                        dmgInfo:SetDamage( ent.ShrapnelDamage )
                        dmgInfo:SetDamageType( DMG_SLASH )
                        dmgInfo:SetAttacker( IsValid( ent.ShrapnelOwner ) and ent.ShrapnelOwner or ent )
                        dmgInfo:SetInflictor( ent )
                        dmgInfo:SetDamageForce( data.OurOldVelocity:GetNormalized() * 500 )

                        hitEntity:TakeDamageInfo( dmgInfo )
                        ent.DamagedEntities[ hitEntity ] = true

                    end
                end

                if data.Speed > 100 then
                    ent:EmitSound( "physics/glass/glass_impact_bullet" .. math.random( 1, 4 ) .. ".wav", 70, math.random( 90, 110 ) )

                    local impact = EffectData()
                    impact:SetOrigin( data.HitPos )
                    impact:SetNormal( data.HitNormal )
                    impact:SetScale( 0.5 )
                    util.Effect( "GlassImpact", impact )

                end
            end )

            SafeRemoveEntityDelayed( gib, math.Rand( 0.5, 3 ) )

        end
    end
end