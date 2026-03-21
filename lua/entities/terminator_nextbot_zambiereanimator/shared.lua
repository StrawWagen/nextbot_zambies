
AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambietank"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName	= "Zombie Reanimator"
ENT.Spawnable	= false
ENT.Author		= "Bluekrakan"

list.Set( "NPC", "terminator_nextbot_zambiereanimator", {
	Name		= "Zombie Reanimator",
	Class		= "terminator_nextbot_zambiereanimator",
	Category	= "Nextbot Zambies"
} )

ENT.MySpecialActions = {
    ["call"] = {
        inBind = IN_RELOAD,
        drawHint = true,
        name = "Raise the dead but better.",
        desc = "Revive zambies that have died near you within your lifetime.",
        ratelimit = 4,
        svAction = function( _drive, _driver, bot ) bot:REANIM_TrySpawnPuppets( true ) end,
    }
}

ENT.JumpHeight = 500
ENT.SpawnHealth = 1750
ENT.ExtraSpawnHealthPerPlayer = 50
ENT.HealthRegen = 3
ENT.HealthRegenInterval = 1
ENT.AimSpeed = 500
ENT.WalkSpeed = 150
ENT.MoveSpeed = 450
ENT.RunSpeed = 650
ENT.AccelerationSpeed = 500

ENT.zamb_MeleeAttackSpeed = 1

ENT.FistDamageMul = 2.5
ENT.FistForceMul = 4
ENT.FistRangeMul = 2
ENT.PrefersVehicleEnemies = false

local REANIM_ZAMBIE_MODEL = "models/Zombie/Fast.mdl"
ENT.ARNOLD_MODEL = REANIM_ZAMBIE_MODEL
ENT.TERM_MODELSCALE = 1.4
ENT.CollisionBounds = { Vector( -12, -12, 0 ), Vector( 12, 12, 40 ) }
ENT.MyPhysicsMass = 800

local IdleActivity = ACT_IDLE_ANGRY
ENT.IdleActivity = IdleActivity
ENT.IdleActivityTranslations = {
    [ACT_MP_STAND_IDLE]                 = IdleActivity,
    [ACT_MP_WALK]                       = ACT_WALK,
    [ACT_MP_RUN]                        = ACT_RUN,
    [ACT_MP_CROUCH_IDLE]                = ACT_WALK,
    [ACT_MP_CROUCHWALK]                 = ACT_HL2MP_WALK_CROUCH,
    [ACT_MP_ATTACK_STAND_PRIMARYFIRE]   = IdleActivity + 5,
    [ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]  = IdleActivity + 5,
    [ACT_MP_RELOAD_STAND]               = IdleActivity + 6,
    [ACT_MP_RELOAD_CROUCH]              = IdleActivity + 7,
    [ACT_MP_JUMP]                       = ACT_HL2MP_JUMP_FIST,
    [ACT_MP_SWIM]                       = ACT_WALK,
    [ACT_LAND]                          = ACT_LAND,
}

ENT.zamb_CallAnim = ACT_IDLE_ANGRY
ENT.zamb_AttackAnim = ACT_MELEE_ATTACK1

ENT.Term_BaseMsBetweenSteps = 300
ENT.Term_FootstepMsReductionPerUnitSpeed = 0.5

local REANIM_VECTOR_ONE = Vector( 1, 1, 1 )
local REANIM_SHARED_ID = 0 -- Makes sure each revived or qeued zambie gets its own unqiue ID.

if SERVER then 
	util.AddNetworkString( "REANIM_SpawnPulseOnClients" ) 
	
elseif CLIENT then
	language.Add( "terminator_nextbot_zambiereanimator", ENT.PrintName )
	
end
 -- This is here so that the effect is created regardless if there is a ton of effects on the server, that way there
 -- is still an indicator to where the reanimator is if there is a lot of effects
 -- Otherwise you'd be playing where's waldo with it
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

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 31, "Vulnerable" )
	self:SetVulnerable( false )

end

function ENT:canDoRun()
    if self:Health() < self:GetMaxHealth() * ( self.zamb_LoseCoolRatio * 1.25 ) then
        return BaseClass.canDoRun( self )

    else
        return false

    end
	
end

