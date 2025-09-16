local ItemsConfig = {
    sword_iron = {
        id = "sword_iron",
        name = "Espada de Ferro",
        type = "equipment",
        slot = "weapon",
        description = "Uma espada resistente feita de ferro polido.",
        attributes = {
            attack = 15,
        },
    },
    armor_leather = {
        id = "armor_leather",
        name = "Armadura de Couro",
        type = "equipment",
        slot = "armor",
        description = "Proteção leve feita com couro reforçado.",
        attributes = {
            defense = 10,
        },
    },
    potion_small = {
        id = "potion_small",
        name = "Poção de Cura Pequena",
        type = "consumable",
        description = "Restaura uma pequena quantidade de vida quando utilizada.",
        effects = {
            health = 35,
        },
    },
    tome_apprentice = {
        id = "tome_apprentice",
        name = "Tomo do Aprendiz",
        type = "consumable",
        description = "Concede experiência adicional quando lido.",
        effects = {
            experience = 50,
        },
    },
    training_blade = {
        id = "training_blade",
        name = "Lâmina de Treinamento",
        type = "equipment",
        slot = "weapon",
        description = "Uma espada leve usada para ensinar fundamentos aos guerreiros.",
        attributes = {
            attack = 5,
        },
    },
    training_quiver = {
        id = "training_quiver",
        name = "Aljava de Treinamento",
        type = "material",
        description = "Conjunto de flechas simples para praticar mira e postura.",
    },
    training_grimoire = {
        id = "training_grimoire",
        name = "Grimório do Noviço",
        type = "consumable",
        description = "Um tomo com feitiços básicos que aumenta o domínio arcano.",
        effects = {
            experience = 25,
        },
    },
    light_shield = {
        id = "light_shield",
        name = "Escudo Leve",
        type = "equipment",
        slot = "offhand",
        description = "Escudo prático utilizado para proteger carregamentos pesados.",
        attributes = {
            defense = 4,
        },
    },
    hunters_arrows = {
        id = "hunters_arrows",
        name = "Flechas do Caçador",
        type = "material",
        description = "Flechas reforçadas ideais para espantar aves e pequenas criaturas.",
    },
    growth_components = {
        id = "growth_components",
        name = "Componentes de Crescimento",
        type = "material",
        description = "Ingredientes mágicos capazes de acelerar o crescimento das plantas.",
    },
    guardian_blade = {
        id = "guardian_blade",
        name = "Lâmina do Guardião",
        type = "equipment",
        slot = "weapon",
        description = "Uma espada equilibrada concedida a quem protege segredos antigos.",
        attributes = {
            attack = 8,
        },
    },
    trail_lantern = {
        id = "trail_lantern",
        name = "Lanterna de Rastreamento",
        type = "equipment",
        slot = "trinket",
        description = "Lanterna encantada que destaca rastros escondidos na mata.",
        attributes = {
            defense = 1,
        },
    },
    rune_focus = {
        id = "rune_focus",
        name = "Foco Rúnico",
        type = "equipment",
        slot = "trinket",
        description = "Um foco arcano que amplia a estabilidade das magias.",
        attributes = {
            maxMana = 10,
        },
    },
    molten_gauntlets = {
        id = "molten_gauntlets",
        name = "Manoplas Derretidas",
        type = "equipment",
        slot = "hands",
        description = "Manoplas forjadas para resistir ao calor extremo do vulcão.",
        attributes = {
            defense = 6,
        },
    },
    ember_arrow_bundle = {
        id = "ember_arrow_bundle",
        name = "Feixe de Flechas Incandescentes",
        type = "material",
        description = "Flechas tratadas para perfurar criaturas adaptadas ao fogo.",
    },
    stability_charm = {
        id = "stability_charm",
        name = "Amuleto de Estabilidade",
        type = "equipment",
        slot = "accessory",
        description = "Amuleto usado para manter cristais instáveis sob controle.",
        attributes = {
            defense = 4,
        },
    },
    arena_plate = {
        id = "arena_plate",
        name = "Armadura da Arena",
        type = "equipment",
        slot = "armor",
        description = "Armadura pesada concedida aos campeões da arena.",
        attributes = {
            defense = 12,
        },
    },
    precision_string = {
        id = "precision_string",
        name = "Cordas de Precisão",
        type = "material",
        description = "Cordas de arco calibradas para disparos rápidos e precisos.",
    },
    dueling_tome = {
        id = "dueling_tome",
        name = "Tomo de Duelo",
        type = "consumable",
        description = "Registro de feitiços usado pelos duelistas da arena.",
        effects = {
            experience = 80,
        },
    },
    foragers_belt = {
        id = "foragers_belt",
        name = "Cinto do Coletor",
        type = "equipment",
        slot = "belt",
        description = "Cinto reforçado que ajuda a transportar ingredientes raros.",
        attributes = {
            defense = 3,
        },
    },
    tracker_calls = {
        id = "tracker_calls",
        name = "Apito do Rastreador",
        type = "material",
        description = "Apito que atrai criaturas raras encontradas pelo arqueiro.",
    },
    alchemical_gloves = {
        id = "alchemical_gloves",
        name = "Luvas Alquímicas",
        type = "equipment",
        slot = "hands",
        description = "Luvas encantadas que protegem o usuário durante misturas complexas.",
        attributes = {
            maxMana = 10,
        },
    },
    interrogation_badge = {
        id = "interrogation_badge",
        name = "Distintivo de Interrogador",
        type = "equipment",
        slot = "accessory",
        description = "Símbolo de autoridade usado para conduzir interrogatórios no castelo.",
        attributes = {
            defense = 3,
        },
    },
    shadow_boots = {
        id = "shadow_boots",
        name = "Botas das Sombras",
        type = "equipment",
        slot = "boots",
        description = "Botas leves que silenciam passos durante perseguições.",
        attributes = {
            defense = 4,
        },
    },
    divination_orb = {
        id = "divination_orb",
        name = "Orbe de Adivinhação",
        type = "equipment",
        slot = "trinket",
        description = "Orbe que auxilia magos a detectar resquícios mágicos.",
        attributes = {
            maxMana = 15,
        },
    },
    warding_hammer = {
        id = "warding_hammer",
        name = "Martelo Guardião",
        type = "equipment",
        slot = "weapon",
        description = "Martelo pesado capaz de destruir totens amaldiçoados.",
        attributes = {
            attack = 12,
        },
    },
    purging_arrows = {
        id = "purging_arrows",
        name = "Flechas Purificantes",
        type = "material",
        description = "Flechas imbuidas de magia para purificar criaturas corrompidas.",
    },
    blooming_staff = {
        id = "blooming_staff",
        name = "Cajado Florescente",
        type = "equipment",
        slot = "weapon",
        description = "Cajado que canaliza energia vital para restaurar a floresta.",
        attributes = {
            attack = 6,
            maxMana = 10,
        },
    },
    skybreaker_plate = {
        id = "skybreaker_plate",
        name = "Couraça Quebra-Céus",
        type = "equipment",
        slot = "armor",
        description = "Armadura projetada para suportar pressões das alturas.",
        attributes = {
            defense = 14,
        },
    },
    mechanism_kit = {
        id = "mechanism_kit",
        name = "Kit de Mecanismos",
        type = "material",
        description = "Ferramentas precisas usadas para ativar mecanismos suspensos.",
    },
    celestial_codex = {
        id = "celestial_codex",
        name = "Códice Celestial",
        type = "consumable",
        description = "Um tomo estrelado que amplia a reserva de mana ao ser estudado.",
        effects = {
            mana = 50,
        },
    },
    dragonscale_shield = {
        id = "dragonscale_shield",
        name = "Escudo de Escama de Dragão",
        type = "equipment",
        slot = "offhand",
        description = "Escudo imponente forjado com escamas do dragão sombrio.",
        attributes = {
            defense = 18,
        },
    },
    dragonbane_arrows = {
        id = "dragonbane_arrows",
        name = "Flechas Mata-Dragão",
        type = "material",
        description = "Flechas projetadas para perfurar a blindagem das criaturas dracônicas.",
    },
    protective_barrier_scroll = {
        id = "protective_barrier_scroll",
        name = "Pergaminho de Barreira Protetora",
        type = "consumable",
        description = "Pergaminho que ensina a erguer barreiras mágicas poderosas.",
        effects = {
            mana = 35,
        },
    },
    gatekeeper_halberd = {
        id = "gatekeeper_halberd",
        name = "Alabarda do Guardião",
        type = "equipment",
        slot = "weapon",
        description = "Arma usada pelos guardas responsáveis por proteger os portões da cidade.",
        attributes = {
            attack = 16,
        },
    },
    volley_quiver = {
        id = "volley_quiver",
        name = "Aljava de Rajada",
        type = "material",
        description = "Aljava preparada para disparar múltiplas flechas em sequência.",
    },
    stormcall_focus = {
        id = "stormcall_focus",
        name = "Foco Chamado da Tempestade",
        type = "equipment",
        slot = "trinket",
        description = "Artefato que auxilia magos a canalizar energia explosiva em campo.",
        attributes = {
            maxMana = 20,
        },
    },
    legendary_blade = {
        id = "legendary_blade",
        name = "Espada Lendária",
        type = "equipment",
        slot = "weapon",
        description = "A lendária lâmina destinada ao golpe final contra o tirano.",
        attributes = {
            attack = 22,
        },
    },
    forja_compass = {
        id = "forja_compass",
        name = "Bússola da Forja",
        type = "material",
        description = "Bússola encantada que aponta para a forja perdida.",
    },
    ritual_catalyst = {
        id = "ritual_catalyst",
        name = "Catalisador Ritualístico",
        type = "consumable",
        description = "Concentrado mágico utilizado para rituais complexos.",
        effects = {
            experience = 120,
        },
    },
    royal_guard_plate = {
        id = "royal_guard_plate",
        name = "Armadura do Guardião Real",
        type = "equipment",
        slot = "armor",
        description = "Armadura resistente concedida a quem defende o trono restaurado.",
        attributes = {
            defense = 20,
        },
    },
    royal_arrowheads = {
        id = "royal_arrowheads",
        name = "Pontas Reais",
        type = "material",
        description = "Pontas de flecha forjadas com precisão para acertar pontos críticos.",
    },
    crown_sigil_cloak = {
        id = "crown_sigil_cloak",
        name = "Manto do Selo Real",
        type = "equipment",
        slot = "cloak",
        description = "Manto cerimonial que amplia a proteção mágica do portador.",
        attributes = {
            defense = 5,
            maxMana = 25,
        },
    },
    maca_vermelha = {
        id = "maca_vermelha",
        name = "Maçã Vermelha",
        type = "material",
        description = "Fruta fresca colhida para o fazendeiro da vila.",
    },
    fragmento_mapa_central = {
        id = "fragmento_mapa_central",
        name = "Fragmento de Mapa Central",
        type = "material",
        description = "Uma das peças do mapa antigo que revela o caminho adiante.",
    },
    cristal_vulcanico = {
        id = "cristal_vulcanico",
        name = "Cristal Vulcânico",
        type = "material",
        description = "Cristal raro coletado nas profundezas do vulcão.",
    },
    essencia_alquimica = {
        id = "essencia_alquimica",
        name = "Essência Alquímica",
        type = "material",
        description = "Componentes raros necessários para misturar poções poderosas.",
    },
}

return ItemsConfig

