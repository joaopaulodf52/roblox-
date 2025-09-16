return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
    local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))
    local QuestManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("QuestManager"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("QuestManager", function()
        local mockStore

        beforeAll(function()
            mockStore = MockProfileStore.new()
        end)

        afterAll(function()
            mockStore:restore()
        end)

        local player

        local function createControllers()
            local statsController = CharacterStats.new(player)
            local inventoryController = Inventory.new(player, statsController)
            local questController = QuestManager.new(player, statsController, inventoryController)
            inventoryController:BindQuestManager(questController)
            return statsController, inventoryController, questController
        end

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("QuestUser")
        end)

        afterEach(function()
            TestPlayers.destroy(player)
        end)

        it("accepts known quests and rejects unknown entries", function()
            local statsController, inventoryController, questController = createControllers()

            local accepted = questController:AcceptQuest("slay_goblins")
            local rejected, rejectErr = questController:AcceptQuest("unknown_quest")

            expect(accepted).to.equal(true)
            expect(rejected).to.equal(false)
            expect(rejectErr).never.to.equal(nil)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("tracks progress and rewards the player upon completion", function()
            local statsController, inventoryController, questController = createControllers()
            local startingStats = statsController:GetStats()

            questController:AcceptQuest("slay_goblins")
            for _ = 1, QuestConfig.slay_goblins.objective.count do
                questController:RegisterKill("Goblin")
            end

            local summary = questController:GetSummary()
            expect(summary.active.slay_goblins).to.equal(nil)
            expect(summary.completed.slay_goblins).to.be.ok()

            local rewards = QuestConfig.slay_goblins.reward
            local updatedStats = statsController:GetStats()
            local expectedLevel = startingStats.level
            local expectedExperience = startingStats.experience + (rewards.experience or 0)
            local expToLevel = GameConfig.getExperienceToLevel(expectedLevel)
            while expectedExperience >= expToLevel do
                expectedExperience -= expToLevel
                expectedLevel += 1
                expToLevel = GameConfig.getExperienceToLevel(expectedLevel)
            end

            expect(updatedStats.level).to.equal(expectedLevel)
            expect(updatedStats.experience).to.equal(expectedExperience)
            expect(updatedStats.gold).to.equal(startingStats.gold + (rewards.gold or 0))

            local inventorySummary = inventoryController:GetSummary()
            expect(inventorySummary.items.potion_small).to.be.ok()
            expect(inventorySummary.items.potion_small.quantity).to.equal(rewards.items.potion_small)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("grants class specific rewards when available", function()
            local statsController, inventoryController, questController = createControllers()

            local success, err = statsController:SetClass("arqueiro")
            expect(success).to.equal(true)
            expect(err).to.equal(nil)

            questController:AcceptQuest("primeira_caca")
            local objective = QuestConfig.primeira_caca.objective
            for _ = 1, objective.count do
                questController:RegisterKill(objective.target)
            end

            local summary = questController:GetSummary()
            expect(summary.completed.primeira_caca).to.be.ok()

            local classRewards = QuestConfig.primeira_caca.reward.classRewards.arqueiro.items
            local inventorySummary = inventoryController:GetSummary()
            expect(inventorySummary.items.training_quiver).to.be.ok()
            expect(inventorySummary.items.training_quiver.quantity).to.equal(classRewards.training_quiver)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)
    end)
end
