local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))
local AchievementConfig = require(ReplicatedStorage:WaitForChild("AchievementConfig"))
local MapUtils = require(script.Parent.MapUtils)
local DEFAULT_MAP_ID = MapUtils.getDefaultMapId(MapConfig)
assert(DEFAULT_MAP_ID, "MapConfig deve definir ao menos um mapa válido")

local DataMigrations = {}
local registered = false

local function ensureSchemaContainer(state)
    state.schemas = state.schemas or {}
    return state.schemas
end

local function registerMigrations()
    DataStoreManager:RegisterMigration({
        id = "20240501_profile_schema_v1",
        order = 1,
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            if schemas.profile and schemas.profile.version and schemas.profile.version >= 1 then
                return
            end

            schemas.profile = {
                version = 1,
                fields = {
                    "stats",
                    "inventory",
                    "quests",
                },
                stats = {
                    version = 1,
                    defaults = GameConfig.DefaultStats,
                },
            }
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240502_inventory_categories",
        order = 2,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}
            profile.inventory = profile.inventory or {}
            profile.inventory.version = 2
            profile.inventory.categories = {
                "equipment",
                "consumable",
                "quest",
            }
            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240503_quests_tracking",
        order = 3,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}
            profile.quests = profile.quests or {}
            profile.quests.version = 1
            profile.quests.states = {
                "active",
                "completed",
            }
            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240504_player_map_state",
        order = 4,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}

            local stats = profile.stats or {}
            stats.defaults = stats.defaults or {}

            if typeof(stats.defaults.currentMap) ~= "string" or not MapConfig[stats.defaults.currentMap] then
                stats.defaults.currentMap = DEFAULT_MAP_ID
            end

            profile.stats = stats

            local currentMap = profile.currentMap
            if typeof(currentMap) ~= "string" or not MapConfig[currentMap] then
                profile.currentMap = DEFAULT_MAP_ID
            end

            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240505_profile_skills_structure",
        order = 5,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}
            local skills = profile.skills or {}

            if typeof(skills.version) == "number" and skills.version >= 1 then
                profile.skills = skills
                schemas.profile = profile
                return
            end

            skills.version = 1
            skills.fields = {
                "unlocked",
                "hotbar",
            }

            profile.skills = skills
            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240506_profile_crafting_structure",
        order = 6,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}
            local crafting = profile.crafting or {}

            if typeof(crafting.version) == "number" and crafting.version >= 1 then
                profile.crafting = crafting
                schemas.profile = profile
                return
            end

            crafting.version = 1
            crafting.fields = {
                "unlocked",
                "statistics",
            }

            local statistics = crafting.statistics or {}
            statistics.fields = statistics.fields or {
                "totalCrafted",
                "byRecipe",
            }
            statistics.totalCrafted = statistics.totalCrafted or 0
            statistics.byRecipe = statistics.byRecipe or {}

            crafting.statistics = statistics

            profile.crafting = crafting
            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240507_profile_achievements_structure",
        order = 7,
        dependencies = { "20240501_profile_schema_v1" },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local profile = schemas.profile or {}
            local achievements = profile.achievements or {}

            if typeof(achievements.version) ~= "number" or achievements.version < 1 then
                achievements.version = 1
            end

            achievements.fields = achievements.fields or {
                "unlocked",
                "progress",
                "counters",
            }

            local counters = achievements.counters or {}
            counters.fields = counters.fields or {
                "experience",
                "kills",
            }

            counters.experience = counters.experience or 0

            local kills = counters.kills or {}
            kills.fields = kills.fields or {
                "total",
                "byType",
            }
            kills.total = kills.total or 0
            kills.byType = kills.byType or {}

            counters.kills = kills
            achievements.counters = counters

            profile.achievements = achievements
            schemas.profile = profile
        end,
    })

    DataStoreManager:RegisterMigration({
        id = "20240508_achievements_leaderboard_schema",
        order = 8,
        dependencies = {
            "20240507_profile_achievements_structure",
        },
        run = function(state)
            local schemas = ensureSchemaContainer(state)
            local leaderboards = schemas.leaderboards or {}
            local achievementsBoard = leaderboards.achievements or {}

            if typeof(achievementsBoard.version) ~= "number" or achievementsBoard.version < 1 then
                achievementsBoard.version = 1
            end

            achievementsBoard.fields = achievementsBoard.fields or {
                "storeName",
                "maxEntries",
            }

            local leaderboardSettings = AchievementConfig.leaderboard or {}
            achievementsBoard.storeName = achievementsBoard.storeName or leaderboardSettings.storeName or "RPG_ACHIEVEMENTS_LEADERBOARD"
            achievementsBoard.maxEntries = achievementsBoard.maxEntries or leaderboardSettings.maxEntries or 50

            leaderboards.achievements = achievementsBoard
            schemas.leaderboards = leaderboards
        end,
    })
end

function DataMigrations.Register()
    if registered then
        return
    end

    registerMigrations()
    registered = true
end

return DataMigrations

