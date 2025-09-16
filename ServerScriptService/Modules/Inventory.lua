local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local Inventory = {}
Inventory.__index = Inventory

local function sanitizeQuantity(quantity, default)
    if quantity == nil then
        quantity = default or 1
    end

    if type(quantity) ~= "number" then
        return nil
    end

    local normalized = math.floor(quantity)
    if normalized < 1 then
        return nil
    end

    return normalized
end

local function cloneItemsTable(items)
    local copy = {}
    for id, entry in pairs(items) do
        copy[id] = {
            id = entry.id,
            quantity = entry.quantity,
        }
    end
    return copy
end

function Inventory.new(player, characterStats)
    local self = setmetatable({}, Inventory)
    self.player = player
    self.characterStats = characterStats
    self.profile = PlayerProfileStore.Load(player)
    self.data = self.profile.inventory
    self.questManager = nil
    self:_ensureStructure()
    self:_pushUpdate()
    return self
end

function Inventory:BindQuestManager(questManager)
    self.questManager = questManager
end

function Inventory:_ensureStructure()
    self.data.items = self.data.items or {}
    self.data.equipped = self.data.equipped or {}
    self.data.capacity = self.data.capacity or GameConfig.Inventory.maxSlots
end

function Inventory:_save()
    PlayerProfileStore.Update(self.player, function(profile)
        profile.inventory = self.data
        return profile
    end)
end

function Inventory:_pushUpdate()
    Remotes.InventoryUpdated:FireClient(self.player, self:GetSummary())
end

function Inventory:GetSummary()
    return {
        capacity = self.data.capacity,
        items = cloneItemsTable(self.data.items),
        equipped = table.clone(self.data.equipped),
    }
end

function Inventory:GetEquipped()
    return table.clone(self.data.equipped)
end

function Inventory:_currentLoad()
    local load = 0
    for _, entry in pairs(self.data.items) do
        load = load + (entry.quantity or 0)
    end
    return load
end

function Inventory:HasSpace(quantity)
    local sanitized = sanitizeQuantity(quantity, 1)
    if not sanitized then
        return false
    end

    return self:_currentLoad() + sanitized <= self.data.capacity
end

function Inventory:AddItem(itemId, quantity, options)
    local sanitizedQuantity = sanitizeQuantity(quantity, 1)
    if not sanitizedQuantity then
        return false, "Quantidade inválida"
    end

    quantity = sanitizedQuantity
    options = options or {}
    local notifyQuest = options.notifyQuest
    if notifyQuest == nil then
        notifyQuest = true
    end

    assert(ItemsConfig[itemId], string.format("Item %s não está definido", tostring(itemId)))
    if not self:HasSpace(quantity) then
        return false, "Inventário cheio"
    end

    local entry = self.data.items[itemId]
    if entry then
        entry.quantity = entry.quantity + quantity
    else
        self.data.items[itemId] = {
            id = itemId,
            quantity = quantity,
        }
    end

    self:_save()
    self:_pushUpdate()

    if notifyQuest and self.questManager then
        self.questManager:RegisterCollection(itemId, quantity)
    end

    return true
end

function Inventory:RemoveItem(itemId, quantity)
    local sanitizedQuantity = sanitizeQuantity(quantity, 1)
    if not sanitizedQuantity then
        return false, "Quantidade inválida"
    end

    quantity = sanitizedQuantity
    local entry = self.data.items[itemId]
    if not entry or entry.quantity < quantity then
        return false
    end

    entry.quantity = entry.quantity - quantity
    if entry.quantity <= 0 then
        self.data.items[itemId] = nil
    end

    self:_save()
    self:_pushUpdate()
    return true
end

function Inventory:HasItem(itemId, quantity)
    local sanitizedQuantity = sanitizeQuantity(quantity, 1)
    if not sanitizedQuantity then
        return false
    end

    quantity = sanitizedQuantity
    local entry = self.data.items[itemId]
    return entry ~= nil and entry.quantity >= quantity
end

local function normalizeIngredientsTable(ingredients)
    local normalized = {}
    for key, value in pairs(ingredients) do
        local itemId = key
        local amount = value

        if type(key) == "number" and type(value) == "table" then
            itemId = value.itemId or value.id
            amount = value.quantity or value.amount or value.count or 1
        end

        if type(itemId) ~= "string" or itemId == "" then
            return nil, "Receita inválida"
        end

        if not ItemsConfig[itemId] then
            return nil, string.format("Ingrediente desconhecido: %s", tostring(itemId))
        end

        local sanitized = sanitizeQuantity(amount, 1)
        if not sanitized then
            return nil, string.format("Quantidade inválida para %s", tostring(itemId))
        end

        normalized[itemId] = (normalized[itemId] or 0) + sanitized
    end

    if next(normalized) == nil then
        return nil, "Receita inválida"
    end

    return normalized
