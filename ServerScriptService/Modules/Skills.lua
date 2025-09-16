local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillsConfig = require(ReplicatedStorage:WaitForChild("SkillsConfig"))
local PlayerProfileStore = require(script.Parent.PlayerProfileStore)

local Skills = {}
Skills.__index = Skills

local function sanitizeSkillId(value)
    if type(value) ~= "string" then
        return nil
    end

    local trimmed = string.match(value, "^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil
    end

    return string.lower(trimmed)
end

local function sanitizeNumber(value)
    if type(value) ~= "number" then
        return nil
    end

    if value ~= value then
        return nil
    end

    return value
end

local timeProvider = os.clock

function Skills._setTimeProvider(provider)
    if type(provider) == "function" then
        timeProvider = provider
    else
        timeProvider = os.clock
    end
end

function Skills._resetTimeProvider()
    timeProvider = os.clock
end

function Skills.new(player, characterStats)
    assert(player, "Jogador é obrigatório para Skills")
    assert(characterStats, "CharacterStats é obrigatório para Skills")

    local self = setmetatable({}, Skills)
    self.player = player
    self.characterStats = characterStats
    self.profile = PlayerProfileStore.Load(player)
    self.data = self.profile.skills or {}
    self.cooldowns = {}
    self._destroyed = false

    self:_ensureStructure()

    return self
end

function Skills:_ensureStructure()
    self.data.unlocked = self.data.unlocked or {}
    self.data.hotbar = self.data.hotbar or {}
    self.data.version = self.data.version or 1
end

function Skills:GetSkillsForClass(className)
    className = className or (self.characterStats and self.characterStats:GetClass())
    if type(className) ~= "string" then
        return {}
    end

    local normalized = string.lower(className)
    return SkillsConfig[normalized] or {}
end

function Skills:GetSkillDefinition(skillId)
    local sanitized = sanitizeSkillId(skillId)
    if not sanitized then
        return nil
    end

    local className = self.characterStats and self.characterStats:GetClass()
    if type(className) ~= "string" then
        return nil
    end

    local classSkills = self:GetSkillsForClass(className)
    return classSkills[sanitized]
end

function Skills:GetCooldownRemaining(skillId)
    local sanitized = sanitizeSkillId(skillId)
    if not sanitized then
        return 0
    end

    local expiresAt = self.cooldowns[sanitized]
    if not expiresAt then
        return 0
    end

    local remaining = expiresAt - timeProvider()
    if remaining <= 0 then
        self.cooldowns[sanitized] = nil
        return 0
    end

    return remaining
end

function Skills:_setCooldown(skillId, cooldown)
    local duration = sanitizeNumber(cooldown) or 0
    if duration <= 0 then
        self.cooldowns[skillId] = nil
        return
    end

    self.cooldowns[skillId] = timeProvider() + duration
end

function Skills:_applyEffects(skillConfig)
    local results = {}
    local effects = skillConfig.effects

    if type(effects) ~= "table" or not self.characterStats then
        return results
    end

    for _, effect in ipairs(effects) do
        if type(effect) == "table" then
            local effectType = effect.type
            if effectType == "attribute" then
                local attribute = effect.attribute
                local amount = sanitizeNumber(effect.amount)
                local duration = sanitizeNumber(effect.duration)
                if type(attribute) == "string" and amount and amount ~= 0 and duration and duration > 0 then
                    local applied = self.characterStats:ApplyTemporaryModifier(attribute, amount, duration)
                    if applied then
                        table.insert(results, {
                            type = "attribute",
                            attribute = attribute,
                            amount = amount,
                            duration = duration,
                        })
                    end
                end
            elseif effectType == "heal" then
                local amount = sanitizeNumber(effect.amount)
                if amount and amount > 0 then
                    local applied = self.characterStats:RestoreHealth(amount)
                    table.insert(results, {
                        type = "heal",
                        requested = amount,
                        applied = applied,
                    })
                end
            elseif effectType == "mana" then
                local amount = sanitizeNumber(effect.amount)
                if amount and amount > 0 then
                    local applied = self.characterStats:RestoreMana(amount)
                    table.insert(results, {
                        type = "mana",
                        requested = amount,
                        applied = applied,
                    })
                end
            elseif effectType == "experience" then
                local amount = sanitizeNumber(effect.amount)
                if amount and amount > 0 then
                    self.characterStats:AddExperience(amount)
                    table.insert(results, {
                        type = "experience",
                        amount = amount,
                    })
                end
            end
        end
    end

    return results
end

function Skills:UseSkill(skillId)
    if self._destroyed then
        return false, "Controlador de habilidades não está disponível"
    end

    if not self.characterStats then
        return false, "Dados de personagem indisponíveis"
    end

    local sanitized = sanitizeSkillId(skillId)
    if not sanitized then
        return false, "skillId inválido"
    end

    local skillConfig = self:GetSkillDefinition(sanitized)
    if not skillConfig then
        return false, "habilidade desconhecida"
    end

    local remainingCooldown = self:GetCooldownRemaining(sanitized)
    if remainingCooldown > 0 then
        return false, "habilidade em recarga", {
            code = "cooldown",
            remaining = remainingCooldown,
        }
    end

    local manaCost = sanitizeNumber(skillConfig.manaCost) or 0
    if manaCost < 0 then
        manaCost = 0
    end

    if manaCost > 0 then
        local consumed = self.characterStats:UseMana(manaCost)
        if not consumed then
            return false, "mana insuficiente", {
                code = "insufficient_mana",
            }
        end
    end

    self:_setCooldown(sanitized, skillConfig.cooldown)

    local appliedEffects = self:_applyEffects(skillConfig)

    return true, {
        id = sanitized,
        name = skillConfig.name,
        cooldown = sanitizeNumber(skillConfig.cooldown) or 0,
        manaCost = manaCost,
        effects = appliedEffects,
    }
end

function Skills:Destroy()
    self._destroyed = true
    self.cooldowns = {}
end

return Skills
