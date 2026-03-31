
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambietank"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName   = "Zombie Reanimator"
ENT.Spawnable   = false
ENT.Author      = "Bluekrakan"

list.Set( "NPC", "terminator_nextbot_zambiereanimator", {
    Name = "Zombie Reanimator",
    Class = "terminator_nextbot_zambiereanimator",
    Category = "Nextbot Zambies"
} )

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Call upon the fallen.",
        desc = "Revive zambies that have died near you within your lifetime.",
        ratelimit = 6,
        svAction = function( _drive, _driver, bot )
            bot:REANIM_TrySpawnPuppets( true )

        end,
    }
}

ENT.JumpHeight = 500
ENT.SpawnHealth = 1250
ENT.Term_Leaps = true
ENT.ExtraSpawnHealthPerPlayer = 75
ENT.HealthRegen = 3
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 500
ENT.WalkSpeed = 150
ENT.MoveSpeed = 500
ENT.RunSpeed = 700
ENT.AccelerationSpeed = 600

ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 1.5
ENT.FistForceMul = 1
ENT.FistRangeMul = 2
ENT.PrefersVehicleEnemies = false

local REANIM_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = REANIM_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.5
ENT.CollisionBounds = { Vector( -12, -12, 0 ), Vector( 12, 12, 40 ) }
ENT.MyPhysicsMass = 500

ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = ACT_IDLE_ANGRY,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_RUN,
    [ACT_MP_CROUCHWALK]                 = ACT_RUN,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = ACT_MELEE_ATTACK1,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = ACT_MELEE_ATTACK1,
    [ACT_MP_RELOAD_STAND]               = ACT_INVALID,
    [ACT_MP_RELOAD_CROUCH]              = ACT_INVALID,
    [ACT_MP_JUMP]                       = ACT_JUMP,
    [ACT_MP_SWIM]                       = ACT_RUN,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = ACT_IDLE_ANGRY
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

ENT.Term_BaseMsBetweenSteps = 300
ENT.Term_FootstepMsReductionPerUnitSpeed = 0.5

local REANIM_VECTOR_ONE = Vector( 1, 1, 1 )

if SERVER then
    util.AddNetworkString( "REANIM_SpawnPulseOnClients" )

elseif CLIENT then
    language.Add( "terminator_nextbot_zambiereanimator", ENT.PrintName )
    --[[--------------------------------------------------------------
    This is here so that the effect is created regardless if there is
    a ton of effects on the server, that way there is still an indicator
    to where the reanimator is if there is a lot of effects Otherwise
    you'd be playing where's waldo with it
    --------------------------------------------------------------]]--
    net.Receive( "REANIM_SpawnPulseOnClients", function()
        local position = net.ReadVector()
        local magnitude = net.ReadFloat()
        local scale = net.ReadFloat()
        local color = net.ReadUInt( 8 )

        local effectData = EffectData()

        effectData:SetOrigin( position )
        effectData:SetMagnitude( magnitude )
        effectData:SetScale( scale )
        effectData:SetColor( color )

        util.Effect( "terminator_reanimatorpulse", effectData )

    end )

    local vulnerableHintMat = Material( "effects/redflare" )

    function ENT:Draw()
        self:DrawModel()

        if not self:Getreanim_IsVulnerable() then return end

        local backBone = self:LookupBone( "ValveBiped.Bip01_Spine2" )
        local backBonePos, backBoneAng = self:GetBonePosition( backBone )
        local boneFacingDir = backBoneAng:Forward()

        local entityFlatForward = Angle( 0, self:GetAngles()["y"], 0 ):Forward()
        local backBoneOffset = boneFacingDir - entityFlatForward * 6
        local offsettedSpritePos = backBonePos + backBoneOffset

        if not self.reanim_LastLOSData then
            self.reanim_LastLOSData = {
                visible = false,
                time = 0,
            }
        end

        local LOS_CheckData = self.reanim_LastLOSData

        if LOS_CheckData.time < CurTime() then
            local LOS_check = util.TraceLine( {
                start = LocalPlayer():EyePos(),
                endpos = offsettedSpritePos,
                filter = LocalPlayer(),
                mask = MASK_VISIBLE_AND_NPCS
            } )

            LOS_CheckData.visible = not LOS_check.Hit or LOS_check.HitPos:Distance( offsettedSpritePos ) < 16
            LOS_CheckData.time = CurTime() + 0.1

        end

        if not LOS_CheckData.visible then return end

        render.SetMaterial( vulnerableHintMat )
        render.DrawSprite( offsettedSpritePos, 256, 256 )

    end
