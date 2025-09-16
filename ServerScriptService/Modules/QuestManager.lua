local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local QuestManager = {}
QuestManager.__index = QuestManager

local function cloneQuestStates(states)
    local copy = {}
    for questId, data in pairs(states) do
        copy[questId] = table.clone(data)
    end
    return copy
end

local function countEntries(dictionary)
    local count = 0
    for _ in pairs(dictionary) do
        count = count + 1
    end
    return count
end

local function applyRewardBundle(self, rewardData)
    if not rewardData then
        return
    end

    if rewardData.experience then
        self.characterStats:AddExperience(rewardData.experience)
    end
    if rewardData.gold then
        self.characterStats:AddGold(rewardData.gold)
    end
    if rewardData.items then
        for itemId, quantity in pairs(rewardData.items) do
            self.inventory:AddItem(itemId, quantity, { notifyQuest = false })
        end
    end
end

local function resolvePlayerClass(characterStats)
    if characterStats.GetClass then
        return characterStats:GetClass()
    end

    local stats = characterStats:GetStats()
    return stats.class
end

function QuestManager.new(player, characterStats, inventory)
    local self = setmetatable({}, QuestManager)
    self.player = player
    self.characterStats = characterStats
    self.inventory = inventory
    self.profile = PlayerProfileStore.Load(player)
    self.data = self.profile.quests
    self:_ensureStructure()
    self:_pushUpdate()
    return self
end

function QuestManager:_ensureStructure()
    self.data.active = self.data.active or {}
    self.data.completed = self.data.completed or {}
end

function QuestManager:_save()
    PlayerProfileStore.Update(self.player, function(profile)
        profile.quests = self.data
        return profile
    end)
end

function QuestManager:_pushUpdate()
    Remotes.QuestUpdated:FireClient(self.player, self:GetSummary())
end

function QuestManager:GetSummary()
    return {
        active = cloneQuestStates(self.data.active),
        completed = cloneQuestStates(self.data.completed),
    }
end

function QuestManager:AcceptQuest(questId)
    local definition = QuestConfig[questId]
    if not definition then
        return false, "Missão desconhecida"
    end

    if self.data.active[questId] or self.data.completed[questId] then
        return false, "Missão já aceita ou concluída"
    end

    if countEntries(self.data.active) >= GameConfig.Quests.maxActive then
        return false, "Limite de missões ativas atingido"
    end

    self.data.active[questId] = {
        id = questId,
        progress = 0,
        goal = definition.objective.count or 1,
        status = "active",
        objective = definition.objective,
    }

    self:_save()
    self:_pushUpdate()
    return true
end

function QuestManager:_completeQuest(questId, entry)
    local definition = QuestConfig[questId]
    if not definition then
        return false
    end

    entry.status = "completed"
    entry.progress = entry.goal
    entry.completedAt = os.time()

    self.data.active[questId] = nil
    self.data.completed[questId] = entry

    self:_grantRewards(definition)
    self:_save()
    self:_pushUpdate()
    return true
end

function QuestManager:_grantRewards(definition)
    local reward = definition.reward or {}
    applyRewardBundle(self, reward)

    local classRewards = reward.classRewards or reward.byClass
    if not classRewards then
        return
    end

    local playerClass = resolvePlayerClass(self.characterStats)
    if type(playerClass) == "string" then
        playerClass = string.lower(playerClass)
    end

    local classReward = classRewards and classRewards[playerClass]
    if classReward then
        applyRewardBundle(self, classReward)
    end
end

function QuestManager:UpdateProgress(questId, amount)
    amount = amount or 1
    local entry = self.data.active[questId]
    if not entry then
        return false
    end

    entry.progress = math.clamp(entry.progress + amount, 0, entry.goal)
    if entry.progress >= entry.goal then
        return self:_completeQuest(questId, entry)
    end

    self:_save()
    self:_pushUpdate()
    return true
end

function QuestManager:RegisterKill(target)
    for questId, entry in pairs(self.data.active) do
        local objective = entry.objective or {}
        if objective.type == "kill" and objective.target == target then
            self:UpdateProgress(questId, 1)
        end
    end
end

function QuestManager:RegisterCollection(target)
    for questId, entry in pairs(self.data.active) do
        local objective = entry.objective or {}
        if objective.type == "collect" and objective.target == target then
            self:UpdateProgress(questId, 1)
        end
    end
end

function QuestManager:Destroy()
    PlayerProfileStore.Save(self.player)
end

return QuestManager

