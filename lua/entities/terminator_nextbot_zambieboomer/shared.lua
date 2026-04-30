AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Boomer"
ENT.Spawnable = true

list.Set( "NPC", "terminator_nextbot_zambieboomer", {
    Name      = "Zombie Boomer",
    Class     = "terminator_nextbot_zambieboomer",
    Category  = "Nextbot Zambies",
} )

local BOOMER_MODEL    = "models/player/zombie_soldier.mdl"
local BOOMER_HEAD     = "models/Zombie/Fast.mdl"
local BOOMER_HEAD_MAT = "models/jcmsblastcrab/body"
local VECTOR_ONE      = Vector( 1, 1, 1 )

if CLIENT then
    language.Add( "terminator_nextbot_zambieboomer", ENT.PrintName )

    local armedBoomers = {}

    net.Receive( "boomer_armed", function()
        local entIdx  = net.ReadUInt( 16 )
        local armTime = net.ReadFloat()
        local armed   = net.ReadBool()

        if armed then
            armedBoomers[ entIdx ] = {
                armTime         = armTime,
                didInflateSound = false,
            }
        else
            armedBoomers[ entIdx ] = nil
        end
    end )

    timer.Create( "boomer_global_fx", 0.05, 0, function()
        for entIdx, data in pairs( armedBoomers ) do
            local ent = Entity( entIdx )
            if not IsValid( ent ) or ent:GetClass() ~= "terminator_nextbot_zambieboomer" then
                armedBoomers[ entIdx ] = nil
                continue
            end

            local frac = math.Clamp( ( CurTime() - ( data.armTime - 2.5 ) ) / 2.5, 0, 1 )

            if not data.didInflateSound then
                data.didInflateSound = true
                ent:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 100, 1 )
            end

            if math.random() < frac then
                local ed  = EffectData()
                local pos = ent:WorldSpaceCenter()
                local ang = math.random() * math.pi * 2
                pos.x = pos.x + math.cos( ang ) * math.Rand( 5, 16 )
                pos.y = pos.y + math.sin( ang ) * math.Rand( 5, 16 )
                pos.z = pos.z + math.Rand( -32, 24 )
                ed:SetOrigin( pos )
                ed:SetColor( math.random( 1, 3 ) )
                util.Effect( "BloodImpact", ed )

                if math.random() < 0.6 then
                    ent:EmitSound(
                        "physics/flesh/flesh_squishy_impact_hard" .. math.random( 1, 4 ) .. ".wav",
                        100, 70 + frac * 60, 1
                    )
                end
            end
        end
    end )

    local function GetOrCreateHead( self )
        if IsValid( self._headModel ) then return self._headModel end

        local mdl = ClientsideModel( BOOMER_HEAD )
        mdl:SetParent( self )
        mdl:AddEffects( EF_BONEMERGE )
        mdl:SetNoDraw( true )
        mdl:SetMaterial( BOOMER_HEAD_MAT )
        mdl:SetBodygroup( 1, 1 )

        for i = 0, mdl:GetBoneCount() - 1 do
            mdl:ManipulateBoneScale( i, vector_origin )
        end
        for i = 40, 51 do
            mdl:ManipulateBoneScale( i, VECTOR_ONE )
        end

        mdl:ManipulateBoneAngles( 40,   Angle( -24, 3.3, 21.8 ) )
        mdl:ManipulateBonePosition( 40, Vector( 0.9, 4.3, -3 ) )

        self._headModel = mdl
        return mdl
    end

    function ENT:OnRemove()
        if IsValid( self._headModel ) then self._headModel:Remove() end
        armedBoomers[ self:EntIndex() ] = nil
    end

    function ENT:Draw()
        local headmdl = GetOrCreateHead( self )
        headmdl:SetParent( self )

        local data = armedBoomers[ self:EntIndex() ]

        if data then
            local frac = math.Clamp( ( CurTime() - ( data.armTime - 2.5 ) ) / 2.5, 0, 1 )
            render.SetColorModulation( 3 + frac * 5, 2 + frac ^ 2 * 4, 1 )
            self:DrawModel()
            headmdl:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        else
            render.SetColorModulation( 3, 2, 1 )
            self:DrawModel()
            headmdl:DrawModel()
            render.SetColorModulation( 1, 1, 1 )
        end
    end

    return
end

util.AddNetworkString( "boomer_armed" )

sound.Add({
    name    = "NPC_ZombieBoomer.Idle",
    channel = CHAN_VOICE,
    volume  = 0.9,
    level   = 75,
    pitch   = 90,
    sound   = {
        "npc/barnacle/barnacle_digesting1.wav",
        "npc/barnacle/barnacle_gulp1.wav",
        "npc/barnacle/barnacle_digesting2.wav",
        "npc/barnacle/barnacle_gulp2.wav",
    },
})

