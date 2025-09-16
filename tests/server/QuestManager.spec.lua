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

        it("increments collection quests according to the collected amount", function()
            local statsController, inventoryController, questController = createControllers()

            questController:AcceptQuest("gather_herbs")
            questController:RegisterCollection("Herb", 2)

            local summary = questController:GetSummary()
            expect(summary.active.gather_herbs).to.be.ok()
            expect(summary.active.gather_herbs.progress).to.equal(2)

            local invalidUpdate = questController:UpdateProgress("gather_herbs", 0)
            expect(invalidUpdate).to.equal(false)

            questController:RegisterCollection("Herb", 1)

            summary = questController:GetSummary()
            expect(summary.active.gather_herbs).to.equal(nil)
            expect(summary.completed.gather_herbs).to.be.ok()

            questController:RegisterCollection("Herb", 0)
            summary = questController:GetSummary()
            expect(summary.completed.gather_herbs.progress).to.equal(summary.completed.gather_herbs.goal)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("includes planned rewards in the quest summary", function()
            local statsController, inventoryController, questController = createControllers()

            statsController:SetClass("mago")
            questController:AcceptQuest("primeira_caca")

            local summary = questController:GetSummary()
            local entry = summary.active.primeira_caca

            expect(entry).to.be.ok()
            expect(entry.plannedReward).to.be.ok()
            expect(entry.plannedReward.experience).to.equal(QuestConfig.primeira_caca.reward.experience)
            expect(entry.plannedReward.gold).to.equal(QuestConfig.primeira_caca.reward.gold)
            expect(entry.plannedReward.items).to.be.ok()
            expect(entry.plannedReward.items.potion_small).to.equal(QuestConfig.primeira_caca.reward.items.potion_small)
            expect(entry.plannedReward.items.training_grimoire).to.equal(1)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("allows abandoning quests to free active slots", function()
            local statsController, inventoryController, questController = createControllers()

            local accepted = questController:AcceptQuest("slay_goblins")
            expect(accepted).to.equal(true)

            local abandoned, abandonErr = questController:AbandonQuest("slay_goblins")
            expect(abandoned).to.equal(true)
            expect(abandonErr).to.equal(nil)

            local summary = questController:GetSummary()
            expect(summary.active.slay_goblins).to.equal(nil)
            expect(summary.completed.slay_goblins).to.equal(nil)

            local reaccepted = questController:AcceptQuest("slay_goblins")
            expect(reaccepted).to.equal(true)

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("rejects abandon attempts for quests that are not active", function()
            local statsController, inventoryController, questController = createControllers()

            local success, err = questController:AbandonQuest("slay_goblins")
            expect(success).to.equal(false)
            expect(err).to.be.ok()

            questController:AcceptQuest("slay_goblins")

            local invalidQuestSuccess, invalidQuestErr = questController:AbandonQuest("gather_herbs")
            expect(invalidQuestSuccess).to.equal(false)
            expect(invalidQuestErr).to.be.ok()

            local invalidTypeSuccess, invalidTypeErr = questController:AbandonQuest(nil)
            expect(invalidTypeSuccess).to.equal(false)
            expect(invalidTypeErr).to.be.ok()

            local summary = questController:GetSummary()
            expect(summary.active.slay_goblins).to.be.ok()

            questController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)
    end)
end
