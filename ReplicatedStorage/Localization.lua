local Localization = {}

Localization.languages = {
    ["pt"] = {
        stats = "Estatísticas",
        inventory = "Inventário",
        quests = "Missões",
        activeQuests = "Missões ativas:",
        activeQuestsTitle = "Missões Ativas",
        noActive = "(nenhuma)",
        noActiveQuests = "Nenhuma missão ativa",
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
        empty = "(vazio)",
        lastCombat = "Último combate:",
        waiting = "aguardando...",
        loading = "Carregando...",
        rewardsLabel = "Recompensas",
        rewardsPrefix = "Recompensas: %s",
        rewardsNone = "Recompensas: nenhuma",
        progressFormat = "Progresso: %d / %d (%d%%)",
        abandonQuest = "Abandonar",
        achievementsTitle = "Conquistas",
        achievementsLockedTitle = "Em Progresso",
        achievementsUnlockedTitle = "Conquistas Desbloqueadas",
        achievementsProgressFormat = "Progresso: %d / %d",
        achievementsProgressComplete = "(concluído)",
        achievementsUnlockedAtFormat = "Conquistado em %d/%m/%Y %H:%M",
        achievementsNoneInProgress = "Nenhuma conquista em andamento",
        achievementsNoneUnlocked = "Nenhuma conquista desbloqueada",
        shopTitle = "Lojas",
        shopSelectPrompt = "Selecione uma loja",
        shopDefaultName = "loja",
        shopSelectMessage = "Selecione uma loja para visualizar os itens disponíveis.",
        bundleNameFormat = "%s (Pacote x%d)",
        bundleDetails = "Pacote: %d itens",
        maxPurchase = "Máx compra: %d",
        quantityPlaceholder = "Qtd",
        buy = "Comprar",
        locked = "Bloqueado",
        shopSelectBeforeBuying = "Selecione uma loja antes de comprar.",
        invalidQuantity = "Informe uma quantidade válida.",
        quantityMinimum = "A quantidade deve ser pelo menos 1.",
        shopNoItems = "Nenhum item disponível nesta loja no momento.",
        shopShowItems = "Mostrando %d itens em %s.",
        shopRequestItems = "Solicitando itens de %s...",
        shopOpenFallbackError = "Não foi possível abrir a loja.",
        purchaseSuccessFormat = "Compra concluída: %s x%d",
        purchaseFailureFallback = "Compra não realizada.",
        currencyGoldFormat = "%d ouro",
        currencyGenericFormat = "%d %s",
        combatAttack = "%s atacou %s causando %d de dano%s",
        combatDefeatedSuffix = " (inimigo derrotado)",
        combatUsingWeapon = " usando %s",
    },
    ["en"] = {
        stats = "Stats",
        inventory = "Inventory",
        quests = "Quests",
        activeQuests = "Active quests:",
        activeQuestsTitle = "Active Quests",
        noActive = "(none)",
        noActiveQuests = "No active quests",
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
        empty = "(empty)",
        lastCombat = "Last combat:",
        waiting = "waiting...",
        loading = "Loading...",
        rewardsLabel = "Rewards",
        rewardsPrefix = "Rewards: %s",
        rewardsNone = "Rewards: none",
        progressFormat = "Progress: %d / %d (%d%%)",
        abandonQuest = "Abandon",
        achievementsTitle = "Achievements",
        achievementsLockedTitle = "In Progress",
        achievementsUnlockedTitle = "Unlocked Achievements",
        achievementsProgressFormat = "Progress: %d / %d",
        achievementsProgressComplete = "(complete)",
        achievementsUnlockedAtFormat = "Unlocked on %m/%d/%Y %H:%M",
        achievementsNoneInProgress = "No achievements in progress",
        achievementsNoneUnlocked = "No achievements unlocked",
        shopTitle = "Shops",
        shopSelectPrompt = "Select a shop",
        shopDefaultName = "shop",
        shopSelectMessage = "Select a shop to view the available items.",
        bundleNameFormat = "%s (Bundle x%d)",
        bundleDetails = "Bundle: %d items",
        maxPurchase = "Max purchase: %d",
        quantityPlaceholder = "Qty",
        buy = "Buy",
        locked = "Locked",
        shopSelectBeforeBuying = "Select a shop before purchasing.",
        invalidQuantity = "Enter a valid quantity.",
        quantityMinimum = "Quantity must be at least 1.",
        shopNoItems = "No items are available in this shop right now.",
        shopShowItems = "Showing %d items in %s.",
        shopRequestItems = "Requesting items from %s...",
        shopOpenFallbackError = "Unable to open the shop.",
        purchaseSuccessFormat = "Purchase completed: %s x%d",
        purchaseFailureFallback = "Purchase failed.",
        currencyGoldFormat = "%d gold",
        currencyGenericFormat = "%d %s",
        combatAttack = "%s attacked %s dealing %d damage%s",
        combatDefeatedSuffix = " (enemy defeated)",
        combatUsingWeapon = " using %s",
    },
}

local languageChangedEvent = Instance.new("BindableEvent")
languageChangedEvent.Name = "LocalizationLanguageChanged"

Localization.currentLanguage = "pt"

function Localization.setLanguage(lang)
    if Localization.languages[lang] and Localization.currentLanguage ~= lang then
        Localization.currentLanguage = lang
        languageChangedEvent:Fire(lang)
    end
end

function Localization.get(key)
    local langTable = Localization.languages[Localization.currentLanguage]
    return (langTable and langTable[key]) or key
end

function Localization.format(key, ...)
    local value = Localization.get(key)
    local argCount = select("#", ...)
    if argCount > 0 then
        return string.format(value, ...)
    end
    return value
end

function Localization.onLanguageChanged(callback)
    assert(type(callback) == "function", "callback must be a function")
    return languageChangedEvent.Event:Connect(callback)
end

function Localization.getCurrentLanguage()
    return Localization.currentLanguage
end

return Localization
