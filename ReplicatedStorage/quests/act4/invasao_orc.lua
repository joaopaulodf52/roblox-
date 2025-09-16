local quest = {
    id = "invasao_orc",
    act = 4,
    questType = "side",
    name = "Invasão Orc",
    description = "Os orcs iniciaram uma ofensiva contra a cidade. Coordene a defesa para repelir a invasão.",
    objective = {
        type = "kill",
        target = "OrcInvasor",
        count = 15,
        description = "Derrote os orcs invasores e proteja os cidadãos.",
        classObjectives = {
            guerreiro = {
                title = "Guardiões dos Portões",
                description = "Proteja os portões da cidade contra a aríete orc.",
            },
            arqueiro = {
                title = "Tiro nas Torres",
                description = "Elimine arqueiros orcs posicionados nas torres distantes.",
            },
            mago = {
                title = "Suporte Explosivo",
                description = "Use feitiços de cura e explosão para conter grandes grupos de inimigos.",
            },
        },
        universal = {
            title = "Invasão Rechaçada",
            description = "Una os esforços para repelir a invasão orc e garantir a segurança da cidade.",
        },
    },
    reward = {
        experience = 250,
        gold = 120,
        classRewards = {
            guerreiro = {
                items = {
                    gatekeeper_halberd = 1,
                },
            },
            arqueiro = {
                items = {
                    volley_quiver = 1,
                },
            },
            mago = {
                items = {
                    stormcall_focus = 1,
                },
            },
        },
    },
}

return quest

