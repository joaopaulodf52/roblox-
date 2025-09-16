local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage:WaitForChild("TestEZ"))
local TestBootstrap = TestEZ.TestBootstrap
local TextReporter = TestEZ.Reporters.TextReporter

local serverFolder = script.Parent:WaitForChild("server")
local testContainers = { serverFolder }

local clientFolder = script.Parent:FindFirstChild("client")
if clientFolder then
    table.insert(testContainers, clientFolder)
end

local results = TestBootstrap:run(testContainers, TextReporter)

if results.failureCount > 0 then
    error(string.format("Falha na suíte de testes: %d falhas", results.failureCount))
end
