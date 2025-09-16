return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local ShopManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("ShopManager"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("ShopManager", function()
        local mockStore

        beforeAll(function()
            mockStore = MockProfileStore.new()
        end)

        afterAll(function()
            mockStore:restore()
        end)

        local player
        local statsController
        local inventoryController
        local shopController

        local function createControllers()
            statsController = CharacterStats.new(player)
            inventoryController = Inventory.new(player, statsController)
            shopController = ShopManager.new(player, statsController, inventoryController)
        end

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("ShopTester")
            createControllers()
            statsController.stats.gold = 200
            statsController.stats.level = 1
        end)

        afterEach(function()
            if shopController then
                shopController:Destroy()
                shopController = nil
            end
            if inventoryController then
                inventoryController:Destroy()
                inventoryController = nil
            end
            if statsController then
                statsController:Destroy()
                statsController = nil
            end
            if player then
                TestPlayers.destroy(player)
                player = nil
            end
        end)

        it("processes valid purchases and updates gold and inventory", function()
            local success, result = shopController:Purchase("general_store", "potion_small", 2)

            expect(success).to.equal(true)
            expect(result).to.be.a("table")
            expect(result.totalCost).to.equal(30)
            expect(result.quantity).to.equal(2)

            local entry = inventoryController.data.items.potion_small
            expect(entry).never.to.equal(nil)
            expect(entry.quantity).to.equal(2)
            expect(statsController.stats.gold).to.equal(170)
        end)

        it("rejects purchases that do not meet requirements", function()
            statsController.stats.gold = 500

            local success, message, detail = shopController:Purchase("arcane_repository", "training_grimoire", 1)

            expect(success).to.equal(false)
            expect(detail and detail.code).to.equal("requirements_not_met")
            expect(message).to.be.a("string")
            expect(string.find(message, "Disponível", 1, true)).never.to.equal(nil)
            expect(statsController.stats.gold).to.equal(500)
            expect(inventoryController.data.items.training_grimoire).to.equal(nil)
        end)

        it("prevents purchases when gold is insuficiente", function()
            statsController.stats.gold = 10

            local success, message, detail = shopController:Purchase("general_store", "training_blade", 1)

            expect(success).to.equal(false)
            expect(detail and detail.code).to.equal("insufficient_gold")
            expect(message).to.equal("Ouro insuficiente")
            expect(statsController.stats.gold).to.equal(10)
            expect(inventoryController.data.items.training_blade).to.equal(nil)
        end)

        it("marks unavailable items in the shop view", function()
            local view, err = shopController:GetShopView("general_store")

            expect(view).never.to.equal(nil)
            expect(err).to.equal(nil)

            local itemsById = {}
            for _, item in ipairs(view.items) do
                itemsById[item.itemId] = item
            end

            expect(itemsById.potion_small).never.to.equal(nil)
            expect(itemsById.potion_small.available).to.equal(true)

            expect(itemsById.light_shield).never.to.equal(nil)
            expect(itemsById.light_shield.available).to.equal(false)
            expect(itemsById.light_shield.reason).to.be.a("string")
        end)
    end)
end
