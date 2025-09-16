local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataMigrations = require(script.Modules.DataMigrations)
local DataStoreManager = require(script.Modules.DataStoreManager)
local PlayerProfileStore = require(script.Modules.PlayerProfileStore)
local CharacterStats = require(script.Modules.CharacterStats)
local Inventory = require(script.Modules.Inventory)
local QuestManager = require(script.Modules.QuestManager)
local Combat = require(script.Modules.Combat)
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

DataMigrations.Register()
local migrationState = DataStoreManager:RunMigrations()
print(string.format("Migrations executadas. Versão atual: %d", migrationState.version))

local controllers = {}

local function createPlayerControllers(player)
    local stats = CharacterStats.new(player)
    local inventory = Inventory.new(player, stats)
    local quests = QuestManager.new(player, stats, inventory)
    inventory:BindQuestManager(quests)
    local combat = Combat.new(player, stats, inventory, quests)

    controllers[player] = {
        stats = stats,
        inventory = inventory,
        quests = quests,
        combat = combat,
    }
end

local function removePlayerControllers(player)
    local controller = controllers[player]
    if not controller then
        return
    end

    controller.stats:Destroy()
    controller.inventory:Destroy()
    controller.quests:Destroy()
    controllers[player] = nil
    PlayerProfileStore.Save(player)
    PlayerProfileStore.Clear(player)
end

Players.PlayerAdded:Connect(function(player)
    PlayerProfileStore.Load(player)
    createPlayerControllers(player)
end)

Players.PlayerRemoving:Connect(removePlayerControllers)

Remotes.InventoryRequest.OnServerEvent:Connect(function(player, request)
    local controller = controllers[player]
    if not controller or type(request) ~= "table" then
        return
    end

    local action = request.action
    if action == "equip" then
        controller.inventory:EquipItem(request.itemId)
    elseif action == "unequip" then
        controller.inventory:UnequipItem(request.slot)
    elseif action == "use" then
        controller.inventory:UseConsumable(request.itemId)
    elseif action == "acceptQuest" then
        controller.quests:AcceptQuest(request.questId)
    end
end)

Remotes.CombatRequest.OnServerEvent:Connect(function(player, targetPlayer, weaponId)
    local controller = controllers[player]
    if not controller then
        return
    end

    if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
        local targetController = controllers[targetPlayer]
        if targetController then
            controller.combat:AttackTarget(targetController.stats, weaponId)
        end
    elseif type(targetPlayer) == "table" and targetPlayer.characterStats then
        controller.combat:AttackTarget(targetPlayer.characterStats, weaponId)
    end
end)

return controllers

