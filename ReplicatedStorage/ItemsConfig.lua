local ItemsConfig = {
    sword_iron = {
        id = "sword_iron",
        name = "Espada de Ferro",
        type = "equipment",
        slot = "weapon",
        description = "Uma espada resistente feita de ferro polido.",
        attributes = {
            attack = 15,
        },
    },
    armor_leather = {
        id = "armor_leather",
        name = "Armadura de Couro",
        type = "equipment",
        slot = "armor",
        description = "Proteção leve feita com couro reforçado.",
        attributes = {
            defense = 10,
        },
    },
    potion_small = {
        id = "potion_small",
        name = "Poção de Cura Pequena",
        type = "consumable",
        description = "Restaura uma pequena quantidade de vida quando utilizada.",
        effects = {
            health = 35,
        },
    },
    tome_apprentice = {
        id = "tome_apprentice",
        name = "Tomo do Aprendiz",
        type = "consumable",
        description = "Concede experiência adicional quando lido.",
        effects = {
            experience = 50,
        },
    },
}

return ItemsConfig

