local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))

local function resolveDefaultMapId()
    local candidate = MapConfig.defaultMap
    if typeof(candidate) == "string" and MapConfig[candidate] then
        return candidate
    end

    for key, value in pairs(MapConfig) do
        if type(value) == "table" and value.assetName then
            return key
        end
    end

    return nil
end

local DEFAULT_MAP_ID = resolveDefaultMapId()
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
end

function DataMigrations.Register()
    if registered then
        return
    end

    registerMigrations()
    registered = true
end

return DataMigrations

