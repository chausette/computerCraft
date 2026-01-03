-- ============================================
-- MOB TOWER MANAGER - Configuration
-- Fichier de configuration utilisateur
-- ============================================

local config = {
    -- Version de la config
    version = "1.0",
    
    -- Informations utilisateur
    player = {
        name = "MikeChausette"
    },
    
    -- Périphériques (noms sur le réseau)
    peripherals = {
        -- Entity Sensor dans la darkroom (haut)
        entitySensorTop = nil,
        
        -- Entity Sensor dans la zone de kill (bas)
        entitySensorBottom = nil,
        
        -- Inventory Manager pour le tri
        inventoryManager = nil,
        
        -- Redstone Integrator pour les lampes
        redstoneIntegrator = nil,
        
        -- Moniteur 3x2
        monitor = nil
    },
    
    -- Configuration redstone (lampes)
    redstone = {
        -- Côté du bundled cable sur le Redstone Integrator
        side = "back",
        
        -- Couleur du câble pour les lampes
        -- Options: white, orange, magenta, lightBlue, yellow, lime,
        --          pink, gray, lightGray, cyan, purple, blue,
        --          brown, green, red, black
        color = "white"
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
