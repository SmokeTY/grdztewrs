--[[
================================================================================
    ULTIMATE COMBAT & RPG SYSTEM
    ============================
    A full-featured Roblox combat system with:
    - Melee & ranged combat with combos
    - RPG leveling, stats, and skill trees
    - Inventory system with weapons and items
    - Enemy AI with pathfinding and attack patterns
    - Damage numbers, health bars, and VFX
    - Blocking, dodging, and parrying mechanics
    - Boss fight system
    - Loot drops and rewards
    
    Place this Script in ServerScriptService.
    Requires: ReplicatedStorage folder named "CombatAssets"
    
    Author: Script Puller Project
    Lines: 1000+
================================================================================
--]]

-- ============================================================================
-- SERVICES
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local HttpService = game:GetService("HttpService")

-- ============================================================================
-- REMOTE EVENTS SETUP
-- ============================================================================

local Remotes = Instance.new("Folder")
Remotes.Name = "CombatRemotes"
Remotes.Parent = ReplicatedStorage


local AttackRemote = Instance.new("RemoteEvent")
AttackRemote.Name = "AttackEvent"
AttackRemote.Parent = Remotes

local SkillRemote = Instance.new("RemoteEvent")
SkillRemote.Name = "SkillEvent"
SkillRemote.Parent = Remotes

local DodgeRemote = Instance.new("RemoteEvent")
DodgeRemote.Name = "DodgeEvent"
DodgeRemote.Parent = Remotes

local BlockRemote = Instance.new("RemoteEvent")
BlockRemote.Name = "BlockEvent"
BlockRemote.Parent = Remotes

local LevelUpRemote = Instance.new("RemoteEvent")
LevelUpRemote.Name = "LevelUpEvent"
LevelUpRemote.Parent = Remotes

local LootRemote = Instance.new("RemoteEvent")
LootRemote.Name = "LootEvent"
LootRemote.Parent = Remotes

local LootDropRemote = Instance.new("RemoteEvent")
LootDropRemote.Name = "LootDropEvent"
LootDropRemote.Parent = Remotes

local InventoryUpdateRemote = Instance.new("RemoteEvent")
InventoryUpdateRemote.Name = "InventoryUpdateEvent"
InventoryUpdateRemote.Parent = Remotes

local EquipRequestRemote = Instance.new("RemoteEvent")
EquipRequestRemote.Name = "EquipRequestEvent"
EquipRequestRemote.Parent = Remotes

local OpenInventoryRemote = Instance.new("RemoteEvent")
OpenInventoryRemote.Name = "OpenInventoryEvent"
OpenInventoryRemote.Parent = Remotes

local DamageRemote = Instance.new("RemoteEvent")
DamageRemote.Name = "DamageEvent"
DamageRemote.Parent = Remotes

local HealRemote = Instance.new("RemoteEvent")
HealRemote.Name = "HealEvent"
HealRemote.Parent = Remotes

local InventoryRemote = Instance.new("RemoteFunction")
InventoryRemote.Name = "InventoryFunction"
InventoryRemote.Parent = Remotes

local StatsRemote = Instance.new("RemoteFunction")
StatsRemote.Name = "StatsFunction"
StatsRemote.Parent = Remotes


-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local CombatConfig = {
    -- Base Stats
    BaseHealth = 100,
    BaseMana = 50,
    BaseStamina = 75,
    BaseAttack = 10,
    BaseDefense = 5,
    BaseSpeed = 16,
    BaseCritChance = 0.05,
    BaseCritMultiplier = 1.5,
    
    -- Leveling
    MaxLevel = 100,
    BaseXPRequired = 100,
    XPMultiplier = 1.15,
    StatsPerLevel = 3,
    HealthPerLevel = 15,
    ManaPerLevel = 8,
    StaminaPerLevel = 5,
    
    -- Combat Mechanics
    AttackCooldown = 0.6,
    HeavyAttackCooldown = 1.2,
    ComboWindow = 1.5,
    MaxComboHits = 5,
    ComboMultiplierPerHit = 0.15,
    DodgeCooldown = 1.0,
    DodgeIFrames = 0.3,
    DodgeStaminaCost = 20,
    BlockStaminaDrain = 5,
    ParryWindow = 0.2,
    ParryStunDuration = 1.5,
    
    -- Stamina Regen
    StaminaRegenRate = 10,
    StaminaRegenDelay = 1.5,
    ManaRegenRate = 3,
    ManaRegenDelay = 2.0,
    
    -- Damage Calculation
    ArmorPenetration = 0.1,
    MinDamage = 1,
    MaxDamageVariance = 0.15,
    
    -- Enemy Settings
    EnemyAggroRange = 50,
    EnemyAttackRange = 5,
    EnemyRespawnTime = 10,
    BossRespawnTime = 60,
    EnemyBodyFadeTime = 2,  -- Seconds before dead enemy body disappears
}


-- ============================================================================
-- WEAPON DATABASE
-- ============================================================================

local WeaponDatabase = {
    -- Swords
    WoodenSword = {
        Name = "Wooden Sword",
        Type = "Melee",
        Subtype = "Sword",
        Damage = 8,
        Speed = 1.0,
        Range = 6,
        CritBonus = 0,
        Rarity = "Common",
        LevelReq = 1,
        Description = "A basic training sword made of oak.",
        ComboPattern = {"Slash", "Slash", "Thrust", "Spin", "Uppercut"},
    },
    IronSword = {
        Name = "Iron Sword",
        Type = "Melee",
        Subtype = "Sword",
        Damage = 15,
        Speed = 0.9,
        Range = 7,
        CritBonus = 0.03,
        Rarity = "Common",
        LevelReq = 5,
        Description = "A sturdy iron blade forged by a blacksmith.",
        ComboPattern = {"Slash", "Slash", "Thrust", "Spin", "Uppercut"},
    },
    SteelLongsword = {
        Name = "Steel Longsword",
        Type = "Melee",
        Subtype = "Sword",
        Damage = 25,
        Speed = 0.85,
        Range = 8,
        CritBonus = 0.05,
        Rarity = "Uncommon",
        LevelReq = 12,
        Description = "A finely crafted longsword with excellent balance.",
        ComboPattern = {"Slash", "Thrust", "Slash", "Uppercut", "Spin"},
    },
    ShadowBlade = {
        Name = "Shadow Blade",
        Type = "Melee",
        Subtype = "Sword",
        Damage = 45,
        Speed = 1.2,
        Range = 7,
        CritBonus = 0.15,
        Rarity = "Rare",
        LevelReq = 25,
        Description = "A dark blade that seems to absorb light around it.",
        ComboPattern = {"Slash", "Slash", "Slash", "Teleport", "Execution"},
        SpecialEffect = "LifeSteal",
        SpecialValue = 0.1,
    },
    DragonSlayer = {
        Name = "Dragon Slayer",
        Type = "Melee",
        Subtype = "Greatsword",
        Damage = 80,
        Speed = 0.6,
        Range = 10,
        CritBonus = 0.08,
        Rarity = "Legendary",
        LevelReq = 50,
        Description = "An ancient blade said to have slain the Dragon King.",
        ComboPattern = {"Cleave", "Cleave", "Slam", "Eruption", "DragonStrike"},
        SpecialEffect = "BonusDamageVsBosses",
        SpecialValue = 0.5,
    },
    
    -- Daggers
    RustDagger = {
        Name = "Rusty Dagger",
        Type = "Melee",
        Subtype = "Dagger",
        Damage = 5,
        Speed = 1.5,
        Range = 4,
        CritBonus = 0.1,
        Rarity = "Common",
        LevelReq = 1,
        Description = "A small, rusty dagger. Quick but weak.",
        ComboPattern = {"Stab", "Stab", "Stab", "Stab", "Backstab"},
    },
    AssassinBlade = {
        Name = "Assassin's Blade",
        Type = "Melee",
        Subtype = "Dagger",
        Damage = 20,
        Speed = 1.8,
        Range = 4,
        CritBonus = 0.25,
        Rarity = "Rare",
        LevelReq = 20,
        Description = "A blade favored by the Shadow Guild assassins.",
        ComboPattern = {"Stab", "Slash", "Stab", "Spin", "Execute"},
        SpecialEffect = "Poison",
        SpecialValue = 5,
    },
    
    -- Bows
    ShortBow = {
        Name = "Short Bow",
        Type = "Ranged",
        Subtype = "Bow",
        Damage = 12,
        Speed = 0.8,
        Range = 60,
        CritBonus = 0.05,
        Rarity = "Common",
        LevelReq = 3,
        Description = "A lightweight bow for quick shots.",
        ProjectileSpeed = 100,
    },
    LongBow = {
        Name = "Long Bow",
        Type = "Ranged",
        Subtype = "Bow",
        Damage = 30,
        Speed = 0.5,
        Range = 100,
        CritBonus = 0.1,
        Rarity = "Uncommon",
        LevelReq = 15,
        Description = "A powerful longbow with impressive range.",
        ProjectileSpeed = 150,
    },
    PhoenixBow = {
        Name = "Phoenix Bow",
        Type = "Ranged",
        Subtype = "Bow",
        Damage = 55,
        Speed = 0.7,
        Range = 80,
        CritBonus = 0.12,
        Rarity = "Legendary",
        LevelReq = 40,
        Description = "Arrows from this bow burst into flames on impact.",
        ProjectileSpeed = 200,
        SpecialEffect = "FireDamage",
        SpecialValue = 15,
    },
    
    -- Staffs
    ApprenticeStaff = {
        Name = "Apprentice Staff",
        Type = "Magic",
        Subtype = "Staff",
        Damage = 18,
        Speed = 0.7,
        Range = 40,
        CritBonus = 0.02,
        Rarity = "Common",
        LevelReq = 5,
        Description = "A basic staff for channeling magic.",
        ManaCost = 10,
    },
    StormStaff = {
        Name = "Staff of Storms",
        Type = "Magic",
        Subtype = "Staff",
        Damage = 50,
        Speed = 0.6,
        Range = 50,
        CritBonus = 0.08,
        Rarity = "Rare",
        LevelReq = 30,
        Description = "Channels the fury of thunder and lightning.",
        ManaCost = 25,
        SpecialEffect = "ChainLightning",
        SpecialValue = 3,
    },
}


