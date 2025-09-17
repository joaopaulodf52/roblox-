return function()
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local MapManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("MapManager"))
    local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
    local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    local mapAssetNames = {}
    for _, config in pairs(MapConfig) do
        if type(config) == "table" then
            local assetName = config.assetName
            if type(assetName) == "string" then
                mapAssetNames[assetName] = true
            end
        end
    end

    local function destroyMapInstances()
        for _, instance in ipairs(Workspace:GetChildren()) do
            if instance:IsA("Model") then
                if mapAssetNames[instance.Name] then
                    instance:Destroy()
                end
            end
        end
    end

    describe("MapTravelRequest", function()
        local mockStore
        local controllers
        local createdPlayers

        local function createTestPlayer(name)
            local player = TestPlayers.create(name)
            table.insert(createdPlayers, player)
            task.wait()
            return player
        end

        local function setPlayerLevel(player, level)
            local controller = controllers[player]
            if controller and controller.stats and controller.stats.stats then
                controller.stats.stats.level = level
            end

            local profile = mockStore:getProfile(player)
            if profile and profile.stats then
                profile.stats.level = level
            end
        end

        local function cleanupPlayers()
            if not createdPlayers then
                return
            end

            for index = #createdPlayers, 1, -1 do
                local player = createdPlayers[index]
                TestPlayers.destroy(player)
            end
            createdPlayers = {}
            task.wait()
        end

        beforeAll(function()
            mockStore = MockProfileStore.new()
            controllers = require(ServerScriptService:WaitForChild("Main"))
            expect(Remotes.MapTravelRequest).to.be.ok()
            createdPlayers = {}
        end)

        afterAll(function()
            cleanupPlayers()
            destroyMapInstances()
            MapManager:Unload()
            mockStore:restore()
        end)

        beforeEach(function()
            createdPlayers = {}
            mockStore:reset()
            destroyMapInstances()
            MapManager:Unload()
        end)

        afterEach(function()
            cleanupPlayers()
            destroyMapInstances()
            MapManager:Unload()
        end)

        it("allows players to travel when requirements are met", function()
            local player = createTestPlayer("ValidTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 20)

            local success, result = controllers._handleMapTravelRequest(player, {
                mapId = "crystal_cavern",
                spawnId = "sanctuary",
            })

            expect(success).to.equal(true)
            expect(result).to.be.ok()
            expect(result.mapId).to.equal("crystal_cavern")
            expect(result.resolvedSpawn).to.equal("sanctuary")

            local profile = mockStore:getProfile(player)
            expect(profile.currentMap).to.equal("crystal_cavern")

            expect(MapManager:GetPlayerMap(player)).to.equal("crystal_cavern")
            expect(MapManager:GetPlayerSpawnName(player)).to.equal("sanctuary")
        end)

        it("rejects travel for unknown maps", function()
            local player = createTestPlayer("UnknownMap")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 20)

            local initialProfile = mockStore:getProfile(player)
            local initialMap = initialProfile.currentMap

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "missing_world",
            })

            expect(success).to.equal(false)
            expect(reason).to.be.ok()
            expect(mockStore:getProfile(player).currentMap).to.equal(initialMap)
            expect(MapManager:GetPlayerMap(player)).to.equal(initialMap)
        end)

        it("rejects travel when player level is below the map requirement", function()
            local player = createTestPlayer("LowLevelTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 3)

            local currentMap = MapManager:GetPlayerMap(player)

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "crystal_cavern",
                spawnId = "entrance",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente")
            expect(MapManager:GetPlayerMap(player)).to.equal(currentMap)
            expect(mockStore:getProfile(player).currentMap).to.equal(currentMap)
        end)

        it("rejects travel when spawn requirements are not satisfied", function()
            local player = createTestPlayer("SpawnLockedTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 6)

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "crystal_cavern",
                spawnId = "sanctuary",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente para o spawn")
        end)

        it("allows travel to the desert outpost when level requirements are met", function()
            local player = createTestPlayer("DesertTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 15)

            local success, result = controllers._handleMapTravelRequest(player, {
                mapId = "desert_outpost",
                spawnId = "camp",
            })

            expect(success).to.equal(true)
            expect(result).to.be.ok()
            expect(result.mapId).to.equal("desert_outpost")
            expect(result.resolvedSpawn).to.equal("camp")

            local profile = mockStore:getProfile(player)
            expect(profile.currentMap).to.equal("desert_outpost")

            expect(MapManager:GetPlayerMap(player)).to.equal("desert_outpost")
            expect(MapManager:GetPlayerSpawnName(player)).to.equal("camp")
        end)

        it("rejects travel to restricted desert outpost spawns when below the requirement", function()
            local player = createTestPlayer("DesertRestricted")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 17)

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "desert_outpost",
                spawnId = "watchtower",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente para o spawn")
        end)

        it("rejects travel to the champion arena when below the map requirement", function()
            local player = createTestPlayer("ArenaLowLevel")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 24)

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "champion_arena",
                spawnId = "vestiario",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente")
        end)

        it("rejects travel to the champion arena central spawn when requirements are not met", function()
            local player = createTestPlayer("ArenaCentralLocked")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 28)

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "champion_arena",
                spawnId = "arena_central",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente para o spawn")
        end)

        it("allows travel to the champion arena when requirements are satisfied", function()
            local player = createTestPlayer("ArenaTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 32)

            local success, result = controllers._handleMapTravelRequest(player, {
                mapId = "champion_arena",
                spawnId = "arena_central",
            })

            expect(success).to.equal(true)
            expect(result).to.be.ok()
            expect(result.mapId).to.equal("champion_arena")
            expect(result.resolvedSpawn).to.equal("arena_central")

            local profile = mockStore:getProfile(player)
            expect(profile.currentMap).to.equal("champion_arena")

            expect(MapManager:GetPlayerMap(player)).to.equal("champion_arena")
            expect(MapManager:GetPlayerSpawnName(player)).to.equal("arena_central")
        end)

        it("rejects travel to the frozen tundra when below the map requirement", function()
            local player = createTestPlayer("FrozenLowLevel")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 19)

            local initialMap = MapManager:GetPlayerMap(player)
            local initialProfile = mockStore:getProfile(player)
            local initialProfileMap = initialProfile.currentMap

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "frozen_tundra",
                spawnId = "encampment",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente")
            expect(MapManager:GetPlayerMap(player)).to.equal(initialMap)
            expect(mockStore:getProfile(player).currentMap).to.equal(initialProfileMap)
        end)

        it("allows travel to frozen tundra spawns when requirements are met", function()
            local player = createTestPlayer("FrozenTraveler")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            setPlayerLevel(player, 30)

            local success, result = controllers._handleMapTravelRequest(player, {
                mapId = "frozen_tundra",
                spawnId = "ridge",
            })

            expect(success).to.equal(true)
            expect(result).to.be.ok()
            expect(result.mapId).to.equal("frozen_tundra")
            expect(result.resolvedSpawn).to.equal("ridge")

            local profile = mockStore:getProfile(player)
            expect(profile.currentMap).to.equal("frozen_tundra")

            expect(MapManager:GetPlayerMap(player)).to.equal("frozen_tundra")
            expect(MapManager:GetPlayerSpawnName(player)).to.equal("ridge")
        end)
    end)
end