function ENT:AdditionalInitialize()	
    self:SetModel( REANIM_ZAMBIE_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.HasBrains = true

    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = math.huge

    self.term_SoundPitchShift = -30
    self.term_SoundLevelShift = 10

    self.term_CallingSound = "npc/stalker/go_alert2a.wav"
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

    self.zamb_NextPuppetCheck = CurTime() + 6
    self.ZAMBIE_PUPPETS = {} -- Yea I changed the name slightly, no I don't care
	self.DONT_REVIVE = {} -- List of zambies to not revive if they show up

	self.reanim_BadParents = { -- A blacklist of things basically, also the reason reanimators aren't here is because they're already handeled
		"terminator_nextbot_zambienecro",
		"terminator_nextbot_zambienecroelite",
		"terminator_nextbot_zambiebigheadcrab",
		"terminator_nextbot_zambiebiggerheadcrab",	
	}

	self.reanim_PulseRadius = 1750 -- How far it can revive things
	self.reanim_PulseSpeed = 60 -- How fast the pulse grows
	self.reanim_PulseColor = 196 -- The red toning of the pulse
	
	self.reanim_ReviveDebuff = -25 -- This is how much percent less should revived zambies have their stats decrease by.
	self.reanim_ShriekSoundLevelShift = 30 -- How much to change our sound level by when we start to revive stuff
	
	self.reanim_PuppetFormationSounds = { -- The sounds that puppets will make when they are forming
		"npc/barnacle/barnacle_die1.wav",
		"npc/barnacle/barnacle_die2.wav"
	}
	self.reanim_PuppetFormationTimer = { -- Some timer info for puppets having their bones configured over time
		duration = 0.25, -- How long it takes for puppets to be fully formed
		cycles = 60, -- You can think of this as the "resolution" of the forming
	}

    self:SetBodygroup( 1, 1 )
	self:SetSubMaterial( 0, "models/charple/charple3_sheet" )
    self.zamb_LoseCoolRatio = 0.5
	
	hook.Add( "OnNPCKilled", self, function( me, npc )
		local npcOwner = npc:GetOwner()
		local class = npc:GetClass()
		local isZambie = string.match( npc:GetClass(), "terminator_nextbot_zambie" ) == "terminator_nextbot_zambie"

		if isZambie then		
			local hasMinions = npc.ZAMBIE_MINIONS
			local dontReviveThese = nil
			
			if hasMinions then dontReviveThese = hasMinions end
		
			me:REANIM_AddZambieDied( npc, dontReviveThese )
		
		end

	end )
	
	--[[----------------------------------------------------------------------------------------------------------
	This is the JankyAssGodCrabDetection(TM), where it uses this janky ass system to detect when godcrabs die since
	they don't call the 'OnNPCKilled' hook for some reason.
	----------------------------------------------------------------------------------------------------------]]--
	hook.Add( "EntityRemoved", self, function( me, entity )
		if entity:GetClass() == "terminator_nextbot_zambiebiggerheadcrab" and entity:Health() <= 0 then			
			local dontReviveThese = entity.ZAMBIE_MINIONS
			me:REANIM_AddZambieDied( entity, dontReviveThese )
			
		end

	end )
	
    hook.Add( "zamb_OnBecomeTorso", self, function( me, died, newTorso )
        local diedOwner = died:GetOwner()
		died.BecameTorso = true
		newTorso:SetOwner( diedOwner )
		newTorso:SetNWBool( "IsPuppet", died:GetNWBool( "IsPuppet" ) )
		newTorso.ID = died.ID
		
		if me.ZAMBIE_PUPPETS[ died.ID ] then me.ZAMBIE_PUPPETS[ died.ID ] = newTorso end

    end )

end

function ENT:AdditionalThink()
	if self.zamb_NextPuppetCheck > CurTime() then return end
	
	local nextResurrectTime = 6
	
	if self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio then nextResurrectTime = 4 end
	
	self.zamb_NextPuppetCheck = CurTime() + nextResurrectTime
	
	if self:IsControlledByPlayer() then return end
	self:REANIM_TrySpawnPuppets()
	
end

function ENT:REANIM_AddZambieDied( zamb, dontReviveList )
	local isTorso = string.match( zamb:GetClass(), "torso" ) == "torso"
	local class = zamb:GetClass()
	local isIdiot = table.HasValue( self.DONT_REVIVE, zamb ) -- This is if we were owned by a necromancer, or a crab of the god variety
	
	-- BEHOLD! THE POWER OF LIKE 8 DIFFERENT 'IF' STATEMENTS!
	if IsValid( zamb:GetOwner() ) then isIdiot = table.HasValue( self.reanim_BadParents, zamb:GetOwner():GetClass() ) end
	if zamb.BecameTorso or isIdiot then if isIdiot then table.RemoveByValue( self.DONT_REVIVE, zamb ) end return end
	if isTorso then class = string.gsub( class, "torso", "" ) end		
	if zamb:GetNWBool( "IsPuppet" ) then if zamb:GetOwner() ~= self or zamb.ID == nil then return end end
	if dontReviveList then self.DONT_REVIVE = table.Add( self.DONT_REVIVE, dontReviveList ) end

	local zambInfo = {
		class = class,
		pos	= zamb:GetPos(),
		pending = false,
		eldritch = zamb.IsEldritch
	}

	local id = zamb.ID or tostring( REANIM_SHARED_ID )
	self.ZAMBIE_PUPPETS[ id ] = zambInfo
	
	if !zamb.ID then
		REANIM_SHARED_ID = REANIM_SHARED_ID + 1
	
	end	

end

function ENT:REANIM_SpawnPuppetedZamb( class, pos, id )
	local newZamb = ents.Create( class )

	local calculatedDebuff = ( 100 + self.reanim_ReviveDebuff ) / 100
	local otherwayAround = ( 100 - self.reanim_ReviveDebuff ) / 100

	local zambHealth = newZamb.SpawnHealth
	local zambXtraHealth = newZamb.ExtraSpawnHealthPerPlayer or 0

	local zambWalk = newZamb.WalkSpeed
	local zambMove = newZamb.MoveSpeed
	local zambRun = newZamb.RunSpeed

	local zambAttack = newZamb.zamb_MeleeAttackSpeed
	local zambHit = newZamb.zamb_MeleeAttackHitFrameMul or 1
	local zambDelay	= newZamb.zamb_MeleeAttackAdditionalDelay or 0
	
	local zambSpawnMinions = newZamb.NECRO_TrySpawnMinions or newZamb.REANIM_TrySpawnPuppets
	-- uuaaaagghhhhh
	newZamb.SpawnHealth	= zambHealth * calculatedDebuff
	newZamb.ExtraSpawnHealthPerPlayer = zambXtraHealth * calculatedDebuff
	
	newZamb.WalkSpeed = zambWalk * calculatedDebuff
	newZamb.MoveSpeed = zambMove * calculatedDebuff
	newZamb.RunSpeed = zambRun * calculatedDebuff
	
	newZamb.zamb_MeleeAttackSpeed = zambAttack * calculatedDebuff
	newZamb.zamb_MeleeAttackHitFrameMul = zambHit * calculatedDebuff
	newZamb.zamb_MeleeAttackAdditionalDelay = zambDelay * otherwayAround
	
	if zambSpawnMinions then
		newZamb.NECRO_TrySpawnMinions = function() return end -- This is so that things that will normally spawn stuff gets neutered and can't do so
		newZamb.REANIM_TrySpawnPuppets = function() return end
		
	end
	
	newZamb:SetOwner( self )
	newZamb:SetNWBool( "IsPuppet", true )
	newZamb.ID = id
	
	newZamb:SetPos( pos )
	newZamb:Spawn()
	newZamb:Activate()
	
	local soundPath = self.reanim_PuppetFormationSounds[ math.random( 1, 2 ) ]
	
	newZamb:EmitSound( soundPath, 125, math.Rand( 75, 150 ), 1, CHAN_AUTO, 2 )
	
	if math.random( 3 ) == 1 then 
		timer.Simple( math.Rand( 0, 2 ), function() newZamb:ZAMB_AngeringCall() end )
		
	end
	
	local cycle = 1	
	local timerData = self.reanim_PuppetFormationTimer
	
	local boneCount = newZamb:GetBoneCount()
	local boneScales = {}
	
	timer.Simple( 0, function()
		newZamb:SetSubMaterial( 0, "models/flesh" )
		newZamb:SetSubMaterial( 1, "models/flesh" )
		newZamb:SetSubMaterial( 2, "models/flesh" )	
		newZamb:SetMaterial( "models/flesh" )
	
		if newZamb:HasBoneManipulations() then
			for index = 0, boneCount - 1 do
				local baseScale = newZamb:GetManipulateBoneScale( index )	
				boneScales[ index ] = baseScale
			
			end
			
		end

		timer.Create( "boneManipTimer_" .. id, timerData.duration / timerData.cycles, timerData.cycles, function()
			if !newZamb and !IsValid( newZamb ) then return end		
			for index = 0, boneCount - 1 do
				local baseScale = boneScales[ index ] or REANIM_VECTOR_ONE
			
				local scale_vector = baseScale / timerData.cycles * cycle
				
				newZamb:ManipulateBoneScale( index, scale_vector )
			
			end
			
			cycle = cycle + 1
		
		end )
		
	end )
	
	return newZamb

end

function ENT:REANIM_GiveAneurysm()
	local headBone = self:LookupBone( "ValveBiped.Bip01_Spine4" ) -- It don't actually have a head
	local headBonePos, headBoneAng = self:GetBonePosition( headBone )
	
	if headBonePos == self:GetPos() then headBonePos = self:GetBoneMatrix( headBone ):GetTranslation() end
	
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
	for id, stuff in pairs( self.ZAMBIE_PUPPETS ) do 
		if isentity( stuff ) and stuff:IsValid() then
			local puppet = stuff
			local damageInfo = DamageInfo()
			
			damageInfo:SetDamage( math.huge )
			damageInfo:SetDamageForce( vector_origin )
			damageInfo:SetAttacker( puppet )
		
			puppet:SetHealth( 1 )
			puppet:TakeDamageInfo( damageInfo )
			--SafeRemoveEntity( puppet )
		
		end
	
	end

end

function ENT:REANIM_TrySpawnPuppets()
	local modelCenter = self:WorldSpaceCenter()
	local hasEldritch = false
	
	--local expiredKeys = {}
	
	local validRevives = {}
	
	for id, value in SortedPairs( self.ZAMBIE_PUPPETS ) do
		local position = value.pos or value:GetPos()
		local distance = position:Distance( modelCenter )
		local withinSOF = distance < self.reanim_PulseRadius
		--[[ -- I feel with this sytem you could exploit it to make its attempts at reviving strong zambies pointless way too easily
		if table.Count( self.ZAMBIE_PUPPETS ) - #expiredKeys > 30 && !withinSOF then
			table.insert( expiredKeys, value )
			if isentity( value ) then
				value.ID = nil
				
				local damageInfo = DamageInfo()
				
				damageInfo:SetDamage( math.huge )
				damageInfo:SetDamageForce( vector_origin )
				damageInfo:SetAttacker( value )
			
				value:SetHealth( 1 )
				value:TakeDamageInfo( damageInfo )
			
			end
		
		end]]
		
		if istable( value ) then
			if withinSOF then
				validRevives[ id ] = value
				validRevives[ id ].distance = distance
			
				if !hasEldritch and value.eldritch then hasEldritch = true end
				
			end
		
		end
	
	end
	--[[
	for _, value in ipairs( expiredKeys ) do
		table.RemoveByValue( self.ZAMBIE_PUPPETS, value )
	
	end]]
	
	if table.Count( validRevives ) <= 0 then return end
	
	self:Term_ClearStuffToSay()
	
	self.term_SoundLevelShift = self.reanim_ShriekSoundLevelShift	
	self:ZAMB_AngeringCall()	
	self.term_SoundLevelShift = -30
	
	self:SetVulnerable( true )
	
	timer.Simple( 2.5, function()
		if !self or !IsValid( self ) then return end
		self:SetVulnerable( false )
		
	end )
	
	if not hasEldritch then
		net.Start( "REANIM_SpawnPulseOnClients" )
			net.WriteVector( modelCenter )
			net.WriteFloat( self.reanim_PulseSpeed )
			net.WriteFloat( self.reanim_PulseRadius * 2.75 ) -- Don't ask me why, but 2.75 is for some reason a magic number here
			net.WriteUInt( self.reanim_PulseColor, 8 )
		net.Broadcast()
		
		for id, stuff in pairs( validRevives ) do 
			if isentity( stuff ) and stuff.pending == true then continue end
			if stuff.distance > self.reanim_PulseRadius then continue end
		
			local time = stuff.distance / ( self.reanim_PulseSpeed * 100 )
			stuff.pending = true
		
			timer.Simple( time * 2.75, function()
				if !self then return end
		
				local newPos = stuff.pos
				local puppet = self:REANIM_SpawnPuppetedZamb( stuff.class, newPos, id )
				
				local effectData = EffectData()
				
				effectData:SetOrigin( newPos )
				effectData:SetNormal( vector_up )
				effectData:SetFlags( 7 )
				effectData:SetScale( 10 )
				effectData:SetColor( 0 )
				
				util.Effect( "bloodspray", effectData )
				
				self.ZAMBIE_PUPPETS[ id ] = puppet
				
			end )
		
		end
		
	else
		timer.Simple( 2, function() self:REANIM_GiveAneurysm() end ) 
		
	end

end

function ENT:OnTakeDamage( damage )
	BaseClass.OnTakeDamage( self, damage )

	if !self:GetVulnerable() then return end
	
	local position = damage:GetDamagePosition()
	local weapon = damage:GetWeapon()
	
	local isCrowbar = nil
	
	if weapon and IsValid( weapon ) then local isCrowbar = weapon:GetClass() == "weapon_crowbar" or weapon:GetClass() == "weapon_stunstick" end
	
	local coneDir = self:EyeAngles():Forward() * -1
	local coneOrigin = self:WorldSpaceCenter() + vector_up * 18 + coneDir
	local coneAngle = math.sin( math.rad( 135 * self.TERM_MODELSCALE / 1.4 ) )
	local coneLength = 1024 * 2
	
	local isBehind = util.IsPointInCone( position, coneOrigin, coneDir, coneAngle, coneLength )
	
	if !isBehind then 
		local damageScale = 2 / 3
		
		damage:ScaleDamage( damageScale )
		self:EmitSound( "physics/surfaces/tile_impact_bullet1.wav", 125 )
		
		local backBone = self:LookupBone( "ValveBiped.Bip01_Spine2" )
		local backBonePos, backBoneAng = self:GetBonePosition( backBone )
		local backBoneDir = backBoneAng:Forward()
		
		local effectData = EffectData()
		
		effectData:SetOrigin( backBonePos )
		effectData:SetNormal( backBoneDir )
		effectData:SetMagnitude( 2 )
		effectData:SetRadius( 0.5 )
		effectData:SetScale( 1 )
		
		util.Effect( "Sparks", effectData )
		
	else	
		local damageScale = 2
		if self:Health() < self:GetMaxHealth() * self.zamb_LoseCoolRatio then damageScale = 1.5 end
		if isCrowbar then damageScale = 10 end -- Risky to go in with a crowbar/stunstick but does a TON of damage as a reward (it's still pointless as hell -w-)
		
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

end

function ENT:Draw()
	self:DrawModel()
	
	if !self:GetVulnerable() then return end
	
	local backBone = self:LookupBone( "ValveBiped.Bip01_Spine2" )
	local backBonePos, backBoneAng = self:GetBonePosition( backBone )
	local backBoneDir = backBoneAng:Forward() - Angle( 0, self:GetAngles()[ "y" ], 0 ):Forward() * 6
	
	local LOS_check = util.TraceLine( {
		start = LocalPlayer():EyePos(),
		endpos = backBonePos + backBoneDir,
		filter = LocalPlayer(),
		mask = MASK_VISIBLE_AND_NPCS
	} )
	
	if LOS_check.Hit && LOS_check.HitPos:Distance( backBonePos + backBoneDir ) > 16 then return end

	render.SetMaterial( Material( "effects/redflare" ) )
	render.DrawSprite( backBonePos + backBoneDir, 256, 256 )		
	
end

function ENT:OnRemove()
	if SERVER and self.ZAMBIE_PUPPETS then self:REANIM_KillAllPuppets() end

end