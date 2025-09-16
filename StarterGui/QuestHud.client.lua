local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local QuestHudController = require(script.Parent:WaitForChild("QuestHudController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local controller = QuestHudController.new(Remotes.QuestUpdated, playerGui)

script.Destroying:Connect(function()
    controller:Destroy()
end)

