local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataMigrations = require(script.Modules.DataMigrations)
local DataStoreManager = require(script.Modules.DataStoreManager)
local PlayerProfileStore = require(script.Modules.PlayerProfileStore)
local CharacterStats = require(script.Modules.CharacterStats)
local Inventory = require(script.Modules.Inventory)
local QuestManager = require(script.Modules.QuestManager)
local Combat = require(script.Modules.Combat)
local Skills = require(script.Modules.Skills)
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))
local MapManager = require(script.Modules.MapManager)

DataMigrations.Register()

local migrationState
local success, err = pcall(function()
    migrationState = DataStoreManager:RunMigrations()
end)

if success and migrationState then
    print(string.format("Migrations executadas. Versão atual: %d", migrationState.version))
else
    warn("Migrations falharam: " .. tostring(err))
end

local controllers = {}

MapManager:EnsureLoaded(MapConfig.defaultMap)

local RATE_LIMIT_WINDOW = 1
local MAX_INVENTORY_REQUESTS_PER_WINDOW = 8
local MAX_COMBAT_REQUESTS_PER_WINDOW = 12
local MAX_SKILL_REQUESTS_PER_WINDOW = 15

local inventoryRequestCounters = {}
local combatRequestCounters = {}
local skillRequestCounters = {}

local function logInvalidRequest(player, requestType, reason)
    local playerName = player and player.Name or "Desconhecido"
    warn(string.format("Solicitação inválida (%s) de %s: %s", requestType, playerName, reason))
end

local function clearRateLimitState(player)
    if not player then
        return
    end

    local userId = player.UserId
    inventoryRequestCounters[userId] = nil
    combatRequestCounters[userId] = nil
    skillRequestCounters[userId] = nil
end

local function isRateLimited(counter, player, maxRequests)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end

    local userId = player.UserId
    if not userId then
        return false
    end

    local now = os.clock()
    local entry = counter[userId]
    if not entry or now - entry.windowStart >= RATE_LIMIT_WINDOW then
        counter[userId] = {
            windowStart = now,
            count = 1,
        }
        return false
    end

    if entry.count >= maxRequests then
        entry.count += 1
        return true
    end

    entry.count += 1
    return false
end

local function isValidString(value, maxLength)
    return type(value) == "string" and value ~= "" and #value <= (maxLength or 64)
end

local function validateInventoryRequest(request)
    if type(request) ~= "table" then
        return false, nil, "payload inválido"
    end

    local action = request.action
    if type(action) ~= "string" then
        return false, nil, "ação inválida"
    end

    if action == "equip" or action == "use" then
        local itemId = request.itemId
        if not isValidString(itemId) then
            return false, nil, "itemId inválido"
        end

        local itemConfig = ItemsConfig[itemId]
        if not itemConfig then
            return false, nil, "item desconhecido"
        end

        if action == "equip" and itemConfig.type ~= "equipment" then
            return false, nil, "item não pode ser equipado"
        end

        if action == "use" and itemConfig.type ~= "consumable" then
            return false, nil, "item não pode ser consumido"
        end

        return true, {
            action = action,
            itemId = itemId,
        }
    elseif action == "unequip" then
        local slot = request.slot
        if not isValidString(slot, 32) then
            return false, nil, "slot inválido"
        end

        return true, {
            action = action,
            slot = slot,
        }
    elseif action == "acceptQuest" then
        local questId = request.questId
        if not isValidString(questId) then
            return false, nil, "questId inválido"
        end

        if not QuestConfig[questId] then
            return false, nil, "missão desconhecida"
        end

        return true, {
            action = action,
            questId = questId,
        }
    end

    return false, nil, string.format("ação não suportada: %s", tostring(action))
end

local function validateCombatRequest(player, targetPlayer, weaponId)
    local sanitizedWeaponId

    if weaponId ~= nil then
        if not isValidString(weaponId) then
            return false, nil, nil, "weaponId inválido"
        end

        local weaponConfig = ItemsConfig[weaponId]
        if not weaponConfig or weaponConfig.type ~= "equipment" then
            return false, nil, nil, "arma desconhecida"
        end

        sanitizedWeaponId = weaponId
    end

    if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
        return false, nil, sanitizedWeaponId, "alvo inválido"
    end

    if targetPlayer == player then
        return false, nil, sanitizedWeaponId, "autoalvo não permitido"
    end

    return true, targetPlayer, sanitizedWeaponId
end

