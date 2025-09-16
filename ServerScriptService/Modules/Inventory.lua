local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local Inventory = {}
Inventory.__index = Inventory

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
    quantity = quantity or 1
    return self:_currentLoad() + quantity <= self.data.capacity
end

function Inventory:AddItem(itemId, quantity, options)
    quantity = quantity or 1
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
        for _ = 1, quantity do
            self.questManager:RegisterCollection(itemId)
        end
    end

    return true
end

function Inventory:RemoveItem(itemId, quantity)
    quantity = quantity or 1
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
    quantity = quantity or 1
    local entry = self.data.items[itemId]
    return entry ~= nil and entry.quantity >= quantity
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

