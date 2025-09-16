local SkillsConfig = {
    guerreiro = {
        power_strike = {
            id = "power_strike",
            name = "Golpe Poderoso",
            description = "Canaliza força bruta para ampliar o dano dos ataques por alguns instantes.",
            manaCost = 12,
            cooldown = 6,
            effects = {
                {
                    type = "attribute",
                    attribute = "attack",
                    amount = 8,
                    duration = 5,
                },
            },
        },
        iron_wall = {
            id = "iron_wall",
            name = "Muralha de Ferro",
            description = "Ergue uma defesa inabalável que reduz o dano recebido.",
            manaCost = 10,
            cooldown = 12,
            effects = {
                {
                    type = "attribute",
                    attribute = "defense",
                    amount = 10,
                    duration = 8,
                },
            },
        },
        battle_cry = {
            id = "battle_cry",
            name = "Brado de Batalha",
            description = "Um grito inspirador que aumenta o vigor para resistir e atacar com firmeza.",
            manaCost = 14,
            cooldown = 18,
            effects = {
                {
                    type = "attribute",
                    attribute = "attack",
                    amount = 5,
                    duration = 8,
                },
                {
                    type = "attribute",
                    attribute = "defense",
                    amount = 3,
                    duration = 8,
                },
            },
        },
    },
    arqueiro = {
        precise_arrow = {
            id = "precise_arrow",
            name = "Flecha Precisa",
            description = "Concentração máxima para acertar pontos vitais do alvo.",
            manaCost = 10,
            cooldown = 6,
            effects = {
                {
                    type = "attribute",
                    attribute = "attack",
                    amount = 7,
                    duration = 5,
                },
            },
        },
        evasive_maneuver = {
            id = "evasive_maneuver",
            name = "Movimento Evasivo",
            description = "Rearranja a postura para evitar golpes inimigos.",
            manaCost = 9,
            cooldown = 10,
            effects = {
                {
                    type = "attribute",
                    attribute = "defense",
                    amount = 6,
                    duration = 6,
                },
            },
        },
        tracking_focus = {
            id = "tracking_focus",
            name = "Foco do Rastreador",
            description = "Energia canalizada para manter a mira estável e recuperar energia arcana.",
            manaCost = 6,
            cooldown = 14,
            effects = {
                {
                    type = "attribute",
                    attribute = "attack",
                    amount = 4,
                    duration = 6,
                },
                {
                    type = "mana",
                    amount = 8,
                },
            },
        },
    },
    mago = {
        arcane_focus = {
            id = "arcane_focus",
            name = "Foco Arcano",
            description = "Canaliza energia arcana para potencializar feitiços ofensivos.",
            manaCost = 14,
            cooldown = 8,
            effects = {
                {
                    type = "attribute",
                    attribute = "attack",
                    amount = 9,
                    duration = 6,
                },
            },
        },
        mystic_barrier = {
            id = "mystic_barrier",
            name = "Barreira Mística",
            description = "Cria um escudo mágico temporário para absorver dano.",
            manaCost = 12,
            cooldown = 16,
            effects = {
                {
                    type = "attribute",
                    attribute = "defense",
                    amount = 7,
                    duration = 7,
                },
            },
        },
        rejuvenating_wave = {
            id = "rejuvenating_wave",
            name = "Onda Revigorante",
            description = "O fluxo de mana restaura parte da vitalidade e energia do mago.",
            manaCost = 16,
            cooldown = 20,
            effects = {
                {
                    type = "heal",
                    amount = 25,
                },
                {
                    type = "mana",
                    amount = 10,
                },
            },
        },
    },
}

return SkillsConfig
