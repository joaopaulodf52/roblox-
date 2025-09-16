local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local function sendInventoryRequest(action, payload)
    payload = payload or {}
    payload.action = action
    Remotes.InventoryRequest:FireServer(payload)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F then
        sendInventoryRequest("equip", { itemId = "sword_iron" })
    elseif input.KeyCode == Enum.KeyCode.G then
        sendInventoryRequest("equip", { itemId = "armor_leather" })
    elseif input.KeyCode == Enum.KeyCode.H then
        sendInventoryRequest("use", { itemId = "potion_small" })
    elseif input.KeyCode == Enum.KeyCode.J then
        sendInventoryRequest("acceptQuest", { questId = "slay_goblins" })
    elseif input.KeyCode == Enum.KeyCode.B then
        sendInventoryRequest("unequip", { slot = "weapon" })
    end
end)

