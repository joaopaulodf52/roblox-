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

    volcanic_crater = {
        name = "Cratera Vulcânica",
        assetName = "VolcanicCrater",
        defaultSpawn = "entrance",
        spawns = {
            entrance = CFrame.new(0, 9, 72),
            central_chamber = CFrame.new(0, 10, 0),
            observation_spire = CFrame.new(96, 10, 18),
        },
        travel = {
            minLevel = 26,
            allowedSpawns = { "entrance", "central_chamber", "observation_spire" },
            spawnRequirements = {
                central_chamber = {
                    minLevel = 32,
                },
                observation_spire = {
                    minLevel = 34,
                },
            },
        },
    },

    champion_arena = {
        name = "Arena dos Campeões",
        assetName = "ChampionArena",
        defaultSpawn = "arrival_gate",
        spawns = {
            arrival_gate = CFrame.new(0, 10, -80),
            contender_ring = CFrame.new(0, 10, 0),
            champion_podium = CFrame.new(0, 12, 80),
        },
        travel = {
            minLevel = 40,
            allowedSpawns = { "arrival_gate", "contender_ring", "champion_podium" },
            spawnRequirements = {
                contender_ring = {
                    minLevel = 44,
                },
                champion_podium = {
                    minLevel = 48,
                },
            },
        },
    },
}

return MapConfig
