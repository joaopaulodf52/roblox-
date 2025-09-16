local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

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
        return Localization.get("rewardsNone")
    end

    local segments = {}
    if reward.experience and reward.experience > 0 then
        table.insert(segments, string.format("%d %s", reward.experience, Localization.get("xp")))
    end
    if reward.gold and reward.gold > 0 then
        table.insert(segments, string.format("%d %s", reward.gold, Localization.get("gold")))
    end
    for _, entry in ipairs(formatRewardItems(reward.items)) do
        table.insert(segments, entry)
    end

    if #segments == 0 then
        return Localization.get("rewardsNone")
    end

    return Localization.format("rewardsPrefix", table.concat(segments, ", "))
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

local function cloneLeaderboardEntries(entries)
    local copy = {}
    if type(entries) ~= "table" then
        return copy
    end

    for index, entry in ipairs(entries) do
        copy[index] = {
            userId = entry.userId,
            displayName = entry.displayName,
            total = tonumber(entry.total) or 0,
        }
    end

    return copy
end

local function formatLeaderboardEntryText(index, entry)
    local total = math.max(tonumber(entry.total) or 0, 0)
    local totalText = Localization.format("achievementsLeaderboardTotalFormat", total)
    local displayName = entry.displayName
    if type(displayName) ~= "string" or displayName == "" then
        if entry.userId then
            displayName = tostring(entry.userId)
        else
            displayName = Localization.get("achievementsLeaderboardUnknown")
        end
    end

    return Localization.format("achievementsLeaderboardEntryFormat", index, displayName, totalText)
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

    local titleLabel = createTextLabel("Title", Localization.get("achievementsTitle"), Enum.Font.GothamBold, 18, TITLE_COLOR)
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = panel

    local leaderboardTitle = createTextLabel("LeaderboardTitle", Localization.get("achievementsLeaderboardTitle"), Enum.Font.GothamBold, 16, TITLE_COLOR)
    leaderboardTitle.LayoutOrder = 2
    leaderboardTitle.Parent = panel

    local leaderboardContainer = Instance.new("Frame")
    leaderboardContainer.Name = "LeaderboardContainer"
    leaderboardContainer.BackgroundTransparency = 1
    leaderboardContainer.Size = UDim2.new(1, 0, 0, 0)
    leaderboardContainer.AutomaticSize = Enum.AutomaticSize.Y
    leaderboardContainer.LayoutOrder = 3
    leaderboardContainer.Parent = panel

    local leaderboardLayout = Instance.new("UIListLayout")
    leaderboardLayout.FillDirection = Enum.FillDirection.Vertical
    leaderboardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    leaderboardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leaderboardLayout.Padding = UDim.new(0, 4)
    leaderboardLayout.Parent = leaderboardContainer

    local leaderboardStatusLabel = createTextLabel("LeaderboardStatus", "", Enum.Font.Gotham, 14, DESCRIPTION_COLOR)
    leaderboardStatusLabel.LayoutOrder = 1
    leaderboardStatusLabel.Parent = leaderboardContainer

    local lockedTitle = createTextLabel("LockedTitle", Localization.get("achievementsLockedTitle"), Enum.Font.GothamBold, 16, TITLE_COLOR)
    lockedTitle.LayoutOrder = 4
    lockedTitle.Parent = panel

    local lockedContainer = Instance.new("Frame")
    lockedContainer.Name = "LockedContainer"
    lockedContainer.BackgroundTransparency = 1
    lockedContainer.Size = UDim2.new(1, 0, 0, 0)
    lockedContainer.AutomaticSize = Enum.AutomaticSize.Y
    lockedContainer.LayoutOrder = 5
    lockedContainer.Parent = panel

    local lockedLayout = Instance.new("UIListLayout")
    lockedLayout.FillDirection = Enum.FillDirection.Vertical
    lockedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    lockedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lockedLayout.Padding = UDim.new(0, 8)
    lockedLayout.Parent = lockedContainer

    local unlockedTitle = createTextLabel("UnlockedTitle", Localization.get("achievementsUnlockedTitle"), Enum.Font.GothamBold, 16, TITLE_COLOR)
    unlockedTitle.LayoutOrder = 6
    unlockedTitle.Parent = panel

    local unlockedContainer = Instance.new("Frame")
    unlockedContainer.Name = "UnlockedContainer"
    unlockedContainer.BackgroundTransparency = 1
    unlockedContainer.Size = UDim2.new(1, 0, 0, 0)
    unlockedContainer.AutomaticSize = Enum.AutomaticSize.Y
    unlockedContainer.LayoutOrder = 7
    unlockedContainer.Parent = panel

    local unlockedLayout = Instance.new("UIListLayout")
    unlockedLayout.FillDirection = Enum.FillDirection.Vertical
    unlockedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    unlockedLayout.SortOrder = Enum.SortOrder.LayoutOrder
    unlockedLayout.Padding = UDim.new(0, 8)
    unlockedLayout.Parent = unlockedContainer

    self.screenGui = screenGui
    self.panel = panel
    self.leaderboardContainer = leaderboardContainer
    self.leaderboardStatusLabel = leaderboardStatusLabel
    self.lockedContainer = lockedContainer
    self.unlockedContainer = unlockedContainer
    self.titleLabel = titleLabel
    self.leaderboardTitle = leaderboardTitle
    self.lockedTitle = lockedTitle
    self.unlockedTitle = unlockedTitle
    self.leaderboardEntries = {}
    self.lockedEntries = {}
    self.unlockedEntries = {}

    self.latestSummary = {}
    self.leaderboardState = {
        status = "loading",
        entries = {},
    }

    self.localizationConnection = Localization.onLanguageChanged(function()
        self:_applyLocalization()
    end)

    self:_applyLocalization()

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
    local text = Localization.format("achievementsProgressFormat", progress, goal)
    if unlocked then
        text ..= " " .. Localization.get("achievementsProgressComplete")
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
        local timestampLabel = createTextLabel("UnlockedAt", os.date(Localization.get("achievementsUnlockedAtFormat"), data.unlockedAt), Enum.Font.Gotham, 12, DESCRIPTION_COLOR)
        timestampLabel.LayoutOrder = 5
        timestampLabel.Parent = frame
    end

    return frame
