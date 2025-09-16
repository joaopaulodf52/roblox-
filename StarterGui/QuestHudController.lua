local QuestHudView = require(script.Parent:WaitForChild("QuestHudView"))

local QuestHudController = {}
QuestHudController.__index = QuestHudController

function QuestHudController.new(remoteEvent, playerGui)
    assert(remoteEvent, "QuestHudController.new requires a remote event")

    local onClientEvent = remoteEvent.OnClientEvent
    assert(onClientEvent and onClientEvent.Connect, "Remote event does not expose OnClientEvent")

    assert(playerGui, "QuestHudController.new requires a PlayerGui instance")

    local self = setmetatable({}, QuestHudController)

    self.view = QuestHudView.new(playerGui)
    self.connection = onClientEvent:Connect(function(summary)
        self.view:UpdateQuests(summary)
    end)

    return self
end

function QuestHudController:GetView()
    return self.view
end

function QuestHudController:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end

    if self.view then
        self.view:Destroy()
        self.view = nil
    end
end

return QuestHudController

