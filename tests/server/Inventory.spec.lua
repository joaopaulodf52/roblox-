return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
    local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("Inventory", function()
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
            return statsController, inventoryController
        end

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("InventoryUser")
        end)

        afterEach(function()
            TestPlayers.destroy(player)
        end)

        it("adds items while respecting capacity limits", function()
            local statsController, inventoryController = createControllers()
            inventoryController.data.capacity = 1

            local firstAdd = inventoryController:AddItem("potion_small", 1)
            local secondAdd = inventoryController:AddItem("potion_small", 1)

            expect(firstAdd).to.equal(true)
            expect(secondAdd).to.equal(false)

            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("equips weapons and applies attribute bonuses", function()
            local statsController, inventoryController = createControllers()

            inventoryController:AddItem("sword_iron", 1)
            local success = inventoryController:EquipItem("sword_iron")

            expect(success).to.equal(true)

            local updatedStats = statsController:GetStats()
            local expectedAttack = GameConfig.DefaultStats.attack + ItemsConfig.sword_iron.attributes.attack
            expect(updatedStats.attack).to.equal(expectedAttack)

            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("consumes items and applies their effects", function()
            local statsController, inventoryController = createControllers()

            statsController:ApplyDamage(40)
            inventoryController:AddItem("potion_small", 1)

            local consumed = inventoryController:UseConsumable("potion_small")
            expect(consumed).to.equal(true)

            local afterUse = statsController:GetStats()
            expect(afterUse.health).to.equal(afterUse.maxHealth)

            local summary = inventoryController:GetSummary()
            expect(summary.items.potion_small).to.equal(nil)

            inventoryController:Destroy()
            statsController:Destroy()
        end)

        it("rejects invalid quantities in inventory operations", function()
            local statsController, inventoryController = createControllers()

            local addResult, addErr = inventoryController:AddItem("potion_small", 0)
            expect(addResult).to.equal(false)
            expect(addErr).to.equal("Quantidade inválida")

            local hasSpace = inventoryController:HasSpace(0)
            expect(hasSpace).to.equal(false)

            inventoryController.data.items.potion_small = {
                id = "potion_small",
                quantity = 2,
            }

            local removeResult, removeErr = inventoryController:RemoveItem("potion_small", -1)
            expect(removeResult).to.equal(false)
            expect(removeErr).to.equal("Quantidade inválida")

            local hasItem = inventoryController:HasItem("potion_small", -5)
            expect(hasItem).to.equal(false)

            inventoryController:Destroy()
            statsController:Destroy()
        end)
    end)
end