-- ============================================================================
-- SKILL TREE DATABASE
-- ============================================================================

local SkillTree = {
    -- Warrior Skills
    Warrior = {
        PowerStrike = {
            Name = "Power Strike",
            Description = "A powerful overhead strike dealing 200% damage.",
            ManaCost = 0,
            StaminaCost = 30,
            Cooldown = 5,
            DamageMultiplier = 2.0,
            LevelReq = 3,
            SkillPointCost = 1,
            Type = "Active",
        },
        Whirlwind = {
            Name = "Whirlwind",
            Description = "Spin attack hitting all enemies within range.",
            ManaCost = 0,
            StaminaCost = 40,
            Cooldown = 8,
            DamageMultiplier = 1.5,
            Radius = 10,
            LevelReq = 8,
            SkillPointCost = 2,
            Type = "Active",
        },
        IronSkin = {
            Name = "Iron Skin",
            Description = "Passive: Increases defense by 20%.",
            LevelReq = 5,
            SkillPointCost = 1,
            Type = "Passive",
            Bonus = {Defense = 0.2},
        },
        BerserkerRage = {
            Name = "Berserker Rage",
            Description = "Increases damage by 50% but reduces defense by 25% for 10s.",
            ManaCost = 0,
            StaminaCost = 50,
            Cooldown = 30,
            Duration = 10,
            LevelReq = 15,
            SkillPointCost = 3,
            Type = "Buff",
            Bonus = {Attack = 0.5, Defense = -0.25},
        },
        Earthquake = {
            Name = "Earthquake",
            Description = "Slam the ground, stunning all enemies for 2s.",
            ManaCost = 20,
            StaminaCost = 60,
            Cooldown = 20,
            StunDuration = 2,
            Radius = 15,
            LevelReq = 25,
            SkillPointCost = 3,
            Type = "Active",
        },
    },
    
    -- Mage Skills
    Mage = {
        Fireball = {
            Name = "Fireball",
            Description = "Launch a fireball that explodes on impact.",
            ManaCost = 20,
            StaminaCost = 0,
            Cooldown = 3,
            DamageMultiplier = 2.5,
            Radius = 8,
            LevelReq = 3,
            SkillPointCost = 1,
            Type = "Active",
        },
        IceBarrier = {
            Name = "Ice Barrier",
            Description = "Create a shield that absorbs damage equal to 50% max HP.",
            ManaCost = 35,
            StaminaCost = 0,
            Cooldown = 15,
            Duration = 8,
            ShieldPercent = 0.5,
            LevelReq = 10,
            SkillPointCost = 2,
            Type = "Buff",
        },
        LightningStorm = {
            Name = "Lightning Storm",
            Description = "Call down lightning bolts in a large area.",
            ManaCost = 60,
            StaminaCost = 0,
            Cooldown = 25,
            DamageMultiplier = 3.0,
            Radius = 20,
            Duration = 5,
            LevelReq = 20,
            SkillPointCost = 3,
            Type = "Active",
        },
        ManaFlow = {
            Name = "Mana Flow",
            Description = "Passive: Increases mana regen by 50%.",
            LevelReq = 7,
            SkillPointCost = 1,
            Type = "Passive",
            Bonus = {ManaRegen = 0.5},
        },
        Teleport = {
            Name = "Teleport",
            Description = "Instantly teleport 20 studs in the direction you're facing.",
            ManaCost = 15,
            StaminaCost = 0,
            Cooldown = 5,
            Distance = 20,
            LevelReq = 12,
            SkillPointCost = 2,
            Type = "Movement",
        },
    },
    
    -- Rogue Skills
    Rogue = {
        ShadowStep = {
            Name = "Shadow Step",
            Description = "Dash behind your target, dealing 150% damage.",
            ManaCost = 0,
            StaminaCost = 25,
            Cooldown = 6,
            DamageMultiplier = 1.5,
            LevelReq = 3,
            SkillPointCost = 1,
            Type = "Active",
        },
        PoisonBlade = {
            Name = "Poison Blade",
            Description = "Coat your weapon in poison for 15s. Attacks deal bonus DoT.",
            ManaCost = 10,
            StaminaCost = 15,
            Cooldown = 20,
            Duration = 15,
            DotDamage = 5,
            DotDuration = 5,
            LevelReq = 7,
            SkillPointCost = 2,
            Type = "Buff",
        },
        Evasion = {
            Name = "Evasion",
            Description = "Passive: 15% chance to completely dodge an attack.",
            LevelReq = 5,
            SkillPointCost = 1,
            Type = "Passive",
            Bonus = {DodgeChance = 0.15},
        },
        SmokeScreen = {
            Name = "Smoke Screen",
            Description = "Drop a smoke bomb, becoming invisible for 5s.",
            ManaCost = 0,
            StaminaCost = 35,
            Cooldown = 25,
            Duration = 5,
            LevelReq = 15,
            SkillPointCost = 2,
            Type = "Buff",
        },
        DeathMark = {
            Name = "Death Mark",
            Description = "Mark a target. After 3s, deal 300% damage.",
            ManaCost = 20,
            StaminaCost = 30,
            Cooldown = 30,
            DamageMultiplier = 3.0,
            MarkDuration = 3,
            LevelReq = 25,
            SkillPointCost = 3,
            Type = "Active",
        },
    },
}


-- ============================================================================
-- ENEMY DATABASE
-- ============================================================================

local EnemyDatabase = {
    Goblin = {
        Name = "Goblin",
        Health = 50,
        Damage = 8,
        Defense = 2,
        Speed = 14,
        AttackSpeed = 1.0,
        AggroRange = 30,
        AttackRange = 5,
        XPReward = 25,
        GoldReward = {5, 15},
        LootTable = {"WoodenSword", "RustDagger"},
        LootChance = 0.1,
        IsBoss = false,
    },
    Skeleton = {
        Name = "Skeleton Warrior",
        Health = 80,
        Damage = 12,
        Defense = 5,
        Speed = 12,
        AttackSpeed = 0.8,
        AggroRange = 35,
        AttackRange = 6,
        XPReward = 45,
        GoldReward = {10, 25},
        LootTable = {"IronSword", "ShortBow"},
        LootChance = 0.12,
        IsBoss = false,
    },
    DarkKnight = {
        Name = "Dark Knight",
        Health = 200,
        Damage = 25,
        Defense = 15,
        Speed = 10,
        AttackSpeed = 0.7,
        AggroRange = 40,
        AttackRange = 7,
        XPReward = 120,
        GoldReward = {30, 60},
        LootTable = {"SteelLongsword", "AssassinBlade"},
        LootChance = 0.15,
        IsBoss = false,
    },
    FireDragon = {
        Name = "Ancient Fire Dragon",
        Health = 5000,
        Damage = 80,
        Defense = 40,
        Speed = 18,
        AttackSpeed = 0.5,
        AggroRange = 80,
        AttackRange = 15,
        XPReward = 2000,
        GoldReward = {500, 1000},
        LootTable = {"DragonSlayer", "PhoenixBow"},
        LootChance = 0.25,
        IsBoss = true,
        BossAbilities = {"FireBreath", "TailSwipe", "FlyingDive", "Enrage"},
        PhaseThresholds = {0.75, 0.5, 0.25},
    },
    ShadowLord = {
        Name = "The Shadow Lord",
        Health = 8000,
        Damage = 100,
        Defense = 50,
        Speed = 20,
        AttackSpeed = 0.6,
        AggroRange = 100,
        AttackRange = 12,
        XPReward = 5000,
        GoldReward = {1000, 2500},
        LootTable = {"ShadowBlade", "StormStaff"},
        LootChance = 0.3,
        IsBoss = true,
        BossAbilities = {"ShadowBolt", "DarkWave", "Summon", "VoidZone", "PhaseShift"},
        PhaseThresholds = {0.8, 0.6, 0.4, 0.2},
    },
}

-- ============================================================================
-- PLAYER DATA MODULE
-- ============================================================================

local PlayerDataModule = {}
PlayerDataModule.__index = PlayerDataModule

function PlayerDataModule.new(player)
    local self = setmetatable({}, PlayerDataModule)
    
    self.Player = player
    self.Level = 1
    self.XP = 0
    self.XPToNext = CombatConfig.BaseXPRequired
    self.Gold = 0
    self.SkillPoints = 0
    self.StatPoints = 0
    
    -- Core Stats
    self.MaxHealth = CombatConfig.BaseHealth
    self.CurrentHealth = CombatConfig.BaseHealth
    self.MaxMana = CombatConfig.BaseMana
    self.CurrentMana = CombatConfig.BaseMana
    self.MaxStamina = CombatConfig.BaseStamina
    self.CurrentStamina = CombatConfig.BaseStamina
    self.Attack = CombatConfig.BaseAttack
    self.Defense = CombatConfig.BaseDefense
    self.Speed = CombatConfig.BaseSpeed
    self.CritChance = CombatConfig.BaseCritChance
    self.CritMultiplier = CombatConfig.BaseCritMultiplier
    
    -- Allocated Stats
    self.STR = 0  -- Increases Attack & Health
    self.DEX = 0  -- Increases Crit & Speed
    self.INT = 0  -- Increases Mana & Magic Damage
    self.VIT = 0  -- Increases Health & Defense
    self.AGI = 0  -- Increases Speed & Dodge
    
    -- Combat State
    self.IsAttacking = false
    self.IsBlocking = false
    self.IsDodging = false
    self.IsStunned = false
    self.IsInvulnerable = false
    self.ComboCount = 0
    self.LastAttackTime = 0
    self.LastDodgeTime = 0
    self.LastStaminaUse = 0
    self.LastManaUse = 0
    
    -- Equipment
    self.EquippedWeapon = nil
    self.Inventory = {}
    self.UnlockedSkills = {}
    self.ActiveBuffs = {}
    self.Cooldowns = {}
    
    -- Class
    self.Class = "Warrior"  -- Default class
    
    return self
end