end

function AchievementHudView:_createLeaderboardEntry(parent, index, entry)
    local label = createTextLabel(string.format("Entry%d", index), formatLeaderboardEntryText(index, entry), Enum.Font.Gotham, 14, TITLE_COLOR)
    label.LayoutOrder = index
    label.Parent = parent
    return label
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

function AchievementHudView:_render()
    local summary = self.latestSummary or {}
    self:_populate(
        self.lockedContainer,
        summary.locked or {},
        self.lockedEntries,
        false,
        Localization.get("achievementsNoneInProgress")
    )
    self:_populate(
        self.unlockedContainer,
        summary.unlocked or {},
        self.unlockedEntries,
        true,
        Localization.get("achievementsNoneUnlocked")
    )
end

function AchievementHudView:_renderLeaderboard()
    if not self.leaderboardStatusLabel then
        return
    end

    destroyEntries(self.leaderboardEntries)

    local state = self.leaderboardState or { status = "empty", entries = {} }
    local status = state.status

    if status == "loading" then
        self.leaderboardStatusLabel.Visible = true
        self.leaderboardStatusLabel.Text = Localization.get("achievementsLeaderboardLoading")
        return
    elseif status == "error" then
        self.leaderboardStatusLabel.Visible = true
        self.leaderboardStatusLabel.Text = Localization.get("achievementsLeaderboardError")
        return
    end

    local entries = state.entries or {}
    if #entries == 0 then
        self.leaderboardStatusLabel.Visible = true
        self.leaderboardStatusLabel.Text = Localization.get("achievementsLeaderboardEmpty")
        return
    end

    self.leaderboardStatusLabel.Visible = false
    for index, entry in ipairs(entries) do
        local frame = self:_createLeaderboardEntry(self.leaderboardContainer, index, entry)
        table.insert(self.leaderboardEntries, frame)
    end
end

function AchievementHudView:Update(summary)
    if summary == nil then
        self.latestSummary = {}
    else
        self.latestSummary = summary
    end

    self:_render()
end

function AchievementHudView:_applyLocalization()
    if self.titleLabel then
        self.titleLabel.Text = Localization.get("achievementsTitle")
    end

    if self.leaderboardTitle then
        self.leaderboardTitle.Text = Localization.get("achievementsLeaderboardTitle")
    end

    if self.lockedTitle then
        self.lockedTitle.Text = Localization.get("achievementsLockedTitle")
    end

    if self.unlockedTitle then
        self.unlockedTitle.Text = Localization.get("achievementsUnlockedTitle")
    end

    self:_render()
    self:_renderLeaderboard()
end

function AchievementHudView:Destroy()
    destroyEntries(self.leaderboardEntries)
    destroyEntries(self.lockedEntries)
    destroyEntries(self.unlockedEntries)
    if self.localizationConnection then
        self.localizationConnection:Disconnect()
        self.localizationConnection = nil
    end
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

function AchievementHudView:SetLeaderboardLoading()
    self.leaderboardState = {
        status = "loading",
        entries = {},
    }
    self:_renderLeaderboard()
end

function AchievementHudView:SetLeaderboardError()
    self.leaderboardState = {
        status = "error",
        entries = {},
    }
    self:_renderLeaderboard()
end

function AchievementHudView:SetLeaderboardEntries(entries)
    local copy = cloneLeaderboardEntries(entries)
    local status = "empty"
    if #copy > 0 then
        status = "success"
    end

    self.leaderboardState = {
        status = status,
        entries = copy,
    }

    self:_renderLeaderboard()
end

function AchievementHudView:GetLeaderboardFrames()
    return self.leaderboardEntries
end

function AchievementHudView:GetLeaderboardStatusLabel()
    return self.leaderboardStatusLabel
end

return AchievementHudView
