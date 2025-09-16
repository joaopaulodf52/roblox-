local Localization = {}

Localization.languages = {
    ["pt"] = {
        stats = "Estatísticas",
        inventory = "Inventário",
        quests = "Missões",
        activeQuests = "Missões ativas:",
        noActive = "(nenhuma)",
        completedQuests = "Missões concluídas:",
        level = "Nível",
        xp = "XP",
        health = "Vida",
        mana = "Mana",
        attack = "Ataque",
        defense = "Defesa",
        gold = "Ouro",
        capacity = "Capacidade",
        items = "Itens",
        equipped = "Equipados",
        none = "(nenhum)",
        lastCombat = "Último combate:",
        waiting = "aguardando..."
    },
    ["en"] = {
        stats = "Stats",
        inventory = "Inventory",
        quests = "Quests",
        activeQuests = "Active quests:",
        noActive = "(none)",
        completedQuests = "Completed quests:",
        level = "Level",
        xp = "XP",
        health = "Health",
        mana = "Mana",
        attack = "Attack",
        defense = "Defense",
        gold = "Gold",
        capacity = "Capacity",
        items = "Items",
        equipped = "Equipped",
        none = "(none)",
        lastCombat = "Last combat:",
        waiting = "waiting..."
    },
}

Localization.currentLanguage = "pt"

function Localization.setLanguage(lang)
    if Localization.languages[lang] then
        Localization.currentLanguage = lang
    end
end

function Localization.get(key)
    local langTable = Localization.languages[Localization.currentLanguage]
    return (langTable and langTable[key]) or key
end

return Localization
