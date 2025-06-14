AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Fallen Supercop"
ENT.Author = "Broadcloth0 + StrawWagen"
ENT.PhysgunDisabled = true
function ENT:CanProperty()
    return false
end

function ENT:CanTool()
    return false
end

ENT.Spawnable = false
ENT.AdminOnly = true
list.Set( "NPC", "terminator_nextbot_zambiecop", {
    Name = "Fallen Supercop",
    Class = "terminator_nextbot_zambiecop",
    Category = "Nextbot Zambies",
    AdminOnly = true
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambiecop", ENT.PrintName )

    function ENT:Draw()
        self:DrawModel()
    end

    return
end

ENT.IsFodder = nil
ENT.CoroutineThresh = 0.0005

ENT.JumpHeight = 80
ENT.DefaultStepHeight = 18
ENT.StandingStepHeight = ENT.DefaultStepHeight * 1 -- used in crouch toggle in motionoverrides
ENT.CrouchingStepHeight = ENT.DefaultStepHeight * 0.9
ENT.StepHeight = ENT.StandingStepHeight
ENT.SpawnHealth = 150000
ENT.ExtraSpawnHealthPerPlayer = 1000
ENT.HealthRegen = 25
ENT.HealthRegenInterval = 5
ENT.AimSpeed = 600
ENT.WalkSpeed = 75
ENT.MoveSpeed = 150
ENT.RunSpeed = 300
ENT.AccelerationSpeed = 2000
ENT.neverManiac = true

ENT.zamb_LookAheadWhenRunning = nil
ENT.zamb_MeleeAttackSpeed = 1
ENT.zamb_MeleeAttackHitFrameMul = 1.25
ENT.zamb_AttackAnim = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL -- ACT_RANGE_ATTACK1
ENT.FistDamageMul = 5000 --dont set this to math.huge, worst mistake of my life.
ENT.FistForceMul = 51
ENT.FistRangeMul = 2
ENT.FistDamageType = bit.bor( DMG_SLASH, DMG_CLUB, DMG_GENERIC )
ENT.DuelEnemyDist = 500

ENT.DoMetallicDamage = false
ENT.MetallicMoveSounds = true
ENT.ReallyHeavy = true

local COP_ZAMBIE_MODEL = "models/player/classic_zombie_player_new.mdl" --https://steamcommunity.com/sharedfiles/filedetails/?id=669645732
ENT.ARNOLD_MODEL = COP_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.15
ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 60 ) } -- this is then scaled by modelscale
ENT.MyPhysicsMass = 10000

ENT.TERM_FISTS = "weapon_term_zombieclaws"


ENT.Models = { COP_ZAMBIE_MODEL }
ENT.term_AnimsWithIdealSpeed = false

local IdleActivity = ACT_HL2MP_IDLE_ZOMBIE
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = randomWalk,
    [ACT_MP_RUN]                        = IdleActivity + 2,
    [ACT_MP_CROUCH_IDLE]                = ACT_HL2MP_IDLE_CROUCH,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_HL2MP_SWIM,
    [ACT_LAND]                          = ACT_LAND,
}

-- dont care about body smell
function ENT:AdditionalAvoidAreas()
end

function ENT:PostHitObject( hit )
    local enemy = self:GetEnemy()
    if IsValid( hit ) and IsValid( enemy ) then
        local hitsObj = hit:GetPhysicsObject()
        if not IsValid( hitsObj ) then return end

        local force = terminator_Extras.dirToPos( self:GetShootPos(), enemy:WorldSpaceCenter() )
        force = force * 500
        force = force * hitsObj:GetMass()
        hitsObj:ApplyForceOffset( force, self:GetShootPos() )
    end
end

