local ShopConfig = {
    general_store = {
        id = "general_store",
        name = "Armazém do Vilarejo",
        description = "Suprimentos básicos para aventureiros iniciantes.",
        currency = "gold",
        items = {
            {
                itemId = "potion_small",
                price = 15,
                quantity = 1,
                maxQuantity = 5,
            },
            {
                itemId = "training_blade",
                price = 40,
                quantity = 1,
                requirements = {
                    minLevel = 1,
                },
            },
            {
                itemId = "light_shield",
                price = 55,
                quantity = 1,
                requirements = {
                    minLevel = 2,
                },
            },
            {
                itemId = "hunters_arrows",
                price = 20,
                quantity = 5,
                requirements = {
                    classes = { "arqueiro" },
                },
            },
        },
    },
    arcane_repository = {
        id = "arcane_repository",
        name = "Acervo Arcano",
        description = "Equipamentos especializados mantidos pelos sábios da guilda.",
        currency = "gold",
        items = {
            {
                itemId = "sword_iron",
                price = 120,
                quantity = 1,
                requirements = {
                    minLevel = 3,
                    classes = { "guerreiro" },
                },
            },
            {
                itemId = "training_grimoire",
                price = 65,
                quantity = 1,
                requirements = {
                    classes = { "mago" },
                },
            },
            {
                itemId = "trail_lantern",
                price = 80,
                quantity = 1,
                requirements = {
                    minLevel = 2,
                },
            },
            {
                itemId = "scout_longbow",
                price = 220,
                quantity = 1,
                requirements = {
                    minLevel = 4,
                    classes = { "arqueiro" },
                },
            },
            {
                itemId = "guardian_greaves",
                price = 360,
                quantity = 1,
                requirements = {
                    minLevel = 5,
                    classes = { "guerreiro" },
                },
            },
        },
    },
}

return ShopConfig

