local quest = {
    id = "maldicao_floresta",
    act = 3,
    questType = "main",
    name = "A Maldição da Floresta",
    description = "Uma maldição tomou conta da floresta ancestral. Purifique a área antes que corrompa o reino inteiro.",
    objective = {
        type = "story",
        target = "floresta_purificada",
        count = 1,
        description = "Remova a maldição que assombra a floresta.",
        classObjectives = {
            guerreiro = {
                title = "Quebra de Totens",
                description = "Destrua totens corrompidos protegidos por espíritos malignos.",
            },
            arqueiro = {
                title = "Caçada Purificadora",
                description = "Cace criaturas amaldiçoadas antes que espalhem a corrupção.",
            },
            mago = {
                title = "Ritual de Quebra",
                description = "Execute um ritual para dissipar a magia sombria que domina a floresta.",
            },
        },
        universal = {
            title = "Floresta Restaurada",
            description = "Conclua os passos necessários para purificar a floresta.",
        },
    },
    reward = {
        experience = 230,
        gold = 110,
        classRewards = {
            guerreiro = {
                items = {
                    warding_hammer = 1,
                },
            },
            arqueiro = {
                items = {
                    purging_arrows = 1,
                },
            },
            mago = {
                items = {
                    blooming_staff = 1,
                },
            },
        },
    },
}

return quest