function ENT:AdditionalInitialize()
    self:SetModel( COP_ZAMBIE_MODEL )
    self:SetBodygroup(0, 1)

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -15
    self.term_SoundLevelShift = 18

    self.term_LoseEnemySound = {
        "nextbot_zambies/zombine/zombine_alert1.wav",
        "nextbot_zambies/zombine/zombine_alert2.wav",
        "nextbot_zambies/zombine/zombine_alert3.wav",
        "nextbot_zambies/zombine/zombine_alert4.wav",
        "nextbot_zambies/zombine/zombine_alert5.wav",
        "nextbot_zambies/zombine/zombine_alert6.wav",
        "nextbot_zambies/zombine/zombine_alert7.wav",
    }
    self.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
    self.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
    self.term_FindEnemySound = {
        "nextbot_zambies/zombine/zombine_alert1.wav",
        "nextbot_zambies/zombine/zombine_alert2.wav",
        "nextbot_zambies/zombine/zombine_alert3.wav",
        "nextbot_zambies/zombine/zombine_alert4.wav",
        "nextbot_zambies/zombine/zombine_alert5.wav",
        "nextbot_zambies/zombine/zombine_alert6.wav",
        "nextbot_zambies/zombine/zombine_alert7.wav",
    }
    self.term_AttackSound = {
        "nextbot_zambies/zombine/zombine_charge1.wav",
        "nextbot_zambies/zombine/zombine_charge2.wav",
    }
    self.term_AngerSound = self.term_FindEnemySound
    self.term_DamagedSound = {
        "nextbot_zambies/zombine/zombine_pain1.wav",
        "nextbot_zambies/zombine/zombine_pain2.wav",
        "nextbot_zambies/zombine/zombine_pain3.wav",
        "nextbot_zambies/zombine/zombine_pain4.wav",
    }
    self.term_DieSound = "npc/overwatch/radiovoice/die2.wav"
    self.term_JumpSound = "nextbot_zambies/zombine/gear3.wav"
    self.IdleLoopingSounds = {
        "nextbot_zambies/supercop/datatransmission01_loop.wav",
        "npc/overwatch/radiovoice/infection.wav",
        "npc/overwatch/radiovoice/infestedzone.wav",
    }
    self.AngryLoopingSounds = {
        "npc/overwatch/radiovoice/infection.wav",
        "npc/overwatch/radiovoice/infestedzone.wav",
        "npc/overwatch/radiovoice/cauterize.wav",
        "npc/overwatch/radiovoice/attention.wav",
        "npc/overwatch/radiovoice/amputate.wav",
        "npc/overwatch/radiovoice/sterilize.wav",
        "npc/overwatch/radiovoice/officerclosingonsuspect.wav",
        "npc/overwatch/radiovoice/lostbiosignalforunit.wav",
    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 900
    self.FallDamagePerHeight = 0.15
    self.TakesFallDamage = false
    self.DeathDropHeight = 1500

    self:SetSkin(6)

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl = 89
    local snd = foot and "nextbot_zambies/zombine/gear1.wav" or "nextbot_zambies/zombine/gear2.wav"
    if self:GetVelocity():LengthSqr() <= self.WalkSpeed^2 then
        lvl = 76
    end
    self:EmitSound( snd, lvl, 90, volume + 1, CHAN_BODY, sndFlags )
    return true
end

local rics = {
    "weapons/fx/rics/ric3.wav",
    "weapons/fx/rics/ric5.wav",

}

local function doRicsEnt( shotEnt )
    shotEnt:EmitSound( table.Random( rics ), 75, math.random( 92, 100 ), 1, CHAN_AUTO )

end

local weakGroups = {
    [6] = true,
    [2] = true,

}

function ENT:PostTookBulletDamage( dmg, group )
    local pos = dmg:GetDamagePosition()
    if not weakGroups[group] then
        doRicsEnt( self )
        timer.Simple( 0, function()
            local effect = EffectData()
            effect:SetOrigin( pos )
            effect:SetMagnitude( 2 * 0.5 )
            effect:SetScale( 1 )
            effect:SetRadius( 6 * 0.5 )
            util.Effect( "Sparks", effect )

        end )
        return true

    end

    -- hit weak point!
    local normal = VectorRand()
    normal.z = math.abs( normal.z )

    timer.Simple( 0, function()
        local Data = EffectData()
        Data:SetOrigin( pos )
        Data:SetColor( 0 )
        Data:SetScale( math.random( 4, 8 ) )
        Data:SetFlags( 3 )
        Data:SetNormal( normal )
        util.Effect( "bloodspray", Data )

    end )
    self:EmitSound( "npc/antlion_grub/squashed.wav", 72, math.random( 150, 200 ), 1, CHAN_STATIC ) -- play in static so it doesnt get overriden

end

function ENT:IsImmuneToDmg( dmg )
    if dmg:IsBulletDamage() then return end -- handled above
    dmg:ScaleDamage( 0.15 )

end

local ignorePlayers = GetConVar( "ai_ignoreplayers" )
local cheats = GetConVar( "sv_cheats" )
local aiDisabled = GetConVar( "ai_disabled" )
local developer = GetConVar( "developer" )
local supercopIgnorePlayers = CreateConVar( "fallen_supercop_nextbot_ignoreplayers", 0, bit.bor( FCVAR_NONE ), "Ignore players?" )

function ENT:IgnoringPlayers()
    if supercopIgnorePlayers:GetBool() then return true end
    if cheats:GetBool() and developer:GetBool() and ignorePlayers:GetBool() then return true end

end
function ENT:DisabledThinking()
    if cheats:GetBool() and developer:GetBool() and aiDisabled:GetBool() then return true end

end

local dotVec = Vector( 0,0,1 )

-- hacky as hell but makes sure the sounds are always in sync
function ENT:AdditionalThink( myTbl )
    if not myTbl.loco:IsOnGround() then return end

    local leftFoot = self:LookupBone( "ValveBiped.Bip01_L_Foot" )
    local leftFootPos, leftFootAng = self:GetBonePosition( leftFoot )

    local rightFoot = self:LookupBone( "ValveBiped.Bip01_R_Foot" )
    local rightFootPos, rightFootAng = self:GetBonePosition( rightFoot )

    local currStepping = { left = false, right = false }
    local oldStepping = myTbl.custom_OldStepping or currStepping
    local feet = { left = { pos = leftFootPos, ang = leftFootAng }, right = { pos = rightFootPos, ang = rightFootAng } }

    for curr, foot in pairs( feet ) do
        local dot = foot.ang:Forward():Dot( dotVec )
        currStepping[curr] = dot < -0.85

        if currStepping[curr] and not oldStepping[curr] then
            myTbl.NeedsAStep = true

        end
    end

    myTbl.custom_OldStepping = currStepping

end

-- yuck!
function ENT:GetFootstepSoundTime()
    if self.NeedsAStep then
        self.NeedsAStep = nil
        return 0

    end
    return math.huge

end