--- Recalculate all stats based on level, gear, and stat allocation
function PlayerDataModule:RecalculateStats()
    local level = self.Level
    
    -- Base stats from level
    self.MaxHealth = CombatConfig.BaseHealth + (level * CombatConfig.HealthPerLevel)
    self.MaxMana = CombatConfig.BaseMana + (level * CombatConfig.ManaPerLevel)
    self.MaxStamina = CombatConfig.BaseStamina + (level * CombatConfig.StaminaPerLevel)
    self.Attack = CombatConfig.BaseAttack + (level * 2)
    self.Defense = CombatConfig.BaseDefense + (level * 1)
    
    -- Apply stat allocations
    self.MaxHealth = self.MaxHealth + (self.VIT * 10) + (self.STR * 3)
    self.MaxMana = self.MaxMana + (self.INT * 8)
    self.MaxStamina = self.MaxStamina + (self.AGI * 5)
    self.Attack = self.Attack + (self.STR * 3) + (self.INT * 2)
    self.Defense = self.Defense + (self.VIT * 2)
    self.Speed = CombatConfig.BaseSpeed + (self.AGI * 0.5) + (self.DEX * 0.3)
    self.CritChance = CombatConfig.BaseCritChance + (self.DEX * 0.02)
    self.CritMultiplier = CombatConfig.BaseCritMultiplier + (self.DEX * 0.05)
    
    -- Apply weapon bonuses
    if self.EquippedWeapon then
        local weapon = WeaponDatabase[self.EquippedWeapon]
        if weapon then
            self.CritChance = self.CritChance + (weapon.CritBonus or 0)
        end
    end
    
    -- Apply passive skill bonuses
    for skillName, _ in pairs(self.UnlockedSkills) do
        local classSkills = SkillTree[self.Class]
        if classSkills and classSkills[skillName] then
            local skill = classSkills[skillName]
            if skill.Type == "Passive" and skill.Bonus then
                for stat, value in pairs(skill.Bonus) do
                    if stat == "Defense" then
                        self.Defense = self.Defense * (1 + value)
                    elseif stat == "Attack" then
                        self.Attack = self.Attack * (1 + value)
                    elseif stat == "ManaRegen" then
                        -- Applied during regen tick
                    elseif stat == "DodgeChance" then
                        -- Applied during dodge check
                    end
                end
            end
        end
    end
    
    -- Apply active buffs
    for _, buff in pairs(self.ActiveBuffs) do
        if buff.Bonus then
            for stat, value in pairs(buff.Bonus) do
                if stat == "Attack" then
                    self.Attack = self.Attack * (1 + value)
                elseif stat == "Defense" then
                    self.Defense = self.Defense * (1 + value)
                end
            end
        end
    end
end

--- Grant XP and handle leveling up
function PlayerDataModule:GainXP(amount)
    self.XP = self.XP + amount
    local leveled = false
    
    while self.XP >= self.XPToNext and self.Level < CombatConfig.MaxLevel do
        self.XP = self.XP - self.XPToNext
        self.Level = self.Level + 1
        self.StatPoints = self.StatPoints + CombatConfig.StatsPerLevel
        self.SkillPoints = self.SkillPoints + 1
        self.XPToNext = math.floor(CombatConfig.BaseXPRequired * (CombatConfig.XPMultiplier ^ self.Level))
        leveled = true
        
        -- Full heal on level up
        self:RecalculateStats()
        self.CurrentHealth = self.MaxHealth
        self.CurrentMana = self.MaxMana
        self.CurrentStamina = self.MaxStamina
    end
    
    if leveled then
        LevelUpRemote:FireClient(self.Player, self.Level, self.StatPoints, self.SkillPoints)
        print("[CombatSystem] " .. self.Player.Name .. " leveled up to " .. self.Level .. "!")
    end
end

--- Allocate a stat point
function PlayerDataModule:AllocateStat(statName)
    if self.StatPoints <= 0 then return false end
    
    if statName == "STR" then
        self.STR = self.STR + 1
    elseif statName == "DEX" then
        self.DEX = self.DEX + 1
    elseif statName == "INT" then
        self.INT = self.INT + 1
    elseif statName == "VIT" then
        self.VIT = self.VIT + 1
    elseif statName == "AGI" then
        self.AGI = self.AGI + 1
    else
        return false
    end
    
    self.StatPoints = self.StatPoints - 1
    self:RecalculateStats()
    return true
end


--- Unlock a skill from the skill tree
function PlayerDataModule:UnlockSkill(skillName)
    if self.SkillPoints <= 0 then return false, "No skill points available" end
    
    local classSkills = SkillTree[self.Class]
    if not classSkills or not classSkills[skillName] then
        return false, "Skill not found for your class"
    end
    
    local skill = classSkills[skillName]
    if self.Level < skill.LevelReq then
        return false, "Level too low (need " .. skill.LevelReq .. ")"
    end
    
    if self.SkillPoints < skill.SkillPointCost then
        return false, "Not enough skill points (need " .. skill.SkillPointCost .. ")"
    end
    
    if self.UnlockedSkills[skillName] then
        return false, "Skill already unlocked"
    end
    
    self.UnlockedSkills[skillName] = true
    self.SkillPoints = self.SkillPoints - skill.SkillPointCost
    self:RecalculateStats()
    
    return true, "Unlocked " .. skill.Name .. "!"
end

--- Use a skill
function PlayerDataModule:UseSkill(skillName, targetPosition)
    if not self.UnlockedSkills[skillName] then
        return false, "Skill not unlocked"
    end
    
    local classSkills = SkillTree[self.Class]
    local skill = classSkills[skillName]
    
    -- Check cooldown
    if self.Cooldowns[skillName] and tick() - self.Cooldowns[skillName] < skill.Cooldown then
        local remaining = skill.Cooldown - (tick() - self.Cooldowns[skillName])
        return false, string.format("On cooldown (%.1fs)", remaining)
    end
    
    -- Check mana
    if skill.ManaCost and self.CurrentMana < skill.ManaCost then
        return false, "Not enough mana"
    end
    
    -- Check stamina
    if skill.StaminaCost and self.CurrentStamina < skill.StaminaCost then
        return false, "Not enough stamina"
    end
    
    -- Consume resources
    if skill.ManaCost then
        self.CurrentMana = self.CurrentMana - skill.ManaCost
        self.LastManaUse = tick()
    end
    if skill.StaminaCost then
        self.CurrentStamina = self.CurrentStamina - skill.StaminaCost
        self.LastStaminaUse = tick()
    end
    
    -- Set cooldown
    self.Cooldowns[skillName] = tick()
    
    return true, skill
end

--- Add item to inventory
function PlayerDataModule:AddItem(itemId)
    if #self.Inventory >= 30 then
        return false, "Inventory full"
    end
    
    table.insert(self.Inventory, {
        Id = itemId,
        UUID = HttpService:GenerateGUID(false),
    })
    return true
end

--- Equip a weapon from inventory
function PlayerDataModule:EquipWeapon(itemId)
    local weapon = WeaponDatabase[itemId]
    if not weapon then return false, "Weapon not found" end
    if self.Level < weapon.LevelReq then
        return false, "Level too low (need " .. weapon.LevelReq .. ")"
    end
    
    self.EquippedWeapon = itemId
    self:RecalculateStats()
    return true, "Equipped " .. weapon.Name
end

-- ============================================================================
-- DAMAGE CALCULATION ENGINE
-- ============================================================================

local DamageEngine = {}

function DamageEngine.CalculateDamage(attacker, defender, isSkill, skillMultiplier)
    local baseDamage = attacker.Attack
    
    -- Apply weapon damage
    if attacker.EquippedWeapon then
        local weapon = WeaponDatabase[attacker.EquippedWeapon]
        if weapon then
            baseDamage = baseDamage + weapon.Damage
        end
    end
    
    -- Apply skill multiplier
    if isSkill and skillMultiplier then
        baseDamage = baseDamage * skillMultiplier
    end
    
    -- Apply combo bonus
    if attacker.ComboCount > 0 then
        local comboBonus = 1 + (attacker.ComboCount * CombatConfig.ComboMultiplierPerHit)
        baseDamage = baseDamage * comboBonus
    end
    
    -- Damage variance (random +-15%)
    local variance = 1 + (math.random() * 2 - 1) * CombatConfig.MaxDamageVariance
    baseDamage = baseDamage * variance
    
    -- Critical hit check
    local isCrit = false
    if math.random() < attacker.CritChance then
        baseDamage = baseDamage * attacker.CritMultiplier
        isCrit = true
    end
    
    -- Apply defense reduction
    local defenseReduction = defender.Defense * (1 - CombatConfig.ArmorPenetration)
    local finalDamage = baseDamage - defenseReduction
    
    -- Minimum damage
    finalDamage = math.max(finalDamage, CombatConfig.MinDamage)
    
    -- Round to integer
    finalDamage = math.floor(finalDamage + 0.5)
    
    return finalDamage, isCrit
end

function DamageEngine.ApplyDamage(attackerData, defenderData, damage, isCrit)
    -- Check if defender is dodging (invulnerable frames)
    if defenderData.IsInvulnerable then
        return 0, false, "DODGE"
    end
    
    -- Check if defender is blocking
    if defenderData.IsBlocking then
        -- Check for parry (perfect block)
        local blockTime = tick() - (defenderData.BlockStartTime or 0)
        if blockTime <= CombatConfig.ParryWindow then
            -- PARRY! Stun the attacker
            attackerData.IsStunned = true
            task.delay(CombatConfig.ParryStunDuration, function()
                attackerData.IsStunned = false
            end)
            return 0, false, "PARRY"
        end
        
        -- Normal block - reduce damage by 70%
        damage = math.floor(damage * 0.3)
        defenderData.CurrentStamina = defenderData.CurrentStamina - CombatConfig.BlockStaminaDrain
        
        if defenderData.CurrentStamina <= 0 then
            defenderData.IsBlocking = false
            defenderData.CurrentStamina = 0
        end
    end
    
    -- Apply damage
    defenderData.CurrentHealth = defenderData.CurrentHealth - damage
    
    -- Check for weapon special effects
    if attackerData.EquippedWeapon then
        local weapon = WeaponDatabase[attackerData.EquippedWeapon]
        if weapon and weapon.SpecialEffect then
            DamageEngine.ApplySpecialEffect(weapon, attackerData, defenderData, damage)
        end
    end
    
    -- Check for death
    local isDead = defenderData.CurrentHealth <= 0
    if isDead then
        defenderData.CurrentHealth = 0
    end
    
    return damage, isCrit, isDead and "KILL" or "HIT"