sound.Add({
    name    = "NPC_ZombieBoomer.Angry",
    channel = CHAN_VOICE,
    volume  = 1,
    level   = 90,
    pitch   = 90,
    sound   = {
        "npc/barnacle/barnacle_pull1.wav",
        "npc/barnacle/barnacle_pull2.wav",
        "npc/barnacle/barnacle_pull3.wav",
        "npc/barnacle/barnacle_pull4.wav",
    },
})

local function BroadcastArmed( self, armed )
    net.Start( "boomer_armed" )
        net.WriteUInt( self:EntIndex(), 16 )
        net.WriteFloat( self.boomerArmTime )
        net.WriteBool( armed )
    net.Broadcast()
end

local function ScaleBones( self, sc )
    local vscale = Vector( sc, sc, sc )
    local count  = self:GetBoneCount()
    for i = 0, count - 1 do
        self:ManipulateBoneScale( i, vscale )
    end
end

local function ResetBones( self )
    local count = self:GetBoneCount()
    for i = 0, count - 1 do
        self:ManipulateBoneScale( i, VECTOR_ONE )
    end
end

local function DoBurst( self )
    if self.boomerBursting then return end
    self.boomerBursting = true

    BroadcastArmed( self, false )

    local pos    = self:WorldSpaceCenter()
    local primed = self.boomerPrimed

    local ed = EffectData()
    ed:SetOrigin( pos )
    ed:SetRadius( 350 )
    ed:SetNormal( vector_up )
    ed:SetMagnitude( primed and 1.4 or 0.6 )
    util.Effect( "eff_boomer_explosion", ed, true, true )

    self:EmitSound( "npc/zombie/zombie_die1.wav", 100, 80, 1 )
    self:EmitSound( "physics/flesh/flesh_bloody_break.wav", 100, 70, 1 )

    local dmg = DamageInfo()
    dmg:SetAttacker( game.GetWorld() )
    dmg:SetInflictor( game.GetWorld() )
    dmg:SetReportedPosition( pos )

    for _, ent in ipairs( ents.FindInSphere( pos, 350 ) ) do
        local phys = ent:GetPhysicsObject()
        if not IsValid( phys ) then continue end

        local epos    = ent:WorldSpaceCenter()
        local diff    = epos - pos
        local dist    = diff:Length()
        if dist == 0 then continue end
        diff:Normalize()

        local falloff = math.Clamp( 1 - dist / 350, 0, 1 )
        dmg:SetDamage( falloff * ( primed and 150 or 1 ) )
        dmg:SetDamagePosition( epos )
        dmg:SetDamageType( DMG_CRUSH )

        local impulse = diff * ( falloff * 1400 )
        local mt      = ent:GetMoveType()
        if mt == MOVETYPE_VPHYSICS then
            phys:ApplyForceOffset( impulse * phys:GetMass(), pos )
        elseif mt == MOVETYPE_WALK then
            ent:SetVelocity( impulse * 0.6 )
        elseif mt ~= MOVETYPE_PUSH then
            ent:SetVelocity( ent:GetVelocity() + impulse )
        end
        ent:TakeDamageInfo( dmg )
    end

    if not self.boomerObliterated then
        for i = 1, 7 do
            local crab = ents.Create( "terminator_nextbot_zambieblastcrab" )
            if not IsValid( crab ) then continue end
            crab:SetPos( pos + VectorRand( -25, 25 ) )
            crab:Spawn()
            crab:Activate()
            local a = math.random() * math.pi * 2
            crab:SetVelocity( Vector(
                math.cos( a ) * math.random() * 320,
                math.sin( a ) * math.random() * 320,
                math.Rand( -150, 420 )
            ) )
        end
    end

    timer.Simple( 0, function()
        if IsValid( self ) then self:Remove() end
    end )
end

ENT.IsFodder    = false
ENT.IsStupid    = true
ENT.CanSpeak    = true

ENT.SpawnHealth               = 37
ENT.ExtraSpawnHealthPerPlayer = 0

ENT.WalkSpeed          = 40
ENT.MoveSpeed          = 115
ENT.RunSpeed           = 350
ENT.AccelerationSpeed  = 350
ENT.DeccelerationSpeed = 900

ENT.CanUseStuff = nil

ENT.FistDamageMul      = 0
ENT.DuelEnemyDist      = 200
ENT.CloseEnemyDistance = 200

ENT.ARNOLD_MODEL    = BOOMER_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.02, 1.08 ) end
ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 65 ) }
ENT.MyPhysicsMass   = 150

ENT.TERM_FISTS = "weapon_term_zombieclaws"
ENT.Models     = { BOOMER_MODEL }

