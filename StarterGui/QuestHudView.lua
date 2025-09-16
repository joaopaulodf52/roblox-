local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local QuestHudView = {}
QuestHudView.__index = QuestHudView

local TITLE_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local DESCRIPTION_TEXT_COLOR = Color3.fromRGB(220, 220, 220)
local REWARD_TEXT_COLOR = Color3.fromRGB(255, 234, 145)
local PANEL_BACKGROUND = Color3.fromRGB(20, 20, 20)
local ABANDON_BUTTON_COLOR = Color3.fromRGB(170, 60, 60)

local function createTextLabel(name, text, font, textSize, textColor)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize or 14
    label.TextColor3 = textColor or TITLE_TEXT_COLOR
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

local function formatRewardText(questId, questState)
    local plannedReward = questState and questState.plannedReward
    local definition = QuestConfig[questId]
    local baseReward = definition and definition.reward or {}

    local reward = {}
    if baseReward.experience then
        reward.experience = baseReward.experience
    end
    if baseReward.gold then
        reward.gold = baseReward.gold
    end
    if baseReward.items then
        reward.items = table.clone(baseReward.items)
    end

    if plannedReward then
        if plannedReward.experience then
            reward.experience = plannedReward.experience
        end
        if plannedReward.gold then
            reward.gold = plannedReward.gold
        end
        if plannedReward.items then
            reward.items = reward.items or {}
            for itemId, quantity in pairs(plannedReward.items) do
                reward.items[itemId] = quantity
            end
        end
    end

    local segments = {}
    if reward.experience and reward.experience > 0 then
        table.insert(segments, string.format("%d %s", reward.experience, Localization.get("xp")))
    end
    if reward.gold and reward.gold > 0 then
        table.insert(segments, string.format("%d %s", reward.gold, Localization.get("gold")))
    end
    for _, itemSegment in ipairs(formatRewardItems(reward.items)) do
        table.insert(segments, itemSegment)
    end

    if #segments == 0 then
        return Localization.get("rewardsNone")
    end

    return Localization.format("rewardsPrefix", table.concat(segments, ", "))
end

local function formatProgressText(progress, goal)
    progress = progress or 0
    goal = goal or 0

    local percent = 0
    if goal > 0 then
        percent = math.clamp(math.floor((progress / goal) * 100 + 0.5), 0, 100)
    end

    return Localization.format("progressFormat", progress, goal, percent)
end

