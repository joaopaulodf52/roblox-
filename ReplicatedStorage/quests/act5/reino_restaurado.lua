local quest = {
    id = "reino_restaurado",
    act = 5,
    questType = "main",
    name = "O Reino Restaurado",
    description = "O confronto final se aproxima. Una as forças das três classes para derrotar o tirano que ameaça o reino.",
    objective = {
        type = "kill",
        target = "LordeSombrio",
        count = 1,
        description = "Derrote o chefe final e restaure a paz no reino.",
        classObjectives = {
            guerreiro = {
                title = "Foco do Inimigo",
                description = "Mantenha o inimigo ocupado em combate corpo a corpo e proteja os aliados.",
            },
            arqueiro = {
                title = "Alvos Críticos",
                description = "Acerte pontos críticos do chefe para abrir brechas de dano.",
            },
            mago = {
                title = "Barreira Arcana",
                description = "Proteja o grupo e neutralize as invocações com feitiços de área.",
            },
        },
        universal = {
            title = "Tirano Derrotado",
            description = "Coordene os esforços para derrotar o chefe final e restaurar o reino.",
        },
    },
    reward = {
        experience = 420,
        gold = 240,
        classRewards = {
            guerreiro = {
                items = {
                    royal_guard_plate = 1,
                    sentinel_helm = 1,
                },
            },
            arqueiro = {
                items = {
                    royal_arrowheads = 1,
                },
            },
            mago = {
                items = {
                    crown_sigil_cloak = 1,
                },
            },
        },
    },
}

return quest

