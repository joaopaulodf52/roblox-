return function()
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local AchievementHudView = require(StarterGui:WaitForChild("AchievementHudView"))
    local AchievementHudController = require(StarterGui:WaitForChild("AchievementHudController"))
    local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

    local supportedLanguages = { "pt", "en" }

    local function createMockRemoteEvent()
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

    local function createMockRemoteFunction()
        local remote = { calls = {}, responses = {} }

        function remote:queueResponse(response)
            table.insert(self.responses, response)
        end

        function remote:InvokeServer(payload)
            table.insert(self.calls, payload)
            local response = table.remove(self.responses, 1)
            if not response then
                return nil
            end
            if response.error then
                error(response.error)
            end
            return response.result
        end

        return remote
    end

    describe("AchievementHudView", function()
        local playerGui

        beforeEach(function()
            Localization.setLanguage("pt")
            playerGui = Instance.new("PlayerGui")
        end)

        afterEach(function()
            playerGui:Destroy()
        end)

        it("renders leaderboard entries and reacts to localization changes", function()
            local view = AchievementHudView.new(playerGui)

            view:SetLeaderboardEntries({
                { userId = 1, displayName = "Aventureiro", total = 5 },
                { userId = 2, total = 3 },
            })

            local statusLabel = view:GetLeaderboardStatusLabel()
            expect(statusLabel.Visible).to.equal(false)

            local frames = view:GetLeaderboardFrames()
            expect(#frames).to.equal(2)
            expect(frames[1].Text).to.contain("#1")
            expect(frames[1].Text).to.contain("Aventureiro")
            expect(frames[1].Text).to.contain("5")

            Localization.setLanguage("en")
            task.wait()

            frames = view:GetLeaderboardFrames()
            expect(#frames).to.equal(2)
            expect(frames[1].Text).to.contain("#1")
            expect(frames[1].Text).to.contain("Aventureiro")
            expect(frames[1].Text).to.contain(Localization.format("achievementsLeaderboardTotalFormat", 5))

            view:Destroy()
            Localization.setLanguage("pt")
        end)

        for _, language in ipairs(supportedLanguages) do
            it(string.format("shows error messages for leaderboard failures (%s)", language), function()
                Localization.setLanguage(language)
                local view = AchievementHudView.new(playerGui)

                view:SetLeaderboardError()

                local statusLabel = view:GetLeaderboardStatusLabel()
                expect(statusLabel.Visible).to.equal(true)
                expect(statusLabel.Text).to.equal(Localization.get("achievementsLeaderboardError"))

                view:Destroy()
            end)
        end
    end)

    describe("AchievementHudController", function()
        local playerGui

        beforeEach(function()
            Localization.setLanguage("pt")
            playerGui = Instance.new("PlayerGui")
        end)

        afterEach(function()
            playerGui:Destroy()
        end)

        it("requests the leaderboard on creation and updates the view", function()
            local updateRemote = createMockRemoteEvent()
            local leaderboardRemote = createMockRemoteFunction()
            leaderboardRemote:queueResponse({
                result = {
                    { userId = 10, displayName = "Herói", total = 8 },
                },
            })

            local controller = AchievementHudController.new(updateRemote, leaderboardRemote, playerGui)
            task.wait()

            expect(#leaderboardRemote.calls).to.equal(1)
            local frames = controller:GetView():GetLeaderboardFrames()
            expect(#frames).to.equal(1)
            expect(frames[1].Text).to.contain("Herói")
            expect(frames[1].Text).to.contain("8")

            controller:Destroy()
        end)

        it("shows an error state when the leaderboard request fails", function()
            local updateRemote = createMockRemoteEvent()
            local leaderboardRemote = createMockRemoteFunction()
            leaderboardRemote:queueResponse({ error = "Falha" })

            local controller = AchievementHudController.new(updateRemote, leaderboardRemote, playerGui)
            task.wait()

            local statusLabel = controller:GetView():GetLeaderboardStatusLabel()
            expect(statusLabel.Visible).to.equal(true)
            expect(statusLabel.Text).to.equal(Localization.get("achievementsLeaderboardError"))

            controller:Destroy()
        end)
    end)
end
