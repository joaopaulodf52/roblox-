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
local Crafting = require(script.Modules.Crafting)
local ShopManager = require(script.Modules.ShopManager)
local AchievementManager = require(script.Modules.AchievementManager)
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
local MAX_CRAFTING_REQUESTS_PER_WINDOW = 6
local MAX_SHOP_OPEN_REQUESTS_PER_WINDOW = 6
local MAX_SHOP_PURCHASE_REQUESTS_PER_WINDOW = 10
local MAX_MAP_TRAVEL_REQUESTS_PER_WINDOW = 4
local MAX_ACHIEVEMENT_LEADERBOARD_REQUESTS_PER_WINDOW = 4

local inventoryRequestCounters = {}
local combatRequestCounters = {}
local skillRequestCounters = {}
local craftingRequestCounters = {}
local shopOpenRequestCounters = {}
local shopPurchaseRequestCounters = {}
local mapTravelRequestCounters = {}
local achievementLeaderboardRequestCounters = {}

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
    craftingRequestCounters[userId] = nil
    shopOpenRequestCounters[userId] = nil
    shopPurchaseRequestCounters[userId] = nil
    mapTravelRequestCounters[userId] = nil
    achievementLeaderboardRequestCounters[userId] = nil
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

local function getItemDisplayName(itemId)
    local itemConfig = ItemsConfig[itemId]
    if itemConfig and itemConfig.name then
        return itemConfig.name
    end

    return itemId
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
    elseif action == "abandonQuest" then
        local questId = request.questId
        if not isValidString(questId) then
            return false, nil, "questId inválido"
        end

        return true, {
            action = action,
            questId = questId,
        }
    end

    return false, nil, string.format("ação não suportada: %s", tostring(action))
end

local function getMapDefinition(mapId)
    local definition = MapConfig[mapId]
    if type(definition) ~= "table" then
        return nil
    end

    if type(definition.assetName) ~= "string" then
        return nil
    end

    if type(definition.spawns) ~= "table" then
        return nil
    end

    return definition
end

local function buildSpawnSet(list)
    if type(list) ~= "table" then
        return nil
    end

    local set
    for key, value in pairs(list) do
        if type(key) == "number" then
            if type(value) == "string" then
                set = set or {}
                set[value] = true
            end
        elseif type(key) == "string" then
            if type(value) == "boolean" then
                if value then
                    set = set or {}
                    set[key] = true
                end
            elseif type(value) == "string" then
                set = set or {}
                set[key] = true
            end
        end
    end

    return set
end

local function getPlayerLevel(controller)
    if not controller or not controller.stats then
        return 1
    end

    local success, stats = pcall(function()
        return controller.stats:GetStats()
    end)

    if success and type(stats) == "table" and type(stats.level) == "number" then
        return stats.level
    end

    local rawStats = controller.stats.stats
    if type(rawStats) == "table" and type(rawStats.level) == "number" then
        return rawStats.level
    end

    return 1
end

local function normalizeSpawnRequest(spawn)
    if spawn == nil then
        return nil
    end

    if type(spawn) == "table" then
        local candidate = spawn.spawnId or spawn.id or spawn.name
        if candidate == nil then
            return nil
        end
        spawn = candidate
    end

    if not isValidString(spawn, 64) then
        return nil, "spawnId inválido"
    end

    return spawn
end

