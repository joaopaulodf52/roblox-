local quest = {
    id = "arena_campeoes",
    act = 2,
    questType = "main",
    name = "A Arena dos Campeões",
    description = "Prove sua força na arena enfrentando desafios alinhados à sua especialidade.",
    recommendedMap = {
        mapId = "champion_arena",
        spawnId = "vestiario",
        instructions = "Viaje até o vestiário da Arena dos Campeões e avance ao centro quando estiver pronto para lutar.",
    },
    matchmakingTag = "champion_arena",
    objective = {
        type = "story",
        target = "titulo_campeao",
        count = 1,
        description = "Conquiste o direito de ser chamado de Campeão da Arena.",
        classObjectives = {
            guerreiro = {
                title = "Confrontos Titânicos",
                description = "Vença batalhas corpo a corpo contra campeões fortemente armados.",
            },
            arqueiro = {
                title = "Precisão Impecável",
                description = "Supere desafios de tiro ao alvo com tempo limitado.",
            },
            mago = {
                title = "Duelo Arcano",
                description = "Triunfe em duelos mágicos contra conjuradores da arena.",
            },
        },
        universal = {
            title = "Vença a Arena",
            description = "Independente do estilo, vença os desafios para obter o título de campeão.",
        },
    },
    reward = {
        experience = 180,
        gold = 90,
        items = {
            potion_small = 2,
        },
        classRewards = {
            guerreiro = {
                items = {
                    arena_plate = 1,
                },
            },
            arqueiro = {
                items = {
                    precision_string = 1,
                },
            },
            mago = {
                items = {
                    dueling_tome = 1,
                },
            },
        },
    },
}

return quest

