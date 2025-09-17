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

local function sanitizeDuration(value)
    local numberValue = sanitizeNumber(value)
    if not numberValue or numberValue <= 0 then
        return nil
    end

    return numberValue
end

local function sanitizeTargetType(value)
    if type(value) ~= "string" then
        return nil
    end

    local trimmed = string.match(value, "^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil
    end

    return string.lower(trimmed)
end

local function sanitizeScalingTable(source)
    if type(source) ~= "table" then
        return nil
    end

    local sanitized = {}
    for stat, multiplier in pairs(source) do
        local numberValue = sanitizeNumber(multiplier)
        if numberValue and numberValue ~= 0 then
            sanitized[stat] = numberValue
        end
    end

    if next(sanitized) == nil then
        return nil
    end

    return sanitized
end

local function extractSkillId(entry)
    if type(entry) == "string" then
        return sanitizeSkillId(entry)
    elseif type(entry) == "table" then
        return sanitizeSkillId(entry.id)
            or sanitizeSkillId(entry.skillId)
            or sanitizeSkillId(entry.skill)
    end

    return nil
end

local function containerHasSkill(container, sanitizedId)
    if type(container) ~= "table" or not sanitizedId then
        return false
    end

    local directValue = container[sanitizedId]
    if directValue ~= nil then
        return directValue ~= false
    end

    for key, value in pairs(container) do
        if sanitizeSkillId(key) == sanitizedId and value ~= false then
            return true
        end

        local resolvedId = extractSkillId(value)
        if resolvedId == sanitizedId then
            return true
        end
    end

    return false
end

local function isCharacterStatsController(value)
    return type(value) == "table" and type(value.ApplyDamage) == "function" and type(value.GetStats) == "function"
end

local function resolveTargetName(statsController)
    if not statsController then
        return "Desconhecido"
    end

    local player = statsController.player
    if player then
        return player.DisplayName or player.Name
    end

    local snapshot = statsController:GetStats()
    return snapshot.name or snapshot.enemyType or "NPC"
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

function Skills.new(player, characterStats, combatController)
    assert(player, "Jogador é obrigatório para Skills")
    assert(characterStats, "CharacterStats é obrigatório para Skills")

    local self = setmetatable({}, Skills)
    self.player = player
    self.characterStats = characterStats
    self.combat = combatController
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

function Skills:BindCombatController(controller)
    self.combat = controller
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

function Skills:_resolveEffectTargets(effect, context, options)
    context = context or {}
    options = options or {}

    local resolved = {}
    local seen = {}

    local function addTarget(target)
        if isCharacterStatsController(target) and not seen[target] then
            table.insert(resolved, target)
            seen[target] = true
        end
    end

    local targetType = sanitizeTargetType(effect and effect.target)
    if not targetType then
        targetType = options.defaultTarget or "self"
    end

    if targetType == "self" or targetType == "caster" then
        addTarget(self.characterStats)
    elseif targetType == "enemy" or targetType == "target" then
        addTarget(context.target or context.targetStats)
        if #resolved == 0 and type(context.targets) == "table" then
            addTarget(context.targets[1])
        end
    elseif targetType == "allies" or targetType == "ally" or targetType == "team" then
        if type(context.allies) == "table" then
            for _, ally in ipairs(context.allies) do
                addTarget(ally)
            end
        end
        if options.includeSelf ~= false then
            addTarget(self.characterStats)
        end
    elseif targetType == "area" then
        if type(context.targets) == "table" then
            for _, target in ipairs(context.targets) do
                addTarget(target)
            end
        else
            addTarget(context.target or context.targetStats)
        end
    elseif targetType == "self_and_target" then
        addTarget(self.characterStats)
        addTarget(context.target or context.targetStats)
    else
        if options.defaultTarget == "target" then
            addTarget(context.target or context.targetStats)
        else
            addTarget(self.characterStats)
        end
    end

    if #resolved == 0 and options.fallbackToSelf ~= false then
        addTarget(self.characterStats)
    end

    return resolved
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

function Skills:_applyAttributeEffect(effect, context, results)
    local attribute = effect and effect.attribute
    local amount = sanitizeNumber(effect and effect.amount)
    local duration = sanitizeDuration(effect and effect.duration)

    if type(attribute) ~= "string" or attribute == "" or not amount or amount == 0 or not duration then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { fallbackToSelf = true })
    for _, target in ipairs(targets) do
        local applied = target:ApplyTemporaryModifier(attribute, amount, duration)
        if applied then
            table.insert(results, {
                type = "attribute",
                attribute = attribute,
                amount = amount,
                duration = duration,
                target = resolveTargetName(target),
            })
        end
    end
end

