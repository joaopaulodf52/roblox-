local QuestConfig = {
    slay_goblins = {
        id = "slay_goblins",
        name = "Varredura Goblin",
        description = "Derrote 5 goblins nas planícies para proteger a vila.",
        objective = {
            type = "kill",
            target = "Goblin",
            count = 5,
        },
        reward = {
            experience = 120,
            gold = 40,
            items = {
                potion_small = 2,
            },
        },
    },
    gather_herbs = {
        id = "gather_herbs",
        name = "Suprimentos de Ervas",
        description = "Colete 3 ervas medicinais para o alquimista da cidade.",
        objective = {
            type = "collect",
            target = "Herb",
            count = 3,
        },
        reward = {
            experience = 80,
            gold = 25,
        },
    },
}

return QuestConfig