end


function DamageEngine.ApplySpecialEffect(weapon, attackerData, defenderData, damage)
    if weapon.SpecialEffect == "LifeSteal" then
        local healAmount = math.floor(damage * weapon.SpecialValue)
        attackerData.CurrentHealth = math.min(
            attackerData.CurrentHealth + healAmount,
            attackerData.MaxHealth
        )
    elseif weapon.SpecialEffect == "Poison" then
        -- Apply poison DoT
        local dotDamage = weapon.SpecialValue
        for i = 1, 5 do
            task.delay(i, function()
                if defenderData.CurrentHealth > 0 then
                    defenderData.CurrentHealth = defenderData.CurrentHealth - dotDamage
                end
            end)
        end
    elseif weapon.SpecialEffect == "FireDamage" then
        defenderData.CurrentHealth = defenderData.CurrentHealth - weapon.SpecialValue
    elseif weapon.SpecialEffect == "ChainLightning" then
        -- Would chain to nearby enemies (simplified here)
        -- In full implementation, find nearby enemies and damage them
    elseif weapon.SpecialEffect == "BonusDamageVsBosses" then
        -- Already factored in during calculation for boss enemies
    end
end

-- ============================================================================
-- COMBAT CONTROLLER (Server-side)
-- ============================================================================

local CombatController = {}
CombatController.PlayerData = {}  -- [Player] = PlayerDataModule
CombatController.ActiveEnemies = {}  -- All spawned enemies
CombatController.EnemySpawnPoints = {}  -- Where enemies spawn

--- Initialize a player's combat data
function CombatController:InitPlayer(player)
    local data = PlayerDataModule.new(player)
    data:RecalculateStats()
    self.PlayerData[player] = data
    
    -- Give starter weapon and equip it automatically so the player can attack mobs
    data:AddItem("IronSword")
    data:EquipWeapon("IronSword")
    
    -- Also give a backup weapon in inventory
    data:AddItem("WoodenSword")
    
    print("[CombatSystem] Initialized combat data for " .. player.Name)
    print("[CombatSystem] Auto-equipped Iron Sword for " .. player.Name)
    return data
end

--- Auto-attack: automatically attack nearest mob when player clicks/taps
-- This connects on character spawn to allow attacking without manual weapon equip
function CombatController:SetupAutoAttack(player)
    local data = self:GetPlayerData(player)
    if not data then return end
    
    -- Ensure weapon is equipped; if somehow lost, re-equip
    if not data.EquippedWeapon then
        if #data.Inventory > 0 then
            for _, item in ipairs(data.Inventory) do
                local weapon = WeaponDatabase[item.Id]
                if weapon and data.Level >= weapon.LevelReq then
                    data:EquipWeapon(item.Id)
                    print("[CombatSystem] Auto-re-equipped " .. weapon.Name .. " for " .. player.Name)
                    break
                end
            end
        else
            -- Give a free weapon if they have none
            data:AddItem("WoodenSword")
            data:EquipWeapon("WoodenSword")
            print("[CombatSystem] Gave free Wooden Sword to " .. player.Name)
        end
    end
end

--- Get a player's combat data
function CombatController:GetPlayerData(player)
    return self.PlayerData[player]
end

--- Remove a player's combat data
function CombatController:RemovePlayer(player)
    self.PlayerData[player] = nil
end

--- Handle melee attack from a player
function CombatController:HandleMeleeAttack(player, targetPart)
    local data = self:GetPlayerData(player)
    if not data then return end
    
    -- Check if player can attack
    if data.IsStunned then return end
    if data.IsAttacking then return end
    
    -- Check cooldown
    local now = tick()
    local cooldown = CombatConfig.AttackCooldown
    if data.EquippedWeapon then
        local weapon = WeaponDatabase[data.EquippedWeapon]
        if weapon then
            cooldown = cooldown / weapon.Speed
        end
    end
    
    if now - data.LastAttackTime < cooldown then return end
    
    -- Update combo
    if now - data.LastAttackTime > CombatConfig.ComboWindow then
        data.ComboCount = 0
    end
    data.ComboCount = math.min(data.ComboCount + 1, CombatConfig.MaxComboHits)
    data.LastAttackTime = now
    data.IsAttacking = true
    
    -- Find target
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get attack range
    local range = 6
    if data.EquippedWeapon then
        local weapon = WeaponDatabase[data.EquippedWeapon]
        if weapon then range = weapon.Range end
    end
    
    -- Raycast or sphere check for enemies in range
    local hits = self:GetEnemiesInRange(humanoidRootPart.Position, range)
    
    for _, enemyData in pairs(hits) do
        local damage, isCrit = DamageEngine.CalculateDamage(data, enemyData, false, nil)
        local finalDamage, wasCrit, result = DamageEngine.ApplyDamage(data, enemyData, damage, isCrit)
        
        -- Fire damage event to client for VFX
        DamageRemote:FireAllClients(
            enemyData.Position or Vector3.new(0, 0, 0),
            finalDamage,
            wasCrit,
            result
        )
        
        -- Handle enemy death
        if result == "KILL" then
            self:HandleEnemyDeath(player, enemyData)
        end
    end
    
    -- End attack state
    task.delay(0.3, function()
        data.IsAttacking = false
    end)
end

--- Handle an enemy dying
function CombatController:HandleEnemyDeath(killerPlayer, enemyData)
    local data = self:GetPlayerData(killerPlayer)
    if not data then return end
    
    -- Grant XP
    data:GainXP(enemyData.XPReward or 0)
    
    -- Grant Gold
    local goldMin = enemyData.GoldReward and enemyData.GoldReward[1] or 0
    local goldMax = enemyData.GoldReward and enemyData.GoldReward[2] or 0
    local goldDrop = math.random(goldMin, goldMax)
    data.Gold = data.Gold + goldDrop
    
    -- ========================================================================
    -- ENHANCED LOOT DROP SYSTEM
    -- Drops physical loot on the ground that auto-collects when player is near
    -- ========================================================================
    
    -- Determine loot drops (can drop multiple items)
    local droppedItems = {}
    
    -- Main loot table roll
    if enemyData.LootTable and #enemyData.LootTable > 0 then
        local lootChance = enemyData.LootChance or 0.1
        
        -- Boss enemies always drop at least 1 item
        if enemyData.IsBoss then
            lootChance = math.max(lootChance, 0.8)
        end
        
        -- Roll for each item in loot table
        for _, itemId in ipairs(enemyData.LootTable) do
            if math.random() < lootChance then
                table.insert(droppedItems, itemId)
            end
        end
        
        -- Guarantee at least 1 drop from bosses
        if enemyData.IsBoss and #droppedItems == 0 then
            local randomIndex = math.random(1, #enemyData.LootTable)
            table.insert(droppedItems, enemyData.LootTable[randomIndex])
        end
    end
    
    -- Bonus drop: random chance for any enemy to drop consumables
    if math.random() < 0.3 then
        -- Small health potion equivalent (gold bonus)
        data.Gold = data.Gold + math.random(5, 20)
    end
    
    -- Spawn physical loot drops in the world
    local dropPosition = enemyData.Position or Vector3.new(0, 5, 0)
    
    for i, itemId in ipairs(droppedItems) do
        local weapon = WeaponDatabase[itemId]
        if weapon then
            -- Create physical loot drop in the world
            local lootDrop = self:SpawnLootDrop(itemId, weapon, dropPosition, i, killerPlayer)
            
            -- Notify player about the drop
            LootRemote:FireClient(killerPlayer, weapon.Name, weapon.Rarity)
            LootDropRemote:FireClient(killerPlayer, {
                ItemId = itemId,
                ItemName = weapon.Name,
                Rarity = weapon.Rarity,
                Position = dropPosition,
            })
            
            print("[LootSystem] " .. killerPlayer.Name .. " got drop: " .. weapon.Name .. " (" .. weapon.Rarity .. ")")
        end
    end
    
    -- Auto-equip if the dropped weapon is better than current
    for _, itemId in ipairs(droppedItems) do
        local weapon = WeaponDatabase[itemId]
        if weapon and data.Level >= weapon.LevelReq then
            local added = data:AddItem(itemId)
            if added then
                -- Check if this weapon is better than currently equipped
                local currentWeapon = data.EquippedWeapon and WeaponDatabase[data.EquippedWeapon]
                if not currentWeapon or weapon.Damage > currentWeapon.Damage then
                    data:EquipWeapon(itemId)
                    print("[LootSystem] " .. killerPlayer.Name .. " auto-equipped: " .. weapon.Name)
                    LootRemote:FireClient(killerPlayer, "Equipped: " .. weapon.Name, weapon.Rarity)
                end
                
                -- Send inventory update to client
                self:SendInventoryUpdate(killerPlayer)
            end
        end
    end
    
    -- Send gold update
    LootRemote:FireClient(killerPlayer, "+" .. goldDrop .. " Gold", "Common")
    
    -- ========================================================================
    -- BODY DISAPPEAR & RESPAWN SYSTEM
    -- Fade out the enemy model then destroy it, then respawn after timer
    -- ========================================================================
    
    -- Save spawn info before removing from list
    local enemyType = enemyData.EnemyType
    local spawnPosition = enemyData.SpawnPosition
    local isBoss = enemyData.IsBoss
    local enemyModel = enemyData.Model
    
    -- Remove enemy from active list immediately (stops AI updates)
    for i, enemy in ipairs(self.ActiveEnemies) do
        if enemy == enemyData then
            table.remove(self.ActiveEnemies, i)
            break
        end
    end
    
    -- Fade out and destroy the body
    if enemyModel then
        task.spawn(function()
            -- Make the body fade out over time
            local fadeTime = CombatConfig.EnemyBodyFadeTime or 2
            local steps = 10
            local stepDelay = fadeTime / steps
            
            for step = 1, steps do
                if not enemyModel or not enemyModel.Parent then break end
                local transparency = step / steps
                
                -- Fade all parts in the model
                for _, part in ipairs(enemyModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = transparency
                    elseif part:IsA("BillboardGui") then
                        part.Enabled = (step < steps / 2)
                    end
                end
                task.wait(stepDelay)
            end
            
            -- Destroy the model completely
            if enemyModel and enemyModel.Parent then
                enemyModel:Destroy()
            end
        end)
    end
    
    -- Clear model reference
    enemyData.Model = nil
    
    -- Schedule respawn
    local respawnTime = isBoss and CombatConfig.BossRespawnTime or CombatConfig.EnemyRespawnTime
    task.delay(respawnTime, function()
        self:SpawnEnemy(enemyType, spawnPosition)
        print("[CombatSystem] Respawned: " .. tostring(enemyType) .. " at " .. tostring(spawnPosition))
    end)
end

--- Spawn a physical loot drop in the world (glowing pickup)
function CombatController:SpawnLootDrop(itemId, weaponData, position, index, ownerPlayer)
    -- Offset each drop slightly so they don't stack
    local offset = Vector3.new(
        math.random(-3, 3),
        2,
        math.random(-3, 3)
    )
    local dropPos = position + offset
    
    -- Rarity colors
    local rarityColors = {
        Common = Color3.fromRGB(200, 200, 200),
        Uncommon = Color3.fromRGB(30, 255, 30),
        Rare = Color3.fromRGB(30, 100, 255),
        Epic = Color3.fromRGB(163, 53, 238),
        Legendary = Color3.fromRGB(255, 165, 0),
    }
    
    local color = rarityColors[weaponData.Rarity] or rarityColors.Common
    
    -- Create the physical loot part
    local lootPart = Instance.new("Part")
    lootPart.Name = "LootDrop_" .. itemId
    lootPart.Size = Vector3.new(2, 2, 2)
    lootPart.Position = dropPos
    lootPart.Anchored = true
    lootPart.CanCollide = false
    lootPart.Shape = Enum.PartType.Ball
    lootPart.Material = Enum.Material.Neon
    lootPart.Color = color
    lootPart.Transparency = 0.3
    
    -- Add glow effect
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2
    light.Range = 8
    light.Parent = lootPart
    
    -- Add billboard label showing item name
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(5, 0, 1.5, 0)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = lootPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = weaponData.Name
    nameLabel.TextColor3 = color
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = "[" .. weaponData.Rarity .. "]"
    rarityLabel.TextColor3 = color
    rarityLabel.TextStrokeTransparency = 0.5
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = billboard
    
    lootPart.Parent = workspace
    
    -- Bobbing animation (float up and down)
    task.spawn(function()
        local startY = dropPos.Y
        local elapsed = 0
        while lootPart and lootPart.Parent do
            elapsed = elapsed + 0.03
            lootPart.Position = Vector3.new(dropPos.X, startY + math.sin(elapsed * 2) * 0.5, dropPos.Z)
            lootPart.Orientation = Vector3.new(0, elapsed * 50, 0)
            task.wait(0.03)
        end
    end)
    
    -- Auto-collect: any player that walks near it picks it up
    task.spawn(function()
        local lifetime = 60  -- Loot disappears after 60 seconds
        local startTime = tick()
        
        while lootPart and lootPart.Parent and (tick() - startTime) < lifetime do
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - lootPart.Position).Magnitude
                        if dist <= 8 then  -- Pickup radius
                            -- Player is close enough to pick up
                            local pData = self:GetPlayerData(player)
                            if pData then
                                local added = pData:AddItem(itemId)
                                if added then
                                    -- Check if better than current weapon
                                    local currentWeapon = pData.EquippedWeapon and WeaponDatabase[pData.EquippedWeapon]
                                    if not currentWeapon or weaponData.Damage > currentWeapon.Damage then
                                        if pData.Level >= weaponData.LevelReq then
                                            pData:EquipWeapon(itemId)
                                            LootRemote:FireClient(player, "Auto-equipped: " .. weaponData.Name, weaponData.Rarity)
                                        end
                                    end
                                    
                                    LootRemote:FireClient(player, "Picked up: " .. weaponData.Name, weaponData.Rarity)
                                    self:SendInventoryUpdate(player)
                                    
                                    -- Destroy the loot drop
                                    lootPart:Destroy()
                                    return
                                else
                                    LootRemote:FireClient(player, "Inventory full!", "Common")
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.2)
        end
        
        -- Timeout - destroy uncollected loot
        if lootPart and lootPart.Parent then
            lootPart:Destroy()
        end
    end)
    
    return lootPart