local function validateMapTravelRequest(player, controller, request)
    if type(request) ~= "table" then
        return false, nil, "payload inválido"
    end

    local mapId = request.mapId or request.id
    if not isValidString(mapId) then
        return false, nil, "mapId inválido"
    end

    local mapDefinition = getMapDefinition(mapId)
    if not mapDefinition then
        return false, nil, "mapa desconhecido"
    end

    local spawnId, spawnError = normalizeSpawnRequest(request.spawnId or request.spawn)
    if spawnError then
        return false, nil, spawnError
    end

    local resolvedSpawnCFrame
    local resolvedSpawnName
    local ok = pcall(function()
        resolvedSpawnCFrame, resolvedSpawnName = MapManager:ResolveSpawn(mapId, spawnId)
    end)

    if not ok or typeof(resolvedSpawnCFrame) ~= "CFrame" or type(resolvedSpawnName) ~= "string" then
        return false, nil, "spawn não disponível"
    end

    local travelConfig = mapDefinition.travel
    if travelConfig then
        local playerLevel = getPlayerLevel(controller)

        if type(travelConfig.minLevel) == "number" and playerLevel < travelConfig.minLevel then
            return false, nil, "nível insuficiente"
        end

        local allowedSet = buildSpawnSet(travelConfig.allowedSpawns)
        if allowedSet and not allowedSet[resolvedSpawnName] then
            return false, nil, "spawn não permitido"
        end

        local blockedSet = buildSpawnSet(travelConfig.blockedSpawns)
        if blockedSet and blockedSet[resolvedSpawnName] then
            return false, nil, "spawn não permitido"
        end

        local spawnRequirements = travelConfig.spawnRequirements
        if type(spawnRequirements) == "table" then
            local requirements = spawnRequirements[resolvedSpawnName]
            if type(requirements) == "table" then
                if requirements.allowed == false then
                    return false, nil, "spawn não permitido"
                end

                if type(requirements.minLevel) == "number" and playerLevel < requirements.minLevel then
                    return false, nil, "nível insuficiente para o spawn"
                end
            end
        end
    end

    return true, {
        mapId = mapId,
        spawnId = spawnId,
        resolvedSpawn = resolvedSpawnName,
    }
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

local function validateCraftingRequest(payload)
    if type(payload) == "string" then
        payload = {
            recipeId = payload,
        }
    end

    if type(payload) ~= "table" then
        return false, nil, "payload inválido"
    end

    local recipeId = payload.recipeId or payload.id
    if not isValidString(recipeId) then
        return false, nil, "recipeId inválido"
    end

    local recipes = ItemsConfig.recipes or {}
    if not recipes[recipeId] then
        return false, nil, "receita desconhecida"
    end

    local quantity = payload.quantity
    if quantity ~= nil and type(quantity) ~= "number" then
        return false, nil, "quantidade inválida"
    end

    return true, {
        recipeId = recipeId,
        quantity = quantity,
    }
end

local NON_CRITICAL_SHOP_FAILURES = {
    insufficient_gold = true,
    inventory_full = true,
    requirements_not_met = true,
    limit_exceeded = true,
}

local function handleMapTravelRequest(player, request)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "jogador inválido"
    end

    local controller = controllers[player]
    if not controller then
        return false, "jogador não inicializado"
    end

    if isRateLimited(mapTravelRequestCounters, player, MAX_MAP_TRAVEL_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "MapTravelRequest", "limite de requisições excedido")
        return false, "limite de requisições excedido"
    end

    local isValid, sanitized, reason = validateMapTravelRequest(player, controller, request)
    if not isValid then
        logInvalidRequest(player, "MapTravelRequest", reason or "dados inválidos")
        return false, reason or "dados inválidos"
    end

    local success, err = pcall(function()
        MapManager:SpawnPlayer(player, sanitized.mapId, sanitized.resolvedSpawn)
    end)

    if not success then
        logInvalidRequest(player, "MapTravelRequest", err or "falha ao posicionar jogador")
        return false, "falha ao posicionar jogador"
    end

    PlayerProfileStore.Update(player, function(profile)
        profile.currentMap = sanitized.mapId
        return profile
    end)

    return true, sanitized
end

local function resolvePayloadShopId(payload)
    if type(payload) == "table" then
        return payload.shopId or payload.id
    end

    if type(payload) == "string" then
        return payload
    end

    return nil
end

