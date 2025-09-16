return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
    local AchievementManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("AchievementManager"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))
    local Combat = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Combat"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    local leaderboardConfig = AchievementConfig.leaderboard or {}
    local leaderboardStoreName = leaderboardConfig.storeName or "RPG_ACHIEVEMENTS_LEADERBOARD"

    local function createMockOrderedStore()
        local store = { data = {} }

        function store:UpdateAsync(key, transform)
            local current = self.data[key]
            local updated = transform(current)
            self.data[key] = updated
            return updated
        end

        function store:GetAsync(key)
            return self.data[key]
        end

        return store
    end

    local function createMockDataStoreService()
        local service = {
            orderedStores = {},
        }

        function service:GetOrderedDataStore(name)
            if not self.orderedStores[name] then
                self.orderedStores[name] = createMockOrderedStore()
            end
            return self.orderedStores[name]
        end

        return service
    end

    describe("AchievementManager", function()
        local mockStore

        beforeAll(function()
            mockStore = MockProfileStore.new()
        end)

        afterAll(function()
            mockStore:restore()
        end)

        local player
        local stats
        local inventory
        local manager
        local combat
        local mockDataStoreService

        local function initializeControllers()
            stats = CharacterStats.new(player)
            inventory = Inventory.new(player, stats)
            combat = Combat.new(player, stats, inventory, nil)
            manager = AchievementManager.new(player, stats, inventory, combat)
        end

        local function cleanupControllers()
            if manager then
                manager:Destroy()
                manager = nil
            end
            if combat then
                combat = nil
            end
            if inventory then
                inventory:Destroy()
                inventory = nil
            end
            if stats then
                stats:Destroy()
                stats = nil
            end
            if player then
                TestPlayers.destroy(player)
                player = nil
            end
        end

        beforeEach(function()
            mockStore:reset()
            player = TestPlayers.create("AchievementTester")
            mockDataStoreService = createMockDataStoreService()
            AchievementManager._setDataStoreService(mockDataStoreService)
        end)

        afterEach(function()
            cleanupControllers()
            AchievementManager._resetDataStoreService()
        end)

        it("acumula progresso de experiência e concede recompensas", function()
            initializeControllers()

            stats:AddExperience(200)

            local summary = manager:GetSummary()
            expect(summary.unlocked.novice_adventurer).to.be.ok()
            expect(summary.locked.seasoned_hero).to.be.ok()
            expect(summary.locked.seasoned_hero.progress).to.equal(200)

            local statsData = stats:GetStats()
            expect(statsData.gold).to.equal(25)

            local store = mockDataStoreService.orderedStores[leaderboardStoreName]
            expect(store).to.be.ok()
            expect(store.data[tostring(player.UserId)]).to.equal(1)
        end)

        it("registra abates específicos e atualiza o leaderboard", function()
            initializeControllers()

            combat:OnEnemyDefeated("Goblin")

            local summary = manager:GetSummary()
            expect(summary.unlocked.first_blood).to.be.ok()
            expect(summary.locked.goblin_slayer).to.be.ok()
            expect(summary.locked.goblin_slayer.progress).to.equal(1)

            local inventorySummary = inventory:GetSummary()
            expect(inventorySummary.items.potion_small).to.be.ok()
            expect(inventorySummary.items.potion_small.quantity).to.equal(1)

            local store = mockDataStoreService.orderedStores[leaderboardStoreName]
            expect(store).to.be.ok()
            expect(store.data[tostring(player.UserId)]).to.equal(1)

            for _ = 2, 5 do
                combat:OnEnemyDefeated("Goblin")
            end

            summary = manager:GetSummary()
            expect(summary.unlocked.goblin_slayer).to.be.ok()

            store = mockDataStoreService.orderedStores[leaderboardStoreName]
            expect(store.data[tostring(player.UserId)]).to.equal(2)
        end)
    end)
end
