local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))

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
    label.Text = "Carregando..."
    label.Parent = screenGui
    return label
end

local statsLabel = createLabel("StatsLabel", UDim2.new(0, 20, 0, 20))
local inventoryLabel = createLabel("InventoryLabel", UDim2.new(0, 320, 0, 20))
local combatLabel = createLabel("CombatLabel", UDim2.new(0, 20, 0, 220))
combatLabel.Size = UDim2.new(0, 280, 0, 80)
combatLabel.Text = "Último combate: aguardando..."

local function renderStats(stats)
    if not stats then
        return
    end

    statsLabel.Text = string.format(
        "Nível: %d\nXP: %d\nVida: %d / %d\nMana: %d / %d\nAtaque: %d\nDefesa: %d\nOuro: %d",
        stats.level or 1,
        stats.experience or 0,
        stats.health or 0,
        stats.maxHealth or 0,
        stats.mana or 0,
        stats.maxMana or 0,
        stats.attack or 0,
        stats.defense or 0,
        stats.gold or 0
    )
end

local function renderInventory(summary)
    if not summary then
        return
    end

    local lines = {
        string.format("Capacidade: %d", summary.capacity or 0),
        "Itens:",
    }

    local items = summary.items or {}
    if next(items) == nil then
        table.insert(lines, "  (vazio)")
    else
        for _, entry in pairs(items) do
            local itemConfig = ItemsConfig[entry.id]
            local itemName = itemConfig and itemConfig.name or entry.id
            table.insert(lines, string.format("  %s x%d", itemName, entry.quantity))
        end
    end

    table.insert(lines, "Equipados:")
    local equipped = summary.equipped or {}
    if next(equipped) == nil then
        table.insert(lines, "  (nenhum)")
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
    if not event then
        return
    end

    local text = string.format(
        "%s atacou %s causando %d de dano%s",
        event.attacker or "?",
        event.target or "?",
        event.damage or 0,
        event.defeated and " (inimigo derrotado)" or ""
    )

    if event.weapon then
        local weaponConfig = ItemsConfig[event.weapon]
        local weaponName = weaponConfig and weaponConfig.name or event.weapon
        text = text .. string.format(" usando %s", weaponName)
    end

    combatLabel.Text = text
end

Remotes.StatsUpdated.OnClientEvent:Connect(renderStats)
Remotes.InventoryUpdated.OnClientEvent:Connect(renderInventory)
Remotes.CombatNotification.OnClientEvent:Connect(handleCombat)