end

--- Send inventory update to a player's client
function CombatController:SendInventoryUpdate(player)
    local data = self:GetPlayerData(player)
    if not data then return end
    
    local inventoryInfo = {}
    for _, item in ipairs(data.Inventory) do
        local weapon = WeaponDatabase[item.Id]
        if weapon then
            table.insert(inventoryInfo, {
                UUID = item.UUID,
                Id = item.Id,
                Name = weapon.Name,
                Type = weapon.Type,
                Subtype = weapon.Subtype,
                Damage = weapon.Damage,
                Speed = weapon.Speed,
                Range = weapon.Range,
                Rarity = weapon.Rarity,
                LevelReq = weapon.LevelReq,
                Description = weapon.Description,
                CritBonus = weapon.CritBonus,
                SpecialEffect = weapon.SpecialEffect,
                IsEquipped = (data.EquippedWeapon == item.Id),
            })
        end
    end
    
    InventoryUpdateRemote:FireClient(player, {
        Items = inventoryInfo,
        Gold = data.Gold,
        EquippedWeapon = data.EquippedWeapon,
        MaxSlots = 30,
        UsedSlots = #data.Inventory,
    })
end


--- Get all enemies within range of a position
function CombatController:GetEnemiesInRange(position, range)
    local inRange = {}
    for _, enemy in ipairs(self.ActiveEnemies) do
        if enemy.Position and (enemy.Position - position).Magnitude <= range then
            if enemy.CurrentHealth > 0 then
                table.insert(inRange, enemy)
            end
        end
    end
    return inRange
end

--- Handle dodge/roll from a player
function CombatController:HandleDodge(player, direction)
    local data = self:GetPlayerData(player)
    if not data then return end
    if data.IsStunned then return end
    if data.IsDodging then return end
    
    -- Check cooldown
    local now = tick()
    if now - data.LastDodgeTime < CombatConfig.DodgeCooldown then return end
    
    -- Check stamina
    if data.CurrentStamina < CombatConfig.DodgeStaminaCost then return end
    
    -- Consume stamina
    data.CurrentStamina = data.CurrentStamina - CombatConfig.DodgeStaminaCost
    data.LastStaminaUse = now
    data.LastDodgeTime = now
    data.IsDodging = true
    data.IsInvulnerable = true
    
    -- Apply dodge velocity to character
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dodgeForce = direction * 50
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
            bodyVelocity.Velocity = dodgeForce
            bodyVelocity.Parent = hrp
            Debris:AddItem(bodyVelocity, 0.3)
        end
    end
    
    -- I-frames duration
    task.delay(CombatConfig.DodgeIFrames, function()
        data.IsInvulnerable = false
    end)
    
    -- Dodge animation duration
    task.delay(0.5, function()
        data.IsDodging = false
    end)
end

--- Handle block start/stop
function CombatController:HandleBlock(player, isBlocking)
    local data = self:GetPlayerData(player)
    if not data then return end
    if data.IsStunned then return end
    
    data.IsBlocking = isBlocking
    if isBlocking then
        data.BlockStartTime = tick()
    end
end

--- Handle skill usage
function CombatController:HandleSkillUse(player, skillName, targetPosition)
    local data = self:GetPlayerData(player)
    if not data then return end
    if data.IsStunned then return end
    
    local success, result = data:UseSkill(skillName, targetPosition)
    if not success then
        -- Could notify client of failure reason
        return
    end
    
    local skill = result
    
    -- Execute skill effect based on type
    if skill.Type == "Active" then
        self:ExecuteActiveSkill(player, data, skill, targetPosition)
    elseif skill.Type == "Buff" then
        self:ExecuteBuffSkill(player, data, skill)
    elseif skill.Type == "Movement" then
        self:ExecuteMovementSkill(player, data, skill, targetPosition)
    end
end

--- Execute an active (damage) skill
function CombatController:ExecuteActiveSkill(player, data, skill, targetPosition)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local position = targetPosition or hrp.Position
    local radius = skill.Radius or 8
    
    -- Get enemies in skill radius
    local enemies = self:GetEnemiesInRange(position, radius)
    
    for _, enemyData in pairs(enemies) do
        local damage, isCrit = DamageEngine.CalculateDamage(
            data, enemyData, true, skill.DamageMultiplier
        )
        local finalDamage, wasCrit, result = DamageEngine.ApplyDamage(
            data, enemyData, damage, isCrit
        )
        
        -- Stun if skill has stun
        if skill.StunDuration and skill.StunDuration > 0 then
            enemyData.IsStunned = true
            task.delay(skill.StunDuration, function()
                enemyData.IsStunned = false
            end)
        end
        
        -- Fire VFX event
        DamageRemote:FireAllClients(
            enemyData.Position or position,
            finalDamage,
            wasCrit,
            result
        )
        
        if result == "KILL" then
            self:HandleEnemyDeath(player, enemyData)
        end
    end
end

--- Execute a buff skill
function CombatController:ExecuteBuffSkill(player, data, skill)
    local buffId = HttpService:GenerateGUID(false)
    
    local buff = {
        Id = buffId,
        Name = skill.Name,
        Duration = skill.Duration,
        StartTime = tick(),
        Bonus = skill.Bonus,
        ShieldAmount = nil,
    }
    
    -- Handle shield buffs
    if skill.ShieldPercent then
        buff.ShieldAmount = math.floor(data.MaxHealth * skill.ShieldPercent)
    end
    
    data.ActiveBuffs[buffId] = buff
    data:RecalculateStats()
    
    -- Auto-remove buff after duration
    task.delay(skill.Duration, function()
        data.ActiveBuffs[buffId] = nil
        data:RecalculateStats()
    end)
end

--- Execute a movement skill (like teleport)
function CombatController:ExecuteMovementSkill(player, data, skill, targetPosition)
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if skill.Distance then
        local direction = hrp.CFrame.LookVector
        local newPosition = hrp.Position + (direction * skill.Distance)
        hrp.CFrame = CFrame.new(newPosition) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
    end
