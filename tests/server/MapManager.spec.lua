return function()
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local MapManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("MapManager"))
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)
    local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

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

    describe("MapManager", function()
        local player

        beforeEach(function()
            destroyMapInstances()
            MapManager:Unload()
            player = TestPlayers.create("MapTester")
        end)

        afterEach(function()
            if player then
                MapManager:UnbindPlayer(player)
                if player.Character then
                    player.Character:Destroy()
                end
                TestPlayers.destroy(player)
                player = nil
            end
            destroyMapInstances()
            MapManager:Unload()
        end)

        it("loads map assets and removes the previous map", function()
            local firstModel = MapManager:Load("starter_village")
            expect(firstModel.Parent).to.equal(Workspace)
            expect(firstModel.Name).to.equal("StarterVillage")

            local secondModel = MapManager:Load("crystal_cavern")
            expect(secondModel.Parent).to.equal(Workspace)
            expect(secondModel.Name).to.equal("CrystalCavern")
            expect(firstModel.Parent).to.equal(nil)
            expect(MapManager:GetCurrentMapId()).to.equal("crystal_cavern")
        end)

        it("loads desert maps when requested", function()
            local desertModel = MapManager:Load("desert_outpost")
            expect(desertModel.Parent).to.equal(Workspace)
            expect(desertModel.Name).to.equal("DesertOutpost")
            expect(MapManager:GetCurrentMapId()).to.equal("desert_outpost")
        end)

        it("loads the volcanic crater map when requested", function()
            local craterModel = MapManager:Load("volcanic_crater")
            expect(craterModel.Parent).to.equal(Workspace)
            expect(craterModel.Name).to.equal("VolcanicCrater")
            expect(MapManager:GetCurrentMapId()).to.equal("volcanic_crater")
        end)

        it("spawns players at the configured positions", function()
            local spawnCFrame = MapManager:GetSpawnCFrame("starter_village", "blacksmith")
            MapManager:SpawnPlayer(player, "starter_village", "blacksmith")

            local character = Instance.new("Model")
            character.Name = player.Name .. "Character"
            character.Parent = Workspace

            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Parent = character

            player.Character = character
            task.wait()

            expect(root.CFrame).to.equal(spawnCFrame)
            expect(MapManager:GetPlayerMap(player)).to.equal("starter_village")
        end)

        it("spawns players at frozen tundra spawns", function()
            local spawnCFrame = MapManager:GetSpawnCFrame("frozen_tundra", "glacier")
            MapManager:SpawnPlayer(player, "frozen_tundra", "glacier")

            local character = Instance.new("Model")
            character.Name = player.Name .. "Character"
            character.Parent = Workspace

            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Parent = character

            player.Character = character
            task.wait()

            expect(root.CFrame).to.equal(spawnCFrame)
            expect(MapManager:GetPlayerMap(player)).to.equal("frozen_tundra")

            local currentMap = MapManager:GetCurrentMap()
            expect(currentMap).to.be.ok()
            expect(currentMap.Name).to.equal("FrozenTundra")
            expect(currentMap.Parent).to.equal(Workspace)
        end)
    end)
end
