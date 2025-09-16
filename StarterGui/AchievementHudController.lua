local AchievementHudView = require(script.Parent:WaitForChild("AchievementHudView"))

local AchievementHudController = {}
AchievementHudController.__index = AchievementHudController

local function sanitizeEntries(entries)
    local sanitized = {}
    if type(entries) ~= "table" then
        return sanitized
    end

    for index, entry in ipairs(entries) do
        sanitized[index] = {
            userId = entry.userId,
            displayName = entry.displayName,
            total = tonumber(entry.total) or 0,
        }
    end

    return sanitized
end

function AchievementHudController.new(updateRemote, leaderboardRemote, playerGui)
    assert(updateRemote, "AchievementHudController.new requires an update remote event")
    assert(leaderboardRemote, "AchievementHudController.new requires a leaderboard remote")
    assert(playerGui, "AchievementHudController.new requires a PlayerGui instance")

    local onClientEvent = updateRemote.OnClientEvent
    assert(onClientEvent and onClientEvent.Connect, "Update remote must expose OnClientEvent")
    assert(leaderboardRemote.InvokeServer, "Leaderboard remote must expose InvokeServer")

    local self = setmetatable({}, AchievementHudController)
    self.view = AchievementHudView.new(playerGui)
    self._destroyed = false
    self.leaderboardRemote = leaderboardRemote
    self._leaderboardRequestToken = 0

    self.connection = onClientEvent:Connect(function(summary)
        if self.view then
            self.view:Update(summary)
        end
    end)

    self.view:SetLeaderboardLoading()
    self:_requestLeaderboard()

    return self
end

function AchievementHudController:GetView()
    return self.view
end

function AchievementHudController:_requestLeaderboard(limit)
    if not self.leaderboardRemote or self._destroyed then
        return
    end

    self._leaderboardRequestToken += 1
    local requestToken = self._leaderboardRequestToken
    local remote = self.leaderboardRemote

    self.view:SetLeaderboardLoading()

    task.spawn(function()
        local success, result = pcall(function()
            if limit then
                return remote:InvokeServer({ limit = limit })
            end
            return remote:InvokeServer()
        end)

        if self._destroyed or requestToken ~= self._leaderboardRequestToken or not self.view then
            return
        end

        if not success then
            self.view:SetLeaderboardError()
            return
        end

        if type(result) ~= "table" then
            self.view:SetLeaderboardError()
            return
        end

        self.view:SetLeaderboardEntries(sanitizeEntries(result))
    end)
end

function AchievementHudController:RefreshLeaderboard(limit)
    self:_requestLeaderboard(limit)
end

function AchievementHudController:Destroy()
    if self._destroyed then
        return
    end

    self._destroyed = true

    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    if self.view then
        self.view:Destroy()
        self.view = nil
    end
end

return AchievementHudController
