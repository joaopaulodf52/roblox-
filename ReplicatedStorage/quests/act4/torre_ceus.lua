local quest = {
    id = "torre_ceus",
    act = 4,
    questType = "main",
    name = "A Torre dos Céus",
    description = "A torre flutuante guarda segredos antigos e mecanismos perigosos. Suba até o topo para abrir caminho ao inimigo final.",
    objective = {
        type = "story",
        target = "topo_da_torre",
        count = 1,
        description = "Alcance o topo da Torre dos Céus.",
        classObjectives = {
            guerreiro = {
                title = "Força Inabalável",
                description = "Quebre barreiras físicas e proteja o grupo em plataformas instáveis.",
            },
            arqueiro = {
                title = "Mecanismos Precisos",
                description = "Ative mecanismos delicados em plataformas giratórias mantendo o equilíbrio.",
            },
            mago = {
                title = "Enigmas Celestes",
                description = "Resolva enigmas mágicos para desbloquear passagens ocultas.",
            },
        },
        universal = {
            title = "Topo da Torre",
            description = "Independentemente da função, todos devem cooperar para alcançar o topo.",
        },
    },
    reward = {
        experience = 270,
        gold = 130,
        classRewards = {
            guerreiro = {
                items = {
                    skybreaker_plate = 1,
                },
            },
            arqueiro = {
                items = {
                    mechanism_kit = 1,
                },
            },
            mago = {
                items = {
                    celestial_codex = 1,
                },
            },
        },
    },
}

return quest

