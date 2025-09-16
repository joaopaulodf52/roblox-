return function()
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local MapManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("MapManager"))
    local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    local function destroyMapInstances()
        for _, instance in ipairs(Workspace:GetChildren()) do
            if instance:IsA("Model") then
                if instance.Name == "StarterVillage" or instance.Name == "CrystalCavern" then
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

            controller.stats.stats.level = 20

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

            local spawnData = MapManager.playerSpawns[player]
            expect(spawnData).to.be.ok()
            expect(spawnData.mapId).to.equal("crystal_cavern")
            expect(spawnData.spawnName).to.equal("sanctuary")
        end)

        it("rejects travel for unknown maps", function()
            local player = createTestPlayer("UnknownMap")
            local controller = controllers[player]
            expect(controller).to.be.ok()

            controller.stats.stats.level = 20

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

            controller.stats.stats.level = 3

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

            controller.stats.stats.level = 6

            local success, reason = controllers._handleMapTravelRequest(player, {
                mapId = "crystal_cavern",
                spawnId = "sanctuary",
            })

            expect(success).to.equal(false)
            expect(reason).to.equal("nível insuficiente para o spawn")
        end)
    end)
end
