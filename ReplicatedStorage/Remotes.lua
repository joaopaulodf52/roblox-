local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
    RemotesFolder = Instance.new("Folder")
    RemotesFolder.Name = "Remotes"
    RemotesFolder.Parent = ReplicatedStorage
end

local function getOrCreate(remoteType, name)
    local remote = RemotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new(remoteType)
        remote.Name = name
        remote.Parent = RemotesFolder
    end
    return remote
end

local Remotes = {
    StatsUpdated = getOrCreate("RemoteEvent", "StatsUpdated"),
    InventoryUpdated = getOrCreate("RemoteEvent", "InventoryUpdated"),
    QuestUpdated = getOrCreate("RemoteEvent", "QuestUpdated"),
    CombatNotification = getOrCreate("RemoteEvent", "CombatNotification"),
    CombatRequest = getOrCreate("RemoteEvent", "CombatRequest"),
    InventoryRequest = getOrCreate("RemoteEvent", "InventoryRequest"),
}

return Remotes

