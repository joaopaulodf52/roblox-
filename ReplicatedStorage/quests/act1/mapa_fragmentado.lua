local quest = {
    id = "mapa_fragmentado",
    act = 1,
    questType = "main",
    name = "Mapa Fragmentado",
    description = "Rumores indicam que um mapa antigo foi dividido entre diferentes guardiões. Reúna as peças para revelar o caminho adiante.",
    objective = {
        type = "collect",
        target = "fragmento_mapa_central",
        count = 1,
        description = "Recupere a peça do mapa perdida e una-a às demais partes.",
        classObjectives = {
            guerreiro = {
                title = "Guardião do Fragmento",
                description = "Derrote o inimigo que vigia a peça do mapa em combate direto.",
            },
            arqueiro = {
                title = "Rastros na Floresta",
                description = "Siga pegadas até localizar um baú escondido contendo o fragmento.",
            },
            mago = {
                title = "Enigma Arcano",
                description = "Resolva um quebra-cabeça mágico para libertar o fragmento do selo.",
            },
        },
        universal = {
            title = "Fragmento Recuperado",
            description = "Qualquer abordagem leva à mesma meta: recuperar a peça do mapa.",
        },
    },
    reward = {
        experience = 80,
        gold = 40,
        classRewards = {
            guerreiro = {
                items = {
                    guardian_blade = 1,
                },
            },
            arqueiro = {
                items = {
                    trail_lantern = 1,
                },
            },
            mago = {
                items = {
                    rune_focus = 1,
                },
            },
        },
    },
}

return quest