end

function Inventory:CraftItem(resultItemId, ingredients, crafts, outputPerCraft)
    if not ItemsConfig[resultItemId] then
        return false, string.format("Item %s não está definido", tostring(resultItemId))
    end

    local sanitizedCrafts = sanitizeQuantity(crafts, 1)
    if not sanitizedCrafts then
        return false, "Quantidade inválida"
    end

    local sanitizedOutput = sanitizeQuantity(outputPerCraft, 1)
    if not sanitizedOutput then
        return false, "Quantidade inválida"
    end

    if type(ingredients) ~= "table" then
        return false, "Receita inválida"
    end

    local normalized, normalizeError = normalizeIngredientsTable(ingredients)
    if not normalized then
        return false, normalizeError or "Receita inválida"
    end

    local totalRemoved = 0
    for itemId, baseQuantity in pairs(normalized) do
        local requiredQuantity = baseQuantity * sanitizedCrafts
        local entry = self.data.items[itemId]
        if not entry or entry.quantity < requiredQuantity then
            return false, string.format("Ingrediente insuficiente: %s", itemId)
        end
        normalized[itemId] = requiredQuantity
        totalRemoved += requiredQuantity
    end

    local resultQuantity = sanitizedCrafts * sanitizedOutput
    local finalLoad = self:_currentLoad() - totalRemoved + resultQuantity
    if finalLoad > self.data.capacity then
        return false, "Inventário cheio"
    end

    for itemId, requiredQuantity in pairs(normalized) do
        local entry = self.data.items[itemId]
        if entry then
            entry.quantity = entry.quantity - requiredQuantity
            if entry.quantity <= 0 then
                self.data.items[itemId] = nil
            end
        end
    end

    local resultEntry = self.data.items[resultItemId]
    if resultEntry then
        resultEntry.quantity = resultEntry.quantity + resultQuantity
    else
        self.data.items[resultItemId] = {
            id = resultItemId,
            quantity = resultQuantity,
        }
    end

    self:_save()
    self:_pushUpdate()

    if self.questManager then
        self.questManager:RegisterCollection(resultItemId, resultQuantity)
    end

    return true
end

function Inventory:_applyAttributes(itemId, multiplier)
    local config = ItemsConfig[itemId]
    if not config or not config.attributes then
        return
    end

    for attribute, value in pairs(config.attributes) do
        self.characterStats:ApplyAttributeModifier(attribute, value * multiplier)
    end
end

function Inventory:EquipItem(itemId)
    local config = ItemsConfig[itemId]
    assert(config, string.format("Item %s não está definido", tostring(itemId)))
    assert(config.type == "equipment", "Somente itens de equipamento podem ser equipados")

    if not self:HasItem(itemId, 1) then
        return false, "Item não disponível"
    end

    local slot = config.slot or "generic"
    local currentlyEquipped = self.data.equipped[slot]
    if currentlyEquipped == itemId then
        return true
    end

    if currentlyEquipped then
        self:_applyAttributes(currentlyEquipped, -1)
    end

    self.data.equipped[slot] = itemId
    self:_applyAttributes(itemId, 1)
    self:_save()
    self:_pushUpdate()
    return true
end

function Inventory:UnequipItem(slot)
    local equippedItem = self.data.equipped[slot]
    if not equippedItem then
        return false
    end

    self:_applyAttributes(equippedItem, -1)
    self.data.equipped[slot] = nil
    self:_save()
    self:_pushUpdate()
    return true
end

function Inventory:UseConsumable(itemId)
    local config = ItemsConfig[itemId]
    assert(config, string.format("Item %s não está definido", tostring(itemId)))
    assert(config.type == "consumable", "Somente itens consumíveis podem ser utilizados")

    if not self:HasItem(itemId, 1) then
        return false, "Item não disponível"
    end

    local effects = config.effects or {}
    if effects.health then
        self.characterStats:RestoreHealth(effects.health)
    end
    if effects.mana then
        self.characterStats:RestoreMana(effects.mana)
    end
    if effects.experience then
        self.characterStats:AddExperience(effects.experience)
    end

    self:RemoveItem(itemId, 1)
    return true
end

function Inventory:Destroy()
    PlayerProfileStore.Save(self.player)
end

return Inventory

