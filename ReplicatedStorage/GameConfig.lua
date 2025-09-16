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
    class = "guerreiro",
    resistances = {
        physical = 0,
        fire = 0,
        ice = 0,
        lightning = 0,
        poison = 0,
    },
    dodgeChance = 0,
    blockChance = 0,
    blockReduction = 0.5,
}

GameConfig.Classes = {
    default = "guerreiro",
    guerreiro = {
        name = "Guerreiro",
        role = "Tank/Dano corpo a corpo",
        strengths = {
            "Alta resistência física",
            "Capaz de proteger aliados em combate próximo",
        },
    },
    arqueiro = {
        name = "Arqueiro",
        role = "Dano à distância",
        strengths = {
            "Rastreia alvos e explora o terreno",
            "Especialista em acertar pontos fracos de inimigos distantes",
        },
    },
    mago = {
        name = "Mago",
        role = "Suporte/Dano mágico",
        strengths = {
            "Manipula feitiços de área",
            "Fornece suporte e proteção mágica ao grupo",
        },
    },
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