local function resolvePayloadItemId(payload)
    if type(payload) == "table" then
        return payload.itemId or payload.id
    end

    return nil
end

local function createPlayerControllers(player)
    local stats = CharacterStats.new(player)
    local inventory = Inventory.new(player, stats)
    local quests = QuestManager.new(player, stats, inventory)
    inventory:BindQuestManager(quests)
    local combat = Combat.new(player, stats, inventory, quests)
    local skills = Skills.new(player, stats)
    local crafting = Crafting.new(player, inventory)
    local shop = ShopManager.new(player, stats, inventory)
    local achievements = AchievementManager.new(player, stats, inventory, combat, quests)

    controllers[player] = {
        stats = stats,
        inventory = inventory,
        quests = quests,
        combat = combat,
        skills = skills,
        crafting = crafting,
        shop = shop,
        achievements = achievements,
    }
end

local function removePlayerControllers(player)
    local controller = controllers[player]
    if not controller then
        MapManager:UnbindPlayer(player)
        return
    end

    if controller.achievements then
        controller.achievements:Destroy()
    end
    controller.stats:Destroy()
    controller.inventory:Destroy()
    controller.quests:Destroy()
    controller.combat:Destroy()
    if controller.crafting then
        controller.crafting:Destroy()
    end
    if controller.skills then
        controller.skills:Destroy()
    end
    if controller.shop then
        controller.shop:Destroy()
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

Remotes.AchievementLeaderboardRequest.OnServerInvoke = function(player, payload)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return {}
    end

    if isRateLimited(achievementLeaderboardRequestCounters, player, MAX_ACHIEVEMENT_LEADERBOARD_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "AchievementLeaderboardRequest", "limite de requisições excedido")
        error("limite de requisições excedido")
    end

    local limit = resolveLeaderboardRequestLimit(payload)
    local entries, err = AchievementManager.GetLeaderboardEntriesAsync(limit)
    if not entries then
        local message = string.format("Falha ao ler leaderboard de conquistas: %s", tostring(err))
        warn(message)
        error(message)
    end

    return enrichLeaderboardEntries(entries)
end

Remotes.MapTravelRequest.OnServerEvent:Connect(function(player, payload)
    handleMapTravelRequest(player, payload)
end)

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
    elseif action == "abandonQuest" then
        controller.quests:AbandonQuest(sanitized.questId)
    end
end)

Remotes.CraftingRequest.OnServerEvent:Connect(function(player, payload)
    local controller = controllers[player]
    if not controller or not controller.crafting then
        return
    end

    if isRateLimited(craftingRequestCounters, player, MAX_CRAFTING_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "CraftingRequest", "limite de requisições excedido")
        return
    end

    local isValid, sanitized, reason = validateCraftingRequest(payload)
    if not isValid then
        logInvalidRequest(player, "CraftingRequest", reason or "dados inválidos")
        return
    end

    local success, message = controller.crafting:Craft(sanitized.recipeId, sanitized.quantity)
    if not success then
        local shouldLog = true
        if type(message) == "string" then
            if message == "Inventário cheio" or string.find(message, "Ingrediente insuficiente", 1, true) then
                shouldLog = false
            end
        end

        if shouldLog then
            logInvalidRequest(player, "CraftingRequest", message or "falha ao criar item")
        end
    end
end)

Remotes.ShopOpen.OnServerEvent:Connect(function(player, payload)
    local controller = controllers[player]
    if not controller or not controller.shop then
        return
    end

    if isRateLimited(shopOpenRequestCounters, player, MAX_SHOP_OPEN_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "ShopOpen", "limite de requisições excedido")
        return
    end

    local requestedShopId = resolvePayloadShopId(payload)
    local view, err = controller.shop:GetShopView(payload)
    if not view then
        Remotes.ShopOpen:FireClient(player, {
            action = "error",
            shopId = requestedShopId,
            message = err or "Loja indisponível",
        })

        if err ~= "ShopManager destruído" then
            logInvalidRequest(player, "ShopOpen", err or "loja inválida")
        end
        return
    end

    Remotes.ShopOpen:FireClient(player, {
        action = "open",
        shop = view,
    })
end)