end

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", "reanim_IsVulnerable" )
    self:Setreanim_IsVulnerable( false )

end

function ENT:canDoRun()
    if self:Health() < self:GetMaxHealth() * ( self.zamb_LoseCoolRatio / 2 ) then
        return BaseClass.canDoRun( self )

    else
        return false

    end
end

function ENT:AdditionalInitialize()
    self:SetModel( REANIM_ZAMBIE_MODEL )

    self.reanim_TryReviveInterval = 8

    self.reanim_PulseRadius = 2000 -- How far it can revive things
    self.reanim_PulseSpeed = 60 -- How fast the pulse grows
    self.reanim_PulseColor = 196 -- The red toning of the pulse

    self.reanim_ReviveDebuff = -25 -- This is how much percent less should revived zambies have their stats decrease by.

    self.reanim_PuppetFormationSounds = { -- The sounds that puppets will make when they are forming
        "npc/barnacle/barnacle_die1.wav",
        "npc/barnacle/barnacle_die2.wav"
    }
    self.reanim_PuppetFormationTimer = { -- Some timer info for puppets having their bones configured over time
        duration = 2, -- How long it takes for puppets to be fully formed
        cycles = 10, -- You can think of this as the "resolution" of the forming
    }

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -30
    self.term_SoundLevelShift = 15

    self.term_CallingSound = "npc/strider/striderx_die1.wav"
    self.term_CallingSmallSound = "npc/stalker/go_alert2a.wav"
    self.term_FindEnemySound = { "npc/headcrab_poison/ph_scream1.wav", "npc/headcrab_poison/ph_scream2.wav", "npc/headcrab_poison/ph_scream3.wav" }
    self.term_AttackSound = { "npc/fast_zombie/fz_scream1.wav" }
    self.term_AngerSound = "NPC_FastZombie.Alert"
    self.term_DamagedSound = { "npc/headcrab_poison/ph_pain1.wav", "npc/headcrab_poison/ph_pain2.wav", "npc/headcrab_poison/ph_pain3.wav" }
    self.term_DieSound = "npc/zombie_poison/pz_die1.wav"
    self.term_JumpSound = "npc/zombie_poison/pz_left_foot1.wav"
    self.IdleLoopingSounds = {
        "npc/headcrab_poison/ph_talk1.wav",
        "npc/headcrab_poison/ph_talk2.wav",
        "npc/headcrab_poison/ph_talk3.wav"
    }
    self.AngryLoopingSounds = {
        "npc/headcrab_poison/ph_warning1.wav",
        "npc/headcrab_poison/ph_warning2.wav",
        "npc/headcrab_poison/ph_warning3.wav"
    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 600
    self.FallDamagePerHeight = 0.05
    self.DeathDropHeight = 2000
    self.CanUseLadders = false

    self.zamb_NextPuppetCheck = CurTime() + self.reanim_TryReviveInterval
    self.ZAMBIE_PUPPETS = {}
    self.DONT_REVIVE = {} -- List of zambies to not revive if they show up

    self.reanim_BadParents = { -- A blacklist of things basically, also the reason reanimators aren't here is because they're already handeled
        "terminator_nextbot_zambienecro",
        "terminator_nextbot_zambienecroelite",
        "terminator_nextbot_zambiebigheadcrab",
        "terminator_nextbot_zambiebiggerheadcrab",
    }

    self:SetBodygroup( 1, 1 )
    self:SetSubMaterial( 0, "models/charple/charple3_sheet" )
    self.zamb_LoseCoolRatio = 2 / 3 -- behavior changes at 2/3 health, loses cool and can run at 1/3 health

    hook.Add( "zamb_OnBecomeTorso", self, function( me, died, newTorso )
        local diedOwner = died:GetOwner()
        died.BecameTorso = true

        if not me.ZAMBIE_PUPPETS[died.ID] then return end

        newTorso:SetOwner( diedOwner )
        newTorso:SetNWBool( "IsZambReanim_Puppet", died:GetNWBool( "IsZambReanim_Puppet" ) )
        newTorso.ID = died.sharedID

        me.ZAMBIE_PUPPETS[died.ID] = newTorso

    end )

    hook.Add( "OnNPCKilled", self, function( me, npc )
        if not npc.IsTerminatorZambie then return end

        local hasMinions = npc.ZAMBIE_MINIONS
        local dontReviveThese = nil

        if hasMinions then
            dontReviveThese = hasMinions

        end

        me:REANIM_AddZambieDied( npc, dontReviveThese )

    end )
end

function ENT:REANIM_AddZambieDied( zamb, dontReviveList )
    local isTorso = string.match( zamb:GetClass(), "torso" ) == "torso"
    local class = zamb:GetClass()
    local isMinion -- This is if we were owned by a necromancer, or a crab of the god variety

    -- BEHOLD! THE POWER OF LIKE 8 DIFFERENT 'IF' STATEMENTS!
    if IsValid( zamb:GetOwner() ) then
        isMinion = table.HasValue( self.reanim_BadParents, zamb:GetOwner():GetClass() )

    else
        isMinion = table.HasValue( self.DONT_REVIVE, zamb )

    end

    if isMinion then
        table.RemoveByValue( self.DONT_REVIVE, zamb )
        return

    end

    if zamb.BecameTorso then -- If our class is not a torso but when we died we became one
        return

    elseif isTorso then
        class = string.gsub( class, "torso", "" )

    end

    if zamb:GetOwner() ~= self and zamb:GetNWBool( "IsZambReanim_Puppet" ) then
        return

    end

    if dontReviveList then
        self.DONT_REVIVE = table.Add( self.DONT_REVIVE, dontReviveList )

    end

    local zambInfo = {
        class = class,
        pos = zamb:GetPos(),
        pending = false,
        eldritch = zamb.IsEldritch,
    }

    local localID = zamb.ID or tostring( zamb:GetCreationID() )
    self.ZAMBIE_PUPPETS[ localID ] = zambInfo

end

function ENT:REANIM_SpawnPuppetedZamb( class, pos, ID )
    local newZamb = ents.Create( class )

    if not IsValid( newZamb ) then
        return

    end

    local reviveDebuff = self.reanim_ReviveDebuff
    local calculatedDebuff = ( 100 + reviveDebuff ) / 100

    local statsToChange = {
        { key = "SpawnHealth" },
        { key = "ExtraSpawnHealthPerPlayer", fallback = 0 },
        { key = "WalkSpeed" },
        { key = "MoveSpeed" },
        { key = "RunSpeed" },
    }

    for _, statData in ipairs( statsToChange ) do
        local key = statData.key
        local fallback = statData.fallback or nil

        local currentValue = newZamb[key] or fallback
        newZamb[key] = currentValue * calculatedDebuff

    end

    newZamb:SetOwner( self )
    newZamb:SetNWBool( "IsZambReanim_Puppet", true )
    newZamb.ID = ID
    --[[------------------------------------------------------------------------------------------------------------
    Basically, if another reanimator wants to check if this zombie has already been revived this will return true.
    You can see it in use within the loop that obtains valid zombies to spawn owo.
    ------------------------------------------------------------------------------------------------------------]]--
    hook.Add( ID .. "_puppetExists", newZamb, function()
        return true

    end )

    newZamb:SetPos( pos )
    newZamb:Spawn()
    newZamb:Activate()

    if newZamb.zamb_NextPuppetCheck then
        newZamb.zamb_NextPuppetCheck = math.huge

    elseif newZamb.zamb_NextMinionCheck then
        newZamb.zamb_NextMinionCheck = math.huge

    end

    local soundPath = self.reanim_PuppetFormationSounds[ math.random( 1, 2 ) ]

    newZamb:EmitSound( soundPath, 125, math.Rand( 75, 150 ), 1, CHAN_AUTO, 2 )

    if math.random( 3 ) == 1 then
        timer.Simple( math.Rand( 0, 2 ), function()
            if not IsValid( newZamb ) then return end
            newZamb:ZAMB_AngeringCall()

        end )
    end

    local timerData = self.reanim_PuppetFormationTimer

    local boneCount = newZamb:GetBoneCount()
    local boneScales = {}

    local timerName = "boneManipTimer_" .. ID .. self:GetCreationID()

    timer.Simple( 0, function()
        newZamb:SetSubMaterial( 0, "models/flesh" )
        newZamb:SetSubMaterial( 1, "models/flesh" )
        newZamb:SetSubMaterial( 2, "models/flesh" )
        newZamb:SetMaterial( "models/flesh" )

        if newZamb:HasBoneManipulations() then
            for index = 0, boneCount - 1 do
                local baseScale = newZamb:GetManipulateBoneScale( index )
                boneScales[index] = baseScale

            end
        end

        timer.Create( timerName, timerData.duration / timerData.cycles, timerData.cycles, function()
            if not IsValid( newZamb ) then
                timer.Pause( timerName )
                timer.Remove( timerName )

                return

            end

            local cycle = timerData.cycles - timer.RepsLeft( timerName )
            for index = 0, boneCount - 1 do
                local baseScale = boneScales[index] or REANIM_VECTOR_ONE
                local scale_vector = baseScale / timerData.cycles * cycle

                newZamb:ManipulateBoneScale( index, scale_vector )

            end
        end )
    end )

    return newZamb

end

function ENT:REANIM_GiveAneurysm()
    local headBone = self:LookupBone( "ValveBiped.Bip01_Spine4" ) -- It don't actually have a head
    local headBonePos, headBoneAng = self:GetBonePosition( headBone )

    if headBonePos == self:GetPos() then
        headBonePos = self:GetBoneMatrix( headBone ):GetTranslation()

    end

    local effectData = EffectData()

    effectData:SetScale( 1 )
    effectData:SetOrigin( headBonePos )
    effectData:SetNormal( headBoneAng:Forward() )

    util.Effect( "StriderBlood", effectData )

    local damageInfo = DamageInfo()

    damageInfo:SetDamage( math.huge )
    damageInfo:SetDamageForce( vector_origin )

    self:SetHealth( 0 )
    self:TakeDamageInfo( damageInfo )

end

function ENT:REANIM_KillAllPuppets()
    local timeAdd = 0

    for id, puppet in pairs( self.ZAMBIE_PUPPETS ) do
        if not IsValid( puppet ) then continue end

        timeAdd = timeAdd + 1

        timer.Simple( ( timeAdd - 1 ) * 0.1, function()
            if not IsValid( puppet ) then return end

            local damageInfo = DamageInfo()

            damageInfo:SetDamage( math.huge )
            damageInfo:SetDamageForce( vector_origin )
            damageInfo:SetAttacker( puppet )

            puppet:SetHealth( 1 )
            puppet:TakeDamageInfo( damageInfo )
            SafeRemoveEntity( puppet )

        end )
    end
end

function ENT:REANIM_TrySpawnPuppets()
    local modelCenter = self:WorldSpaceCenter()
    local hasEldritch = false

    local validRevives = {}

    for id, value in SortedPairs( self.ZAMBIE_PUPPETS ) do
        if table.Count( self.ZAMBIE_PUPPETS ) + table.Count( validRevives ) > 20 then break end
        if IsEntity( value ) then continue end

        local position = value.pos
        local distance = position:Distance( modelCenter )
        local closeEnough = distance < self.reanim_PulseRadius
        local withinView = self:VisibleVec( position )
        local alreadyExists = hook.Run( id .. "_puppetExists" )
        local isPending = value.pending

        if not closeEnough or not withinView or alreadyExists or isPending then continue end

        validRevives[id] = value
        validRevives[id].distance = distance

        if not hasEldritch and value.eldritch then
            hasEldritch = true

        end
    end

    if table.IsEmpty( validRevives ) then return end

    self:Term_ClearStuffToSay()
    self:ZAMB_AngeringCall()

    self:Setreanim_IsVulnerable( true )

    timer.Simple( 2.5, function()
        if not IsValid( self ) then return end
        self:Setreanim_IsVulnerable( false )

    end )

    if hasEldritch then
        timer.Simple( 2, function()
            if not IsValid( self ) then return end
            self:REANIM_GiveAneurysm()

        end )
    else
        net.Start( "REANIM_SpawnPulseOnClients" )
            net.WriteVector( modelCenter )
            net.WriteFloat( self.reanim_PulseSpeed )
            net.WriteFloat( self.reanim_PulseRadius )
            net.WriteUInt( self.reanim_PulseColor, 8 )
        net.Send( terminator_Extras.recipFilterAllTargetablePlayers() )

        for id, stuff in pairs( validRevives ) do
            stuff.pending = true

            local time = stuff.distance / ( self.reanim_PulseSpeed * 100 )

            timer.Simple( time, function()
                if not IsValid( self ) then return end

                local newPos = stuff.pos
                local puppet = self:REANIM_SpawnPuppetedZamb( stuff.class, newPos, id )

                local effectData = EffectData()

                effectData:SetOrigin( newPos )
                effectData:SetNormal( vector_up )
                effectData:SetFlags( 7 )
                effectData:SetScale( 10 )
                effectData:SetColor( 0 )

                util.Effect( "bloodspray", effectData )

                self.ZAMBIE_PUPPETS[id] = puppet

            end )
        end
    end
end

ENT.MyClassTask = {
    OnDamaged = function( self, _, damage )
        if not self:Getreanim_IsVulnerable() then return end

        local position = damage:GetDamagePosition()
        local weapon = damage:GetWeapon()

        local isCrowbar = nil

        if IsValid( weapon ) then
            local isCrowbar = weapon:GetClass() == "weapon_crowbar" or weapon:GetClass() == "weapon_stunstick"

        end

        local coneDir = self:EyeAngles():Forward() * -1
        local coneOrigin = self:WorldSpaceCenter() + vector_up * 18 + coneDir
        local coneAngle = math.sin( math.rad( 135 * self.TERM_MODELSCALE / 1.4 ) )
        local coneLength = 1024 * 2

        local isBehind = util.IsPointInCone( position, coneOrigin, coneDir, coneAngle, coneLength )

        if not isBehind then
            local damageScale = 1 / 4

            damage:ScaleDamage( damageScale )
            self:EmitSound( "physics/surfaces/tile_impact_bullet1.wav", 125 )

            local backBone = self:LookupBone( "ValveBiped.Bip01_Spine2" )
            local backBonePos, backBoneAng = self:GetBonePosition( backBone )
            local backBoneDir = backBoneAng:Forward()

            local effectData = EffectData()

            effectData:SetOrigin( backBonePos )
            effectData:SetNormal( backBoneDir )
            effectData:SetMagnitude( 1 )
            effectData:SetRadius( 1 )
            effectData:SetScale( 1 )

            util.Effect( "Sparks", effectData )

        else
            local damageScale
            if self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio then
                damageScale = 1.5

            elseif isCrowbar then
                damageScale = 20 -- Risky to go in with a crowbar/stunstick but does a TON of damage as a reward (hopefully less pointless -w-)

            else
                damageScale = 2

            end

            damage:ScaleDamage( damageScale )
            self:EmitSound( "npc/antlion_grub/squashed.wav", 125 )

            local backBone = self:LookupBone( "ValveBiped.Bip01_Spine2" )
            local backBonePos, backBoneAng = self:GetBonePosition( backBone )
            local backBoneDir = backBoneAng:Forward() * -1

            local effectData = EffectData()

            effectData:SetOrigin( backBonePos )
            effectData:SetNormal( backBoneDir )
            effectData:SetScale( 1 )

            util.Effect( "StriderBlood", effectData )

        end
    end,

    OnRemoved = function( self )
        if SERVER and self.ZAMBIE_PUPPETS then
            self:REANIM_KillAllPuppets()

        end
    end,
    
    Think = function( self )
        if self.zamb_NextPuppetCheck > CurTime() then return end

        local nextResurrectTime

        if self:Health() < self:GetMaxHealth() * ( self.zamb_LoseCoolRatio / 2 ) then
            nextResurrectTime = self.reanim_TryReviveInterval * 0.75

        else
            nextResurrectTime = self.reanim_TryReviveInterval

        end

        self.zamb_NextPuppetCheck = CurTime() + nextResurrectTime

        if self:IsControlledByPlayer() then return end
        self:REANIM_TrySpawnPuppets()

    end
}
