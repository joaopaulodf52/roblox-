local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

local function resolveDefaultMapId()
    local candidate = MapConfig.defaultMap
    if typeof(candidate) == "string" and MapConfig[candidate] then
        return candidate
    end

    for key, value in pairs(MapConfig) do
        if type(value) == "table" and value.assetName then
            return key
        end
    end

    return nil
end

local DEFAULT_MAP_ID = resolveDefaultMapId()
assert(DEFAULT_MAP_ID, "MapConfig deve definir ao menos um mapa válido")

local PlayerProfileStore = {}

local PROFILE_DATASTORE = "RPG_PLAYER_PROFILES"
local profileCache = {}
local MAX_RETRY_ATTEMPTS = 5
local RETRY_BASE_DELAY = 0.5

local function backoffWait(attempt)
    local delay = RETRY_BASE_DELAY * (2 ^ (attempt - 1))
    delay += math.random() * 0.25
    task.wait(delay)
end

local function retryWithBackoff(operation)
    local lastError
    for attempt = 1, MAX_RETRY_ATTEMPTS do
        local success, result = pcall(operation)
        if success then
            return true, result
        end

        lastError = result
        if attempt < MAX_RETRY_ATTEMPTS then
            backoffWait(attempt)
        end
    end

    return false, lastError
end

local function cloneDefaults()
    local defaults = table.clone(GameConfig.DefaultStats)
    defaults.health = defaults.maxHealth
    defaults.mana = defaults.maxMana
    return defaults
end

local function ensureCurrentMap(mapId)
    if typeof(mapId) ~= "string" or not MapConfig[mapId] then
        return DEFAULT_MAP_ID
    end

    return mapId
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

local function ensureSkills(skills)
    skills = skills or {}
    skills.unlocked = skills.unlocked or {}
    skills.hotbar = skills.hotbar or {}
    skills.version = skills.version or 1
    return skills
end

local function ensureProfileStructure(profile)
    profile = profile or {}
    profile.stats = profile.stats or cloneDefaults()
    profile.inventory = ensureInventory(profile.inventory)
    profile.quests = ensureQuests(profile.quests)
    profile.skills = ensureSkills(profile.skills)
    profile.currentMap = ensureCurrentMap(profile.currentMap)
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
    local success, result = retryWithBackoff(function()
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

    local success, result = retryWithBackoff(function()
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
        local cached = profileCache[key] or ensureProfileStructure(nil)
        profileCache[key] = cached
        return cached
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