ENT.Term_FootstepSoundWalking = {
    { path = "Zombie.ScuffLeft",  lvl = 76, pitch = 90 },
    { path = "Zombie.ScuffRight", lvl = 76, pitch = 90 },
}
ENT.Term_FootstepSound = {
    { path = "npc/zombie/foot1.wav", lvl = 77, pitch = 80 },
    { path = "npc/zombie/foot2.wav", lvl = 77, pitch = 80 },
}
ENT.Term_FootstepShake = {
    amplitude = 0.5,
    frequency = 10,
    duration  = 0.1,
    radius    = 300,
}

ENT.MySpecialActions = {}

ENT.MyClassTask = {

    OnCreated = function( self, data )
        self.boomerBursting    = false
        self.boomerPrimed      = false
        self.boomerObliterated = false
        self.boomerArmed       = false
        self.boomerArmTime     = 0
        data.nextIdleSound = CurTime() + math.Rand( 3, 6 )
    end,

    BehaveUpdatePriority = function( self, data )
        if self.boomerBursting then return end

        local t = CurTime()

        if self.boomerArmed then
            local frac   = math.Clamp( ( t - ( self.boomerArmTime - 2.5 ) ) / 2.5, 0, 1 )
            local curved = frac ^ 6
            local sc     = 1 + curved * 0.9
            ScaleBones( self, sc )

            local spineBone = self.boomerSpineBone
            if spineBone and spineBone >= 0 then
                local jitter = frac * 25
                self:ManipulateBoneAngles( spineBone, Angle(
                    math.Rand( -jitter, jitter ),
                    math.Rand( -jitter, jitter ),
                    math.Rand( -jitter, jitter )
                ) )
            end

            if t >= self.boomerArmTime then
                DoBurst( self )
            end
            return
        end

        ResetBones( self )

        local enemy = self:GetEnemy()
        if IsValid( enemy ) and self.IsSeeEnemy and self.DistToEnemy and self.DistToEnemy <= 200 then
            self.boomerArmed   = true
            self.boomerArmTime = t + 2.5
            BroadcastArmed( self, true )
            self:EmitSound( "NPC_ZombieBoomer.Angry" )
        end

        if t >= ( data.nextIdleSound or 0 ) then
            data.nextIdleSound = t + math.Rand( 4, 7 )
            self:EmitSound( IsValid( enemy ) and "NPC_ZombieBoomer.Angry" or "NPC_ZombieBoomer.Idle" )
        end
    end,

    OnDamaged = function( self, data, dmg )
        if self.boomerBursting then return end

        local dtype  = dmg:GetDamageType()
        local amount = dmg:GetDamage()

        local isObliterating = bit.band( dtype, bit.bor( DMG_BLAST, DMG_RADIATION, DMG_DISSOLVE ) ) > 0
        if amount >= ( isObliterating and 75 or 300 ) then
            self.boomerObliterated = true
        end

        if bit.band( dtype, bit.bor( DMG_BLAST, DMG_SONIC, DMG_CLUB ) ) > 0 then
            self.boomerPrimed = true
        end

        if self.boomerArmed then
            self.boomerArmTime = self.boomerArmTime - amount / 60
        end
    end,

    OnKilled = function( self, data, attacker, inflictor, ragdoll )
        DoBurst( self )
    end,

}

function ENT:AdditionalInitialize()
    BaseClass.AdditionalInitialize( self )

    self:SetModel( BOOMER_MODEL )

    local spine = self:LookupBone( "ValveBiped.Bip01_Spine1" )
    if not spine or spine < 0 then
        spine = self:LookupBone( "ValveBiped.Bip01_Spine" )
    end
    self.boomerSpineBone = spine

    self.boomerBursting    = false
    self.boomerPrimed      = false
    self.boomerObliterated = false
    self.boomerArmed       = false
    self.boomerArmTime     = 0

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains                = false

    self.term_SoundPitchShift = -10
    self.term_SoundLevelShift = 5

    self.term_LoseEnemySound  = "Zombie.Idle"
    self.term_FindEnemySound  = "Zombie.Alert"
    self.term_AttackSound     = { "NPC_ZombieBoomer.Angry" }
    self.term_AngerSound      = "Zombie.Idle"
    self.term_DamagedSound    = "Zombie.Pain"
    self.term_DieSound        = "Zombie.Die"
    self.term_JumpSound       = "npc/zombie/foot1.wav"

    self.IdleLoopingSounds = {
        "npc/zombie/zombie_voice_idle1.wav",
        "npc/zombie/zombie_voice_idle2.wav",
        "npc/zombie/zombie_voice_idle3.wav",
        "npc/zombie/zombie_voice_idle4.wav",
        "npc/zombie_poison/pz_breathe_loop1.wav",
        "npc/zombie/moan_loop2.wav",
    }
    self.AngryLoopingSounds = {
        "npc/zombie/moan_loop1.wav",
        "npc/zombie/moan_loop3.wav",
    }
    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight       = 0.03
    self.DeathDropHeight           = 1500
end