local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local Combat = {}
Combat.__index = Combat

local randomGenerator = Random.new()
local MINIMUM_DAMAGE = 1
local DEFAULT_CRITICAL_MULTIPLIER = 1.5

local function sanitizeNumber(value, defaultValue)
    if type(value) ~= "number" or value ~= value then
        return defaultValue or 0
    end

    return value
end

local function clampProbability(value)
    return math.clamp(sanitizeNumber(value, 0), 0, 0.95)
end

function Combat._setRandomGenerator(generator)
    if typeof(generator) == "Random" then
        randomGenerator = generator
    elseif type(generator) == "table" and type(generator.NextNumber) == "function" then
        randomGenerator = generator
    else
        randomGenerator = Random.new()
    end
end

function Combat._resetRandomGenerator()
    randomGenerator = Random.new()
end

local function getRandom()
    return randomGenerator
end

function Combat.CalculateDamage(attackerStats, defenderStats, context)
    attackerStats = attackerStats or {}
    defenderStats = defenderStats or {}
    context = context or {}

    local weaponConfig = context.weaponConfig
    if not weaponConfig and context.weaponId then
        weaponConfig = ItemsConfig[context.weaponId]
    end

    local includeWeaponDamage = context.includeWeaponDamage
    if includeWeaponDamage == nil then
        includeWeaponDamage = weaponConfig ~= nil
    end

    local damageType = context.damageType
    if not damageType then
        if weaponConfig and weaponConfig.damageType then
            damageType = weaponConfig.damageType
        else
            damageType = "physical"
        end
    end

    local detail = {
        damageType = damageType,
        includeWeaponDamage = includeWeaponDamage,
    }

    local baseAttack = sanitizeNumber(attackerStats.attack, 0)
    detail.baseAttack = baseAttack

    local weaponBonus = 0
    if includeWeaponDamage and weaponConfig and type(weaponConfig.attributes) == "table" then
        weaponBonus = sanitizeNumber(weaponConfig.attributes.attack, 0)
    end
    detail.weaponBonus = weaponBonus

    local basePower = sanitizeNumber(context.basePower or context.baseDamage or context.power, 0)
    detail.basePower = basePower

    local scalingBonus = 0
    if type(context.scaling) == "table" then
        for stat, multiplier in pairs(context.scaling) do
            if type(multiplier) == "number" then
                local statValue = sanitizeNumber(attackerStats[stat], 0)
                scalingBonus += statValue * multiplier
            end
        end
    end
    detail.scalingBonus = scalingBonus

    local attackPower = baseAttack + weaponBonus + basePower + scalingBonus
    detail.attackPower = attackPower

    local attackerLevel = sanitizeNumber(attackerStats.level, 1)
    local defenderLevel = sanitizeNumber(defenderStats.level, 1)
    local levelDifference = attackerLevel - defenderLevel
    local levelModifier = 1 + math.clamp(levelDifference * 0.05, -0.4, 0.6)
    detail.levelModifier = levelModifier
    attackPower *= levelModifier

    local attackerMultiplier = 1
    if type(attackerStats.damageMultipliers) == "table" then
        local typeMultiplier = attackerStats.damageMultipliers[damageType] or attackerStats.damageMultipliers.all
        if type(typeMultiplier) == "number" then
            attackerMultiplier *= typeMultiplier
        end
    end
    detail.attackerMultiplier = attackerMultiplier
    attackPower *= attackerMultiplier

    local defense = sanitizeNumber(defenderStats.defense, 0)
    local defenseMultiplier = sanitizeNumber(context.defenseMultiplier, 1)
    if type(defenderStats.defenseMultipliers) == "table" then
        local typeMultiplier = defenderStats.defenseMultipliers[damageType] or defenderStats.defenseMultipliers.all
        if type(typeMultiplier) == "number" then
            defenseMultiplier *= typeMultiplier
        end
    end

    if defenseMultiplier ~= 1 then
        defense *= defenseMultiplier
    end

    local armorPenetration = sanitizeNumber(context.armorPenetration, 0)
    if includeWeaponDamage and weaponConfig and type(weaponConfig.attributes) == "table" then
        armorPenetration += sanitizeNumber(weaponConfig.attributes.armorPenetration, 0)
    end

    if context.ignoreDefense then
        detail.defenseIgnored = true
        defense = 0
    elseif armorPenetration > 0 then
        defense = math.max(defense - armorPenetration, 0)
    end
    detail.effectiveDefense = defense

    local postDefenseDamage = math.max(attackPower - defense, 0)
    detail.postDefenseDamage = postDefenseDamage

    local rng = getRandom()

    local dodgeChance = clampProbability(defenderStats.dodgeChance or 0)
    if context.canBeDodged == false then
        dodgeChance = 0
    end

    if dodgeChance > 0 then
        local roll = rng:NextNumber()
        detail.dodgeChance = dodgeChance
        detail.dodgeRoll = roll
        if roll < dodgeChance then
            detail.dodged = true
            detail.calculatedDamage = 0
            detail.finalDamage = 0
            detail.minimumDamageApplied = false
            return 0, detail
        end
    end

    local criticalChance = sanitizeNumber(context.criticalChance, 0)
    local criticalMultiplier = sanitizeNumber(context.criticalMultiplier, 0)

    if includeWeaponDamage and weaponConfig and type(weaponConfig.attributes) == "table" then
        criticalChance += sanitizeNumber(weaponConfig.attributes.criticalChance, 0)
        if criticalMultiplier <= 0 then
            criticalMultiplier = sanitizeNumber(weaponConfig.attributes.criticalMultiplier, 0)
        end
    end

    if criticalMultiplier <= 0 then
        criticalMultiplier = DEFAULT_CRITICAL_MULTIPLIER
    end

    detail.criticalChance = criticalChance
    detail.criticalMultiplier = criticalMultiplier

    if criticalChance > 0 then
        local roll = rng:NextNumber()
        detail.criticalRoll = roll
        if roll < criticalChance then
            detail.critical = true
            postDefenseDamage *= criticalMultiplier
        end
    end

    local blockChance = clampProbability(defenderStats.blockChance or 0)
    local blockReduction = math.clamp(sanitizeNumber(defenderStats.blockReduction, 0.5), 0, 1)
    if context.canBeBlocked == false then
        blockChance = 0
    end

    if blockChance > 0 then
        local roll = rng:NextNumber()
        detail.blockChance = blockChance
        detail.blockRoll = roll
        if roll < blockChance then
            detail.blocked = true
            postDefenseDamage *= (1 - blockReduction)
            detail.blockReduction = blockReduction
        end
    end

    local resistance = 0
    if type(defenderStats.resistances) == "table" then
        local value = defenderStats.resistances[damageType]
        if value == nil then
            value = defenderStats.resistances.all
        end
        if type(value) == "number" then
            resistance = value
        end
    elseif type(defenderStats.resistance) == "number" then
        resistance = defenderStats.resistance
    end

    resistance = math.clamp(resistance, -0.95, 0.95)
    if context.resistanceMultiplier then
        resistance *= context.resistanceMultiplier
    end

    detail.resistance = resistance
    local resistanceMultiplier = 1 - resistance
    detail.resistanceMultiplier = resistanceMultiplier
    postDefenseDamage *= resistanceMultiplier

    local defenderMitigation = 1
    if type(defenderStats.damageMitigation) == "table" then
        local mitigation = defenderStats.damageMitigation[damageType] or defenderStats.damageMitigation.all
        if type(mitigation) == "number" then
            mitigation = math.clamp(mitigation, -0.95, 0.95)
            defenderMitigation *= (1 - mitigation)
        end
    end
    detail.defenderMitigation = defenderMitigation
    postDefenseDamage *= defenderMitigation

    local minimumDamage = sanitizeNumber(context.minimumDamage, MINIMUM_DAMAGE)
    if postDefenseDamage < minimumDamage then
        detail.minimumDamageApplied = true
        postDefenseDamage = minimumDamage
    end

    detail.rawDamage = postDefenseDamage
    local finalDamage = math.max(math.floor(postDefenseDamage + 0.5), 0)
    detail.calculatedDamage = finalDamage
    detail.finalDamage = finalDamage

    return finalDamage, detail
