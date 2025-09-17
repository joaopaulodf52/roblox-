return function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local SkillsConfig = require(ReplicatedStorage:WaitForChild("SkillsConfig"))
    local Skills = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Skills"))
    local CharacterStats = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("CharacterStats"))
    local Combat = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("Combat"))
    local PlayerProfileStore = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("PlayerProfileStore"))

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
    local originalExplosiveArrow = deepCopy(SkillsConfig.arqueiro.explosive_arrow)

    local function restorePowerStrike()
        local skill = SkillsConfig.guerreiro.power_strike
        for key in pairs(skill) do
            skill[key] = nil
        end
        for key, value in pairs(originalPowerStrike) do
            skill[key] = deepCopy(value)
        end
    end

    local function restoreExplosiveArrow()
        local skill = SkillsConfig.arqueiro.explosive_arrow
        for key in pairs(skill) do
            skill[key] = nil
        end
        for key, value in pairs(originalExplosiveArrow) do
            skill[key] = deepCopy(value)
        end
    end

    local function normalizeSkillId(skillId)
        if type(skillId) ~= "string" then
            return nil
        end

        local trimmed = string.match(skillId, "^%s*(.-)%s*$")
        if not trimmed or trimmed == "" then
            return nil
        end

        return string.lower(trimmed)
    end

    local function unlockSkillFor(playerInstance, skillId)
        local normalized = normalizeSkillId(skillId)
        if not normalized then
            return nil
        end

        local profile = PlayerProfileStore.Load(playerInstance)
        profile.skills = profile.skills or {}
        profile.skills.unlocked = profile.skills.unlocked or {}
        profile.skills.unlocked[normalized] = true
        return profile
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
            restoreExplosiveArrow()
            mockStore:restore()
        end)

        beforeEach(function()
            mockStore:reset()
            restorePowerStrike()
            restoreExplosiveArrow()

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
            restoreExplosiveArrow()
            Skills._resetTimeProvider()
        end)

        it("consome mana, aplica efeitos e respeita cooldown", function()
            unlockSkillFor(player, "power_strike")
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

        it("rejeita habilidades não desbloqueadas", function()
            local statsController = CharacterStats.new(player)
            local skillsController = Skills.new(player, statsController)

            local baseline = statsController:GetStats()
            local success, message, detail = skillsController:UseSkill("power_strike")

            expect(success).to.equal(false)
            expect(message).to.equal("habilidade não desbloqueada")
            expect(detail).to.be.ok()
            expect(detail.code).to.equal("skill_locked")
            expect(detail.skillId).to.equal("power_strike")

            local current = statsController:GetStats()
            expect(current.mana).to.equal(baseline.mana)
            expect(skillsController:GetCooldownRemaining("power_strike")).to.equal(0)

            skillsController:Destroy()
            statsController:Destroy()
        end)

        it("aplica dano ofensivo e efeitos adicionais", function()
            local attacker = TestPlayers.create("ArcherSkillUser")
            local defender = TestPlayers.create("ArcherSkillTarget")

            local attackerProfile = unlockSkillFor(attacker, "explosive_arrow")
            if attackerProfile then
                attackerProfile.stats.class = "arqueiro"
            end

            local attackerStats = CharacterStats.new(attacker)
            local defenderStats = CharacterStats.new(defender)
            defenderStats.stats.health = 150

            local combatController = Combat.new(attacker, attackerStats)
            local skillsController = Skills.new(attacker, attackerStats, combatController)

            local explosiveArrow = SkillsConfig.arqueiro.explosive_arrow
            explosiveArrow.cooldown = 0.1
            for _, effect in ipairs(explosiveArrow.effects) do
                if effect.type == "dot" then
                    effect.interval = 0.05
                    effect.ticks = 2
                    effect.amount = 4
                end
            end

            local initialHealth = defenderStats:GetStats().health

            local context = {
                targetPlayer = defender,
                target = defenderStats,
                targetStats = defenderStats,
                targets = { defenderStats },
                position = Vector3.new(),
                radius = 0,
            }

            local success = skillsController:UseSkill("explosive_arrow", context)
            expect(success).to.equal(true)

            local impactHealth = defenderStats:GetStats().health
            expect(impactHealth < initialHealth).to.equal(true)

            task.wait(0.2)

            local finalHealth = defenderStats:GetStats().health
            expect(finalHealth < impactHealth).to.equal(true)

            skillsController:Destroy()
            attackerStats:Destroy()
            defenderStats:Destroy()
            TestPlayers.destroy(attacker)
            TestPlayers.destroy(defender)
        end)
    end)
end
