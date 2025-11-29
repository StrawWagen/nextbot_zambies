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
// TODO: Add spawnicons
list.Set( "NPC", "terminator_nextbot_zambieglasselite_mega", {
    Name = "Zombie Glass Elite Mega",
    Class = "terminator_nextbot_zambieglasselite",
    Category = "Nextbot Zambies",
	KeyValues = { iShards = 50 }
} )
// This much particles causes the frame to freeze,
// and I doubt that even setting it to admin only will help!
//	// This one is purely for comedic effect,
//	// and has no intention of being, as
//	// id Software says, "even remotely fair"
//	list.Set( "NPC", "terminator_nextbot_zambieglasselite_giga", {
//	    Name = "Zombie Glass Elite Giga",
//	    Class = "terminator_nextbot_zambieglasselite",
//	    Category = "Nextbot Zambies",
//		KeyValues = { iShards = 100 }
//	} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieglasselite", ENT.PrintName )

	local render_SetColorModulation = render.SetColorModulation
    function ENT:Draw()
        render_SetColorModulation( .5, .7, 1.0 )
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

ENT.iShards = 25

local sound_Add = sound.Add
sound_Add {
	name = "nextbotZambies_GlassBreakEliteA",
	level = 95,
	pitch = 90,
	sound = {
		"physics/glass/glass_largesheet_break1.wav",
		"physics/glass/glass_largesheet_break2.wav",
		"physics/glass/glass_largesheet_break3.wav"
	}
}
sound_Add {
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
local SHARD_MODELS_LENGTH = 6

local string_lower = string.lower
local tonumber = tonumber

function ENT:KeyValue( sKey, sValue )
	if string.lower( sKey ) == "ishards" then
		local f = tonumber( sValue )
		if f then self.iShards = f end
		return
	end
	return BaseClass.KeyValue( self, sKey, sValue )
end

local EffectData = EffectData
local util_Effect = util.Effect
local ents_Create = ents.Create
local math = math
local math_random = math.random
local VectorRand = VectorRand
local AngleRand = AngleRand
local math_Rand = math.Rand
local util_SpriteTrail = util.SpriteTrail
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed

function ENT:GlassZambDie()
    local pos = self:WorldSpaceCenter()

    self:EmitSound "nextbotZambies_GlassBreakA"
    self:EmitSound "nextbotZambies_GlassBreakB"

    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetScale( 2 )
    util_Effect( "GlassImpact", effectdata )

	local iShards = self.iShards
	if iShards <= 0 then return end
	local flAngularVelocity = iShards * 40
	local flVelocityMin, flVelocityMax = iShards * 32, iShards * 48
    for _ = 1, iShards do
        local gib = ents_Create "prop_physics"
        if IsValid( gib ) then
            pos = pos + VectorRand() * 15
            pos.z = pos.z + math_random( -5, 5 )
            gib:SetModel( SHARD_MODELS[ math_random( 1, SHARD_MODELS_LENGTH ) ] )
            gib:SetPos( pos )
            gib:SetAngles( AngleRand() )
            gib:SetMaterial( "models/props_windows/window_glass" )
            gib:Spawn()
            gib:Activate()

            local phys = gib:GetPhysicsObject()
            if IsValid( phys ) then
                local velDir = VectorRand() + self:GetAimVector() * 0.5 -- bias forward
                phys:Wake()
                phys:SetVelocity( velDir * math_Rand( flVelocityMin, flVelocityMax ) )
                phys:AddAngleVelocity( VectorRand() * flAngularVelocity )

            end

            util_SpriteTrail( gib, 0, Color( 150, 200, 255, 220 ), false, 10, 0, 0.4, 0.08, "trails/laser.vmt" )

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