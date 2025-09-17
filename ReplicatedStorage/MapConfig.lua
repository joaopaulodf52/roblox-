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
            observation_spire = CFrame.new(102, 10, 18),
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

    royal_castle = {
        name = "Castelo Real",
        assetName = "RoyalCastle",
        defaultSpawn = "courtyard",
        spawns = {
            courtyard = CFrame.new(0, 6, -80),
            grand_hall = CFrame.new(0, 12, 20),
            dungeon_cells = CFrame.new(0, 8, 86),
        },
        travel = {
            minLevel = 45,
            allowedSpawns = { "courtyard", "grand_hall", "dungeon_cells" },
            spawnRequirements = {
                grand_hall = {
                    minLevel = 49,
                },
                dungeon_cells = {
                    minLevel = 51,
                },
            },
        },
    },

    ancient_forest = {
        name = "Floresta Ancestral Corrompida",
        assetName = "AncientForest",
        defaultSpawn = "forest_edge",
        spawns = {
            forest_edge = CFrame.new(0, 6, -120),
            ritual_glade = CFrame.new(0, 7, 0),
            corrupted_heart = CFrame.new(0, 8, 96),
        },
        travel = {
            minLevel = 50,
            allowedSpawns = { "forest_edge", "ritual_glade", "corrupted_heart" },
            spawnRequirements = {
                ritual_glade = {
                    minLevel = 55,
                },
                corrupted_heart = {
                    minLevel = 57,
                },
            },
        },
    },

    sky_tower = {
        name = "Torre dos Céus",
        assetName = "SkyTower",
        defaultSpawn = "tower_base",
        spawns = {
            tower_base = CFrame.new(0, 6, 0),
            mid_spire = CFrame.new(0, 62, 0),
            apex_platform = CFrame.new(0, 102, 0),
        },
        travel = {
            minLevel = 56,
            allowedSpawns = { "tower_base", "mid_spire", "apex_platform" },
            spawnRequirements = {
                mid_spire = {
                    minLevel = 60,
                },
                apex_platform = {
                    minLevel = 62,
                },
            },
        },
    },

    sieged_city = {
        name = "Cidade Sitiada",
        assetName = "SiegedCity",
        defaultSpawn = "front_gate",
        spawns = {
            front_gate = CFrame.new(0, 8, -120),
            battlement_wall = CFrame.new(70, 14, -20),
            inner_courtyard = CFrame.new(0, 6, 40),
        },
        travel = {
            minLevel = 62,
            allowedSpawns = { "front_gate", "battlement_wall", "inner_courtyard" },
            spawnRequirements = {
                battlement_wall = {
                    minLevel = 66,
                },
                inner_courtyard = {
                    minLevel = 68,
                },
            },
        },
    },

    shadow_dragon_lair = {
        name = "Covil do Dragão Sombrio",
        assetName = "ShadowDragonLair",
        defaultSpawn = "lair_entrance",
        spawns = {
            lair_entrance = CFrame.new(0, 6, 140),
            lava_pit = CFrame.new(0, 4, 0),
            hoard_vault = CFrame.new(0, 10, -140),
        },
        travel = {
            minLevel = 68,
            allowedSpawns = { "lair_entrance", "lava_pit", "hoard_vault" },
            spawnRequirements = {
                lava_pit = {
                    minLevel = 72,
                },
                hoard_vault = {
                    minLevel = 74,
                },
            },
        },
    },

    legendary_forge = {
        name = "Forja Lendária",
        assetName = "LegendaryForge",
        defaultSpawn = "entrance_chamber",
        spawns = {
            entrance_chamber = CFrame.new(0, 6, -120),
            forge_heart = CFrame.new(0, 12, 0),
            summit_balcony = CFrame.new(80, 16, 0),
        },
        travel = {
            minLevel = 74,
            allowedSpawns = { "entrance_chamber", "forge_heart", "summit_balcony" },
            spawnRequirements = {
                forge_heart = {
                    minLevel = 78,
                },
                summit_balcony = {
                    minLevel = 80,
                },
            },
        },
    },

    dark_lord_sanctum = {
        name = "Santuário do Lorde Sombrio",
        assetName = "DarkLordSanctum",
        defaultSpawn = "outer_ring",
        spawns = {
            outer_ring = CFrame.new(0, 6, -120),
            throne_dais = CFrame.new(0, 14, 80),
            shadow_overlook = CFrame.new(100, 10, 0),
        },
        travel = {
            minLevel = 80,
            allowedSpawns = { "outer_ring", "throne_dais", "shadow_overlook" },
            spawnRequirements = {
                throne_dais = {
                    minLevel = 84,
                },
                shadow_overlook = {
                    minLevel = 86,
                },
            },
        },
    },
}

return MapConfig
