local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local CharacterStats = {}
CharacterStats.__index = CharacterStats

local function clamp(value, minValue, maxValue)
    return math.clamp(value, minValue, maxValue)
end

local function getDefaultClass()
    local classes = GameConfig.Classes
    if classes then
        local defaultClass = classes.default
        if type(defaultClass) == "string" and classes[string.lower(defaultClass)] then
            return string.lower(defaultClass)
        end
        for classId, definition in pairs(classes) do
            if classId ~= "default" and type(definition) == "table" then
                return classId
            end
        end
    end

    if GameConfig.DefaultStats and GameConfig.DefaultStats.class then
        return string.lower(GameConfig.DefaultStats.class)
    end

    return "guerreiro"
end

local function normalizeClass(className)
    if type(className) ~= "string" then
        return nil
    end

    local normalized = string.lower(className)
    local classes = GameConfig.Classes
    if classes and type(classes[normalized]) == "table" then
        return normalized
    end

    return nil
end

function CharacterStats.new(player)
    local self = setmetatable({}, CharacterStats)
    self.player = player
    self.profile = PlayerProfileStore.Load(player)
    self.stats = self.profile.stats
    self._temporaryModifiers = {}
    self._temporaryModifierCounter = 0
    self._destroyed = false
    self:_ensureBounds()
    self:_pushUpdate()
    return self
end

function CharacterStats:_ensureBounds()
    self.stats.maxHealth = math.max(self.stats.maxHealth or GameConfig.DefaultStats.maxHealth, 1)
    self.stats.maxMana = math.max(self.stats.maxMana or GameConfig.DefaultStats.maxMana, 0)
    self.stats.health = clamp(self.stats.health or self.stats.maxHealth, 0, self.stats.maxHealth)
    self.stats.mana = clamp(self.stats.mana or self.stats.maxMana, 0, self.stats.maxMana)
    self.stats.attack = self.stats.attack or GameConfig.DefaultStats.attack
    self.stats.defense = self.stats.defense or GameConfig.DefaultStats.defense
    self.stats.gold = self.stats.gold or GameConfig.DefaultStats.gold

    local currentClass = normalizeClass(self.stats.class)
    if not currentClass then
        currentClass = getDefaultClass()
    end
    self.stats.class = currentClass
end

function CharacterStats:_experienceToNextLevel()
    return GameConfig.getExperienceToLevel(self.stats.level)
end

function CharacterStats:_levelUpIfNeeded()
    local leveledUp = false
    local expToLevel = self:_experienceToNextLevel()
    while self.stats.experience >= expToLevel do
        self.stats.experience = self.stats.experience - expToLevel
        self.stats.level = self.stats.level + 1
        self.stats.maxHealth = self.stats.maxHealth + 10
        self.stats.maxMana = self.stats.maxMana + 5
        self.stats.attack = self.stats.attack + 2
        self.stats.defense = self.stats.defense + 1
        self.stats.health = self.stats.maxHealth
        self.stats.mana = self.stats.maxMana
        leveledUp = true
        expToLevel = self:_experienceToNextLevel()
    end
    if leveledUp then
        self:_pushUpdate()
    end
    return leveledUp
end

function CharacterStats:AddExperience(amount)
    amount = math.max(amount or 0, 0)
    if amount == 0 then
        return
    end

    self.stats.experience = self.stats.experience + amount
    local leveled = self:_levelUpIfNeeded()
    self:_save()
    if not leveled then
        self:_pushUpdate()
    end
end

function CharacterStats:AddGold(amount)
    amount = amount or 0
    if amount == 0 then
        return
    end
    self.stats.gold = self.stats.gold + amount
    self:_save()
    self:_pushUpdate()
end

function CharacterStats:ApplyDamage(amount)
    amount = math.max(amount or 0, 0)
    if amount == 0 then
        return 0, false
    end

    local previous = self.stats.health
    self.stats.health = clamp(self.stats.health - amount, 0, self.stats.maxHealth)
    local defeated = self.stats.health <= 0
    local newHealth = self.stats.health

    self:_save()
    self:_pushUpdate()

    if defeated then
        self:OnDefeated()
    end

    return previous - newHealth, defeated
end

function CharacterStats:RestoreHealth(amount)
    amount = math.max(amount or 0, 0)
    if amount == 0 then
        return 0
    end

    local previous = self.stats.health
    self.stats.health = clamp(self.stats.health + amount, 0, self.stats.maxHealth)
    self:_save()
    self:_pushUpdate()
    return self.stats.health - previous
end

