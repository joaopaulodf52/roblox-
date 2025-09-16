local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local ShopManager = {}
ShopManager.__index = ShopManager

local function sanitizeQuantity(quantity, default)
    if quantity == nil then
        quantity = default or 1
    end

    if type(quantity) ~= "number" then
        return nil
    end

    local normalized = math.floor(quantity + 0.0001)
    if normalized < 1 then
        return nil
    end

    return normalized
end

local function extractShopId(reference)
    if type(reference) == "table" then
        return reference.shopId or reference.id
    end

    return reference
end

local function extractItemId(reference)
    if type(reference) == "table" then
        return reference.itemId or reference.id
    end

    return reference
end

local function normalizeClassList(classRequirement)
    local normalized = {}
    local display = {}
    local seen = {}
    local classesConfig = GameConfig.Classes or {}

    local function append(classId)
        if type(classId) ~= "string" then
            return
        end

        local lowered = string.lower(classId)
        if seen[lowered] then
            return
        end

        seen[lowered] = true
        table.insert(normalized, lowered)

        local definition = classesConfig[lowered]
        if type(definition) == "table" and definition.name then
            table.insert(display, definition.name)
        else
            table.insert(display, string.gsub(lowered, "^%l", string.upper))
        end
    end

    if type(classRequirement) == "string" then
        append(classRequirement)
    elseif type(classRequirement) == "table" then
        if #classRequirement > 0 then
            for _, entry in ipairs(classRequirement) do
                append(entry)
            end
        else
            for key, value in pairs(classRequirement) do
                if value ~= false then
                    append(key)
                end
            end
        end
    end

    return normalized, display
end

function ShopManager.new(player, characterStats, inventory)
    assert(typeof(player) == "Instance" and player:IsA("Player"), "ShopManager requer um jogador válido")
    assert(characterStats, "ShopManager requer referência de CharacterStats")
    assert(inventory, "ShopManager requer referência de Inventory")

    local self = setmetatable({}, ShopManager)
    self.player = player
    self.characterStats = characterStats
    self.inventory = inventory
    self._destroyed = false
    return self
end

function ShopManager:_resolveShop(reference)
    local shopId = extractShopId(reference)
    if type(shopId) ~= "string" or shopId == "" then
        return nil, "Loja inválida"
    end

    local definition = ShopConfig[shopId]
    if not definition then
        for _, entry in pairs(ShopConfig) do
            if type(entry) == "table" and entry.id == shopId then
                definition = entry
                break
            end
        end
    end

    if not definition then
        return nil, string.format("Loja desconhecida: %s", tostring(shopId))
    end

    return definition, definition.id or shopId
end

function ShopManager:_resolveItem(shopDefinition, reference)
    if type(shopDefinition) ~= "table" then
        return nil, nil, "Loja inválida"
    end

    local itemId = extractItemId(reference)
    if type(itemId) ~= "string" or itemId == "" then
        return nil, nil, "Item inválido"
    end

    local items = shopDefinition.items
    if type(items) ~= "table" then
        return nil, nil, string.format("Item não disponível: %s", itemId)
    end

    for _, entry in ipairs(items) do
        if type(entry) == "table" then
            local entryId = extractItemId(entry)
            if entryId == itemId then
                return entry, entryId
            end
        end
    end

    return nil, nil, string.format("Item não disponível: %s", itemId)
end

function ShopManager:_checkRequirements(stats, requirements)
    if type(requirements) ~= "table" then
        return true
    end

    local level = stats.level or 1

    local minLevel = requirements.minLevel
    if type(minLevel) == "number" and level < minLevel then
        return false, string.format("Requer nível %d", minLevel)
    end

    local maxLevel = requirements.maxLevel
    if type(maxLevel) == "number" and level > maxLevel then
        return false, string.format("Disponível até o nível %d", maxLevel)
    end

    local classRequirement = requirements.classes or requirements.class
    if classRequirement then
        local normalized, display = normalizeClassList(classRequirement)
        if #normalized > 0 then
            local playerClass = string.lower(stats.class or "")
            local allowed = false

            for _, classId in ipairs(normalized) do
                if classId == playerClass then
                    allowed = true
                    break
                end
            end

            if not allowed then
                local label
                if #display > 0 then
                    label = table.concat(display, ", ")
                else
                    label = table.concat(normalized, ", ")
                end

                return false, string.format("Disponível para: %s", label)
            end
        end
    end

    return true
end

local function sanitizePrice(value)
    local numberValue = tonumber(value) or 0
    if numberValue < 0 then
        numberValue = 0
    end
    return numberValue
end

local function sanitizeBundleSize(value)
    return sanitizeQuantity(value, 1) or 1
end

local function sanitizeMaxQuantity(value)
    if value == nil then
        return nil
    end

    return sanitizeQuantity(value)
end

