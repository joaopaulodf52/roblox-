local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local AchievementManager = {}
AchievementManager.__index = AchievementManager

local leaderboardConfig = AchievementConfig.leaderboard or {}
local LEADERBOARD_STORE_NAME = leaderboardConfig.storeName or "RPG_ACHIEVEMENTS_LEADERBOARD"
local LEADERBOARD_MAX_ENTRIES = math.max(1, math.min(math.floor(leaderboardConfig.maxEntries or 50), 100))
local LEADERBOARD_CACHE_SECONDS = math.max(1, math.floor(leaderboardConfig.cacheSeconds or 15))

local dataStoreService = DataStoreService

local timeProvider = os.clock

local leaderboardCache = {
    entries = nil,
    limit = 0,
    expiresAt = 0,
}

local leaderboardEntryCache = {}

local definitionsSource = AchievementConfig.definitions or AchievementConfig

local ACHIEVEMENTS = {}
local EXPERIENCE_ACHIEVEMENTS = {}
local KILL_ACHIEVEMENTS_DEFAULT = {}
local KILL_ACHIEVEMENTS_BY_TARGET = {}
local QUEST_ACHIEVEMENTS_DEFAULT = {}
local QUEST_ACHIEVEMENTS_BY_TARGET = {}

local function resolveGoal(condition)
    local goal = condition.threshold or condition.goal or condition.count or 1
    if type(goal) ~= "number" then
        goal = tonumber(goal) or 1
    end
    goal = math.floor(goal)
    if goal < 1 then
        goal = 1
    end
    return goal
end

local function normalizeConditionType(condition)
    local conditionType = condition.type
    if type(conditionType) ~= "string" then
        return nil
    end
    return string.lower(conditionType)
end

local function cloneReward(reward)
    if not reward then
        return nil
    end

    local copy = {}
    if reward.experience and type(reward.experience) == "number" then
        copy.experience = reward.experience
    end
    if reward.gold and type(reward.gold) == "number" then
        copy.gold = reward.gold
    end
    if reward.items and type(reward.items) == "table" then
        local itemsCopy = {}
        for itemId, quantity in pairs(reward.items) do
            itemsCopy[itemId] = quantity
        end
        if next(itemsCopy) ~= nil then
            copy.items = itemsCopy
        end
    end

    if next(copy) == nil then
        return nil
    end

    return copy
end

for id, definition in pairs(definitionsSource) do
    if type(definition) == "table" then
        local condition = definition.condition or {}
        local conditionType = normalizeConditionType(condition)
        local goal = resolveGoal(condition)

        local normalized = {
            id = id,
            name = definition.name or id,
            description = definition.description or "",
            type = conditionType,
            target = condition.target,
            goal = goal,
            reward = cloneReward(definition.reward),
        }

        ACHIEVEMENTS[id] = normalized

        if conditionType == "experience" then
            table.insert(EXPERIENCE_ACHIEVEMENTS, normalized)
        elseif conditionType == "kill" then
            local target = normalized.target
            if type(target) ~= "string" or target == "" then
                table.insert(KILL_ACHIEVEMENTS_DEFAULT, normalized)
            else
                KILL_ACHIEVEMENTS_BY_TARGET[target] = KILL_ACHIEVEMENTS_BY_TARGET[target] or {}
                table.insert(KILL_ACHIEVEMENTS_BY_TARGET[target], normalized)
            end
        elseif conditionType == "quest" then
            local target = normalized.target
            if type(target) ~= "string" or target == "" then
                table.insert(QUEST_ACHIEVEMENTS_DEFAULT, normalized)
            else
                QUEST_ACHIEVEMENTS_BY_TARGET[target] = QUEST_ACHIEVEMENTS_BY_TARGET[target] or {}
                table.insert(QUEST_ACHIEVEMENTS_BY_TARGET[target], normalized)
            end
        end
    end
end

local function ensureKillsStructure(container)
    container = container or {}
    container.total = container.total or 0
    container.byType = container.byType or {}
    return container
end

local function ensureQuestStructure(container)
    container = container or {}
    container.total = container.total or 0
    container.byQuest = container.byQuest or {}
    return container
end