end

function Combat.new(player, characterStats, inventory, questManager)
    local self = setmetatable({}, Combat)
    self.player = player
    self.characterStats = characterStats
    self.inventory = inventory
    self.questManager = questManager
    self.achievementManager = nil
    return self
end

function Combat:_notifyClients(event)
    Remotes.CombatNotification:FireClient(self.player, event)
    if event.targetPlayer then
        local mirrored = table.clone(event)
        mirrored.targetPlayer = nil
        Remotes.CombatNotification:FireClient(event.targetPlayer, mirrored)
    end
end

function Combat:_resolveWeapon(weaponId)
    if weaponId then
        return weaponId, ItemsConfig[weaponId]
    end

    if not self.inventory then
        return nil, nil
    end

    local equipped = self.inventory:GetEquipped()
    if equipped and equipped.weapon then
        return equipped.weapon, ItemsConfig[equipped.weapon]
    end

    return nil, nil
end

function Combat:_applyDamageToTarget(targetController, params)
    assert(targetController, "Target controller necessário para ataque")

    local attackerStats = self.characterStats:GetStats()
    local defenderStats = targetController:GetStats()
    local damage, detail = Combat.CalculateDamage(attackerStats, defenderStats, params)
    local computedDamage = damage

    local appliedDamage, defeated = targetController:ApplyDamage(damage)

    detail.computedDamage = detail.finalDamage or computedDamage
    detail.finalDamage = appliedDamage
    detail.defeated = defeated
    detail.weaponId = params and params.weaponId or detail.weaponId
    detail.source = params and params.source or detail.source or "attack"
    detail.skillId = params and params.skillId or detail.skillId
    detail.includeWeaponDamage = params and params.includeWeaponDamage
    detail.damageType = detail.damageType or (params and params.damageType) or "physical"

    detail.attackerLevel = attackerStats.level
    detail.defenderLevel = defenderStats.level

    local attackerName = self.player and self.player.Name or attackerStats.name or "NPC"
    local targetPlayer = targetController.player
    local defenderName = defenderStats.name or defenderStats.enemyType or (targetPlayer and targetPlayer.Name) or "NPC"

    detail.attackerName = attackerName
    detail.defenderName = defenderName
    detail.targetPlayer = targetPlayer

    local targetSnapshot = targetController:GetStats()
    detail.remainingHealth = targetSnapshot.health
    detail.remainingMana = targetSnapshot.mana

    return detail, defenderStats
