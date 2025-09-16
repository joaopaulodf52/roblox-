local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsConfig = require(ReplicatedStorage:WaitForChild("ItemsConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local Combat = {}
Combat.__index = Combat

function Combat.CalculateDamage(attackerStats, defenderStats, weaponConfig)
    local baseAttack = attackerStats.attack or 0
    local defense = defenderStats.defense or 0
    local weaponBonus = 0
    local criticalChance = 0

    if weaponConfig and weaponConfig.attributes then
        weaponBonus = weaponConfig.attributes.attack or 0
        criticalChance = weaponConfig.attributes.criticalChance or 0
    end

    local damage = baseAttack + weaponBonus - defense
    if damage < 1 then
        damage = 1
    end

    if criticalChance > 0 then
        local roll = math.random()
        if roll <= criticalChance then
            damage = math.floor(damage * 1.5)
        end
    end

    return math.floor(damage)
end

function Combat.new(player, characterStats, inventory, questManager)
    local self = setmetatable({}, Combat)
    self.player = player
    self.characterStats = characterStats
    self.inventory = inventory
    self.questManager = questManager
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

function Combat:AttackTarget(targetController, weaponId)
    assert(targetController, "Target controller necessário para ataque")

    local attackerStats = self.characterStats:GetStats()
    local defenderStats = targetController:GetStats()
    local resolvedWeapon, weaponConfig = self:_resolveWeapon(weaponId)

    local damage = Combat.CalculateDamage(attackerStats, defenderStats, weaponConfig)
    local appliedDamage, defeated = targetController:ApplyDamage(damage)

    self.characterStats:AddExperience(10)

    local targetPlayer = targetController.player

    local payload = {
        type = "attack",
        attacker = self.player and self.player.Name or "NPC",
        target = targetPlayer and targetPlayer.Name or "NPC",
        weapon = resolvedWeapon,
        damage = appliedDamage,
        defeated = defeated,
        targetPlayer = targetPlayer,
    }
    self:_notifyClients(payload)

    if defeated then
        self:OnEnemyDefeated(defenderStats.enemyType or defenderStats.name)
    end

    return appliedDamage, defeated
end

function Combat:OnEnemyDefeated(enemyType)
    if self.questManager and enemyType then
        self.questManager:RegisterKill(enemyType)
    end
end

function Combat:HandleLootDrop(itemId, quantity)
    if not self.inventory then
        return
    end

    self.inventory:AddItem(itemId, quantity or 1)
end

return Combat

