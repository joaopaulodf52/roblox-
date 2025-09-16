local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local Crafting = {}
Crafting.__index = Crafting

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

local function cloneDictionary(source)
    local copy = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            copy[key] = cloneDictionary(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Crafting.new(player, inventory)
    assert(typeof(player) == "Instance" and player:IsA("Player"), "Crafting requer um jogador válido")
    assert(inventory, "Crafting requer uma referência de inventário")

    local self = setmetatable({}, Crafting)
    self.player = player
    self.inventory = inventory
    self.profile = inventory.profile or PlayerProfileStore.Load(player)
    self.data = self.profile.crafting or {}
    self:_ensureStructure()
    return self
end

function Crafting:_ensureStructure()
    self.data.version = self.data.version or 1
    self.data.unlocked = self.data.unlocked or {}

    local statistics = self.data.statistics or {}
    statistics.totalCrafted = statistics.totalCrafted or 0
    statistics.byRecipe = statistics.byRecipe or {}
    self.data.statistics = statistics

    self.profile.crafting = self.data
end

function Crafting:_save()
    PlayerProfileStore.Update(self.player, function(profile)
        profile.crafting = self.data
        return profile
    end)
end

function Crafting:GetState()
    local statistics = self.data.statistics or {}

    return {
        unlocked = cloneDictionary(self.data.unlocked or {}),
        statistics = {
            totalCrafted = statistics.totalCrafted or 0,
            byRecipe = cloneDictionary(statistics.byRecipe or {}),
        },
    }
end

function Crafting:Craft(recipeId, quantity)
    if type(recipeId) ~= "string" or recipeId == "" then
        return false, "Receita inválida"
    end

    local recipes = ItemsConfig.recipes or {}
    local recipe = recipes[recipeId]
    if not recipe then
        return false, "Receita desconhecida"
    end

    local crafts = sanitizeQuantity(quantity, 1)
    if not crafts then
        return false, "Quantidade inválida"
    end

    local resultItemId = recipe.result or recipeId
    if not ItemsConfig[resultItemId] then
        return false, string.format("Item resultante desconhecido: %s", tostring(resultItemId))
    end

    local outputPerCraft = recipe.output
    if outputPerCraft == nil then
        outputPerCraft = 1
    end

    local sanitizedOutput = sanitizeQuantity(outputPerCraft, 1)
    if not sanitizedOutput then
        return false, "Quantidade inválida"
    end

    local ingredients = recipe.ingredients
    if type(ingredients) ~= "table" then
        return false, "Receita inválida"
    end

    local success, message = self.inventory:CraftItem(resultItemId, ingredients, crafts, sanitizedOutput)
    if not success then
        return false, message
    end

    local resultQuantity = crafts * sanitizedOutput

    self.data.unlocked[recipeId] = true

    local statistics = self.data.statistics
    statistics.totalCrafted = (statistics.totalCrafted or 0) + resultQuantity
    local byRecipe = statistics.byRecipe or {}
    byRecipe[recipeId] = (byRecipe[recipeId] or 0) + resultQuantity
    statistics.byRecipe = byRecipe

    self:_save()

    return true
end

function Crafting:Destroy()
    PlayerProfileStore.Save(self.player)
end

return Crafting