end

function Combat:AttackTarget(targetController, weaponId)
    assert(targetController, "Target controller necessário para ataque")

    local resolvedWeapon, weaponConfig = self:_resolveWeapon(weaponId)
    local context = {
        weaponId = resolvedWeapon,
        weaponConfig = weaponConfig,
        includeWeaponDamage = true,
        damageType = (weaponConfig and weaponConfig.damageType) or "physical",
        source = "attack",
    }

    local detail, defenderStats = self:_applyDamageToTarget(targetController, context)

    self.characterStats:AddExperience(10)

    local payload = {
        type = "attack",
        attacker = detail.attackerName,
        target = detail.defenderName,
        weapon = resolvedWeapon,
        damage = detail.finalDamage,
        defeated = detail.defeated,
        targetPlayer = targetController.player,
        detail = detail,
    }
    self:_notifyClients(payload)

    if detail.defeated then
        self:OnEnemyDefeated(defenderStats.enemyType or defenderStats.name)
    end

    return detail.finalDamage, detail.defeated, detail
end

function Combat:OnEnemyDefeated(enemyType)
    if self.questManager and enemyType then
        self.questManager:RegisterKill(enemyType)
    end

    if self.achievementManager then
        self.achievementManager:OnEnemyDefeated(enemyType)
    end
end

function Combat:HandleLootDrop(itemId, quantity)
    if not self.inventory then
        return
    end

    self.inventory:AddItem(itemId, quantity or 1)
end

function Combat:ApplySkillDamage(targetController, params)
    assert(targetController, "Target controller necessário para dano de habilidade")

    params = params or {}
    if params.includeWeaponDamage == nil then
        params.includeWeaponDamage = false
    end

    if params.includeWeaponDamage then
        local resolvedWeapon, weaponConfig = self:_resolveWeapon(params.weaponId)
        params.weaponId = resolvedWeapon
        params.weaponConfig = params.weaponConfig or weaponConfig
    end

    params.source = params.source or "skill"
    params.damageType = params.damageType or "magical"
    params.minimumDamage = params.minimumDamage or MINIMUM_DAMAGE

    local detail, defenderStats = self:_applyDamageToTarget(targetController, params)

    local payload = {
        type = "skill",
        attacker = detail.attackerName,
        target = detail.defenderName,
        damage = detail.finalDamage,
        defeated = detail.defeated,
        targetPlayer = targetController.player,
        skillId = params.skillId,
        detail = detail,
    }

    self:_notifyClients(payload)

    if detail.defeated then
        self:OnEnemyDefeated(defenderStats.enemyType or defenderStats.name)
    end

    return detail.finalDamage, detail.defeated, payload
end

function Combat:BindAchievementManager(manager)
    self.achievementManager = manager
end

function Combat:UnbindAchievementManager(manager)
    if manager == nil or manager == self.achievementManager then
        self.achievementManager = nil
    end
end

return Combat