Remotes.ShopPurchase.OnServerEvent:Connect(function(player, payload)
    local controller = controllers[player]
    if not controller or not controller.shop then
        return
    end

    if isRateLimited(shopPurchaseRequestCounters, player, MAX_SHOP_PURCHASE_REQUESTS_PER_WINDOW) then
        logInvalidRequest(player, "ShopPurchase", "limite de requisições excedido")
        return
    end

    local success, result, detail = controller.shop:Purchase(payload)
    if not success then
        Remotes.ShopPurchase:FireClient(player, {
            action = "result",
            success = false,
            shopId = resolvePayloadShopId(payload),
            itemId = resolvePayloadItemId(payload),
            message = result or "Compra não realizada",
            detail = detail,
        })

        local code = detail and detail.code
        if not (code and NON_CRITICAL_SHOP_FAILURES[code]) then
            logInvalidRequest(player, "ShopPurchase", result or "falha ao efetuar compra")
        end
        return
    end

    local itemName = getItemDisplayName(result.itemId)
    local totalCost = result.totalCost or 0
    local costText = ""
    if totalCost > 0 then
        costText = string.format(" por %d ouro", totalCost)
    end

    Remotes.ShopPurchase:FireClient(player, {
        action = "result",
        success = true,
        shopId = result.shopId,
        itemId = result.itemId,
        quantity = result.quantity,
        requestedQuantity = result.requestedQuantity,
        bundleSize = result.bundleSize,
        totalCost = totalCost,
        currency = result.currency,
        message = string.format("Compra concluída: %s x%d%s", itemName, result.quantity or 0, costText),
        detail = result,
    })
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

local function resolveLeaderboardRequestLimit(payload)
    if type(payload) == "table" then
        if payload.limit ~= nil then
            return payload.limit
        end
        if payload.maxEntries ~= nil then
            return payload.maxEntries
        end
    elseif type(payload) == "number" then
        return payload
    end

    return nil
end

local function enrichLeaderboardEntries(entries)
    local results = {}
    if type(entries) ~= "table" then
        return results
    end

    local userIds = {}
    local indexByUserId = {}

    for index, entry in ipairs(entries) do
        local userId = tonumber(entry.userId)
        local total = tonumber(entry.total) or 0
        local clone = {
            userId = userId,
            total = total,
        }

        results[index] = clone

        if userId and userId > 0 then
            indexByUserId[userId] = index
            table.insert(userIds, userId)

            local onlinePlayer = Players:GetPlayerByUserId(userId)
            if onlinePlayer then
                clone.displayName = onlinePlayer.DisplayName or onlinePlayer.Name
            end
        end
    end

    local missing = {}
    for _, userId in ipairs(userIds) do
        local index = indexByUserId[userId]
        if index and not results[index].displayName then
            table.insert(missing, userId)
        end
    end

    if #missing > 0 then
        local success, userInfos = pcall(function()
            return Players:GetUserInfosByUserIdsAsync(missing)
        end)

        if success and type(userInfos) == "table" then
            for _, info in ipairs(userInfos) do
                if info then
                    local targetIndex = indexByUserId[info.Id]
                    if targetIndex then
                        local entry = results[targetIndex]
                        if info.DisplayName and info.DisplayName ~= "" then
                            entry.displayName = info.DisplayName
                        elseif info.Username and info.Username ~= "" then
                            entry.displayName = info.Username
                        end
                    end
                end
            end
        else
            warn(string.format("Falha ao buscar nomes do leaderboard: %s", tostring(userInfos)))
        end
    end

    return results
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

controllers._handleMapTravelRequest = handleMapTravelRequest

return controllers

