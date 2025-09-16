local quest = {
    id = "primeira_caca",
    act = 1,
    questType = "main",
    name = "Primeira Caça",
    description = "Os habitantes da vila precisam de ajuda para conter os slimes que surgem perto das plantações.",
    objective = {
        type = "kill",
        target = "Slime",
        count = 3,
        description = "Derrote 3 slimes para demonstrar sua habilidade inicial de combate.",
        classObjectives = {
            guerreiro = {
                title = "Investida Protetora",
                description = "Enfrente 3 slimes em combate corpo a corpo para praticar bloqueios e contra-ataques.",
            },
            arqueiro = {
                title = "Olhos no Alvo",
                description = "Acerte 3 slimes à distância utilizando o arco para manter a linha segura.",
            },
            mago = {
                title = "Explosão Arcanista",
                description = "Use um feitiço de área para eliminar múltiplos slimes pequenos de uma só vez.",
            },
        },
        universal = {
            title = "Eliminar Slimes",
            description = "Qualquer método conta para derrotar 3 slimes e proteger as colheitas.",
        },
    },
    reward = {
        experience = 60,
        gold = 25,
        items = {
            potion_small = 1,
        },
        classRewards = {
            guerreiro = {
                items = {
                    training_blade = 1,
                },
            },
            arqueiro = {
                items = {
                    training_quiver = 1,
                },
            },
            mago = {
                items = {
                    training_grimoire = 1,
                },
            },
        },
    },
}

return quest

