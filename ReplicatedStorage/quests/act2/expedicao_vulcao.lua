local quest = {
    id = "expedicao_vulcao",
    act = 2,
    questType = "main",
    name = "Expedição ao Vulcão",
    description = "Os cristais do vulcão são vitais para estabilizar a energia do reino. Ajude a recuperá-los com segurança.",
    objective = {
        type = "collect",
        target = "cristal_vulcanico",
        count = 3,
        description = "Recupere cristais vulcânicos intactos das profundezas da cratera.",
        classObjectives = {
            guerreiro = {
                title = "Carga Resistente",
                description = "Carregue cristais pesados pela lava enquanto protege os aliados.",
            },
            arqueiro = {
                title = "Guarda Aérea",
                description = "Elimine morcegos vulcânicos que atacam à distância durante a expedição.",
            },
            mago = {
                title = "Estabilização Arcana",
                description = "Use feitiços para estabilizar cristais instáveis e impedir explosões.",
            },
        },
        universal = {
            title = "Cristais Recuperados",
            description = "Todas as tarefas convergem para recuperar cristais vulcânicos seguros.",
        },
    },
    reward = {
        experience = 150,
        gold = 70,
        classRewards = {
            guerreiro = {
                items = {
                    molten_gauntlets = 1,
                },
            },
            arqueiro = {
                items = {
                    ember_arrow_bundle = 1,
                },
            },
            mago = {
                items = {
                    stability_charm = 1,
                },
            },
        },
    },
}

return quest

