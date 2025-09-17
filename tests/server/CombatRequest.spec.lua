return function()
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local MapManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("MapManager"))
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
            if instance:IsA("Model") and mapAssetNames[instance.Name] then
                instance:Destroy()
            end
        end
    end

    describe("CombatRequest matchmaking", function()
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

        local function acceptArenaQuest(player)
            local controller = controllers[player]
            expect(controller).to.be.ok()
            local quests = controller.quests
            expect(quests).to.be.ok()
            local accepted, reason = quests:AcceptQuest("arena_campeoes")
            if not accepted and reason == "Missão já aceita ou concluída" then
                return
            end
            expect(accepted).to.equal(true)
        end

        beforeAll(function()
            mockStore = MockProfileStore.new()
            controllers = require(ServerScriptService:WaitForChild("Main"))
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

        it("blocks PvP when players are in different maps", function()
            local attacker = createTestPlayer("ArenaDifferentA")
            local defender = createTestPlayer("ArenaDifferentB")

            setPlayerLevel(attacker, 32)
            setPlayerLevel(defender, 32)

            MapManager:SpawnPlayer(attacker, "starter_village")
            MapManager:SpawnPlayer(defender, "champion_arena", "vestiario")

            local ok, target, weapon, reason = controllers._validateCombatRequest(attacker, defender, nil)
            expect(ok).to.equal(false)
            expect(reason).to.equal("jogadores em mapas diferentes")
            expect(target).to.equal(nil)
            expect(weapon).to.equal(nil)
        end)

        it("enforces quest requirement for champion arena PvP", function()
            local attacker = createTestPlayer("ArenaNoQuestA")
            local defender = createTestPlayer("ArenaNoQuestB")

            setPlayerLevel(attacker, 34)
            setPlayerLevel(defender, 34)

            MapManager:SpawnPlayer(attacker, "champion_arena", "arena_central")
            MapManager:SpawnPlayer(defender, "champion_arena", "arena_central")

            local ok, _, _, reason = controllers._validateCombatRequest(attacker, defender, nil)
            expect(ok).to.equal(false)
            expect(reason).to.equal("requisitos de matchmaking não atendidos")
        end)

        it("blocks champion arena PvP outside the allowed spawn", function()
            local attacker = createTestPlayer("ArenaSpawnA")
            local defender = createTestPlayer("ArenaSpawnB")

            setPlayerLevel(attacker, 35)
            setPlayerLevel(defender, 35)

            acceptArenaQuest(attacker)
            acceptArenaQuest(defender)

            MapManager:SpawnPlayer(attacker, "champion_arena", "vestiario")
            MapManager:SpawnPlayer(defender, "champion_arena", "vestiario")

            local ok, _, _, reason = controllers._validateCombatRequest(attacker, defender, nil)
            expect(ok).to.equal(false)
            expect(reason).to.equal("pvp restrito a spawns específicos")
        end)

        it("allows champion arena PvP when all requirements are satisfied", function()
            local attacker = createTestPlayer("ArenaReadyA")
            local defender = createTestPlayer("ArenaReadyB")

            setPlayerLevel(attacker, 36)
            setPlayerLevel(defender, 36)

            acceptArenaQuest(attacker)
            acceptArenaQuest(defender)

            MapManager:SpawnPlayer(attacker, "champion_arena", "arena_central")
            MapManager:SpawnPlayer(defender, "champion_arena", "arena_central")

            local ok, target, weapon, reason = controllers._validateCombatRequest(attacker, defender, nil)
            expect(ok).to.equal(true)
            expect(target).to.equal(defender)
            expect(weapon).to.equal(nil)
            expect(reason).to.equal(nil)
        end)
    end)
end
