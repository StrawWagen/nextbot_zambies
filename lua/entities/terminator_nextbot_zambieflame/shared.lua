AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )
ENT.PrintName = "Zombie Flaming"
ENT.Spawnable = false
list.Set( "NPC", "terminator_nextbot_zambieflame", {
    Name = "Zombie Flaming",
    Class = "terminator_nextbot_zambieflame",
    Category = "Nextbot Zambies",
} )
if CLIENT then
    language.Add( "terminator_nextbot_zambieflame", ENT.PrintName )
    return

end

ENT.SpawnHealth = 75

ENT.FistDamageMul = 0.75

ENT.IsFodder = true
ENT.IsStupid = true
ENT.CanSpeak = true

local BURNT_COLOR = Color( 100, 100, 100 )

-- WHY U MAKE ME DO THIS VFIRE
function ENT:IsImmuneToDmg( dmg )
    local attacker = dmg:GetAttacker()
    if IsValid( attacker ) and attacker.vFireIsVFireEnt then return true end

end

function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetMaterial( "models/props_debris/plasterwall009d" )
    self:SetColor( BURNT_COLOR )
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    local hasBrains = math.random( 1, 100 ) < 30
    if hasBrains then
        self.HasBrains = true
        self.CanHearStuff = true

    end
    self.term_DMG_ImmunityMask = bit.bor( DMG_BURN, DMG_SLOWBURN )
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 4

    self.term_SoundPitchShift = 10
    self.term_SoundLevelShift = 10

    self.term_LoseEnemySound = "Zombie.Idle"
    self.term_CallingSound = "ambient/creatures/town_zombie_call1.wav"
    self.term_CallingSmallSound = "npc/zombie/zombie_voice_idle6.wav"
    self.term_FindEnemySound = "Zombie.Alert"
    self.term_AttackSound = "Zombie.Alert"
    self.term_AngerSound = "Zombie.Idle"
    self.term_DamagedSound = "Zombie.Pain"
    self.term_DieSound = "Zombie.Die"
    self.term_JumpSound = "npc/zombie/foot1.wav"
    self.IdleLoopingSounds = {
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

function ENT:AdditionalThink()
    BaseClass.AdditionalThink( self )

    if self:IsOnFire() then
        local groundEnt = self:GetGroundEntity()
        if IsValid( groundEnt ) then
            groundEnt:Ignite( 1 )

        end
        return

    end

    if self:WaterLevel() > 1 then self:Extinguish() return end
    self:Ignite( 999 )

end

-- does not flinch
function ENT:HandleFlinching()
end

function ENT:AdditionalOnKilled()
    self:Extinguish()

    self:EmitSound( "ambient/fire/ignite.wav", 80, 110, 1, CHAN_STATIC )
    self:EmitSound( "ambient/fire/ignite.wav", 80, 140, 1, CHAN_STATIC )

    local pos = self:WorldSpaceCenter()
    local rad = 250
    local expl = EffectData()
        expl:SetEntity( self )
        expl:SetOrigin( pos )
        expl:SetScale( 1 )
        expl:SetFlags( 5 )
    util.Effect( "Explosion", expl )

    for _, ent in ipairs( ents.FindInSphere( pos, rad ) ) do
        local theirParent = ent:GetParent()
        if IsValid( theirParent ) and theirParent ~= ent then continue end

        if not IsValid( ent:GetPhysicsObject() ) then continue end

        local time = rad - ent:WorldSpaceCenter():Distance( pos )
        time = time / 10

        if ent:IsPlayer() then
            if not self:ShouldBeEnemy( ent, 180 ) then
                continue

            end
            time = time * 0.25

        end
        if not ( ent:IsNPC() or ent:IsNextBot() ) then
            time = time * 0.5

        end
        ent:Ignite( time )

    end
end