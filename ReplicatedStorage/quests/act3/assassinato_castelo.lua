local quest = {
    id = "assassinato_castelo",
    act = 3,
    questType = "main",
    name = "O Assassinato no Castelo",
    description = "Um crime abalou o castelo e a verdade precisa ser descoberta antes que o reino mergulhe no caos.",
    objective = {
        type = "story",
        target = "culpado_identificado",
        count = 1,
        description = "Reúna provas suficientes para identificar o assassino.",
        classObjectives = {
            guerreiro = {
                title = "Linha de Interrogatório",
                description = "Interrogue guardas suspeitos e confronte inconsistências.",
            },
            arqueiro = {
                title = "Caça às Pistas",
                description = "Siga pegadas e rastros sutis deixados pelo culpado.",
            },
            mago = {
                title = "Resíduo Arcano",
                description = "Analise resquícios mágicos presentes na cena do crime.",
            },
        },
        universal = {
            title = "Verdade Revelada",
            description = "Combine as pistas para acusar corretamente o responsável.",
        },
    },
    reward = {
        experience = 210,
        gold = 100,
        classRewards = {
            guerreiro = {
                items = {
                    interrogation_badge = 1,
                },
            },
            arqueiro = {
                items = {
                    shadow_boots = 1,
                },
            },
            mago = {
                items = {
                    divination_orb = 1,
                },
            },
        },
    },
}

return quest

