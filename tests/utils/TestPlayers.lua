local Players = game:GetService("Players")

local TestPlayers = {}
local nextId = 1000

local function ensurePlayerName(userId, name)
    if name then
        return name
    end
    return string.format("TestPlayer_%d", userId)
end

function TestPlayers.create(name)
    nextId += 1
    local player = Instance.new("Player")
    player.UserId = nextId
    player.Name = ensurePlayerName(player.UserId, name)
    player.Parent = Players
    return player
end

function TestPlayers.destroy(player)
    if player and player.Parent then
        player:Destroy()
    end
end

return TestPlayers
