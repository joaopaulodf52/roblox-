local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage:WaitForChild("TestEZ"))
local TestBootstrap = TestEZ.TestBootstrap
local TextReporter = TestEZ.Reporters.TextReporter

local serverFolder = script.Parent:WaitForChild("server")
local results = TestBootstrap:run({ serverFolder }, TextReporter)

if results.failureCount > 0 then
    error(string.format("Falha na suíte de testes: %d falhas", results.failureCount))
end
