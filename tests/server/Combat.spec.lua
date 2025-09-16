return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
    local QuestConfig = require(ReplicatedStorage:WaitForChild("QuestConfig"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Inventory = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Inventory"))
    local QuestManager = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("QuestManager"))
    local Combat = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Combat"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    describe("Combat", function()
        local mockStore
        local originalKillRequirement

        beforeAll(function()
            mockStore = MockProfileStore.new()
            originalKillRequirement = QuestConfig.slay_goblins.objective.count
        end)

        afterAll(function()
            mockStore:restore()
        end)

        beforeEach(function()
            mockStore:reset()
        end)

        afterEach(function()
            if originalKillRequirement then
                QuestConfig.slay_goblins.objective.count = originalKillRequirement
            end
            Combat._resetRandomGenerator()
        end)

        it("ensures damage is never below one", function()
            local attacker = { attack = 5 }
            local defender = { defense = 50 }
            local damage = Combat.CalculateDamage(attacker, defender)

            expect(damage).to.equal(1)
        end)

        it("applies deterministic critical chance when RNG is injected", function()
            local attacker = { attack = 20 }
            local defender = { defense = 5 }
            local weaponConfig = {
                attributes = {
                    attack = 0,
                    criticalChance = 0.5,
                },
            }

            local function mockRandom(values)
                local index = 0
                local stub = {}

                function stub:NextNumber()
                    index = index + 1
                    return values[index] or values[#values]
                end

                return stub
            end

            Combat._setRandomGenerator(mockRandom({ 0.75 }))
            local nonCritical = Combat.CalculateDamage(attacker, defender, weaponConfig)
            expect(nonCritical).to.equal(15)

            Combat._setRandomGenerator(mockRandom({ 0.25 }))
            local critical = Combat.CalculateDamage(attacker, defender, weaponConfig)
            expect(critical).to.equal(math.floor(15 * 1.5))
        end)

        it("resolves attacks and completes kill quests when enemy is defeated", function()
            QuestConfig.slay_goblins.objective.count = 1

            local attackerPlayer = TestPlayers.create("CombatAttacker")
            local defenderPlayer = TestPlayers.create("CombatDefender")

            local attackerStats = CharacterStats.new(attackerPlayer)
            local attackerInventory = Inventory.new(attackerPlayer, attackerStats)
            local attackerQuests = QuestManager.new(attackerPlayer, attackerStats, attackerInventory)
            attackerInventory:BindQuestManager(attackerQuests)
            local combatController = Combat.new(attackerPlayer, attackerStats, attackerInventory, attackerQuests)

            local defenderStats = CharacterStats.new(defenderPlayer)
            defenderStats.stats.enemyType = "Goblin"
            defenderStats.stats.health = 10

            attackerQuests:AcceptQuest("slay_goblins")
            attackerInventory:AddItem("sword_iron", 1)
            attackerInventory:EquipItem("sword_iron")

            local damage, defeated = combatController:AttackTarget(defenderStats)
            expect(damage > 0).to.equal(true)
            expect(defeated).to.equal(true)

            local questSummary = attackerQuests:GetSummary()
            expect(questSummary.completed.slay_goblins).to.be.ok()

            combatController = nil
            attackerQuests:Destroy()
            attackerInventory:Destroy()
            attackerStats:Destroy()
            defenderStats:Destroy()
            TestPlayers.destroy(attackerPlayer)
            TestPlayers.destroy(defenderPlayer)

        end)
    end)
end
