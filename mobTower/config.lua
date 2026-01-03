-- ============================================
-- MOB TOWER MANAGER v1.1 - Configuration
-- Version 1.21 NeoForge
-- ============================================

local config = {
    version = "1.1",
    
    player = {
        name = "MikeChausette",
        detectionRange = 16
    },
    
    peripherals = {
        playerDetector = nil,
        monitor = nil
    },
    
    redstone = {
        side = "back",
        inverted = false
    },
    
    storage = {
        collectorChest = nil,
        sortingRules = {}
    },
    
    display = {
        refreshRate = 1,
        graphHours = 12,
        rareItemsCount = 5,
        alertDuration = 5
    },
    
    sorting = {
        interval = 5,
        enabled = true
    },
    
    alerts = {
        warningThreshold = 80,
        criticalThreshold = 95
    },
    
    initialState = {
        spawnOn = true
    },
    
    setupComplete = false
}

return config
