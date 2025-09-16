local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local player = Players.LocalPlayer

local function applyLanguageAttribute()
    local language = player:GetAttribute("Language")
    if typeof(language) == "string" then
        Localization.setLanguage(language)
    end
end

if typeof(player:GetAttribute("Language")) ~= "string" then
    player:SetAttribute("Language", Localization.getCurrentLanguage())
else
    applyLanguageAttribute()
end

player:GetAttributeChangedSignal("Language"):Connect(applyLanguageAttribute)
