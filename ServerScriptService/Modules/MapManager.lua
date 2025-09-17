local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapConfig = require(ReplicatedStorage:WaitForChild("MapConfig"))
local MapUtils = require(script.Parent.MapUtils)

local DEFAULT_MAP_ID = MapUtils.getDefaultMapId(MapConfig)
assert(DEFAULT_MAP_ID, "MapConfig deve definir ao menos um mapa válido")

local MapManager = {
    _mapsFolder = nil,
    currentMapModel = nil,
    currentMapId = nil,
    playerConnections = {},
    playerSpawns = {},
}

local function getMapsFolder()
    if MapManager._mapsFolder and MapManager._mapsFolder.Parent then
        return MapManager._mapsFolder
    end

    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if not assets then
        error("Pasta de assets não encontrada em ReplicatedStorage")
    end

    local maps = assets:FindFirstChild("Maps")
    if not maps then
        error("Pasta de mapas não encontrada em ReplicatedStorage.Assets")
    end

    MapManager._mapsFolder = maps
    return maps
end

local function getMapConfig(mapId)
    local config = MapConfig[mapId]
    if type(config) ~= "table" then
        error(string.format("Configuração do mapa '%s' não encontrada", tostring(mapId)))
    end
    return config
end

local function resolveSpawn(mapId, spawnId)
    local config = getMapConfig(mapId)
    local spawns = config.spawns

    if type(spawns) ~= "table" then
        error(string.format("Mapa '%s' não possui spawns configurados", tostring(mapId)))
    end

    if spawnId and typeof(spawns[spawnId]) == "CFrame" then
        return spawns[spawnId], spawnId
    end

    if config.defaultSpawn and typeof(spawns[config.defaultSpawn]) == "CFrame" then
        return spawns[config.defaultSpawn], config.defaultSpawn
    end

    if typeof(spawns.default) == "CFrame" then
        return spawns.default, "default"
    end

    for key, value in pairs(spawns) do
        if typeof(value) == "CFrame" then
            return value, key
        end
    end

    error(string.format("Mapa '%s' não possui pontos de spawn válidos", tostring(mapId)))
end

local function applySpawnToCharacter(player, character)
    local spawnData = MapManager.playerSpawns[player]
    if not spawnData then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        rootPart = character:WaitForChild("HumanoidRootPart", 5)
    end

    if rootPart then
        rootPart.CFrame = spawnData.cframe
    else
        warn(string.format("Personagem de %s não possui HumanoidRootPart para spawn", player.Name))
    end
end

function MapManager:GetCurrentMapId()
    return self.currentMapId
end

function MapManager:GetCurrentMap()
    return self.currentMapModel
end

function MapManager:GetMapsFolder()
    return getMapsFolder()
end

function MapManager:GetSpawnCFrame(mapId, spawnId)
    local cframe = select(1, resolveSpawn(mapId, spawnId))
    return cframe
end

function MapManager:ResolveSpawn(mapId, spawnId)
    local targetMapId = mapId or self.currentMapId or DEFAULT_MAP_ID
    local cframe, resolvedSpawn = resolveSpawn(targetMapId, spawnId)
    return cframe, resolvedSpawn
end

function MapManager:GetPlayerMap(player)
    local spawnData = self.playerSpawns[player]
    return spawnData and spawnData.mapId or nil
end

function MapManager:Load(mapId)
    local config = getMapConfig(mapId)
    local maps = getMapsFolder()

    local asset = maps:FindFirstChild(config.assetName)
    if not asset then
        error(string.format("Asset do mapa '%s' não encontrado em ReplicatedStorage.Assets.Maps", config.assetName))
    end

    if not asset:IsA("Model") then
        error(string.format("Asset '%s' não é um Model válido", config.assetName))
    end

    local clone = asset:Clone()
    clone.Name = config.assetName
    clone.Parent = Workspace

    if self.currentMapModel then
        self.currentMapModel:Destroy()
    end

    self.currentMapModel = clone
    self.currentMapId = mapId

    return clone
end

function MapManager:EnsureLoaded(mapId)
    local targetMapId = mapId or self.currentMapId or DEFAULT_MAP_ID
    if not targetMapId then
        error("Nenhum mapa padrão configurado")
    end

    if self.currentMapId ~= targetMapId or not self.currentMapModel or self.currentMapModel.Parent ~= Workspace then
        return self:Load(targetMapId)
    end

    return self.currentMapModel
end

function MapManager:SpawnPlayer(player, mapId, spawnId)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        error("MapManager:SpawnPlayer requer um Player válido")
    end

    local targetMapId = mapId or self.currentMapId or DEFAULT_MAP_ID
    local mapModel = self:EnsureLoaded(targetMapId)
    local spawnCFrame, resolvedSpawn = self:ResolveSpawn(targetMapId, spawnId)

    local existingConnection = self.playerConnections[player]
    if existingConnection then
        existingConnection:Disconnect()
    end

    self.playerSpawns[player] = {
        mapId = targetMapId,
        spawnName = resolvedSpawn,
        cframe = spawnCFrame,
    }

    self.playerConnections[player] = player.CharacterAdded:Connect(function(character)
        applySpawnToCharacter(player, character)
    end)

    if player.Character then
        applySpawnToCharacter(player, player.Character)
    end

    return mapModel, spawnCFrame
end

function MapManager:UnbindPlayer(player)
    local connection = self.playerConnections[player]
    if connection then
        connection:Disconnect()
        self.playerConnections[player] = nil
    end

    self.playerSpawns[player] = nil
end

function MapManager:Unload()
    local trackedPlayers = {}
    for player in pairs(self.playerConnections) do
        table.insert(trackedPlayers, player)
    end

    for _, trackedPlayer in ipairs(trackedPlayers) do
        self:UnbindPlayer(trackedPlayer)
    end

    if self.currentMapModel then
        self.currentMapModel:Destroy()
        self.currentMapModel = nil
    end

    self.currentMapId = nil
end

return MapManager
