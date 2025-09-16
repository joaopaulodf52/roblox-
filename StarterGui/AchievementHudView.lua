local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))

local AchievementHudView = {}
AchievementHudView.__index = AchievementHudView

local TITLE_COLOR = Color3.fromRGB(255, 255, 255)
local DESCRIPTION_COLOR = Color3.fromRGB(220, 220, 220)
local REWARD_COLOR = Color3.fromRGB(255, 234, 145)
local PANEL_COLOR = Color3.fromRGB(18, 18, 18)

local function createTextLabel(name, text, font, textSize, textColor)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 14
    label.TextColor3 = textColor or TITLE_COLOR
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextWrapped = true
    label.Text = text or ""
    return label
end

local function formatRewardItems(items)
    local segments = {}
    for itemId, quantity in pairs(items or {}) do
        local itemConfig = ItemsConfig[itemId]
        local itemName = itemConfig and itemConfig.name or itemId
        table.insert(segments, string.format("%s x%d", itemName, quantity))
    end
    return segments
end

local function formatRewardText(reward)
    if not reward then
        return "Recompensas: nenhuma"
    end

    local segments = {}
    if reward.experience and reward.experience > 0 then
        table.insert(segments, string.format("%d XP", reward.experience))
    end
    if reward.gold and reward.gold > 0 then
        table.insert(segments, string.format("%d Ouro", reward.gold))
    end
    for _, entry in ipairs(formatRewardItems(reward.items)) do
        table.insert(segments, entry)
    end

    if #segments == 0 then
        return "Recompensas: nenhuma"
    end

    return "Recompensas: " .. table.concat(segments, ", ")
end

local function toSortedArray(dictionary)
    local array = {}
    for _, entry in pairs(dictionary or {}) do
        table.insert(array, entry)
    end
    table.sort(array, function(a, b)
        return string.lower(a.name or a.id) < string.lower(b.name or b.id)
    end)
    return array
end

function AchievementHudView.new(playerGui)
    assert(playerGui, "AchievementHudView.new requires a PlayerGui instance")

    local self = setmetatable({}, AchievementHudView)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AchievementHud"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.BackgroundColor3 = PANEL_COLOR
    panel.BackgroundTransparency = 0.35
    panel.BorderSizePixel = 0
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -360, 0, 20)
    panel.Size = UDim2.new(0, 320, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Parent = screenGui

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = panel

    local titleLabel = createTextLabel("Title", "Conquistas", Enum.Font.GothamBold, 18, TITLE_COLOR)
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = panel

    local lockedTitle = createTextLabel("LockedTitle", "Em Progresso", Enum.Font.GothamBold, 16, TITLE_COLOR)
    lockedTitle.LayoutOrder = 2
    lockedTitle.Parent = panel

    local lockedContainer = Instance.new("Frame")
    lockedContainer.Name = "LockedContainer"
    lockedContainer.BackgroundTransparency = 1
    lockedContainer.Size = UDim2.new(1, 0, 0, 0)
    lockedContainer.AutomaticSize = Enum.AutomaticSize.Y
    lockedContainer.LayoutOrder = 3
    lockedContainer.Parent = panel

    local lockedLayout = Instance.new("UIListLayout")
    lockedLayout.FillDirection = Enum.FillDirection.Vertical
    lockedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    lockedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lockedLayout.Padding = UDim.new(0, 8)
    lockedLayout.Parent = lockedContainer

    local unlockedTitle = createTextLabel("UnlockedTitle", "Conquistas Desbloqueadas", Enum.Font.GothamBold, 16, TITLE_COLOR)
    unlockedTitle.LayoutOrder = 4
    unlockedTitle.Parent = panel

    local unlockedContainer = Instance.new("Frame")
    unlockedContainer.Name = "UnlockedContainer"
    unlockedContainer.BackgroundTransparency = 1
    unlockedContainer.Size = UDim2.new(1, 0, 0, 0)
    unlockedContainer.AutomaticSize = Enum.AutomaticSize.Y
    unlockedContainer.LayoutOrder = 5
    unlockedContainer.Parent = panel

    local unlockedLayout = Instance.new("UIListLayout")
    unlockedLayout.FillDirection = Enum.FillDirection.Vertical
    unlockedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    unlockedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    unlockedLayout.Padding = UDim.new(0, 8)
    unlockedLayout.Parent = unlockedContainer

    self.screenGui = screenGui
    self.panel = panel
    self.lockedContainer = lockedContainer
    self.unlockedContainer = unlockedContainer
    self.lockedEntries = {}
    self.unlockedEntries = {}

    return self
end

local function destroyEntries(entries)
    for _, entry in ipairs(entries) do
        if entry then
            entry:Destroy()
        end
    end
    table.clear(entries)
end

local function formatProgress(progress, goal, unlocked)
    progress = progress or 0
    goal = goal or 0
    local text = string.format("Progresso: %d / %d", progress, goal)
    if unlocked then
        text ..= " (concluído)"
    end
    return text
end

function AchievementHudView:_createEntry(parent, data, unlocked)
    local frame = Instance.new("Frame")
    frame.Name = data.id or "Achievement"
    frame.BackgroundTransparency = 0.2
    frame.BackgroundColor3 = PANEL_COLOR
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = 1
    frame.Parent = parent

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = frame

    local nameLabel = createTextLabel("Name", data.name or data.id, Enum.Font.GothamBold, 16, TITLE_COLOR)
    nameLabel.LayoutOrder = 1
    nameLabel.Parent = frame

    if data.description and data.description ~= "" then
        local description = createTextLabel("Description", data.description, Enum.Font.Gotham, 14, DESCRIPTION_COLOR)
        description.LayoutOrder = 2
        description.Parent = frame
    end

    local progressLabel = createTextLabel("Progress", formatProgress(data.progress, data.goal, unlocked), Enum.Font.Gotham, 14, DESCRIPTION_COLOR)
    progressLabel.LayoutOrder = 3
    progressLabel.Parent = frame

    local rewardText = formatRewardText(data.reward)
    local rewardLabel = createTextLabel("Reward", rewardText, Enum.Font.Gotham, 14, REWARD_COLOR)
    rewardLabel.LayoutOrder = 4
    rewardLabel.Parent = frame

    if unlocked and data.unlockedAt then
        local timestampLabel = createTextLabel("UnlockedAt", os.date("Conquistado em %d/%m/%Y %H:%M", data.unlockedAt), Enum.Font.Gotham, 12, DESCRIPTION_COLOR)
        timestampLabel.LayoutOrder = 5
        timestampLabel.Parent = frame
    end

    return frame
end

function AchievementHudView:_populate(container, entries, cache, unlocked, emptyMessage)
    destroyEntries(cache)

    local ordered = toSortedArray(entries)
    if #ordered == 0 then
        local emptyLabel = createTextLabel("Empty", emptyMessage, Enum.Font.Gotham, 14, DESCRIPTION_COLOR)
        emptyLabel.Parent = container
        table.insert(cache, emptyLabel)
        return
    end

    for _, entry in ipairs(ordered) do
        local frame = self:_createEntry(container, entry, unlocked)
        table.insert(cache, frame)
    end
end

function AchievementHudView:Update(summary)
    summary = summary or {}
    self:_populate(self.lockedContainer, summary.locked or {}, self.lockedEntries, false, "Nenhuma conquista em andamento")
    self:_populate(self.unlockedContainer, summary.unlocked or {}, self.unlockedEntries, true, "Nenhuma conquista desbloqueada")
end

function AchievementHudView:Destroy()
    destroyEntries(self.lockedEntries)
    destroyEntries(self.unlockedEntries)
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

return AchievementHudView
