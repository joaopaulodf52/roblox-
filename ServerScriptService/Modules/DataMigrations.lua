local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

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
end

function DataMigrations.Register()
    if registered then
        return
    end

    registerMigrations()
    registered = true
end

return DataMigrations

