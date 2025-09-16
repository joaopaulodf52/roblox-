local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStoreManager = {}

DataStoreManager._migrations = {}
DataStoreManager._migrationOrder = {}

local MIGRATION_STORE_NAME = "RPG_MIGRATIONS"
local MIGRATION_STATE_KEY = "GLOBAL_STATE"

local function isServer()
    return RunService:IsServer()
end

local function ensureTable(value)
    return typeof(value) == "table" and value or {}
end

local function deepCopy(value)
    if typeof(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function ensureMigrationStateStructure(state)
    state = ensureTable(state)
    state.version = state.version or 0
    state.applied = ensureTable(state.applied)
    state.history = ensureTable(state.history)
    return state
end

local function validateMigrationDefinition(migration)
    assert(type(migration) == "table", "Migration deve ser uma tabela")
    assert(type(migration.id) == "string" and migration.id ~= "", "Migration precisa de um id string")
    assert(type(migration.run) == "function", "Migration precisa de função run")
    if migration.dependencies ~= nil then
        assert(type(migration.dependencies) == "table", "dependencies deve ser uma tabela")
    end
    migration.dependencies = migration.dependencies or {}
    migration.order = migration.order or #DataStoreManager._migrationOrder + 1
end

local function sortMigrations()
    table.sort(DataStoreManager._migrationOrder, function(a, b)
        local migrationA = DataStoreManager._migrations[a]
        local migrationB = DataStoreManager._migrations[b]
        if migrationA.order == migrationB.order then
            return migrationA.id < migrationB.id
        end
        return migrationA.order < migrationB.order
    end)
end

local function validateDependencyGraph()
    for _, id in ipairs(DataStoreManager._migrationOrder) do
        local migration = DataStoreManager._migrations[id]
        for _, dependencyId in ipairs(migration.dependencies) do
            assert(DataStoreManager._migrations[dependencyId], string.format("Dependência %s não registrada para migration %s", dependencyId, id))
        end
    end
end

local function getMigrationStore()
    return DataStoreService:GetDataStore(MIGRATION_STORE_NAME)
end

local function loadMigrationState(migrationStore)
    local success, result = pcall(function()
        return migrationStore:GetAsync(MIGRATION_STATE_KEY)
    end)
    if not success then
        error(string.format("Falha ao carregar estado das migrations: %s", result))
    end

    if not result then
        return ensureMigrationStateStructure(nil)
    end

    return ensureMigrationStateStructure(result)
end

local function saveMigrationState(migrationStore, state)
    local attempts = 0
    local lastError

    while attempts < 5 do
        attempts += 1

        local success, result = pcall(function()
            return migrationStore:UpdateAsync(MIGRATION_STATE_KEY, function(existing)
                existing = ensureMigrationStateStructure(existing)
                existing.version = state.version
                existing.applied = deepCopy(state.applied)
                existing.history = deepCopy(state.history)
                return existing
            end)
        end)

        if success then
            return ensureMigrationStateStructure(result)
        end

        lastError = result
        if attempts < 5 then
            local backoff = 0.5 * (2 ^ (attempts - 1))
            backoff += math.random() * 0.25
            task.wait(backoff)
        end
    end

    error(string.format("Não foi possível salvar estado das migrations: %s", tostring(lastError)))
end

local function refreshState(target, source)
    target.version = source.version
    target.applied = source.applied
    target.history = source.history
    return target
end

local function updateStateFromPersistence(migrationStore, state)
    local persisted = saveMigrationState(migrationStore, state)
    return refreshState(state, persisted)
end

function DataStoreManager:RegisterMigration(migration)
    validateMigrationDefinition(migration)

    if DataStoreManager._migrations[migration.id] then
        error(string.format("Migration %s já registrada", migration.id))
    end

    DataStoreManager._migrations[migration.id] = migration
    table.insert(DataStoreManager._migrationOrder, migration.id)
    sortMigrations()
end

local function canRunMigration(state, migration)
    for _, dependencyId in ipairs(migration.dependencies) do
        if not state.applied[dependencyId] then
            return false, string.format("Dependência %s pendente", dependencyId)
        end
    end
    return true
end

local function applyMigration(migrationStore, state, migration)
    local canRun, reason = canRunMigration(state, migration)
    if not canRun then
        error(string.format("Não foi possível executar migration %s: %s", migration.id, reason))
    end

    local success, err = pcall(function()
        migration.run(state)
    end)

    if not success then
        error(string.format("Erro ao executar migration %s: %s", migration.id, err))
    end

    state.applied[migration.id] = true
    state.version = state.version + 1
    state.history[#state.history + 1] = {
        id = migration.id,
        timestamp = os.time(),
    }

    return updateStateFromPersistence(migrationStore, state)
end

function DataStoreManager:RunMigrations()
    assert(isServer(), "RunMigrations deve ser executado apenas no servidor")

    validateDependencyGraph()

    local migrationStore = getMigrationStore()
    local state = loadMigrationState(migrationStore)

    for _, migrationId in ipairs(DataStoreManager._migrationOrder) do
        if not state.applied[migrationId] then
            local migration = DataStoreManager._migrations[migrationId]
            state = applyMigration(migrationStore, state, migration)
        end
    end

    return state
end

function DataStoreManager:GetState()
    local migrationStore = getMigrationStore()
    return loadMigrationState(migrationStore)
end

return DataStoreManager

