local QuestHudView = require(script.Parent:WaitForChild("QuestHudView"))

local QuestHudController = {}
QuestHudController.__index = QuestHudController

function QuestHudController.new(remoteEvent, playerGui, inventoryRequestRemote)
    assert(remoteEvent, "QuestHudController.new requires a remote event")

    local onClientEvent = remoteEvent.OnClientEvent
    assert(onClientEvent and onClientEvent.Connect, "Remote event does not expose OnClientEvent")

    assert(playerGui, "QuestHudController.new requires a PlayerGui instance")

    local self = setmetatable({}, QuestHudController)

    self.view = QuestHudView.new(playerGui)
    self.inventoryRequestRemote = inventoryRequestRemote

    if self.view.SetAbandonQuestHandler then
        self.view:SetAbandonQuestHandler(function(questId)
            if type(questId) ~= "string" or questId == "" then
                return
            end

            local remote = self.inventoryRequestRemote
            if remote and remote.FireServer then
                remote:FireServer({
                    action = "abandonQuest",
                    questId = questId,
                })
            end
        end)
    end

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
        if self.view.SetAbandonQuestHandler then
            self.view:SetAbandonQuestHandler(nil)
        end
        self.view:Destroy()
        self.view = nil
    end

    self.inventoryRequestRemote = nil
end

return QuestHudController

