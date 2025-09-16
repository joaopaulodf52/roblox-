local quest = {
    id = "alquimista_perdido",
    act = 2,
    questType = "side",
    name = "O Alquimista Perdido",
    description = "Um alquimista desapareceu na mata coletando ingredientes raros. Reúna o que ele precisa para retornar ao trabalho.",
    objective = {
        type = "collect",
        target = "essencia_alquimica",
        count = 3,
        description = "Junte ingredientes raros para preparar a poção do alquimista.",
        classObjectives = {
            guerreiro = {
                title = "Proteção à Procura",
                description = "Colete ervas em áreas perigosas afastando monstros do alquimista.",
            },
            arqueiro = {
                title = "Caça Precisa",
                description = "Cace criaturas raras para obter glândulas e penas especiais.",
            },
            mago = {
                title = "Mistura Perfeita",
                description = "Misture os ingredientes no caldeirão mágico garantindo a proporção correta.",
            },
        },
        universal = {
            title = "Poção Reconstruída",
            description = "Independentemente das tarefas, entregue ao alquimista os componentes da poção.",
        },
    },
    reward = {
        experience = 120,
        gold = 65,
        classRewards = {
            guerreiro = {
                items = {
                    foragers_belt = 1,
                },
            },
            arqueiro = {
                items = {
                    tracker_calls = 1,
                },
            },
            mago = {
                items = {
                    alchemical_gloves = 1,
                },
            },
        },
    },
}

return quest

