local GameConfig = {}

GameConfig.DefaultStats = {
    level = 1,
    experience = 0,
    health = 100,
    maxHealth = 100,
    mana = 50,
    maxMana = 50,
    attack = 10,
    defense = 5,
    gold = 0,
}

GameConfig.Experience = {
    baseRequirement = 100,
    perLevelGrowth = 25,
}

function GameConfig.getExperienceToLevel(level)
    level = math.max(level, 1)
    return GameConfig.Experience.baseRequirement + (level - 1) * GameConfig.Experience.perLevelGrowth
end

GameConfig.Inventory = {
    maxSlots = 30,
}

GameConfig.Quests = {
    maxActive = 3,
}

return GameConfig

