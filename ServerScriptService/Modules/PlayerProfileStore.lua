local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local PlayerProfileStore = {}

local PROFILE_DATASTORE = "RPG_PLAYER_PROFILES"
local profileCache = {}

local function cloneDefaults()
    local defaults = table.clone(GameConfig.DefaultStats)
    defaults.health = defaults.maxHealth
    defaults.mana = defaults.maxMana
    return defaults
end

local function ensureInventory(inventory)
    inventory = inventory or {}
    inventory.items = inventory.items or {}
    inventory.equipped = inventory.equipped or {}
    inventory.capacity = inventory.capacity or GameConfig.Inventory.maxSlots
    return inventory
end

local function ensureQuests(quests)
    quests = quests or {}
    quests.active = quests.active or {}
    quests.completed = quests.completed or {}
    return quests
end

local function ensureProfileStructure(profile)
    profile = profile or {}
    profile.stats = profile.stats or cloneDefaults()
    profile.inventory = ensureInventory(profile.inventory)
    profile.quests = ensureQuests(profile.quests)
    return profile
end

local function getStore()
    return DataStoreService:GetDataStore(PROFILE_DATASTORE)
end

local function getKey(player)
    return string.format("player_%d", player.UserId)
end

function PlayerProfileStore.Load(player)
    local key = getKey(player)
    if profileCache[key] then
        return profileCache[key]
    end

    local store = getStore()
    local success, result = pcall(function()
        return store:GetAsync(key)
    end)

    if not success then
        warn(string.format("Falha ao carregar perfil de %s: %s", player.Name, result))
        result = nil
    end

    result = ensureProfileStructure(result)
    profileCache[key] = result
    return result
end

function PlayerProfileStore.Update(player, transform)
    local key = getKey(player)
    local store = getStore()

    local success, result = pcall(function()
        return store:UpdateAsync(key, function(oldValue)
            oldValue = ensureProfileStructure(oldValue)
            local newValue = transform(oldValue)
            newValue = ensureProfileStructure(newValue)
            profileCache[key] = newValue
            return newValue
        end)
    end)

    if not success then
        warn(string.format("Falha ao atualizar perfil de %s: %s", player.Name, result))
        return profileCache[key]
    end

    profileCache[key] = ensureProfileStructure(result)
    return profileCache[key]
end

function PlayerProfileStore.Save(player)
    local key = getKey(player)
    if not profileCache[key] then
        return
    end

    PlayerProfileStore.Update(player, function()
        return profileCache[key]
    end)
end

function PlayerProfileStore.Clear(player)
    profileCache[getKey(player)] = nil
end

Players.PlayerRemoving:Connect(function(player)
    local success, err = pcall(function()
        PlayerProfileStore.Save(player)
    end)
    if not success then
        warn(string.format("Erro ao salvar perfil na saída de %s: %s", player.Name, err))
    end
    PlayerProfileStore.Clear(player)
end)

return PlayerProfileStore

