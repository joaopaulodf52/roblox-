return function()
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
    local QuestHudView = require(StarterGui:WaitForChild("QuestHudView"))
    local QuestHudController = require(StarterGui:WaitForChild("QuestHudController"))

    local function createMockRemote()
        local connections = {}

        local remote = {}
        remote.OnClientEvent = {}

        function remote.OnClientEvent:Connect(callback)
            table.insert(connections, callback)
            return {
                Disconnect = function()
                    for index, existing in ipairs(connections) do
                        if existing == callback then
                            table.remove(connections, index)
                            break
                        end
                    end
                end,
            }
        end

        function remote:Fire(summary)
            for _, callback in ipairs(connections) do
                callback(summary)
            end
        end

        return remote
    end

    local function createMockInventoryRemote()
        local remote = {}
        remote.calls = {}

        function remote:FireServer(payload)
            table.insert(self.calls, payload)
        end

        return remote
    end

    describe("QuestHudView", function()
        local playerGui

        beforeEach(function()
            playerGui = Instance.new("PlayerGui")
        end)

        afterEach(function()
            playerGui:Destroy()
        end)

        it("shows a placeholder when there are no active quests", function()
            local view = QuestHudView.new(playerGui)
            view:UpdateQuests({ active = {} })

            local questFrames = view:GetQuestFrames()
            expect(#questFrames).to.equal(0)

            local screenGui = playerGui:FindFirstChild("QuestHud")
            expect(screenGui).to.be.ok()
            local entriesContainer = screenGui:FindFirstChild("Panel"):FindFirstChild("Entries")
            local emptyLabel = entriesContainer:FindFirstChild("EmptyLabel")
            expect(emptyLabel.Visible).to.equal(true)

            view:Destroy()
        end)

        it("renders quest entries with progress and rewards", function()
            local view = QuestHudView.new(playerGui)

            view:UpdateQuests({
                active = {
                    slay_goblins = {
                        id = "slay_goblins",
                        progress = 2,
                        goal = 5,
                        plannedReward = {
                            experience = QuestConfig.slay_goblins.reward.experience,
                            gold = QuestConfig.slay_goblins.reward.gold,
                            items = {
                                potion_small = QuestConfig.slay_goblins.reward.items.potion_small,
                            },
                        },
                    },
                },
            })

            local questFrames = view:GetQuestFrames()
            expect(#questFrames).to.equal(1)

            local questFrame = questFrames[1]
            local titleLabel = questFrame:FindFirstChild("Title")
            expect(titleLabel.Text).to.equal(QuestConfig.slay_goblins.name)

            local progressLabel = questFrame:FindFirstChild("Progress")
            expect(progressLabel.Text).to.contain("2 / 5")

            local rewardLabel = questFrame:FindFirstChild("Rewards")
            expect(rewardLabel.Text).to.contain("Recompensas")
            expect(rewardLabel.Text).to.contain(tostring(QuestConfig.slay_goblins.reward.experience))
            expect(rewardLabel.Text).to.contain("Ouro")
            expect(rewardLabel.Text).to.contain("Poção de Cura Pequena")

            local screenGui = playerGui:FindFirstChild("QuestHud")
            local entriesContainer = screenGui:FindFirstChild("Panel"):FindFirstChild("Entries")
            local emptyLabel = entriesContainer:FindFirstChild("EmptyLabel")
            expect(emptyLabel.Visible).to.equal(false)

            view:Destroy()
        end)

        it("exposes an abandon button that invokes the configured handler", function()
            local view = QuestHudView.new(playerGui)
            local capturedQuestId

            view:SetAbandonQuestHandler(function(questId)
                capturedQuestId = questId
            end)

            view:UpdateQuests({
                active = {
                    slay_goblins = {
                        id = "slay_goblins",
                        progress = 0,
                        goal = 3,
                    },
                },
            })

            local questFrames = view:GetQuestFrames()
            expect(#questFrames).to.equal(1)

            local abandonButton = questFrames[1]:FindFirstChild("AbandonButton")
            expect(abandonButton).to.be.ok()

            abandonButton:Activate()

            expect(capturedQuestId).to.equal("slay_goblins")

            view:Destroy()
        end)

        it("updates the view when the remote event fires", function()
            local remote = createMockRemote()
            local controller = QuestHudController.new(remote, playerGui, createMockInventoryRemote())

            remote:Fire({
                active = {
                    gather_herbs = {
                        id = "gather_herbs",
                        progress = 1,
                        goal = 3,
                    },
                },
            })

            local frames = controller:GetView():GetQuestFrames()
            expect(#frames).to.equal(1)
            expect(frames[1].Name).to.equal("gather_herbs")

            controller:Destroy()
        end)

        it("fires an inventory request when the abandon button is activated", function()
            local remote = createMockRemote()
            local inventoryRemote = createMockInventoryRemote()
            local controller = QuestHudController.new(remote, playerGui, inventoryRemote)

            remote:Fire({
                active = {
                    slay_goblins = {
                        id = "slay_goblins",
                        progress = 0,
                        goal = 3,
                    },
                },
            })

            local frames = controller:GetView():GetQuestFrames()
            expect(#frames).to.equal(1)

            local abandonButton = frames[1]:FindFirstChild("AbandonButton")
            expect(abandonButton).to.be.ok()

            abandonButton:Activate()

            expect(#inventoryRemote.calls).to.equal(1)
            expect(inventoryRemote.calls[1]).to.be.a("table")
            expect(inventoryRemote.calls[1].action).to.equal("abandonQuest")
            expect(inventoryRemote.calls[1].questId).to.equal("slay_goblins")

            controller:Destroy()
        end)
    end)
end