function ShopManager:GetShopView(reference)
    if self._destroyed then
        return nil, "ShopManager destruído"
    end

    local shopDefinition, resolvedIdOrError = self:_resolveShop(reference)
    if not shopDefinition then
        return nil, resolvedIdOrError
    end

    local stats = self.characterStats:GetStats()
    local currency = shopDefinition.currency or "gold"

    local view = {
        id = shopDefinition.id or resolvedIdOrError,
        name = shopDefinition.name or resolvedIdOrError,
        description = shopDefinition.description or "",
        currency = currency,
        items = {},
    }

    local items = shopDefinition.items
    if type(items) ~= "table" then
        return view
    end

    for _, entry in ipairs(items) do
        if type(entry) == "table" then
            local itemId = extractItemId(entry)
            if type(itemId) == "string" and itemId ~= "" then
                local itemConfig = ItemsConfig[itemId]
                local price = sanitizePrice(entry.price)
                local bundleSize = sanitizeBundleSize(entry.quantity)
                local maxQuantity = sanitizeMaxQuantity(entry.maxQuantity)
                local itemCurrency = entry.currency or currency
                local available, reason = true, nil

                if not itemConfig then
                    available = false
                    reason = string.format("Item desconhecido: %s", itemId)
                else
                    available, reason = self:_checkRequirements(stats, entry.requirements)
                end

                table.insert(view.items, {
                    itemId = itemId,
                    name = itemConfig and itemConfig.name or itemId,
                    description = itemConfig and itemConfig.description or "",
                    price = price,
                    currency = itemCurrency,
                    bundleSize = bundleSize,
                    available = available,
                    reason = reason,
                    maxQuantity = maxQuantity,
                })
            end
        end
    end

    return view
end

function ShopManager:Purchase(shopReference, itemReference, quantity)
    if self._destroyed then
        return false, "ShopManager destruído"
    end

    if type(shopReference) == "table" and itemReference == nil and quantity == nil then
        local payload = shopReference
        shopReference = payload.shopId or payload.id
        itemReference = payload.itemId or payload.id
        quantity = payload.quantity or payload.amount or payload.count
    end

    local shopDefinition, resolvedShopIdOrError = self:_resolveShop(shopReference)
    if not shopDefinition then
        return false, resolvedShopIdOrError, { code = "invalid_shop" }
    end

    local itemDefinition, resolvedItemId, itemError = self:_resolveItem(shopDefinition, itemReference)
    if not itemDefinition then
        return false, itemError, { code = "invalid_item" }
    end

    local sanitizedQuantity = sanitizeQuantity(quantity, 1)
    if not sanitizedQuantity then
        return false, "Quantidade inválida", { code = "invalid_quantity" }
    end

    local maxQuantity = sanitizeMaxQuantity(itemDefinition.maxQuantity)
    if maxQuantity and sanitizedQuantity > maxQuantity then
        return false,
            string.format("Limite de compra: %d", maxQuantity),
            { code = "limit_exceeded", limit = maxQuantity }
    end

    local stats = self.characterStats:GetStats()
    local available, reason = self:_checkRequirements(stats, itemDefinition.requirements)
    if not available then
        return false, reason or "Requisitos não atendidos", { code = "requirements_not_met" }
    end

    local currency = itemDefinition.currency or shopDefinition.currency or "gold"
    if currency ~= "gold" then
        return false, string.format("Moeda não suportada: %s", tostring(currency)), { code = "unsupported_currency" }
    end

    local price = sanitizePrice(itemDefinition.price)
    local totalCost = price * sanitizedQuantity

    if (stats.gold or 0) < totalCost then
        return false,
            "Ouro insuficiente",
            { code = "insufficient_gold", cost = totalCost, balance = stats.gold or 0 }
    end

    local bundleSize = sanitizeBundleSize(itemDefinition.quantity)
    local totalItems = bundleSize * sanitizedQuantity

    if not self.inventory:HasSpace(totalItems) then
        return false, "Inventário cheio", { code = "inventory_full" }
    end

    if totalCost > 0 then
        self.characterStats:AddGold(-totalCost)
    end

    local success, errorMessage = self.inventory:AddItem(resolvedItemId, totalItems)
    if not success then
        if totalCost > 0 then
            self.characterStats:AddGold(totalCost)
        end
        return false, errorMessage or "Falha ao conceder item", { code = "inventory_error" }
    end

    return true, {
        shopId = shopDefinition.id or resolvedShopIdOrError,
        itemId = resolvedItemId,
        requestedQuantity = sanitizedQuantity,
        bundleSize = bundleSize,
        quantity = totalItems,
        totalCost = totalCost,
        currency = currency,
    }
end

function ShopManager:Destroy()
    self._destroyed = true
    self.player = nil
    self.characterStats = nil
    self.inventory = nil
end

return ShopManager

