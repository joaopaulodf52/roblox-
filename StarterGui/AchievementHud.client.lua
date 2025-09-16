local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local AchievementHudController = require(script.Parent:WaitForChild("AchievementHudController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local controller = AchievementHudController.new(Remotes.AchievementUpdated, Remotes.AchievementLeaderboardRequest, playerGui)

script.Destroying:Connect(function()
    controller:Destroy()
end)
