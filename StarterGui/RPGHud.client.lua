local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPGHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function createLabel(name, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Size = UDim2.new(0, 280, 0, 180)
    label.Position = position
    label.Text = Localization.get("loading")
    label.Parent = screenGui
    return label
end

local statsLabel = createLabel("StatsLabel", UDim2.new(0, 20, 0, 20))
local inventoryLabel = createLabel("InventoryLabel", UDim2.new(0, 320, 0, 20))
local combatLabel = createLabel("CombatLabel", UDim2.new(0, 20, 0, 220))
combatLabel.Size = UDim2.new(0, 280, 0, 80)
combatLabel.Text = string.format("%s %s", Localization.get("lastCombat"), Localization.get("waiting"))

local lastStats
local lastInventory
local lastCombatEvent

local function renderStats(stats)
    lastStats = stats

    if not stats then
        statsLabel.Text = Localization.get("loading")
        return
    end

    local lines = {
        string.format("%s: %d", Localization.get("level"), stats.level or 1),
        string.format("%s: %d", Localization.get("xp"), stats.experience or 0),
        string.format("%s: %d / %d", Localization.get("health"), stats.health or 0, stats.maxHealth or 0),
        string.format("%s: %d / %d", Localization.get("mana"), stats.mana or 0, stats.maxMana or 0),
        string.format("%s: %d", Localization.get("attack"), stats.attack or 0),
        string.format("%s: %d", Localization.get("defense"), stats.defense or 0),
        string.format("%s: %d", Localization.get("gold"), stats.gold or 0),
    }

    statsLabel.Text = table.concat(lines, "\n")
end

local function renderInventory(summary)
    lastInventory = summary

    if not summary then
        inventoryLabel.Text = Localization.get("loading")
        return
    end

    local lines = {
        string.format("%s: %d", Localization.get("capacity"), summary.capacity or 0),
        Localization.get("items") .. ":",
    }

    local items = summary.items or {}
    if next(items) == nil then
        table.insert(lines, "  " .. Localization.get("empty"))
    else
        for _, entry in pairs(items) do
            local itemConfig = ItemsConfig[entry.id]
            local itemName = itemConfig and itemConfig.name or entry.id
            table.insert(lines, string.format("  %s x%d", itemName, entry.quantity))
        end
    end

    table.insert(lines, Localization.get("equipped") .. ":")
    local equipped = summary.equipped or {}
    if next(equipped) == nil then
        table.insert(lines, "  " .. Localization.get("none"))
    else
        for slot, itemId in pairs(equipped) do
            local itemConfig = ItemsConfig[itemId]
            local itemName = itemConfig and itemConfig.name or itemId
            table.insert(lines, string.format("  %s: %s", slot, itemName))
        end
    end

    inventoryLabel.Text = table.concat(lines, "\n")
end

local function handleCombat(event)
    lastCombatEvent = event

    if not event then
        combatLabel.Text = string.format("%s %s", Localization.get("lastCombat"), Localization.get("waiting"))
        return
    end

    local defeatedSuffix = event.defeated and Localization.get("combatDefeatedSuffix") or ""
    local text = Localization.format(
        "combatAttack",
        event.attacker or "?",
        event.target or "?",
        event.damage or 0,
        defeatedSuffix
    )

    if event.weapon then
        local weaponConfig = ItemsConfig[event.weapon]
        local weaponName = weaponConfig and weaponConfig.name or event.weapon
        text ..= Localization.format("combatUsingWeapon", weaponName)
    end

    combatLabel.Text = text
end

Remotes.StatsUpdated.OnClientEvent:Connect(renderStats)
Remotes.InventoryUpdated.OnClientEvent:Connect(renderInventory)
Remotes.CombatNotification.OnClientEvent:Connect(handleCombat)

Localization.onLanguageChanged(function()
    renderStats(lastStats)
    renderInventory(lastInventory)
    handleCombat(lastCombatEvent)
end)

