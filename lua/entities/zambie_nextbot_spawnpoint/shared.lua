AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category    = "Other"
ENT.PrintName   = "AI \"Directed\" Zambie Spawnpoint"
ENT.Author      = "StrawWagen"
ENT.Purpose     = "Spawns zombies when nobody's near to it, or looking at it!"
ENT.Information = ENT.Purpose
ENT.Spawnable    = true
ENT.AdminOnly    = true
ENT.Model = "models/props_junk/sawblade001a.mdl"

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", 0, "On" )

    if not SERVER then return end
    self:SetOn( true )

end

if CLIENT then
    -- copied from campaign entities...
    local cachedIsEditing = nil
    local nextCache = 0
    local CurTime = CurTime
    local LocalPlayer = LocalPlayer

    local function zambs_CanBeUgly()
        local ply = LocalPlayer()
        --if IsValid( ply:GetActiveWeapon() ) and string.find( LocalPlayer():GetActiveWeapon():GetClass(), "camera" ) then return false end
        return true

    end

    local function zambs_IsEditing()
        if nextCache > CurTime() then return cachedIsEditing end
        nextCache = CurTime() + 0.01

        local ply = LocalPlayer()
        local moveType = ply:GetMoveType()
        if moveType ~= MOVETYPE_NOCLIP then     cachedIsEditing = nil return end
        if ply:InVehicle() then                 cachedIsEditing = nil return end
        if not zambs_CanBeUgly() then        cachedIsEditing = nil return end

        cachedIsEditing = true
        return true

    end

    function ENT:Draw()
        if zambs_IsEditing() then
            self:DrawModel()

        end
    end

    return

end

function ENT:Initialize()
    self:SetModel( self.Model )
    self:SetNoDraw( false )
    self:DrawShadow( false )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    self:NextThink( CurTime() + 5 )

    local configData = {
        spawnsOnlyIfHidden = true,

    }

    terminator_Extras.zamb_RegisterSpawner( self, configData )

end

function ENT:Zamb_OnZambSpawned( spawnedZamb )
    self:DeleteOnRemove( spawnedZamb )
    local creator = self:GetCreator()
    if IsValid( creator ) and creator:IsPlayer() then
        cleanup.Add( creator, "NPC", spawnedZamb )

    end
end

function ENT:ACF_PreDamage()
    -- can't be broken by ACF
    return false

end