local function now()
    local provider = timeProvider
    if provider then
        return provider()
    end
    return os.clock()
end

local function clearLeaderboardCaches()
    leaderboardCache.entries = nil
    leaderboardCache.limit = 0
    leaderboardCache.expiresAt = 0
    table.clear(leaderboardEntryCache)
end

local function sanitizeLimit(limit)
    local numeric = tonumber(limit)
    if not numeric then
        return LEADERBOARD_MAX_ENTRIES
    end

    numeric = math.floor(numeric)
    if numeric < 1 then
        numeric = 1
    elseif numeric > LEADERBOARD_MAX_ENTRIES then
        numeric = LEADERBOARD_MAX_ENTRIES
    end

    return numeric
end

local function copyLeaderboardEntries(source, limit)
    local results = {}
    if not source then
        return results
    end

    local maxIndex = math.min(limit or #source, #source)
    for index = 1, maxIndex do
        local entry = source[index]
        if entry then
            results[index] = {
                userId = entry.userId,
                total = entry.total,
            }
        end
    end

    return results
end

local function readLeaderboardFromStore(fetchLimit)
    local store = dataStoreService:GetOrderedDataStore(LEADERBOARD_STORE_NAME)
    local pages = store:GetSortedAsync(false, fetchLimit)
    local page = pages:GetCurrentPage()

    local entries = {}
    for _, item in ipairs(page) do
        local key = item.key
        local value = item.value
        local userId = tonumber(key)
        if userId and userId > 0 then
            table.insert(entries, {
                userId = userId,
                total = tonumber(value) or 0,
            })
        end
    end

    return entries
end

local function cachePersonalValue(userId, value)
    if type(userId) ~= "number" or userId <= 0 then
        return
    end

    leaderboardEntryCache[userId] = {
        value = value,
        expiresAt = now() + LEADERBOARD_CACHE_SECONDS,
    }
end

local function invalidateLeaderboardCache()
    leaderboardCache.entries = nil
    leaderboardCache.limit = 0
    leaderboardCache.expiresAt = 0
end

function AchievementManager._setDataStoreService(service)
    dataStoreService = service or dataStoreService
    clearLeaderboardCaches()
end

function AchievementManager._resetDataStoreService()
    dataStoreService = game:GetService("DataStoreService")
    clearLeaderboardCaches()
end

function AchievementManager._setTimeProvider(provider)
    if type(provider) == "function" then
        timeProvider = provider
    else
        timeProvider = os.clock
    end
end

function AchievementManager._resetTimeProvider()
    timeProvider = os.clock
end

function AchievementManager._clearLeaderboardCache()
    clearLeaderboardCaches()
end

local function countEntries(dictionary)
    local count = 0
    for _ in pairs(dictionary) do
        count += 1
    end
    return count
end

function AchievementManager.new(player, characterStats, inventory, combat, questManager)
    local self = setmetatable({}, AchievementManager)
    self.player = player
    self.characterStats = characterStats
    self.inventory = inventory
    self.combat = combat
    self.questManager = questManager
    self.profile = PlayerProfileStore.Load(player)
    self.data = self.profile.achievements or {}
    self._destroyed = false
    self._experienceSuppression = 0

    self:_ensureStructure()
    self:_bindControllers()
    self:_pushUpdate()
    return self
end

function AchievementManager:_bindControllers()
    if self.characterStats and self.characterStats.BindAchievementManager then
        self.characterStats:BindAchievementManager(self)
    end

    if self.combat and self.combat.BindAchievementManager then
        self.combat:BindAchievementManager(self)
    end

    if self.questManager and self.questManager.BindAchievementManager then
        self.questManager:BindAchievementManager(self)
    end
end

function AchievementManager:_ensureStructure()
    self.data.version = self.data.version or 1
    self.data.unlocked = self.data.unlocked or {}
    self.data.progress = self.data.progress or {}
    local counters = self.data.counters or {}
    counters.experience = counters.experience or 0
    counters.kills = ensureKillsStructure(counters.kills)
    counters.quests = ensureQuestStructure(counters.quests)
    self.data.counters = counters
end

function AchievementManager:_save()
    PlayerProfileStore.Update(self.player, function(profile)
        profile.achievements = self.data
        return profile
    end)
end

function AchievementManager:_pushUpdate()
    if self._destroyed then
        return
    end

    Remotes.AchievementUpdated:FireClient(self.player, self:GetSummary())
end

function AchievementManager:_saveAndSync()
    self:_save()
    self:_pushUpdate()
end

function AchievementManager:_getUnlockedCount()
    return countEntries(self.data.unlocked)
end

function AchievementManager:_updateLeaderboard()
    local player = self.player
    if not player then
        return
    end

    local userId = player.UserId
    if type(userId) ~= "number" or userId <= 0 then
        return
    end

    local unlockedCount = self:_getUnlockedCount()
    local success, err = pcall(function()
        local store = dataStoreService:GetOrderedDataStore(LEADERBOARD_STORE_NAME)
        local key = tostring(userId)
        store:UpdateAsync(key, function()
            return unlockedCount
        end)
    end)

    if not success then
        warn(string.format("Falha ao atualizar leaderboard de conquistas para %s: %s", player.Name, tostring(err)))
        return
    end

    cachePersonalValue(userId, unlockedCount)
    invalidateLeaderboardCache()
end

function AchievementManager:_suppressExperienceTracking()
    self._experienceSuppression += 1
end

function AchievementManager:_resumeExperienceTracking()
    if self._experienceSuppression > 0 then
        self._experienceSuppression -= 1
    end
end

function AchievementManager:_isExperienceSuppressed()
    return self._experienceSuppression > 0
end

function AchievementManager:_applyReward(reward)
    if not reward then
        return
    end

    if reward.experience and self.characterStats then
        self:_suppressExperienceTracking()
        self.characterStats:AddExperience(reward.experience)
        self:_resumeExperienceTracking()
    end

    if reward.gold and self.characterStats then
        self.characterStats:AddGold(reward.gold)
    end

    if reward.items and self.inventory then
        for itemId, quantity in pairs(reward.items) do
            local success, err = self.inventory:AddItem(itemId, quantity, { notifyQuest = false })
            if not success then
                warn(string.format("Falha ao conceder item de conquista %s ao jogador %s: %s", tostring(itemId), self.player and self.player.Name or "?", tostring(err)))
            end
        end
    end
end

function AchievementManager:_unlockAchievement(definition)
    local id = definition.id
    if self.data.unlocked[id] then
        return
    end

    self.data.unlocked[id] = {
        unlockedAt = os.time(),
    }
    self.data.progress[id] = definition.goal

    self:_applyReward(definition.reward)
    self:_saveAndSync()
    self:_updateLeaderboard()
end

function AchievementManager:_incrementProgress(definition, amount)
    if amount <= 0 then
        return false
    end

    local id = definition.id
    if self.data.unlocked[id] then
        return false
    end

    local current = self.data.progress[id] or 0
    local newValue = current + amount
    if newValue >= definition.goal then
        self.data.progress[id] = definition.goal
        self:_unlockAchievement(definition)
        return true
    end

    if newValue ~= current then
        self.data.progress[id] = newValue
        return true
    end

    return false
end

function AchievementManager:OnExperienceGained(amount)
    amount = math.max(amount or 0, 0)
    if amount <= 0 or self:_isExperienceSuppressed() or self._destroyed then
        return
    end

    self.data.counters.experience = self.data.counters.experience + amount

    local changed = false
    for _, definition in ipairs(EXPERIENCE_ACHIEVEMENTS) do
        if self:_incrementProgress(definition, amount) then
            changed = true
        end
    end

    if changed then
        self:_saveAndSync()
    else
        self:_save()
    end
end

function AchievementManager:OnEnemyDefeated(enemyType)
    if self._destroyed then
        return
    end

    local kills = self.data.counters.kills
    kills.total += 1
    if enemyType then
        local byType = kills.byType
        byType[enemyType] = (byType[enemyType] or 0) + 1
    end

    local changed = false
    for _, definition in ipairs(KILL_ACHIEVEMENTS_DEFAULT) do
        if self:_incrementProgress(definition, 1) then
            changed = true
        end
    end

    if enemyType then
        local byTypeList = KILL_ACHIEVEMENTS_BY_TARGET[enemyType]
        if byTypeList then
            for _, definition in ipairs(byTypeList) do
                if self:_incrementProgress(definition, 1) then
                    changed = true
                end
            end
        end
    end

    if changed then
        self:_saveAndSync()
    else
        self:_save()
    end
end

function AchievementManager:OnQuestCompleted(questId)
    if self._destroyed then
        return
    end

    local quests = self.data.counters.quests
    quests.total += 1
    if questId then
        local byQuest = quests.byQuest
        byQuest[questId] = (byQuest[questId] or 0) + 1
    end

    local changed = false
    for _, definition in ipairs(QUEST_ACHIEVEMENTS_DEFAULT) do
        if self:_incrementProgress(definition, 1) then
            changed = true
        end
    end

    if questId then
        local questSpecific = QUEST_ACHIEVEMENTS_BY_TARGET[questId]
        if questSpecific then
            for _, definition in ipairs(questSpecific) do
                if self:_incrementProgress(definition, 1) then
                    changed = true
                end
            end
        end
    end

    if changed then
        self:_saveAndSync()
    else
        self:_save()
    end
end

local function rewardCopy(reward)
    return cloneReward(reward)
end

local function buildEntry(definition, progress, unlockedAt)
    local entry = {
        id = definition.id,
        name = definition.name,
        description = definition.description,
        goal = definition.goal,
        progress = math.clamp(progress, 0, definition.goal),
        reward = rewardCopy(definition.reward),
    }

    if unlockedAt then
        entry.unlockedAt = unlockedAt
        entry.progress = definition.goal
    end

    return entry
end

function AchievementManager:GetSummary()
    local locked = {}
    local unlocked = {}

    for id, definition in pairs(ACHIEVEMENTS) do
        local unlockedInfo = self.data.unlocked[id]
        local progressValue = self.data.progress[id] or 0
        local entry = buildEntry(definition, progressValue, unlockedInfo and unlockedInfo.unlockedAt)
        if unlockedInfo then
            unlocked[id] = entry
        else
            locked[id] = entry
        end
    end

    return {
        locked = locked,
        unlocked = unlocked,
    }
end

function AchievementManager:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    if self.characterStats and self.characterStats.UnbindAchievementManager then
        self.characterStats:UnbindAchievementManager(self)
    end

    if self.combat and self.combat.UnbindAchievementManager then
        self.combat:UnbindAchievementManager(self)
    end

    if self.questManager and self.questManager.UnbindAchievementManager then
        self.questManager:UnbindAchievementManager(self)
    end

    self.questManager = nil

    self:_save()
end

function AchievementManager.GetLeaderboardEntriesAsync(limit)
    local sanitizedLimit = sanitizeLimit(limit)
    local cached = leaderboardCache

    if cached.entries and now() < cached.expiresAt and cached.limit >= sanitizedLimit then
        return copyLeaderboardEntries(cached.entries, sanitizedLimit)
    end

    local fetchLimit = math.max(sanitizedLimit, LEADERBOARD_MAX_ENTRIES)
    local success, result = pcall(function()
        return readLeaderboardFromStore(fetchLimit)
    end)

    if not success then
        return nil, result
    end

    cached.entries = result
    cached.limit = fetchLimit
    cached.expiresAt = now() + LEADERBOARD_CACHE_SECONDS

    return copyLeaderboardEntries(result, sanitizedLimit)
end

function AchievementManager.GetLeaderboardValueAsync(userId)
    local numericId = tonumber(userId)
    if not numericId or numericId <= 0 then
        return nil, "invalidUserId"
    end

    local cached = leaderboardEntryCache[numericId]
    if cached and now() < cached.expiresAt then
        return cached.value
    end

    local success, valueOrErr = pcall(function()
        local store = dataStoreService:GetOrderedDataStore(LEADERBOARD_STORE_NAME)
        return store:GetAsync(tostring(numericId))
    end)

    if not success then
        return nil, valueOrErr
    end

    local numericValue = tonumber(valueOrErr) or 0
    cachePersonalValue(numericId, numericValue)

    return numericValue
end

return AchievementManager