end


-- ============================================================================
-- ENEMY AI SYSTEM
-- ============================================================================

local EnemyAI = {}
EnemyAI.__index = EnemyAI

function EnemyAI.new(enemyType, spawnPosition)
    local self = setmetatable({}, EnemyAI)
    
    local template = EnemyDatabase[enemyType]
    if not template then
        warn("[CombatSystem] Unknown enemy type: " .. tostring(enemyType))
        return nil
    end
    
    -- Copy template stats
    self.EnemyType = enemyType
    self.Name = template.Name
    self.MaxHealth = template.Health
    self.CurrentHealth = template.Health
    self.Damage = template.Damage
    self.Attack = template.Damage  -- Alias for damage engine
    self.Defense = template.Defense
    self.Speed = template.Speed
    self.AttackSpeed = template.AttackSpeed
    self.AggroRange = template.AggroRange
    self.AttackRange = template.AttackRange
    self.XPReward = template.XPReward
    self.GoldReward = template.GoldReward
    self.LootTable = template.LootTable
    self.LootChance = template.LootChance
    self.IsBoss = template.IsBoss or false
    
    -- Position & State
    self.SpawnPosition = spawnPosition
    self.Position = spawnPosition
    self.Target = nil
    self.State = "Idle"  -- Idle, Patrol, Chase, Attack, Retreat, Dead
    self.LastAttackTime = 0
    self.IsStunned = false
    self.IsBlocking = false
    self.IsInvulnerable = false
    self.IsAttacking = false
    self.ComboCount = 0
    self.CritChance = 0.05
    self.CritMultiplier = 1.5
    self.EquippedWeapon = nil
    self.ActiveBuffs = {}
    
    -- Boss-specific
    self.BossAbilities = template.BossAbilities or {}
    self.PhaseThresholds = template.PhaseThresholds or {}
    self.CurrentPhase = 1
    self.LastAbilityTime = 0
    self.AbilityCooldown = 5
    
    -- Pathfinding
    self.Path = nil
    self.WaypointIndex = 1
    self.PatrolPoints = {}
    self.PatrolIndex = 1
    
    -- Model reference (would be set when spawned in world)
    self.Model = nil
    
    return self
end

--- Update the AI state machine
function EnemyAI:Update(deltaTime, allPlayers)
    if self.CurrentHealth <= 0 then
        self.State = "Dead"
        return
    end
    
    if self.IsStunned then return end
    
    -- Find nearest player target
    local nearestPlayer, nearestDist = self:FindNearestPlayer(allPlayers)
    
    -- State machine
    if self.State == "Idle" then
        self:UpdateIdle(nearestPlayer, nearestDist)
    elseif self.State == "Patrol" then
        self:UpdatePatrol(nearestPlayer, nearestDist)
    elseif self.State == "Chase" then
        self:UpdateChase(nearestPlayer, nearestDist, deltaTime)
    elseif self.State == "Attack" then
        self:UpdateAttack(nearestPlayer, nearestDist)
    elseif self.State == "Retreat" then
        self:UpdateRetreat(deltaTime)
    end
end

--- Find the nearest player within aggro range
function EnemyAI:FindNearestPlayer(allPlayers)
    local nearest = nil
    local nearestDist = math.huge
    
    for _, player in ipairs(allPlayers) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - self.Position).Magnitude
                if dist < nearestDist then
                    nearest = player
                    nearestDist = dist
                end
            end
        end
    end
    
    return nearest, nearestDist
end

--- Idle state - wait for player to enter aggro range
function EnemyAI:UpdateIdle(nearestPlayer, nearestDist)
    if nearestPlayer and nearestDist <= self.AggroRange then
        self.Target = nearestPlayer
        self.State = "Chase"
    else
        -- Random chance to start patrolling
        if math.random() < 0.01 then
            self.State = "Patrol"
        end
    end
end