function QuestHudView.new(playerGui)
    assert(playerGui, "QuestHudView.new requires a PlayerGui instance")

    local self = setmetatable({}, QuestHudView)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "QuestHud"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.BackgroundColor3 = PANEL_BACKGROUND
    panel.BackgroundTransparency = 0.35
    panel.BorderSizePixel = 0
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -20, 0, 20)
    panel.Size = UDim2.new(0, 320, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.Parent = screenGui

    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingTop = UDim.new(0, 12)
    panelPadding.PaddingBottom = UDim.new(0, 12)
    panelPadding.PaddingLeft = UDim.new(0, 12)
    panelPadding.PaddingRight = UDim.new(0, 12)
    panelPadding.Parent = panel

    local panelLayout = Instance.new("UIListLayout")
    panelLayout.FillDirection = Enum.FillDirection.Vertical
    panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
    panelLayout.Padding = UDim.new(0, 10)
    panelLayout.Parent = panel

    local titleLabel = createTextLabel("Title", Localization.get("activeQuestsTitle"), Enum.Font.GothamBold, 18, TITLE_TEXT_COLOR)
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = panel

    local entriesContainer = Instance.new("Frame")
    entriesContainer.Name = "Entries"
    entriesContainer.BackgroundTransparency = 1
    entriesContainer.Size = UDim2.new(1, 0, 0, 0)
    entriesContainer.AutomaticSize = Enum.AutomaticSize.Y
    entriesContainer.LayoutOrder = 2
    entriesContainer.Parent = panel

    local entriesLayout = Instance.new("UIListLayout")
    entriesLayout.FillDirection = Enum.FillDirection.Vertical
    entriesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    entriesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entriesLayout.Padding = UDim.new(0, 8)
    entriesLayout.Parent = entriesContainer

    local emptyLabel = createTextLabel("EmptyLabel", Localization.get("noActiveQuests"), Enum.Font.Gotham, 14, DESCRIPTION_TEXT_COLOR)
    emptyLabel.Parent = entriesContainer

    self.screenGui = screenGui
    self.panel = panel
    self.entriesContainer = entriesContainer
    self.emptyLabel = emptyLabel
    self.titleLabel = titleLabel
    self.questFrames = {}
    self.frameConnections = {}
    self.abandonQuestHandler = nil
    self.latestSummary = nil

    self.localizationConnection = Localization.onLanguageChanged(function()
        self:_applyLocalization()
    end)

    self:_applyLocalization()

    return self
end

function QuestHudView:_clearEntries()
    for _, frame in ipairs(self.questFrames) do
        local connections = self.frameConnections[frame]
        if connections then
            for _, connection in ipairs(connections) do
                if connection and connection.Disconnect then
                    connection:Disconnect()
                end
            end
            self.frameConnections[frame] = nil
        end
        frame:Destroy()
    end
    table.clear(self.questFrames)
    table.clear(self.frameConnections)
end

function QuestHudView:SetAbandonQuestHandler(handler)
    if handler ~= nil then
        assert(type(handler) == "function", "handler deve ser uma função ou nil")
    end

    self.abandonQuestHandler = handler
end

function QuestHudView:_createQuestFrame(order, questId, questState)
    local frame = Instance.new("Frame")
    frame.Name = questId
    frame.BackgroundTransparency = 0.2
    frame.BackgroundColor3 = PANEL_BACKGROUND
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y

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

    local questDefinition = QuestConfig[questId]
    local questName = questDefinition and questDefinition.name or questId
    local questDescription = questDefinition and questDefinition.description or ""

    local titleLabel = createTextLabel("Title", questName, Enum.Font.GothamBold, 16, TITLE_TEXT_COLOR)
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = frame

    local progressText = formatProgressText(questState and questState.progress, questState and questState.goal)
    local progressLabel = createTextLabel("Progress", progressText, Enum.Font.Gotham, 14, TITLE_TEXT_COLOR)
    progressLabel.LayoutOrder = 2
    progressLabel.Parent = frame

    if questDescription ~= "" then
        local descriptionLabel = createTextLabel("Description", questDescription, Enum.Font.Gotham, 14, DESCRIPTION_TEXT_COLOR)
        descriptionLabel.LayoutOrder = 3
        descriptionLabel.Parent = frame
    end

    local rewardText = formatRewardText(questId, questState)
    local rewardLabel = createTextLabel("Rewards", rewardText, Enum.Font.Gotham, 14, REWARD_TEXT_COLOR)
    rewardLabel.LayoutOrder = 4
    rewardLabel.Parent = frame

    local abandonButton = Instance.new("TextButton")
    abandonButton.Name = "AbandonButton"
    abandonButton.LayoutOrder = 5
    abandonButton.Text = Localization.get("abandonQuest")
    abandonButton.Font = Enum.Font.Gotham
    abandonButton.TextSize = 14
    abandonButton.TextColor3 = Color3.new(1, 1, 1)
    abandonButton.AutoButtonColor = false
    abandonButton.BorderSizePixel = 0
    abandonButton.Size = UDim2.new(1, 0, 0, 32)
    abandonButton.BackgroundColor3 = ABANDON_BUTTON_COLOR
    abandonButton.BackgroundTransparency = 0
    abandonButton.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = abandonButton

    local connections = {}

    local connection = abandonButton.Activated:Connect(function()
        if self.abandonQuestHandler then
            self.abandonQuestHandler(questId)
        end
    end)

    table.insert(connections, connection)

    self.frameConnections[frame] = connections

    return frame
end

function QuestHudView:_render()
    self:_clearEntries()

    local summary = self.latestSummary or {}
    local active = summary.active or {}
    local questList = {}
    for questId, questState in pairs(active) do
        table.insert(questList, { id = questId, state = questState })
    end
    table.sort(questList, function(a, b)
        return a.id < b.id
    end)

    if #questList == 0 then
        self.emptyLabel.Visible = true
        return
    end

    self.emptyLabel.Visible = false

    for index, questEntry in ipairs(questList) do
        local frame = self:_createQuestFrame(index, questEntry.id, questEntry.state)
        frame.Parent = self.entriesContainer
        table.insert(self.questFrames, frame)
    end
end

function QuestHudView:UpdateQuests(summary)
    if summary == nil then
        self.latestSummary = {}
    else
        self.latestSummary = summary
    end

    self:_render()
end

function QuestHudView:GetQuestFrames()
    return table.clone(self.questFrames)
end

function QuestHudView:_applyLocalization()
    if self.titleLabel then
        self.titleLabel.Text = Localization.get("activeQuestsTitle")
    end

    if self.emptyLabel then
        self.emptyLabel.Text = Localization.get("noActiveQuests")
    end

    self:_render()
end

function QuestHudView:Destroy()
    self:_clearEntries()
    self.abandonQuestHandler = nil
    if self.localizationConnection then
        self.localizationConnection:Disconnect()
        self.localizationConnection = nil
    end
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

return QuestHudView

