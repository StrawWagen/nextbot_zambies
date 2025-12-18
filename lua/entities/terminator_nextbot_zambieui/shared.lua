AddCSLuaFile()

ENT.Base = "terminator_nextbot_zambie"
DEFINE_BASECLASS( ENT.Base )

ENT.PrintName = "Zombie Ultra Instinct"
ENT.Spawnable = false
ENT.Author = "regunkyle"

list.Set( "NPC", "terminator_nextbot_zambieui", {
    Name = "Zombie Ultra Instinct",
    Class = "terminator_nextbot_zambieui",
    Category = "Nextbot Zambies",
} )

if CLIENT then
    language.Add( "terminator_nextbot_zambieui", ENT.PrintName )

    function ENT:AdditionalClientInitialize()
        local myColor = Vector( 1, 1, 1 )
        self.GetPlayerColor = function()
            return myColor
        end
        
        self._particleEmitter = ParticleEmitter( self:GetPos() )
        self._nextParticle = 0
    end
    
    function ENT:Think()
        if BaseClass.Think then
            BaseClass.Think( self )
        end
        
        if self._particleEmitter and CurTime() >= self._nextParticle then
            self._nextParticle = CurTime() + 0.08
            
            local pos = self:WorldSpaceCenter()
            local offset = VectorRand() * math.Rand( 10, 30 )
            
            local particle = self._particleEmitter:Add( "effects/spark", pos + offset )
            
            if particle then
                particle:SetVelocity( VectorRand() * 30 )
                particle:SetLifeTime( 0 )
                particle:SetDieTime( math.Rand( 0.4, 0.8 ) )
                particle:SetStartAlpha( 255 )
                particle:SetEndAlpha( 0 )
                particle:SetStartSize( math.Rand( 2, 4 ) )
                particle:SetEndSize( 0 )
                particle:SetColor( 255, 255, 255 )
                particle:SetAirResistance( 100 )
                particle:SetGravity( Vector( 0, 0, 50 ) )
            end
        end
    end

    function ENT:Draw()
        self:DrawModel()
        
        local dlight = DynamicLight( self:EntIndex() )
        if dlight then
            dlight.pos = self:WorldSpaceCenter()
            dlight.r = 255
            dlight.g = 255
            dlight.b = 255
            dlight.brightness = 1
            dlight.Decay = 1000
            dlight.Size = 128
            dlight.DieTime = CurTime() + 0.1
        end
    end
    
    function ENT:OnRemove()
        if self._particleEmitter then
            self._particleEmitter:Finish()
        end
    end

    return
end

ENT.SpawnHealth = 5000
ENT.HealthRegen = 5
ENT.HealthRegenInterval = 2

ENT.AimSpeed = 800
ENT.WalkSpeed = 100
ENT.MoveSpeed = 350
ENT.RunSpeed = 600

ENT.FistDamageMul = 1.5
ENT.zamb_MeleeAttackSpeed = 2

ENT.TERM_MODELSCALE = function() return math.Rand( 1.00, 1.05 ) end
ENT.MyPhysicsMass = 85

ENT.UI_DODGE_CHANCE = 75
ENT.UI_DODGE_COOLDOWN = 0.5
ENT.UI_DODGE_DISTANCE = 500
ENT.UI_COLOR = Color( 255, 255, 255 )

function ENT:AdditionalInitialize()
    self:SetBodygroup( 1, 1 )
    self:SetColor( self.UI_COLOR )
    
    self.isTerminatorHunterChummy = "zambies"
    self.CanHearStuff = false
    
    if math.random( 1, 100 ) < 50 then
        self.HasBrains = true
        self.CanHearStuff = true
    end
    
    self.nextInterceptTry = 0
    self.term_NextIdleTaunt = CurTime() + 2
    
    self.term_SoundPitchShift = 15
    self.term_SoundLevelShift = 3
    
    self.zamb_IdleTauntInterval = 1
    
    self.HeightToStartTakingDamage = 400
    self.FallDamagePerHeight = 0.05
    self.DeathDropHeight = 1500
    
    self._lastDodgeTime = 0
    self._dodgeCount = 0
end

function ENT:OnTakeDamage( dmg )
    local curTime = CurTime()
    
    if curTime - self._lastDodgeTime >= self.UI_DODGE_COOLDOWN then
        local dodgeRoll = math.random( 1, 100 )
        
        if dodgeRoll <= self.UI_DODGE_CHANCE then
            self._lastDodgeTime = curTime
            self._dodgeCount = ( self._dodgeCount or 0 ) + 1
            
            self:DodgeEffect( dmg:GetDamagePosition() )
            
            self:EmitSound( "weapons/slam/throw.wav", 70, 150 )
            
            self:Anger( 5 )
            
            return
        end
    end
    
    BaseClass.OnTakeDamage( self, dmg )
end

function ENT:DodgeEffect( hitPos )
    if not hitPos then hitPos = self:WorldSpaceCenter() end
    
    local effectdata = EffectData()
    effectdata:SetOrigin( hitPos )
    effectdata:SetNormal( VectorRand() )
    effectdata:SetMagnitude( 1 )
    effectdata:SetScale( 2 )
    effectdata:SetRadius( 3 )
    util.Effect( "ManhackSparks", effectdata )
    
    if self.loco:IsOnGround() then
        local dodgeDir = VectorRand()
        dodgeDir.z = 0
        dodgeDir:Normalize()
        
        self.loco:SetVelocity( self.loco:GetVelocity() + dodgeDir * self.UI_DODGE_DISTANCE )
    end
end
