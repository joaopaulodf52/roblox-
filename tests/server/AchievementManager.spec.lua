return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
    local AchievementManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("AchievementManager"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))
    local Combat = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Combat"))
    local QuestManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("QuestManager"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    local leaderboardConfig = AchievementConfig.leaderboard or {}
    local leaderboardStoreName = leaderboardConfig.storeName or "RPG_ACHIEVEMENTS_LEADERBOARD"

    local function createMockOrderedStore()
        local store = { data = {}, sortedCalls = 0, getCalls = 0 }

        function store:UpdateAsync(key, transform)
            local current = self.data[key]
            local updated = transform(current)
            self.data[key] = updated
            return updated
        end

        function store:GetAsync(key)
            self.getCalls += 1
            return self.data[key]
        end

        function store:GetSortedAsync(isAscending, limit)
            self.sortedCalls += 1

            local entries = {}
            for key, value in pairs(self.data) do
                table.insert(entries, {
                    key = key,
                    value = value,
                })
            end

            table.sort(entries, function(a, b)
                local aValue = tonumber(a.value) or 0
                local bValue = tonumber(b.value) or 0
                if aValue == bValue then
                    return tostring(a.key) < tostring(b.key)
                end

                if isAscending then
                    return aValue < bValue
                else
                    return aValue > bValue
                end
            end)

            local maxItems = math.min(limit or #entries, #entries)
            local page = {}
            for index = 1, maxItems do
                page[index] = entries[index]
            end

            local pages = {
                _page = page,
            }

            function pages:GetCurrentPage()
                return self._page
            end

            function pages:AdvanceToNextPageAsync()
                return nil
            end

            return pages
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
        local quests
        local mockDataStoreService
        local currentTime

        local function initializeControllers()
            stats = CharacterStats.new(player)
            inventory = Inventory.new(player, stats)
            quests = QuestManager.new(player, stats, inventory)
            inventory:BindQuestManager(quests)
            combat = Combat.new(player, stats, inventory, quests)
            manager = AchievementManager.new(player, stats, inventory, combat, quests)
        end

        local function cleanupControllers()
            if manager then
                manager:Destroy()
                manager = nil
            end
            if quests then
                quests:Destroy()
                quests = nil
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
            AchievementManager._clearLeaderboardCache()
            currentTime = 100
            AchievementManager._setTimeProvider(function()
                return currentTime
            end)
        end)

        afterEach(function()
            cleanupControllers()
            AchievementManager._resetDataStoreService()
            AchievementManager._clearLeaderboardCache()
            AchievementManager._resetTimeProvider()
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

        it("desbloqueia conquistas ao completar missões", function()
            initializeControllers()

            local accepted = quests:AcceptQuest("gather_herbs")
            expect(accepted).to.equal(true)

            local completed = quests:UpdateProgress("gather_herbs", 3)
            expect(completed).to.equal(true)

            local summary = manager:GetSummary()
            expect(summary.unlocked.quest_novice).to.be.ok()
            expect(summary.locked.quest_adept).to.be.ok()
            expect(summary.locked.quest_adept.progress).to.equal(1)

            accepted = quests:AcceptQuest("slay_goblins")
            expect(accepted).to.equal(true)

            completed = quests:UpdateProgress("slay_goblins", 5)
            expect(completed).to.equal(true)

            summary = manager:GetSummary()
            expect(summary.unlocked.quest_novice).to.be.ok()
            expect(summary.unlocked.quest_adept).to.be.ok()

            local store = mockDataStoreService.orderedStores[leaderboardStoreName]
            expect(store).to.be.ok()
            expect(store.data[tostring(player.UserId)]).to.equal(2)
        end)

        describe("leaderboard queries", function()
            it("retorna entradas ordenadas utilizando cache curto", function()
                local store = mockDataStoreService:GetOrderedDataStore(leaderboardStoreName)
                store.data["1"] = 15
                store.data["2"] = 7
                store.data["3"] = 12

                local entries, err = AchievementManager.GetLeaderboardEntriesAsync(2)
                expect(err).to.equal(nil)
                expect(entries).to.be.ok()
                expect(#entries).to.equal(2)
                expect(entries[1].userId).to.equal(1)
                expect(entries[1].total).to.equal(15)
                expect(entries[2].userId).to.equal(3)
                expect(entries[2].total).to.equal(12)
                expect(store.sortedCalls).to.equal(1)

                local cached = AchievementManager.GetLeaderboardEntriesAsync(1)
                expect(#cached).to.equal(1)
                expect(cached[1].userId).to.equal(1)
                expect(store.sortedCalls).to.equal(1)

                currentTime += 30

                local refreshed = AchievementManager.GetLeaderboardEntriesAsync(3)
                expect(refreshed).to.be.ok()
                expect(store.sortedCalls).to.equal(2)
            end)

            it("lê valores individuais com cache temporário", function()
                local store = mockDataStoreService:GetOrderedDataStore(leaderboardStoreName)
                store.data["42"] = 9

                local value, err = AchievementManager.GetLeaderboardValueAsync(42)
                expect(err).to.equal(nil)
                expect(value).to.equal(9)
                expect(store.getCalls).to.equal(1)

                local cached = AchievementManager.GetLeaderboardValueAsync(42)
                expect(cached).to.equal(9)
                expect(store.getCalls).to.equal(1)

                currentTime += 30
                store.data["42"] = 11

                local refreshed = AchievementManager.GetLeaderboardValueAsync(42)
                expect(refreshed).to.equal(11)
                expect(store.getCalls).to.equal(2)
            end)
        end)
    end)
end