function CharacterStats:UseMana(amount)
    amount = math.max(amount or 0, 0)
    if amount == 0 then
        return true
    end

    if self.stats.mana < amount then
        return false
    end

    self.stats.mana = self.stats.mana - amount
    self:_save()
    self:_pushUpdate()
    return true
end

function CharacterStats:RestoreMana(amount)
    amount = math.max(amount or 0, 0)
    if amount == 0 then
        return 0
    end

    local previous = self.stats.mana
    self.stats.mana = clamp(self.stats.mana + amount, 0, self.stats.maxMana)
    self:_save()
    self:_pushUpdate()
    return self.stats.mana - previous
end

function CharacterStats:GetClass()
    return self.stats.class
end

function CharacterStats:SetClass(className)
    local normalized = normalizeClass(className)
    if not normalized then
        return false, "Classe desconhecida"
    end

    if self.stats.class == normalized then
        return true
    end

    self.stats.class = normalized
    self:_save()
    self:_pushUpdate()
    return true
end

function CharacterStats:ApplyAttributeModifier(attribute, delta)
    if not self.stats[attribute] then
        self.stats[attribute] = 0
    end
    self.stats[attribute] = self.stats[attribute] + delta
    if attribute == "maxHealth" then
        self.stats.health = clamp(self.stats.health, 0, self.stats.maxHealth)
    elseif attribute == "maxMana" then
        self.stats.mana = clamp(self.stats.mana, 0, self.stats.maxMana)
    end
    self:_save()
    self:_pushUpdate()
end

function CharacterStats:_removeTemporaryModifier(attribute, modifierId)
    if self._destroyed then
        return
    end

    local container = self._temporaryModifiers and self._temporaryModifiers[attribute]
    if not container then
        return
    end

    local amount = container.entries[modifierId]
    if not amount then
        return
    end

    container.entries[modifierId] = nil
    container.total = (container.total or 0) - amount

    if math.abs(container.total) < 1e-4 then
        container.total = 0
    end

    if next(container.entries) == nil then
        self._temporaryModifiers[attribute] = nil
    end

    self:_pushUpdate()
end

function CharacterStats:ApplyTemporaryModifier(attribute, delta, duration)
    if self._destroyed then
        return false
    end

    if type(attribute) ~= "string" or attribute == "" then
        return false
    end

    if type(delta) ~= "number" or delta == 0 or delta ~= delta then
        return false
    end

    if type(duration) ~= "number" or duration <= 0 then
        return false
    end

    self._temporaryModifierCounter = self._temporaryModifierCounter + 1
    local modifierId = self._temporaryModifierCounter

    local container = self._temporaryModifiers[attribute]
    if not container then
        container = {
            total = 0,
            entries = {},
        }
        self._temporaryModifiers[attribute] = container
    end

    container.entries[modifierId] = delta
    container.total = (container.total or 0) + delta

    self:_pushUpdate()

    task.delay(duration, function()
        self:_removeTemporaryModifier(attribute, modifierId)
    end)

    return true, modifierId
end

function CharacterStats:GetStats()
    local statsCopy = table.clone(self.stats)

    if self._temporaryModifiers then
        for attribute, container in pairs(self._temporaryModifiers) do
            local total = container.total
            if total and total ~= 0 then
                local current = statsCopy[attribute]
                if type(current) ~= "number" then
                    current = current or 0
                end
                statsCopy[attribute] = current + total
            end
        end
    end

    statsCopy.maxHealth = math.max(statsCopy.maxHealth or GameConfig.DefaultStats.maxHealth, 1)
    statsCopy.maxMana = math.max(statsCopy.maxMana or GameConfig.DefaultStats.maxMana, 0)
    statsCopy.health = clamp(statsCopy.health, 0, statsCopy.maxHealth)
    statsCopy.mana = clamp(statsCopy.mana, 0, statsCopy.maxMana)

    return statsCopy
end

function CharacterStats:_save()
    PlayerProfileStore.Update(self.player, function(profile)
        profile.stats = self.stats
        return profile
    end)
end

function CharacterStats:_pushUpdate()
    if self._destroyed then
        return
    end

    Remotes.StatsUpdated:FireClient(self.player, self:GetStats())
end

function CharacterStats:OnDefeated()
    self.stats.health = self.stats.maxHealth
    self.stats.mana = self.stats.maxMana
    self:_save()
    self:_pushUpdate()
end

function CharacterStats:Destroy()
    self._destroyed = true
    self._temporaryModifiers = nil
    PlayerProfileStore.Save(self.player)
end

return CharacterStats