function Skills:_applyHealEffect(effect, context, results)
    local amount = sanitizeNumber(effect and effect.amount)
    if not amount or amount <= 0 then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { fallbackToSelf = true })
    for _, target in ipairs(targets) do
        local applied = target:RestoreHealth(amount)
        table.insert(results, {
            type = "heal",
            requested = amount,
            applied = applied,
            target = resolveTargetName(target),
        })
    end
end

function Skills:_applyManaEffect(effect, context, results)
    local amount = sanitizeNumber(effect and effect.amount)
    if not amount or amount <= 0 then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { fallbackToSelf = true })
    for _, target in ipairs(targets) do
        local applied = target:RestoreMana(amount)
        table.insert(results, {
            type = "mana",
            requested = amount,
            applied = applied,
            target = resolveTargetName(target),
        })
    end
end

function Skills:_applyExperienceEffect(effect, context, results)
    local amount = sanitizeNumber(effect and effect.amount)
    if not amount or amount <= 0 then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { fallbackToSelf = true })
    for _, target in ipairs(targets) do
        target:AddExperience(amount)
        table.insert(results, {
            type = "experience",
            amount = amount,
            target = resolveTargetName(target),
        })
    end
end

function Skills:_applyCrowdControlEffect(effect, context, results)
    local attribute = effect and effect.attribute
    local amount = sanitizeNumber(effect and effect.amount)
    local duration = sanitizeDuration(effect and effect.duration)
    if type(attribute) ~= "string" or attribute == "" or not amount or amount == 0 or not duration then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { defaultTarget = "target", fallbackToSelf = false })
    for _, target in ipairs(targets) do
        local applied = target:ApplyTemporaryModifier(attribute, amount, duration)
        if applied then
            table.insert(results, {
                type = "crowdControl",
                attribute = attribute,
                amount = amount,
                duration = duration,
                target = resolveTargetName(target),
                tag = effect.tag or effect.status,
            })
        end
    end
end

function Skills:_applyAuraEffect(effect, context, results)
    local modifiers = effect and effect.modifiers
    if type(modifiers) ~= "table" then
        return
    end

    local baseDuration = sanitizeDuration(effect.duration)
    local targets = self:_resolveEffectTargets(effect, context, { fallbackToSelf = true, includeSelf = effect.includeSelf ~= false })

    for _, target in ipairs(targets) do
        for _, modifier in ipairs(modifiers) do
            if type(modifier) == "table" then
                local attribute = modifier.attribute
                local amount = sanitizeNumber(modifier.amount)
                local duration = sanitizeDuration(modifier.duration) or baseDuration
                if type(attribute) == "string" and attribute ~= "" and amount and amount ~= 0 and duration then
                    local applied = target:ApplyTemporaryModifier(attribute, amount, duration)
                    if applied then
                        table.insert(results, {
                            type = "aura",
                            attribute = attribute,
                            amount = amount,
                            duration = duration,
                            target = resolveTargetName(target),
                        })
                    end
                end
            end
        end
    end
end

function Skills:_applyDamageEffect(skillConfig, effect, context, results)
    if not self.combat then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { defaultTarget = "target", fallbackToSelf = false })
    if #targets == 0 then
        return
    end

    local scaling = sanitizeScalingTable(effect and effect.scaling)
    local baseAmount = sanitizeNumber(effect and effect.amount)
    local includeWeapon = effect and effect.includeWeaponDamage == true

    local minimumDamageValue = sanitizeNumber(effect and effect.minimumDamage)

    if baseAmount == 0 and not scaling and not includeWeapon and not (minimumDamageValue and minimumDamageValue > 0) then
        return
    end

    local paramsTemplate = {
        basePower = baseAmount,
        scaling = scaling,
        damageType = effect and effect.damageType or skillConfig.damageType or "magical",
        includeWeaponDamage = includeWeapon,
        armorPenetration = sanitizeNumber(effect and effect.armorPenetration),
        resistanceMultiplier = sanitizeNumber(effect and effect.resistanceMultiplier),
        criticalChance = sanitizeNumber(effect and effect.criticalChance),
        criticalMultiplier = sanitizeNumber(effect and effect.criticalMultiplier),
        ignoreDefense = effect and effect.ignoreDefense == true,
        canBeDodged = effect and effect.canBeDodged,
        canBeBlocked = effect and effect.canBeBlocked,
        skillId = skillConfig.id,
    }

    if minimumDamageValue and minimumDamageValue > 0 then
        paramsTemplate.minimumDamage = minimumDamageValue
    end

    for _, target in ipairs(targets) do
        local params = table.clone(paramsTemplate)
        local amountDealt, defeated, payload = self.combat:ApplySkillDamage(target, params)
        table.insert(results, {
            type = "damage",
            amount = amountDealt,
            defeated = defeated,
            target = resolveTargetName(target),
            detail = payload and payload.detail,
        })
    end