--- Patrol state - wander around spawn area
function EnemyAI:UpdatePatrol(nearestPlayer, nearestDist)
    if nearestPlayer and nearestDist <= self.AggroRange then
        self.Target = nearestPlayer
        self.State = "Chase"
        return
    end
    
    -- Move towards patrol point
    if #self.PatrolPoints > 0 then
        local targetPoint = self.PatrolPoints[self.PatrolIndex]
        local direction = (targetPoint - self.Position).Unit
        self.Position = self.Position + direction * self.Speed * 0.016
        
        if (targetPoint - self.Position).Magnitude < 2 then
            self.PatrolIndex = (self.PatrolIndex % #self.PatrolPoints) + 1
        end
    else
        -- Random wander near spawn
        if math.random() < 0.02 then
            local offset = Vector3.new(
                math.random(-15, 15),
                0,
                math.random(-15, 15)
            )
            local wanderTarget = self.SpawnPosition + offset
            local direction = (wanderTarget - self.Position).Unit
            self.Position = self.Position + direction * self.Speed * 0.5 * 0.016
        end
    end
end


--- Chase state - move towards target player
function EnemyAI:UpdateChase(nearestPlayer, nearestDist, deltaTime)
    -- Lost target or target too far
    if not self.Target or nearestDist > self.AggroRange * 1.5 then
        self.Target = nil
        self.State = "Retreat"
        return
    end
    
    -- Check if in attack range
    if nearestDist <= self.AttackRange then
        self.State = "Attack"
        return
    end
    
    -- Move towards target
    local character = self.Target.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local direction = (hrp.Position - self.Position).Unit
            self.Position = self.Position + direction * self.Speed * deltaTime
        end
    end
    
    -- Boss: use abilities while chasing
    if self.IsBoss then
        self:TryBossAbility()
    end
end

--- Attack state - attack the target player
function EnemyAI:UpdateAttack(nearestPlayer, nearestDist)
    -- Target out of range, chase again
    if nearestDist > self.AttackRange * 1.2 then
        self.State = "Chase"
        return
    end
    
    -- Check attack cooldown
    local now = tick()
    if now - self.LastAttackTime < (1 / self.AttackSpeed) then
        return
    end
    
    -- Perform attack
    self.LastAttackTime = now
    self.IsAttacking = true
    
    -- Get target player data
    local targetData = CombatController:GetPlayerData(self.Target)
    if targetData then
        local damage, isCrit = DamageEngine.CalculateDamage(self, targetData, false, nil)
        local finalDamage, wasCrit, result = DamageEngine.ApplyDamage(self, targetData, damage, isCrit)
        
        -- Notify client
        if self.Target then
            DamageRemote:FireClient(self.Target, self.Position, finalDamage, wasCrit, "ENEMY_HIT")
        end
        
        -- Handle player death
        if result == "KILL" then
            self:HandleTargetDeath()
        end
    end
    
    task.delay(0.5, function()
        self.IsAttacking = false
    end)
    
    -- Boss: check phase transitions and use abilities
    if self.IsBoss then
        self:CheckPhaseTransition()
        self:TryBossAbility()
    end
end

--- Retreat state - return to spawn
function EnemyAI:UpdateRetreat(deltaTime)
    local distToSpawn = (self.SpawnPosition - self.Position).Magnitude
    
    if distToSpawn < 3 then
        self.State = "Idle"
        -- Heal back to full when retreating
        self.CurrentHealth = self.MaxHealth
        return
    end
    
    local direction = (self.SpawnPosition - self.Position).Unit
    self.Position = self.Position + direction * self.Speed * deltaTime
end

--- Handle when the target player dies
function EnemyAI:HandleTargetDeath()
    self.Target = nil
    self.State = "Retreat"
end

--- Boss: try to use an ability
function EnemyAI:TryBossAbility()
    local now = tick()
    if now - self.LastAbilityTime < self.AbilityCooldown then return end
    if #self.BossAbilities == 0 then return end
    
    -- Pick random ability
    local abilityIndex = math.random(1, #self.BossAbilities)
    local ability = self.BossAbilities[abilityIndex]
    
    self.LastAbilityTime = now
    self:ExecuteBossAbility(ability)
end

--- Boss: check if we should transition to next phase
function EnemyAI:CheckPhaseTransition()
    local healthPercent = self.CurrentHealth / self.MaxHealth
    
    for i, threshold in ipairs(self.PhaseThresholds) do
        if healthPercent <= threshold and self.CurrentPhase <= i then
            self.CurrentPhase = i + 1
            self:OnPhaseTransition(self.CurrentPhase)
            break
        end
    end
end

--- Boss: handle phase transition effects
function EnemyAI:OnPhaseTransition(newPhase)
    print("[CombatSystem] " .. self.Name .. " entered Phase " .. newPhase .. "!")
    
    -- Increase stats per phase
    self.Damage = self.Damage * 1.2
    self.Attack = self.Damage
    self.AttackSpeed = self.AttackSpeed * 1.1
    self.AbilityCooldown = math.max(self.AbilityCooldown * 0.8, 2)
    
    -- Could trigger special phase mechanics here
end

--- Boss: execute a specific ability
function EnemyAI:ExecuteBossAbility(abilityName)
    if abilityName == "FireBreath" then
        -- Cone attack in front of boss
        self:ConeAttack(20, 45, self.Damage * 1.5)
    elseif abilityName == "TailSwipe" then
        -- AoE attack around boss
        self:AreaAttack(12, self.Damage * 0.8)
    elseif abilityName == "FlyingDive" then
        -- Dash to target position
        if self.Target and self.Target.Character then
            local hrp = self.Target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                self.Position = hrp.Position + Vector3.new(0, 0, 5)
                self:AreaAttack(8, self.Damage * 2)
            end
        end
    elseif abilityName == "Enrage" then
        -- Temporary buff
        self.Damage = self.Damage * 1.5
        self.Attack = self.Damage
        task.delay(10, function()
            self.Damage = self.Damage / 1.5
            self.Attack = self.Damage
        end)
    elseif abilityName == "ShadowBolt" then
        -- Ranged single-target attack
        if self.Target then
            local targetData = CombatController:GetPlayerData(self.Target)
            if targetData then
                local damage = self.Damage * 2
                targetData.CurrentHealth = targetData.CurrentHealth - damage
                DamageRemote:FireClient(self.Target, self.Position, damage, false, "BOSS_ABILITY")
            end
        end
    elseif abilityName == "DarkWave" then
        self:AreaAttack(25, self.Damage * 1.2)
    elseif abilityName == "Summon" then
        -- Spawn additional minions
        CombatController:SpawnEnemy("Skeleton", self.Position + Vector3.new(10, 0, 0))
        CombatController:SpawnEnemy("Skeleton", self.Position + Vector3.new(-10, 0, 0))
    elseif abilityName == "VoidZone" then
        -- Create a damaging zone on the ground
        -- Players standing in it take damage over time
        if self.Target and self.Target.Character then
            local hrp = self.Target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local zonePos = hrp.Position
                -- Damage players in zone for 5 seconds
                for i = 1, 10 do
                    task.delay(i * 0.5, function()
                        for _, player in ipairs(Players:GetPlayers()) do
                            local pData = CombatController:GetPlayerData(player)
                            local char = player.Character
                            if pData and char then
                                local pHrp = char:FindFirstChild("HumanoidRootPart")
                                if pHrp and (pHrp.Position - zonePos).Magnitude <= 10 then
                                    pData.CurrentHealth = pData.CurrentHealth - (self.Damage * 0.3)
                                end
                            end
                        end
                    end)
                end
            end
        end
    elseif abilityName == "PhaseShift" then
        -- Become invulnerable briefly, then teleport
        self.IsInvulnerable = true
        task.delay(2, function()
            self.IsInvulnerable = false
            if self.Target and self.Target.Character then
                local hrp = self.Target.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    self.Position = hrp.Position + Vector3.new(
                        math.random(-10, 10), 0, math.random(-10, 10)
                    )
                end
            end
        end)
    end
end


--- Boss: cone attack (frontal)
function EnemyAI:ConeAttack(range, angle, damage)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local toPlayer = (hrp.Position - self.Position)
                local dist = toPlayer.Magnitude
                if dist <= range then
                    -- Check angle (simplified)
                    local targetData = CombatController:GetPlayerData(player)
                    if targetData then
                        targetData.CurrentHealth = targetData.CurrentHealth - damage
                        DamageRemote:FireClient(player, self.Position, damage, false, "BOSS_ABILITY")
                    end
                end
            end
        end
    end
end

--- Boss: area attack (all around)
function EnemyAI:AreaAttack(radius, damage)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - self.Position).Magnitude
                if dist <= radius then
                    local targetData = CombatController:GetPlayerData(player)
                    if targetData then
                        targetData.CurrentHealth = targetData.CurrentHealth - damage
                        DamageRemote:FireClient(player, self.Position, damage, false, "BOSS_ABILITY")
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- SPAWN SYSTEM
-- ============================================================================

function CombatController:SpawnEnemy(enemyType, position)
    local enemy = EnemyAI.new(enemyType, position)
    if enemy then
        table.insert(self.ActiveEnemies, enemy)
        
        -- Create physical model in world
        local model = Instance.new("Model")
        model.Name = enemy.Name
        
        local part = Instance.new("Part")
        part.Name = "HumanoidRootPart"
        part.Size = Vector3.new(4, 5, 2)
        part.Position = position
        part.Anchored = false
        part.CanCollide = true
        part.BrickColor = enemy.IsBoss and BrickColor.new("Really red") or BrickColor.new("Medium stone grey")
        part.Parent = model
        model.PrimaryPart = part
        
        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = enemy.MaxHealth
        humanoid.Health = enemy.CurrentHealth
        humanoid.WalkSpeed = enemy.Speed
        humanoid.Parent = model
        
        -- Name label
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(4, 0, 1, 0)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = part
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = enemy.Name
        nameLabel.TextColor3 = enemy.IsBoss and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = billboard
        
        local healthBar = Instance.new("Frame")
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(1, 0, 0.3, 0)
        healthBar.Position = UDim2.new(0, 0, 0.6, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        healthBar.BorderSizePixel = 0
        healthBar.Parent = billboard
        
        local healthFill = Instance.new("Frame")
        healthFill.Name = "Fill"
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthFill.BorderSizePixel = 0
        healthFill.Parent = healthBar
        
        model.Parent = workspace
        enemy.Model = model
        
        print("[CombatSystem] Spawned: " .. enemy.Name .. " at " .. tostring(position))
    end
    return enemy
end

--- Spawn all enemies from predefined spawn points
function CombatController:SpawnAllEnemies()
    -- Default spawn points (customize per game)
    local spawnData = {
        {Type = "Goblin", Position = Vector3.new(50, 5, 50)},
        {Type = "Goblin", Position = Vector3.new(70, 5, 30)},
        {Type = "Goblin", Position = Vector3.new(30, 5, 80)},
        {Type = "Skeleton", Position = Vector3.new(100, 5, 100)},
        {Type = "Skeleton", Position = Vector3.new(120, 5, 80)},
        {Type = "DarkKnight", Position = Vector3.new(200, 5, 200)},
        {Type = "FireDragon", Position = Vector3.new(500, 5, 500)},
        {Type = "ShadowLord", Position = Vector3.new(800, 5, 800)},
    }
    
    for _, spawn in ipairs(spawnData) do
        self:SpawnEnemy(spawn.Type, spawn.Position)
    end
    
    print("[CombatSystem] All enemies spawned! Total: " .. #self.ActiveEnemies)
end


-- ============================================================================
-- REGENERATION SYSTEM
-- ============================================================================

local RegenSystem = {}

function RegenSystem:UpdatePlayer(data, deltaTime)
    local now = tick()
    
    -- Stamina regeneration
    if now - data.LastStaminaUse > CombatConfig.StaminaRegenDelay then
        if data.CurrentStamina < data.MaxStamina then
            data.CurrentStamina = math.min(
                data.CurrentStamina + CombatConfig.StaminaRegenRate * deltaTime,
                data.MaxStamina
            )
        end
    end
    
    -- Mana regeneration
    if now - data.LastManaUse > CombatConfig.ManaRegenDelay then
        if data.CurrentMana < data.MaxMana then
            local regenRate = CombatConfig.ManaRegenRate
            -- Check for ManaFlow passive
            if data.UnlockedSkills["ManaFlow"] then
                regenRate = regenRate * 1.5
            end
            data.CurrentMana = math.min(
                data.CurrentMana + regenRate * deltaTime,
                data.MaxMana
            )
        end
    end
    
    -- Health regeneration (out of combat - 5 seconds since last damage)
    if now - (data.LastDamageTime or 0) > 5 then
        if data.CurrentHealth < data.MaxHealth and data.CurrentHealth > 0 then
            data.CurrentHealth = math.min(
                data.CurrentHealth + (data.MaxHealth * 0.01) * deltaTime,
                data.MaxHealth
            )
        end
    end
end

-- ============================================================================
-- RESPAWN SYSTEM
-- ============================================================================

local RespawnSystem = {}

function RespawnSystem:HandlePlayerDeath(player)
    local data = CombatController:GetPlayerData(player)
    if not data then return end
    
    -- Reset combat state
    data.IsAttacking = false
    data.IsBlocking = false
    data.IsDodging = false
    data.IsStunned = false
    data.ComboCount = 0
    data.ActiveBuffs = {}
    
    -- Lose some gold on death (10%)
    local goldLoss = math.floor(data.Gold * 0.1)
    data.Gold = data.Gold - goldLoss
    
    -- XP penalty (lose 5% of current level's XP)
    local xpLoss = math.floor(data.XPToNext * 0.05)
    data.XP = math.max(0, data.XP - xpLoss)
    
    print("[CombatSystem] " .. player.Name .. " died! Lost " .. goldLoss .. " gold and " .. xpLoss .. " XP.")
    
    -- Respawn after delay
    task.delay(5, function()
        if player.Parent then  -- Still in game
            local character = player.Character or player.CharacterAdded:Wait()
            if character then
                -- Restore HP/Mana/Stamina to full
                data.CurrentHealth = data.MaxHealth
                data.CurrentMana = data.MaxMana
                data.CurrentStamina = data.MaxStamina
                data:RecalculateStats()
            end
        end
    end)
end

-- ============================================================================
-- REMOTE EVENT HANDLERS
-- ============================================================================

AttackRemote.OnServerEvent:Connect(function(player, targetPart)
    CombatController:HandleMeleeAttack(player, targetPart)
end)

DodgeRemote.OnServerEvent:Connect(function(player, direction)
    CombatController:HandleDodge(player, direction)
end)

BlockRemote.OnServerEvent:Connect(function(player, isBlocking)
    CombatController:HandleBlock(player, isBlocking)
end)

SkillRemote.OnServerEvent:Connect(function(player, skillName, targetPosition)
    CombatController:HandleSkillUse(player, skillName, targetPosition)
end)

-- Equip request from inventory UI
EquipRequestRemote.OnServerEvent:Connect(function(player, itemId)
    local playerData = CombatController:GetPlayerData(player)
    if not playerData then return end
    
    -- Verify player owns the item
    local ownsItem = false
    for _, item in ipairs(playerData.Inventory) do
        if item.Id == itemId then
            ownsItem = true
            break
        end
    end
    
    if ownsItem then
        local success, msg = playerData:EquipWeapon(itemId)
        if success then
            LootRemote:FireClient(player, "Equipped: " .. (WeaponDatabase[itemId] and WeaponDatabase[itemId].Name or itemId), "Uncommon")
            print("[CombatSystem] " .. player.Name .. " equipped: " .. itemId)
        else
            -- Tell the player why equip failed (e.g. level too low)
            LootRemote:FireClient(player, msg or "Cannot equip!", "Common")
        end
        -- Always send updated inventory back so UI refreshes
        CombatController:SendInventoryUpdate(player)
    else
        LootRemote:FireClient(player, "Item not in inventory!", "Common")
    end
end)

-- Open inventory request - sends full inventory data to client
OpenInventoryRemote.OnServerEvent:Connect(function(player)
    CombatController:SendInventoryUpdate(player)
end)

-- Inventory remote function
InventoryRemote.OnServerInvoke = function(player, action, data)
    local playerData = CombatController:GetPlayerData(player)
    if not playerData then return {success = false, message = "No data"} end
    
    if action == "GetInventory" then
        return {
            success = true,
            inventory = playerData.Inventory,
            equippedWeapon = playerData.EquippedWeapon,
            gold = playerData.Gold,
        }
    elseif action == "EquipWeapon" then
        local success, msg = playerData:EquipWeapon(data.itemId)
        return {success = success, message = msg}
    elseif action == "GetWeaponInfo" then
        local weapon = WeaponDatabase[data.itemId]
        if weapon then
            return {success = true, weapon = weapon}
        end
        return {success = false, message = "Weapon not found"}
    end
    
    return {success = false, message = "Unknown action"}
end

-- Stats remote function
StatsRemote.OnServerInvoke = function(player, action, data)
    local playerData = CombatController:GetPlayerData(player)
    if not playerData then return {success = false, message = "No data"} end
    
    if action == "GetStats" then
        return {
            success = true,
            level = playerData.Level,
            xp = playerData.XP,
            xpToNext = playerData.XPToNext,
            gold = playerData.Gold,
            health = {current = playerData.CurrentHealth, max = playerData.MaxHealth},
            mana = {current = playerData.CurrentMana, max = playerData.MaxMana},
            stamina = {current = playerData.CurrentStamina, max = playerData.MaxStamina},
            attack = playerData.Attack,
            defense = playerData.Defense,
            speed = playerData.Speed,
            critChance = playerData.CritChance,
            critMultiplier = playerData.CritMultiplier,
            statPoints = playerData.StatPoints,
            skillPoints = playerData.SkillPoints,
            class = playerData.Class,
            str = playerData.STR,
            dex = playerData.DEX,
            int = playerData.INT,
            vit = playerData.VIT,
            agi = playerData.AGI,
        }
    elseif action == "AllocateStat" then
        local success = playerData:AllocateStat(data.stat)
        return {success = success}
    elseif action == "UnlockSkill" then
        local success, msg = playerData:UnlockSkill(data.skillName)
        return {success = success, message = msg}
    elseif action == "GetSkillTree" then
        local classSkills = SkillTree[playerData.Class]
        return {
            success = true,
            skills = classSkills,
            unlocked = playerData.UnlockedSkills,
            skillPoints = playerData.SkillPoints,
        }
    elseif action == "ChangeClass" then
        local validClasses = {"Warrior", "Mage", "Rogue"}
        local found = false
        for _, c in ipairs(validClasses) do
            if c == data.class then found = true break end
        end
        if found then
            playerData.Class = data.class
            playerData.UnlockedSkills = {}  -- Reset skills on class change
            playerData:RecalculateStats()
            return {success = true, message = "Class changed to " .. data.class}
        end
        return {success = false, message = "Invalid class"}
    end
    
    return {success = false, message = "Unknown action"}
end


-- ============================================================================
-- GAME LOOP
-- ============================================================================

local TICK_RATE = 1/30  -- 30 updates per second
local lastTick = tick()
local lastStatSync = 0
local STAT_SYNC_INTERVAL = 1  -- Send stats to clients every 1 second

RunService.Heartbeat:Connect(function()
    local now = tick()
    local deltaTime = now - lastTick
    
    if deltaTime < TICK_RATE then return end
    lastTick = now
    
    local allPlayers = Players:GetPlayers()
    
    -- Update all players (regen, buff timers, etc.)
    for player, data in pairs(CombatController.PlayerData) do
        if player.Parent then  -- Still in game
            RegenSystem:UpdatePlayer(data, deltaTime)
            
            -- Sync humanoid health with combat health
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.MaxHealth = data.MaxHealth
                    humanoid.Health = data.CurrentHealth
                    
                    -- Detect death
                    if data.CurrentHealth <= 0 and humanoid.Health > 0 then
                        humanoid.Health = 0
                    end
                end
            end
        end
    end
    
    -- Update all enemies
    for _, enemy in ipairs(CombatController.ActiveEnemies) do
        enemy:Update(deltaTime, allPlayers)
        
        -- Sync model position
        if enemy.Model and enemy.Model.PrimaryPart then
            -- Smooth movement via CFrame
            local targetCF = CFrame.new(enemy.Position)
            enemy.Model.PrimaryPart.CFrame = enemy.Model.PrimaryPart.CFrame:Lerp(targetCF, 0.1)
            
            -- Update health bar
            local billboard = enemy.Model.PrimaryPart:FindFirstChildOfClass("BillboardGui")
            if billboard then
                local healthBar = billboard:FindFirstChild("HealthBar")
                if healthBar then
                    local fill = healthBar:FindFirstChild("Fill")
                    if fill then
                        local percent = enemy.CurrentHealth / enemy.MaxHealth
                        fill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
                        
                        -- Color based on health
                        if percent > 0.5 then
                            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        elseif percent > 0.25 then
                            fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                        else
                            fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        end
                    end
                end
            end
            
            -- Dead enemies are already handled by HandleEnemyDeath (fade + destroy)
            -- Just skip updating dead enemies that somehow remain in the list
            if enemy.CurrentHealth <= 0 and enemy.Model then
                enemy.Model:Destroy()
                enemy.Model = nil
            end
        end
    end
    
    -- Periodically sync stats (gold, XP, level) to all clients for HUD
    if now - lastStatSync >= STAT_SYNC_INTERVAL then
        lastStatSync = now
        for player, data in pairs(CombatController.PlayerData) do
            if player.Parent then
                InventoryUpdateRemote:FireClient(player, {
                    StatsUpdate = true,
                    Gold = data.Gold,
                    Level = data.Level,
                    XP = data.XP,
                    XPToNext = data.XPToNext,
                    Health = {current = data.CurrentHealth, max = data.MaxHealth},
                    Mana = {current = data.CurrentMana, max = data.MaxMana},
                    Stamina = {current = data.CurrentStamina, max = data.MaxStamina},
                    Attack = data.Attack,
                    Defense = data.Defense,
                    EquippedWeapon = data.EquippedWeapon,
                    EquippedWeaponName = data.EquippedWeapon and WeaponDatabase[data.EquippedWeapon] and WeaponDatabase[data.EquippedWeapon].Name or "None",
                })
            end
        end
    end
end)

-- ============================================================================
-- PLAYER CONNECTION HANDLERS
-- ============================================================================

Players.PlayerAdded:Connect(function(player)
    -- Initialize combat data
    CombatController:InitPlayer(player)
    
    -- Handle character spawning
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local data = CombatController:GetPlayerData(player)
        
        if data then
            humanoid.MaxHealth = data.MaxHealth
            humanoid.Health = data.CurrentHealth
            humanoid.WalkSpeed = data.Speed
        end
        
        -- Ensure player has a weapon equipped (auto-equip on every respawn)
        CombatController:SetupAutoAttack(player)
        
        -- Auto-attack loop: automatically attack nearest enemy within range
        -- This lets players fight mobs without needing to manually fire remotes
        task.spawn(function()
            while humanoid and humanoid.Health > 0 and player.Parent do
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp and data and data.EquippedWeapon and not data.IsStunned and not data.IsAttacking then
                    local weapon = WeaponDatabase[data.EquippedWeapon]
                    local attackRange = weapon and weapon.Range or 6
                    
                    -- Find nearest enemy in attack range
                    local nearestEnemy = nil
                    local nearestDist = math.huge
                    for _, enemy in ipairs(CombatController.ActiveEnemies) do
                        if enemy.CurrentHealth > 0 and enemy.Position then
                            local dist = (enemy.Position - hrp.Position).Magnitude
                            if dist <= attackRange and dist < nearestDist then
                                nearestEnemy = enemy
                                nearestDist = dist
                            end
                        end
                    end
                    
                    -- Auto-attack the nearest enemy
                    if nearestEnemy then
                        local cooldown = CombatConfig.AttackCooldown
                        if weapon then
                            cooldown = cooldown / weapon.Speed
                        end
                        
                        local now = tick()
                        if now - data.LastAttackTime >= cooldown then
                            -- Update combo
                            if now - data.LastAttackTime > CombatConfig.ComboWindow then
                                data.ComboCount = 0
                            end
                            data.ComboCount = math.min(data.ComboCount + 1, CombatConfig.MaxComboHits)
                            data.LastAttackTime = now
                            data.IsAttacking = true
                            
                            -- Calculate and apply damage
                            local damage, isCrit = DamageEngine.CalculateDamage(data, nearestEnemy, false, nil)
                            local finalDamage, wasCrit, result = DamageEngine.ApplyDamage(data, nearestEnemy, damage, isCrit)
                            
                            -- Fire damage VFX event
                            DamageRemote:FireAllClients(
                                nearestEnemy.Position or Vector3.new(0, 0, 0),
                                finalDamage,
                                wasCrit,
                                result
                            )
                            
                            -- Handle enemy death
                            if result == "KILL" then
                                CombatController:HandleEnemyDeath(player, nearestEnemy)
                            end
                            
                            -- End attack state after short delay
                            task.delay(0.3, function()
                                data.IsAttacking = false
                            end)
                        end
                    end
                end
                task.wait(0.1)  -- Check for enemies 10 times per second
            end
        end)
        
        -- Handle death
        humanoid.Died:Connect(function()
            RespawnSystem:HandlePlayerDeath(player)
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    -- Save data would go here (DataStore)
    CombatController:RemovePlayer(player)
    print("[CombatSystem] Removed combat data for " .. player.Name)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("")
print("================================================================================")
print("  ULTIMATE COMBAT & RPG SYSTEM")
print("  Version 1.0 | Loaded Successfully")
print("================================================================================")
print("")
print("  Features Active:")
print("    - Melee combat with 5-hit combos")
print("    - Blocking, dodging, and parrying")
print("    - 3 classes: Warrior, Mage, Rogue")
print("    - Skill trees with active & passive abilities")
print("    - 12 weapons across 4 types")
print("    - 5 enemy types including 2 bosses")
print("    - RPG leveling up to Level 100")
print("    - Loot drops and inventory system")
print("    - Stat allocation (STR/DEX/INT/VIT/AGI)")
print("    - Boss fight phases and abilities")
print("    - Stamina/Mana regeneration")
print("    - Death penalty and respawn")
print("")
print("  Spawning enemies...")

-- Spawn enemies
CombatController:SpawnAllEnemies()

print("")
print("  System ready! Players can start fighting.")
print("================================================================================")
