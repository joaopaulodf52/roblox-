local quest = {
    id = "cacada_dragao_sombrio",
    act = 4,
    questType = "main",
    name = "A Caçada ao Dragão Sombrio",
    description = "O dragão sombrio ameaça destruir o reino. Coordene-se com seus aliados para pôr fim à criatura.",
    objective = {
        type = "kill",
        target = "DragaoSombrio",
        count = 1,
        description = "Derrote o dragão sombrio para salvar o reino.",
        classObjectives = {
            guerreiro = {
                title = "Escudo da Linha de Frente",
                description = "Enfrente o dragão corpo a corpo e mantenha sua atenção no tanque.",
            },
            arqueiro = {
                title = "Pontaria Cirúrgica",
                description = "Acerte os pontos fracos nas asas e na cauda para limitar os movimentos do dragão.",
            },
            mago = {
                title = "Suporte Arcano",
                description = "Proteja os aliados com escudos mágicos e conjure feitiços de área.",
            },
        },
        universal = {
            title = "Dragão Abatido",
            description = "Independentemente das funções individuais, o objetivo final é derrubar o dragão.",
        },
    },
    reward = {
        experience = 330,
        gold = 180,
        classRewards = {
            guerreiro = {
                items = {
                    dragonscale_shield = 1,
                },
            },
            arqueiro = {
                items = {
                    dragonbane_arrows = 1,
                },
            },
            mago = {
                items = {
                    protective_barrier_scroll = 1,
                },
            },
        },
    },
}

return quest