end

function Skills:_applyDotEffect(skillConfig, effect, context, results)
    if not self.combat then
        return
    end

    local ticks = math.max(math.floor(sanitizeNumber(effect and effect.ticks) or 0), 0)
    if ticks <= 0 then
        return
    end

    local interval = sanitizeNumber(effect and (effect.interval or effect.tickInterval))
    if not interval or interval <= 0 then
        interval = 1
    end

    local scaling = sanitizeScalingTable(effect and effect.scaling)
    local baseAmount = sanitizeNumber(effect and effect.amount) or 0
    local includeWeapon = effect and effect.includeWeaponDamage == true
    local minimumDamageValue = sanitizeNumber(effect and effect.minimumDamage)

    if baseAmount == 0 and not scaling and not includeWeapon and not (minimumDamageValue and minimumDamageValue > 0) then
        return
    end

    local targets = self:_resolveEffectTargets(effect, context, { defaultTarget = "target", fallbackToSelf = false })
    if #targets == 0 then
        return
    end
    local paramsTemplate = {
        basePower = baseAmount,
        scaling = scaling,
        damageType = effect and effect.damageType or skillConfig.damageType or "magical",
        includeWeaponDamage = includeWeapon,
        armorPenetration = sanitizeNumber(effect and effect.armorPenetration),
        resistanceMultiplier = sanitizeNumber(effect and effect.resistanceMultiplier),
        criticalChance = sanitizeNumber(effect and effect.criticalChance),
        criticalMultiplier = sanitizeNumber(effect and effect.criticalMultiplier),
        ignoreDefense = effect and effect.ignoreDefense == true,
        canBeDodged = effect and effect.canBeDodged,
        canBeBlocked = effect and effect.canBeBlocked,
        skillId = skillConfig.id,
    }

    if minimumDamageValue and minimumDamageValue > 0 then
        paramsTemplate.minimumDamage = minimumDamageValue
    end

    local targetList = table.clone(targets)
    local targetNames = {}
    for _, target in ipairs(targetList) do
        table.insert(targetNames, resolveTargetName(target))
    end

    task.spawn(function()
        for tick = 1, ticks do
            if self._destroyed then
                break
            end

            task.wait(interval)

            if self._destroyed then
                break
            end

            for _, target in ipairs(targetList) do
                if self._destroyed then
                    break
                end

                if target and not target._destroyed then
                    local params = table.clone(paramsTemplate)
                    params.source = "skill_dot"
                    params.tick = tick
                    self.combat:ApplySkillDamage(target, params)
                end
            end
        end
    end)

    table.insert(results, {
        type = "dot",
        ticks = ticks,
        interval = interval,
        amount = baseAmount,
        targets = targetNames,
    })
end

function Skills:_applyEffects(skillConfig, context)
    local results = {}
    local effects = skillConfig.effects

    if type(effects) ~= "table" or not self.characterStats then
        return results
    end

    context = context or {}

    for _, effect in ipairs(effects) do
        if type(effect) == "table" then
            local effectType = effect.type
            if effectType == "attribute" then
                self:_applyAttributeEffect(effect, context, results)
            elseif effectType == "heal" then
                self:_applyHealEffect(effect, context, results)
            elseif effectType == "mana" then
                self:_applyManaEffect(effect, context, results)
            elseif effectType == "experience" then
                self:_applyExperienceEffect(effect, context, results)
            elseif effectType == "damage" then
                self:_applyDamageEffect(skillConfig, effect, context, results)
            elseif effectType == "dot" then
                self:_applyDotEffect(skillConfig, effect, context, results)
            elseif effectType == "crowdControl" then
                self:_applyCrowdControlEffect(effect, context, results)
            elseif effectType == "aura" then
                self:_applyAuraEffect(effect, context, results)
            end
        end
    end

    return results
end

function Skills:UseSkill(skillId, context)
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
        return false, "habilidade desconhecida", {
            code = "unknown_skill",
            skillId = sanitized,
        }
    end

    local unlocked = containerHasSkill(self.data.unlocked, sanitized)
    local equipped = containerHasSkill(self.data.hotbar, sanitized)
    if not unlocked and not equipped then
        return false, "habilidade não desbloqueada", {
            code = "skill_locked",
            skillId = sanitized,
        }
    end

    context = context or {}

    local remainingCooldown = self:GetCooldownRemaining(sanitized)
    if remainingCooldown > 0 then
        return false, "habilidade em recarga", {
            code = "cooldown",
            remaining = remainingCooldown,
            skillId = sanitized,
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
                skillId = sanitized,
            }
        end
    end

    self:_setCooldown(sanitized, skillConfig.cooldown)

    local appliedEffects = self:_applyEffects(skillConfig, context)

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
