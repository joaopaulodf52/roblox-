return function()
    local ServerScriptService = game:GetService("ServerScriptService")

    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))
    local Crafting = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Crafting"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("Crafting", function()
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
            local craftingController = Crafting.new(player, inventoryController)
            return statsController, inventoryController, craftingController
        end

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("CrafterUser")
        end)

        afterEach(function()
            TestPlayers.destroy(player)
        end)

        it("crafts items when ingredients are available", function()
            local statsController, inventoryController, craftingController = createControllers()

            inventoryController:AddItem("maca_vermelha", 2)
            inventoryController:AddItem("essencia_alquimica", 1)

            local success, message = craftingController:Craft("potion_small")

            expect(success).to.equal(true)
            expect(message).to.equal(nil)

            local summary = inventoryController:GetSummary()
            expect(summary.items.potion_small).to.be.ok()
            expect(summary.items.potion_small.quantity).to.equal(1)
            expect(summary.items.maca_vermelha).to.equal(nil)
            expect(summary.items.essencia_alquimica).to.equal(nil)

            local state = craftingController:GetState()
            expect(state.statistics.totalCrafted).to.equal(1)
            expect(state.statistics.byRecipe.potion_small).to.equal(1)
            expect(state.unlocked.potion_small).to.equal(true)

            craftingController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("rejects crafting when ingredients are missing", function()
            local statsController, inventoryController, craftingController = createControllers()

            inventoryController:AddItem("maca_vermelha", 1)
            inventoryController:AddItem("essencia_alquimica", 1)

            local success, message = craftingController:Craft("potion_small")

            expect(success).to.equal(false)
            expect(message).to.equal("Ingrediente insuficiente: maca_vermelha")

            local summary = inventoryController:GetSummary()
            expect(summary.items.potion_small).to.equal(nil)
            expect(summary.items.maca_vermelha).to.be.ok()
            expect(summary.items.maca_vermelha.quantity).to.equal(1)
            expect(summary.items.essencia_alquimica).to.be.ok()
            expect(summary.items.essencia_alquimica.quantity).to.equal(1)

            craftingController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("supports crafting multiple outputs per recipe", function()
            local statsController, inventoryController, craftingController = createControllers()

            inventoryController:AddItem("training_quiver", 2)
            inventoryController:AddItem("precision_string", 2)

            local success, message = craftingController:Craft("hunters_arrows", 2)

            expect(success).to.equal(true)
            expect(message).to.equal(nil)

            local summary = inventoryController:GetSummary()
            expect(summary.items.hunters_arrows).to.be.ok()
            expect(summary.items.hunters_arrows.quantity).to.equal(10)
            expect(summary.items.training_quiver).to.equal(nil)
            expect(summary.items.precision_string).to.equal(nil)

            local state = craftingController:GetState()
            expect(state.statistics.totalCrafted).to.equal(10)
            expect(state.statistics.byRecipe.hunters_arrows).to.equal(10)

            craftingController:Destroy()
            inventoryController:Destroy()
            statsController:Destroy()
        end)
    end)
end
