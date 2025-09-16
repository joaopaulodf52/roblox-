return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("CharacterStats", function()
        local mockStore

        beforeAll(function()
            mockStore = MockProfileStore.new()
        end)

        afterAll(function()
            mockStore:restore()
        end)

        local player

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("CharacterStatsUser")
        end)

        afterEach(function()
            TestPlayers.destroy(player)
        end)

        it("levels up and restores resources when gaining required experience", function()
            local statsController = CharacterStats.new(player)
            local startingStats = statsController:GetStats()
            local required = GameConfig.getExperienceToLevel(startingStats.level)

            statsController:AddExperience(required)
            local updated = statsController:GetStats()

            expect(updated.level).to.equal(startingStats.level + 1)
            expect(updated.experience).to.equal(0)
            expect(updated.health).to.equal(updated.maxHealth)
            expect(updated.mana).to.equal(updated.maxMana)

            statsController:Destroy()
        end)

        it("applies damage and respawns when defeated", function()
            local statsController = CharacterStats.new(player)

            local damage, defeated = statsController:ApplyDamage(500)
            expect(damage > 0).to.equal(true)
            expect(defeated).to.equal(true)

            local refreshed = statsController:GetStats()
            expect(refreshed.health).to.equal(refreshed.maxHealth)

            statsController:Destroy()
        end)

        it("blocks mana usage when insufficient resources are available", function()
            local statsController = CharacterStats.new(player)
            local current = statsController:GetStats()

            local success = statsController:UseMana(current.mana + 50)
            expect(success).to.equal(false)

            statsController:Destroy()
        end)
    end)
end
