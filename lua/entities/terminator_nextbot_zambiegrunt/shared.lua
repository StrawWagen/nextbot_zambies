AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Grunt"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambiegrunt", {
    Name = "Zombie Grunt",
    Class = "terminator_nextbot_zambiegrunt",
    Category = "Nextbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambiegrunt", ENT.PrintName )
    return

end

ENT.SpawnHealth = 600
ENT.WalkSpeed = 40
ENT.MoveSpeed = 115
ENT.RunSpeed = 350
ENT.AccelerationSpeed = 350

ENT.CanUseStuff = nil

ENT.FistDamageMul = 1.5
ENT.DuelEnemyDist = 550
ENT.CloseEnemyDistance = 500

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

local GRUNT_MODEL = "models/player/zombine/combine_zombie.mdl"
ENT.ARNOLD_MODEL = GRUNT_MODEL
ENT.TERM_MODELSCALE = function() return math.Rand( 1.02, 1.05 ) end
ENT.CollisionBounds = { Vector( -14, -14, 0 ), Vector( 14, 14, 65 ) } -- this is then scaled by modelscale
ENT.MyPhysicsMass = 150

ENT.TERM_FISTS = "weapon_term_zombieclaws"

ENT.Models = { GRUNT_MODEL }

function ENT:AdditionalInitialize()
    self:SetModel( GRUNT_MODEL )

    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    local hasBrains = math.random( 1, 100 ) < 30
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true

    end
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = -20
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
    self.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = {
        "nextbot_zambies/zombine/zombine_charge1.wav",
        "nextbot_zambies/zombine/zombine_charge2.wav",
    }
    self.term_AngerSound = "Zombie.Idle"
    self.term_DamagedSound = "Zombie.Pain"
    self.term_DieSound = "Zombie.Die"
    self.term_JumpSound = "npc/zombie/foot1.wav"
    self.IdleLoopingSounds = {
        "npc/zombie/zombie_voice_idle1.wav",
        "npc/zombie/zombie_voice_idle2.wav",
        "npc/zombie/zombie_voice_idle3.wav",
        "npc/zombie/zombie_voice_idle4.wav",
        "npc/zombie/zombie_voice_idle5.wav",
        "npc/zombie_poison/pz_breathe_loop1.wav",
        "npc/zombie/moan_loop2.wav",

    }
    self.AngryLoopingSounds = {
        "npc/zombie/moan_loop1.wav",
        "npc/zombie/moan_loop3.wav",

    }

    self.AlwaysPlayLooping = true

    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.030
    self.DeathDropHeight = 1500

end

local sndFlags = bit.bor( SND_CHANGE_VOL )

function ENT:OnFootstep( _pos, foot, _sound, volume, _filter )
    local lvl = 77
    local pit = math.random( 75, 85 )
    local snd = foot and "npc/zombie_poison/pz_left_foot1.wav" or "npc/zombie_poison/pz_right_foot1.wav"
    local moveSpeed = self:GetVelocity():Length()
    if moveSpeed <= self.WalkSpeed * 1.15 then
        lvl = 76
        pit = math.random( 90, 100 )
        snd = foot and "Zombie.ScuffRight" or "Zombie.ScuffLeft"

    else
        util.ScreenShake( self:GetPos(), 1, 20, 0.15, 200 + moveSpeed )

    end
    self:EmitSound( snd, lvl, pit, volume + 1, CHAN_STATIC, sndFlags )
    return true

end

local HEAD = 1

-- does not flinch
function ENT:HandleFlinching( dmg, hitGroup )
    if hitGroup == HEAD then
        BaseClass.HandleFlinching( self, dmg, hitGroup )
    end
end

function ENT:PostTookBulletDamage( dmg, hitGroup )
    if hitGroup == HEAD then
        dmg:ScaleDamage( 4 )
        local pos = dmg:GetDamagePosition()
        timer.Simple( 0, function()
            local normal = VectorRand()
            normal.z = math.abs( normal.z )

            local Data = EffectData()
            Data:SetOrigin( pos )
            Data:SetColor( 0 )
            Data:SetScale( math.random( 8, 12 ) )
            Data:SetFlags( 3 )
            Data:SetNormal( normal )
            util.Effect( "bloodspray", Data )
            self:EmitSound( "npc/antlion_grub/squashed.wav", 72, math.random( 150, 200 ), 1, CHAN_STATIC ) -- play in static so it doesnt get overriden

        end )
    else
        dmg:ScaleDamage( 0.25 )
        local pos = dmg:GetDamagePosition()
        timer.Simple( 0, function()
            local Data = EffectData()
            Data:SetOrigin( pos )
            Data:SetColor( 1 )
            Data:SetScale( 1 )
            Data:SetRadius( 1 )
            Data:SetMagnitude( 1 )
            Data:SetNormal( VectorRand() )
            util.Effect( "Sparks", Data )
            self:EmitSound( self.Rics[math.random( 1, #self.Rics )], 75, math.random( 75, 85 ) )

        end )
    end
end

function ENT:IsImmuneToDmg( dmg )
    if dmg:IsBulletDamage() then return end -- handled above
    if dmg:IsExplosionDamage() and dmg:GetDamage() > 300 then return end -- thats alot of damage! cant resist that
    dmg:ScaleDamage( 0.25 )

end

function ENT:AdditionalThink( myTbl )
    local cur = CurTime() + self:GetCreationID()
    local doAltRun = cur % 8 < 1.5

    if doAltRun then
        myTbl.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_PROTECTED

    else
        myTbl.IdleActivityTranslations[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE

    end
end
