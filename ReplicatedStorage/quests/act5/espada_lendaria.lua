local quest = {
    id = "espada_lendaria",
    act = 5,
    questType = "main",
    name = "A Espada Lendária",
    description = "A arma lendária capaz de ferir o tirano repousa adormecida. Reúna as forças do grupo para despertá-la.",
    objective = {
        type = "story",
        target = "espada_desperta",
        count = 1,
        description = "Obtenha a espada lendária realizando as etapas necessárias.",
        classObjectives = {
            guerreiro = {
                title = "Empunhadura do Campeão",
                description = "Empunhe a espada lendária e prepare-se para o golpe final.",
            },
            arqueiro = {
                title = "Caminho da Forja",
                description = "Localize o caminho correto até a forja perdida nas montanhas.",
            },
            mago = {
                title = "Ritual de Libertação",
                description = "Conduza o ritual mágico para libertar a espada do selo antigo.",
            },
        },
        universal = {
            title = "Espada Obtida",
            description = "Trabalhem juntos para libertar a espada lendária e levá-la ao campo de batalha.",
        },
    },
    reward = {
        experience = 360,
        gold = 200,
        classRewards = {
            guerreiro = {
                items = {
                    legendary_blade = 1,
                },
            },
            arqueiro = {
                items = {
                    forja_compass = 1,
                },
            },
            mago = {
                items = {
                    ritual_catalyst = 1,
                },
            },
        },
    },
}

return quest

