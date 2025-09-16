local AchievementHudView = require(script.Parent:WaitForChild("AchievementHudView"))

local AchievementHudController = {}
AchievementHudController.__index = AchievementHudController

function AchievementHudController.new(remoteEvent, playerGui)
    assert(remoteEvent, "AchievementHudController.new requires a remote event")
    assert(playerGui, "AchievementHudController.new requires a PlayerGui instance")

    local onClientEvent = remoteEvent.OnClientEvent
    assert(onClientEvent and onClientEvent.Connect, "Remote event does not expose OnClientEvent")

    local self = setmetatable({}, AchievementHudController)
    self.view = AchievementHudView.new(playerGui)
    self.connection = onClientEvent:Connect(function(summary)
        self.view:Update(summary)
    end)

    return self
end

function AchievementHudController:GetView()
    return self.view
end

function AchievementHudController:Destroy()
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
