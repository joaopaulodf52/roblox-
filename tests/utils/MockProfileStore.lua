local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerProfileStore = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PlayerProfileStore"))

local MockProfileStore = {}
MockProfileStore.__index = MockProfileStore

local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

local function clearDictionary(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

function MockProfileStore.new()
    local self = setmetatable({}, MockProfileStore)
    self.playerProfiles = {}
    self.playerStore = PlayerProfileStore
    self.original = {
        Load = PlayerProfileStore.Load,
        Update = PlayerProfileStore.Update,
        Save = PlayerProfileStore.Save,
        Clear = PlayerProfileStore.Clear,
    }

    self:_activate()

    return self
end

function MockProfileStore:_getKey(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return player
end

function MockProfileStore:_createProfile()
    local stats = shallowCopy(GameConfig.DefaultStats)
    stats.health = stats.maxHealth
    stats.mana = stats.maxMana

    return {
        stats = stats,
        inventory = {
            items = {},
            equipped = {},
            capacity = GameConfig.Inventory.maxSlots,
        },
        quests = {
            active = {},
            completed = {},
        },
        skills = {
            unlocked = {},
            hotbar = {},
            version = 1,
        },
        crafting = {
            unlocked = {},
            statistics = {
                totalCrafted = 0,
                byRecipe = {},
            },
            version = 1,
        },
        achievements = {
            version = 1,
            unlocked = {},
            progress = {},
            counters = {
                experience = 0,
                kills = {
                    total = 0,
                    byType = {},
                },
            },
        },
    }
end

function MockProfileStore:_activate()
    local store = self
    local target = self.playerProfiles

    local function ensureProfile(player)
        local key = store:_getKey(player)
        if key == nil then
            return store:_createProfile()
        end

        local profile = target[key]
        if not profile then
            profile = store:_createProfile()
            target[key] = profile
        end
        return profile
    end

    function self.playerStore.Load(player)
        return ensureProfile(player)
    end

    function self.playerStore.Update(player, transform)
        local profile = ensureProfile(player)
        local updated = transform(profile)
        if updated ~= nil then
            target[store:_getKey(player)] = updated
            return updated
        end

        target[store:_getKey(player)] = profile
        return profile
    end

    function self.playerStore.Save(player)
        return ensureProfile(player)
    end

    function self.playerStore.Clear(player)
        target[store:_getKey(player)] = nil
    end
end

function MockProfileStore:getProfile(player)
    return self.playerProfiles[self:_getKey(player)]
end

function MockProfileStore:reset()
    clearDictionary(self.playerProfiles)
end

function MockProfileStore:restore()
    for name, fn in pairs(self.original) do
        self.playerStore[name] = fn
    end
    self:reset()
end

return MockProfileStore
