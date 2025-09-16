return function()
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local MapManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("MapManager"))
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
    end)
end
