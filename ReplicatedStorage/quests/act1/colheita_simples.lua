local quest = {
    id = "colheita_simples",
    act = 1,
    questType = "side",
    name = "Colheita Simples",
    description = "O fazendeiro local precisa de ajuda para garantir que as maçãs sejam entregues em segurança.",
    objective = {
        type = "collect",
        target = "maca_vermelha",
        count = 10,
        description = "Colete 10 maçãs frescas para o fazendeiro.",
        classObjectives = {
            guerreiro = {
                title = "Braços Fortes",
                description = "Carregue sacos pesados de maçãs até o celeiro sem deixá-los cair.",
            },
            arqueiro = {
                title = "Limpando os Céus",
                description = "Cace as aves que roubam frutas antes que estraguem a colheita.",
            },
            mago = {
                title = "Magia de Crescimento",
                description = "Lance um feitiço que acelera o crescimento das macieiras para repor a produção.",
            },
        },
        universal = {
            title = "Maçãs para o Fazendeiro",
            description = "Independentemente do método, entregue 10 maçãs saudáveis ao fazendeiro.",
        },
    },
    reward = {
        experience = 45,
        gold = 20,
        items = {
            potion_small = 1,
        },
        classRewards = {
            guerreiro = {
                items = {
                    light_shield = 1,
                },
            },
            arqueiro = {
                items = {
                    hunters_arrows = 1,
                },
            },
            mago = {
                items = {
                    growth_components = 1,
                },
            },
        },
    },
}

return quest

