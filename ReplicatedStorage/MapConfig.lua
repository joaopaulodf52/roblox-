local MapConfig = {
    defaultMap = "starter_village",

    starter_village = {
        name = "Vila Inicial",
        assetName = "StarterVillage",
        defaultSpawn = "plaza",
        spawns = {
            plaza = CFrame.new(0, 5, 0),
            blacksmith = CFrame.new(24, 5, -16),
        },
        travel = {
            minLevel = 1,
            allowedSpawns = { "plaza", "blacksmith" },
        },
    },

    crystal_cavern = {
        name = "Caverna de Cristal",
        assetName = "CrystalCavern",
        defaultSpawn = "entrance",
        spawns = {
            entrance = CFrame.new(-12, 6, 32),
            sanctuary = CFrame.new(18, 10, -40),
        },
        travel = {
            minLevel = 5,
            allowedSpawns = { "entrance", "sanctuary" },
            spawnRequirements = {
                sanctuary = {
                    minLevel = 10,
                },
            },
        },
    },

    desert_outpost = {
        name = "Posto do Deserto",
        assetName = "DesertOutpost",
        defaultSpawn = "camp",
        spawns = {
            camp = CFrame.new(64, 4, -28),
            watchtower = CFrame.new(92, 12, 14),
        },
        travel = {
            minLevel = 12,
            allowedSpawns = { "camp", "watchtower" },
            spawnRequirements = {
                watchtower = {
                    minLevel = 18,
                },
            },
        },
    },

    frozen_tundra = {
        name = "Tundra Congelada",
        assetName = "FrozenTundra",
        defaultSpawn = "encampment",
        spawns = {
            encampment = CFrame.new(-80, 6, -120),
            glacier = CFrame.new(-132, 14, -86),
            ridge = CFrame.new(-98, 20, -164),
        },
        travel = {
            minLevel = 20,
            allowedSpawns = { "encampment", "glacier", "ridge" },
            spawnRequirements = {
                glacier = {
                    minLevel = 24,
                },
                ridge = {
                    minLevel = 28,
                },
            },
        },
    },
}

return MapConfig
