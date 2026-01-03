-- ============================================
-- MOB TOWER MANAGER v1.1 - Configuration
-- Version 1.21 NeoForge
-- ============================================

local config = {
    -- Version de la config
    version = "1.1",
    
    -- Informations utilisateur
    player = {
        name = "MikeChausette",
        -- Distance de détection du Player Detector
        detectionRange = 16
    },
    
    -- Périphériques (noms sur le réseau)
    peripherals = {
        -- Player Detector (Advanced Peripherals)
        playerDetector = nil,
        
        -- Moniteur 3x2
        monitor = nil
    },
    
    -- Configuration redstone (lampes)
    -- Utilise la sortie redstone directe du computer
    redstone = {
        -- Côté de sortie redstone
        -- Options: top, bottom, left, right, front, back
        side = "back",
        
        -- Inverser le signal
        -- false = signal OFF quand spawn ON (lampes éteintes)
        -- true = signal ON quand spawn ON (lampes allumées)
        inverted = false
    },
    
    -- Configuration stockage
    storage = {
        -- Nom du coffre collecteur sur le réseau
        collectorChest = nil,
        
        -- Règles de tri: { itemId = "minecraft:...", barrel = "nom_baril", pattern = false }
        sortingRules = {}
    },
    
    -- Paramètres d'affichage
    display = {
        -- Intervalle de rafraîchissement (secondes)
        refreshRate = 1,
        
        -- Nombre d'heures dans le graphique
        graphHours = 12,
        
        -- Nombre d'items rares à afficher
        rareItemsCount = 5,
        
        -- Durée de l'alerte item rare (secondes)
        alertDuration = 5
    },
    
    -- Paramètres de tri
    sorting = {
        -- Intervalle de tri automatique (secondes)
        interval = 5,
        
        -- Activer le tri automatique
        enabled = true
    },
    
    -- Seuils d'alerte stockage
    alerts = {
        -- Pourcentage pour alerte warning
        warningThreshold = 80,
        
        -- Pourcentage pour alerte critique
        criticalThreshold = 95
    },
    
    -- État initial
    initialState = {
        -- Spawn activé au démarrage
        spawnOn = true
    },
    
    -- Premier lancement effectué
    setupComplete = false
}

return config