local function createPlayerControllers(player)
    local stats = CharacterStats.new(player)
    local inventory = Inventory.new(player, stats)
    local quests = QuestManager.new(player, stats, inventory)
    inventory:BindQuestManager(quests)
    local combat = Combat.new(player, stats, inventory, quests)
    local skills = Skills.new(player, stats)

    controllers[player] = {
        stats = stats,
        inventory = inventory,
        quests = quests,
        combat = combat,
        skills = skills,
    }
end

local function removePlayerControllers(player)
    local controller = controllers[player]
    if not controller then
        MapManager:UnbindPlayer(player)
        return
    end

    controller.stats:Destroy()
    controller.inventory:Destroy()
    controller.quests:Destroy()
    controller.combat:Destroy()
    if controller.skills then
        controller.skills:Destroy()
    end
    controllers[player] = nil
    PlayerProfileStore.Save(player)
    PlayerProfileStore.Clear(player)
    clearRateLimitState(player)
    MapManager:UnbindPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    local profile = PlayerProfileStore.Load(player)
    local targetMapId = profile.currentMap or MapConfig.defaultMap

    local success, err = pcall(function()
        MapManager:SpawnPlayer(player, targetMapId)
    end)

    if not success then
        warn(string.format("Falha ao posicionar jogador %s no mapa '%s': %s", player.Name, tostring(targetMapId), err))
        MapManager:SpawnPlayer(player, MapConfig.defaultMap)
        targetMapId = MapConfig.defaultMap
    end

    PlayerProfileStore.Update(player, function(data)
        data.currentMap = targetMapId
        return data
    end)

    createPlayerControllers(player)
end)

Players.PlayerRemoving:Connect(removePlayerControllers)

Remotes.InventoryRequest.OnServerEvent:Connect(function(player, request)
    local controller = controllers[player]
    if not controller then
        return
    end

    if isRateLimited(inventoryRequestCounters, player, MAX_INVENTORY_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "InventoryRequest", "limite de requisições excedido")
        return
    end

    local isValid, sanitized, reason = validateInventoryRequest(request)
    if not isValid then
        logInvalidRequest(player, "InventoryRequest", reason or "dados inválidos")
        return
    end

    local action = sanitized.action
    if action == "equip" then
        controller.inventory:EquipItem(sanitized.itemId)
    elseif action == "unequip" then
        controller.inventory:UnequipItem(sanitized.slot)
    elseif action == "use" then
        controller.inventory:UseConsumable(sanitized.itemId)
    elseif action == "acceptQuest" then
        controller.quests:AcceptQuest(sanitized.questId)
    end
end)

Remotes.CombatRequest.OnServerEvent:Connect(function(player, targetPlayer, weaponId)
    local controller = controllers[player]
    if not controller then
        return
    end

    if isRateLimited(combatRequestCounters, player, MAX_COMBAT_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "CombatRequest", "limite de requisições excedido")
        return
    end

    local isValid, sanitizedTarget, sanitizedWeapon, reason = validateCombatRequest(player, targetPlayer, weaponId)
    if not isValid then
        logInvalidRequest(player, "CombatRequest", reason or "dados inválidos")
        return
    end

    if typeof(sanitizedTarget) == "Instance" and sanitizedTarget:IsA("Player") then
        local targetController = controllers[sanitizedTarget]
        if targetController then
            controller.combat:AttackTarget(targetController.stats, sanitizedWeapon)
        end
    end
end)

local function extractSkillId(payload)
    if type(payload) == "table" then
        return payload.skillId or payload.id
    end

    return payload
end

local function validateSkillRequest(payload)
    local skillId = extractSkillId(payload)
    if not isValidString(skillId) then
        return false, nil, "skillId inválido"
    end

    return true, skillId
end

Remotes.SkillRequest.OnServerEvent:Connect(function(player, payload)
    local controller = controllers[player]
    if not controller or not controller.skills then
        return
    end

    if isRateLimited(skillRequestCounters, player, MAX_SKILL_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "SkillRequest", "limite de requisições excedido")
        return
    end

    local isValid, skillId, reason = validateSkillRequest(payload)
    if not isValid then
        logInvalidRequest(player, "SkillRequest", reason or "dados inválidos")
        return
    end

    local success, message, detail = controller.skills:UseSkill(skillId)
    if not success then
        local code = detail and detail.code
        if code ~= "cooldown" and code ~= "insufficient_mana" then
            logInvalidRequest(player, "SkillRequest", message or "falha ao executar habilidade")
        end
    end
end)

return controllers

