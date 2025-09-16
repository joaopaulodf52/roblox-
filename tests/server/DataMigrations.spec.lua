return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local DataStoreManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("DataStoreManager"))
    local DataMigrations = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("DataMigrations"))
    local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
    local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

    local function createMockDataStore()
        local store = {
            data = {},
        }

        function store:GetAsync(key)
            return self.data[key]
        end

        function store:UpdateAsync(key, transform)
            local current = self.data[key]
            local updated = transform(current)
            self.data[key] = updated
            return updated
        end

        return store
    end

    local function createMockDataStoreService()
        local service = {
            _stores = {},
        }

        function service:GetDataStore(name)
            if not self._stores[name] then
                self._stores[name] = createMockDataStore()
            end
            return self._stores[name]
        end

        return service
    end

    describe("DataMigrations", function()
        beforeAll(function()
            DataMigrations.Register()
        end)

        afterEach(function()
            DataStoreManager._resetDataStoreService()
        end)

        it("executes migrations in dependency order and populates expected schema", function()
            local mockService = createMockDataStoreService()
            DataStoreManager._setDataStoreService(mockService)

            local state = DataStoreManager:RunMigrations()

            local expectedCount = #DataStoreManager._migrationOrder
            expect(state.version).to.equal(expectedCount)

            for index, migrationId in ipairs(DataStoreManager._migrationOrder) do
                expect(state.history[index].id).to.equal(migrationId)
                expect(state.applied[migrationId]).to.equal(true)
            end

            local schemas = state.schemas
            expect(schemas).to.be.ok()

            local profileSchema = schemas.profile
            expect(profileSchema).to.be.ok()
            expect(profileSchema.version).to.equal(1)
            expect(profileSchema.stats).to.be.ok()
            expect(profileSchema.stats.defaults).to.be.ok()
            expect(profileSchema.stats.defaults.maxHealth).to.equal(GameConfig.DefaultStats.maxHealth)

            expect(profileSchema.inventory).to.be.ok()
            expect(profileSchema.inventory.version).to.equal(2)

            expect(profileSchema.quests).to.be.ok()
            expect(profileSchema.quests.states).to.be.ok()

            expect(MapConfig[profileSchema.stats.defaults.currentMap]).to.be.ok()
        end)

        it("persists migration state between runs", function()
            local mockService = createMockDataStoreService()
            DataStoreManager._setDataStoreService(mockService)

            local firstState = DataStoreManager:RunMigrations()
            local persistedState = DataStoreManager:GetState()

            expect(persistedState.version).to.equal(firstState.version)
            expect(#persistedState.history).to.equal(#firstState.history)

            local secondState = DataStoreManager:RunMigrations()
            expect(secondState.version).to.equal(firstState.version)
            expect(#secondState.history).to.equal(#firstState.history)
        end)
    end)
end
