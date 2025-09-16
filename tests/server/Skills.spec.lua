return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local SkillsConfig = require(ReplicatedStorage:WaitForChild("SkillsConfig"))
    local Skills = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Skills"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))

    local MockProfileStore = require(script.Parent.Parent.utils.MockProfileStore)
    local TestPlayers = require(script.Parent.Parent.utils.TestPlayers)

    local function deepCopy(source)
        if type(source) ~= "table" then
            return source
        end

        local copy = {}
        for key, value in pairs(source) do
            copy[key] = deepCopy(value)
        end
        return copy
    end

    local originalPowerStrike = deepCopy(SkillsConfig.guerreiro.power_strike)

    local function restorePowerStrike()
        local skill = SkillsConfig.guerreiro.power_strike
        for key in pairs(skill) do
            skill[key] = nil
        end
        for key, value in pairs(originalPowerStrike) do
            skill[key] = deepCopy(value)
        end
    end

    describe("Skills", function()
        local mockStore
        local player
        local clockState

        beforeAll(function()
            mockStore = MockProfileStore.new()
        end)

        afterAll(function()
            Skills._resetTimeProvider()
            restorePowerStrike()
            mockStore:restore()
        end)

        beforeEach(function()
            mockStore:reset()
            restorePowerStrike()

            local powerStrike = SkillsConfig.guerreiro.power_strike
            powerStrike.cooldown = 0.2
            for _, effect in ipairs(powerStrike.effects) do
                if effect.type == "attribute" then
                    effect.duration = 0.1
                end
            end

            player = TestPlayers.create("SkillsUser")
            clockState = { value = 0 }
            Skills._setTimeProvider(function()
                return clockState.value
            end)
        end)

        afterEach(function()
            if player then
                TestPlayers.destroy(player)
                player = nil
            end
            restorePowerStrike()
            Skills._resetTimeProvider()
        end)

        it("consome mana, aplica efeitos e respeita cooldown", function()
            local statsController = CharacterStats.new(player)
            local skillsController = Skills.new(player, statsController)

            local baseline = statsController:GetStats()
            local success, result = skillsController:UseSkill("power_strike")

            expect(success).to.equal(true)
            expect(result).to.be.ok()
            expect(result.id).to.equal("power_strike")

            local currentStats = statsController:GetStats()
            expect(currentStats.mana).to.equal(baseline.mana - SkillsConfig.guerreiro.power_strike.manaCost)
            expect(currentStats.attack).to.equal(baseline.attack + SkillsConfig.guerreiro.power_strike.effects[1].amount)

            local secondSuccess, _, detail = skillsController:UseSkill("power_strike")
            expect(secondSuccess).to.equal(false)
            expect(detail).to.be.ok()
            expect(detail.code).to.equal("cooldown")

            task.wait(0.2)

            local restoredStats = statsController:GetStats()
            expect(restoredStats.attack).to.equal(baseline.attack)

            clockState.value = SkillsConfig.guerreiro.power_strike.cooldown + 0.1

            local thirdSuccess = skillsController:UseSkill("power_strike")
            expect(thirdSuccess).to.equal(true)

            skillsController:Destroy()
            statsController:Destroy()
        end)
    end)
end
