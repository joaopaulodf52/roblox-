local AchievementConfig = {
    leaderboard = {
        storeName = "RPG_ACHIEVEMENTS_LEADERBOARD",
        maxEntries = 50,
    },
    definitions = {
        novice_adventurer = {
            name = "Aventureiro Novato",
            description = "Ganhe 200 pontos de experiência acumulados.",
            condition = {
                type = "experience",
                threshold = 200,
            },
            reward = {
                gold = 25,
            },
        },
        seasoned_hero = {
            name = "Herói Experiente",
            description = "Acumule 1000 pontos de experiência ao longo de sua jornada.",
            condition = {
                type = "experience",
                threshold = 1000,
            },
            reward = {
                experience = 250,
                gold = 100,
            },
        },
        first_blood = {
            name = "Primeiro Abate",
            description = "Derrote seu primeiro inimigo em batalha.",
            condition = {
                type = "kill",
                threshold = 1,
            },
            reward = {
                items = {
                    potion_small = 1,
                },
            },
        },
        goblin_slayer = {
            name = "Caçador de Goblins",
            description = "Derrote 5 Goblins nas planícies.",
            condition = {
                type = "kill",
                target = "Goblin",
                threshold = 5,
            },
            reward = {
                experience = 150,
            },
        },
        quest_novice = {
            name = "Novato em Missões",
            description = "Conclua a missão 'Suprimentos de Ervas'.",
            condition = {
                type = "quest",
                target = "gather_herbs",
                threshold = 1,
            },
            reward = {
                gold = 30,
            },
        },
        quest_adept = {
            name = "Adepto das Missões",
            description = "Conclua duas missões quaisquer.",
            condition = {
                type = "quest",
                threshold = 2,
            },
            reward = {
                items = {
                    potion_small = 1,
                },
            },
        },
    },
}

return AchievementConfig
