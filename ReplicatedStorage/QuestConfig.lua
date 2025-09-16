local QuestConfig = {
    slay_goblins = {
        id = "slay_goblins",
        name = "Varredura Goblin",
        description = "Derrote 5 goblins nas planícies para proteger a vila.",
        objective = {
            type = "kill",
            target = "Goblin",
            count = 5,
        },
        reward = {
            experience = 120,
            gold = 40,
            items = {
                potion_small = 2,
            },
        },
    },
    gather_herbs = {
        id = "gather_herbs",
        name = "Suprimentos de Ervas",
        description = "Colete 3 ervas medicinais para o alquimista da cidade.",
        objective = {
            type = "collect",
            target = "Herb",
            count = 3,
        },
        reward = {
            experience = 80,
            gold = 25,
        },
    },
}

local function loadQuestModule(moduleScript)
    local success, questDefinition = pcall(require, moduleScript)
    if not success then
        warn(string.format("Falha ao carregar missão %s: %s", moduleScript:GetFullName(), questDefinition))
        return
    end

    if type(questDefinition) ~= "table" or not questDefinition.id then
        warn(string.format("Módulo de missão inválido em %s", moduleScript:GetFullName()))
        return
    end

    QuestConfig[questDefinition.id] = questDefinition
end

local function loadQuestFolder(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("ModuleScript") then
            loadQuestModule(child)
        elseif child:IsA("Folder") then
            loadQuestFolder(child)
        end
    end
end

local questsFolder = script.Parent:FindFirstChild("quests")
if questsFolder then
    loadQuestFolder(questsFolder)
end

return QuestConfig

