local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder

if RunService:IsServer() then
    RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not RemotesFolder then
        RemotesFolder = Instance.new("Folder")
        RemotesFolder.Name = "Remotes"
        RemotesFolder.Parent = ReplicatedStorage
    end
else
    RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
end

local function resolveRemote(remoteType, name)
    if RunService:IsServer() then
        local remote = RemotesFolder:FindFirstChild(name)
        if not remote then
            remote = Instance.new(remoteType)
            remote.Name = name
            remote.Parent = RemotesFolder
        end
        return remote
    end

    return RemotesFolder:WaitForChild(name)
end

local Remotes = {
    StatsUpdated = resolveRemote("RemoteEvent", "StatsUpdated"),
    InventoryUpdated = resolveRemote("RemoteEvent", "InventoryUpdated"),
    QuestUpdated = resolveRemote("RemoteEvent", "QuestUpdated"),
    CombatNotification = resolveRemote("RemoteEvent", "CombatNotification"),
    CombatRequest = resolveRemote("RemoteEvent", "CombatRequest"),
    SkillRequest = resolveRemote("RemoteEvent", "SkillRequest"),
    InventoryRequest = resolveRemote("RemoteEvent", "InventoryRequest"),
}

return Remotes

