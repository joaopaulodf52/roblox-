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
    },

    crystal_cavern = {
        name = "Caverna de Cristal",
        assetName = "CrystalCavern",
        defaultSpawn = "entrance",
        spawns = {
            entrance = CFrame.new(-12, 6, 32),
            sanctuary = CFrame.new(18, 10, -40),
        },
    },
}

return MapConfig
