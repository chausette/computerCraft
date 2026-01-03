-- ============================================
-- MOB TOWER MANAGER v1.1 - Peripherals Library
-- Gestion des périphériques pour 1.21 NeoForge
-- Utilise: Advanced Peripherals + CC:Tweaked
-- ============================================

local utils = require("mobTower.lib.utils")

local peripherals = {}

-- Cache des périphériques
local cache = {
    playerDetector = nil,
    monitor = nil,
    inventories = {}
}

-- Configuration redstone
local redstoneConfig = {
    side = "back",
    inverted = false  -- true = signal ON éteint les lampes
}

-- Initialiser les périphériques depuis la config
function peripherals.init(config)
    -- Player Detector (Advanced Peripherals)
    if config.peripherals.playerDetector then
        cache.playerDetector = peripheral.wrap(config.peripherals.playerDetector)
        if cache.playerDetector then
            utils.log("Player Detector connecté: " .. config.peripherals.playerDetector)
        end
    end
    
    -- Monitor
    if config.peripherals.monitor then
        cache.monitor = peripheral.wrap(config.peripherals.monitor)
        if cache.monitor then
            cache.monitor.setTextScale(0.5)
            utils.log("Monitor connecté: " .. config.peripherals.monitor)
        end
    end
    
    -- Configuration redstone
    if config.redstone then
        redstoneConfig.side = config.redstone.side or "back"
        redstoneConfig.inverted = config.redstone.inverted or false
    end
    
    return peripherals.checkAll()
end

-- Vérifier tous les périphériques
function peripherals.checkAll()
    local status = {
        playerDetector = cache.playerDetector ~= nil,
        monitor = cache.monitor ~= nil
    }
    return status
end

-- Lister tous les périphériques disponibles
function peripherals.listAll()
    local all = peripheral.getNames()
    local result = {
        playerDetectors = {},
        monitors = {},
        inventories = {},
        redstoneRelays = {},
        other = {}
    }
    
    for _, name in ipairs(all) do
        local pType = peripheral.getType(name)
        
        if pType == "playerDetector" or pType == "player_detector" or string.find(name, "playerDetector") then
            table.insert(result.playerDetectors, { name = name, type = pType })
        elseif pType == "monitor" then
            table.insert(result.monitors, { name = name, type = pType })
        elseif pType == "redstone_relay" then
            table.insert(result.redstoneRelays, { name = name, type = pType })
        elseif pType and (string.find(pType, "chest") or string.find(pType, "barrel") or
               string.find(name, "chest") or string.find(name, "barrel")) then
            local inv = peripheral.wrap(name)
            if inv and inv.size then
                local success, size = pcall(function() return inv.size() end)
                if success then
                    table.insert(result.inventories, {
                        name = name,
                        type = pType,
                        size = size
                    })
                end
            end
        else
            table.insert(result.other, { name = name, type = pType })
        end
    end
    
    return result
end

-- ============================================
-- PLAYER DETECTOR FUNCTIONS (Advanced Peripherals)
-- ============================================

-- Vérifier si le joueur est dans la zone
function peripherals.isPlayerPresent(playerName, range)
    if not cache.playerDetector then return false end
    range = range or 16
    
    local success, players = pcall(function()
        return cache.playerDetector.getPlayersInRange(range)
    end)
    
    if not success or not players then return false end
    
    for _, player in ipairs(players) do
        if player == playerName then
            return true
        end
    end
    
    return false
end

-- Obtenir la position du joueur
function peripherals.getPlayerPos(playerName)
    if not cache.playerDetector then return nil end
    
    local success, pos = pcall(function()
        return cache.playerDetector.getPlayerPos(playerName)
    end)
    
    if not success then return nil end
    return pos
end

-- Obtenir tous les joueurs en ligne
function peripherals.getOnlinePlayers()
    if not cache.playerDetector then return {} end
    
    local success, players = pcall(function()
        return cache.playerDetector.getOnlinePlayers()
    end)
    
    if not success then return {} end
    return players or {}
end

-- ============================================
-- INVENTORY FUNCTIONS (CC:Tweaked natif)
-- ============================================

-- Lister tous les inventaires du réseau
function peripherals.listInventories()
    local all = peripheral.getNames()
    local inventories = {}
    
    for _, name in ipairs(all) do
        local pType = peripheral.getType(name)
        if pType and (string.find(pType, "chest") or string.find(pType, "barrel") or
           string.find(name, "chest") or string.find(name, "barrel")) then
            local inv = peripheral.wrap(name)
            if inv and inv.size then
                local success, size = pcall(function() return inv.size() end)
                if success then
                    table.insert(inventories, {
                        name = name,
                        type = pType,
                        size = size
                    })
                end
            end
        end
    end
    
    return inventories
end

-- Obtenir le contenu d'un inventaire
function peripherals.getInventoryContents(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return nil end
    
    local success, items = pcall(function()
        return inv.list()
    end)
    
    if not success then return nil end
    return items
end

-- Obtenir les détails d'un item
function peripherals.getItemDetail(invName, slot)
    local inv = peripheral.wrap(invName)
    if not inv then return nil end
    
    local success, item = pcall(function()
        return inv.getItemDetail(slot)
    end)
    
    if not success then return nil end
    return item
end

-- Transférer des items entre inventaires
function peripherals.transferItems(fromInv, fromSlot, toInv, count, toSlot)
    local source = peripheral.wrap(fromInv)
    if not source then return 0 end
    
    local success, transferred = pcall(function()
        if toSlot then
            return source.pushItems(toInv, fromSlot, count, toSlot)
        else
            return source.pushItems(toInv, fromSlot, count)
        end
    end)
    
    if not success then return 0 end
    return transferred or 0
end

-- Obtenir l'espace libre dans un inventaire
function peripherals.getFreeSpace(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return 0 end
    
    local success, size = pcall(function()
        return inv.size()
    end)
    
    if not success then return 0 end
    
    local items = peripherals.getInventoryContents(invName)
    if not items then return size end
    
    local used = 0
    for _ in pairs(items) do
        used = used + 1
    end
    
    return size - used
end

-- Obtenir le pourcentage de remplissage
function peripherals.getFillPercent(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return 0 end
    
    local success, size = pcall(function()
        return inv.size()
    end)
    
    if not success or size == 0 then return 0 end
    
    local items = peripherals.getInventoryContents(invName)
    if not items then return 0 end
    
    local used = 0
    for _ in pairs(items) do
        used = used + 1
    end
    
    return math.floor((used / size) * 100)
end

-- Compter le nombre total d'items dans un inventaire
function peripherals.countTotalItems(invName)
    local items = peripherals.getInventoryContents(invName)
    if not items then return 0 end
    
    local total = 0
    for _, item in pairs(items) do
        total = total + (item.count or 1)
    end
    
    return total
end

-- ============================================
-- REDSTONE FUNCTIONS (CC:Tweaked natif)
-- ============================================

-- Allumer les lampes (désactiver le spawn)
function peripherals.setSpawnOff()
    local signal = not redstoneConfig.inverted
    redstone.setOutput(redstoneConfig.side, signal)
    return true
end

-- Éteindre les lampes (activer le spawn)
function peripherals.setSpawnOn()
    local signal = redstoneConfig.inverted
    redstone.setOutput(redstoneConfig.side, signal)
    return true
end

-- Toggle spawn
function peripherals.toggleSpawn(currentState)
    if currentState then
        peripherals.setSpawnOff()
        return true, false  -- success, newState
    else
        peripherals.setSpawnOn()
        return true, true   -- success, newState
    end
end

-- Obtenir l'état actuel du spawn
function peripherals.getSpawnState()
    local output = redstone.getOutput(redstoneConfig.side)
    if redstoneConfig.inverted then
        return output  -- inverted: signal ON = spawn ON
    else
        return not output  -- normal: signal OFF = spawn ON
    end
end

-- Configurer le côté redstone
function peripherals.setRedstoneSide(side)
    redstoneConfig.side = side
end

-- Configurer l'inversion
function peripherals.setRedstoneInverted(inverted)
    redstoneConfig.inverted = inverted
end

-- ============================================
-- MONITOR FUNCTIONS
-- ============================================

-- Obtenir le moniteur
function peripherals.getMonitor()
    return cache.monitor
end

-- Obtenir la taille du moniteur
function peripherals.getMonitorSize()
    if not cache.monitor then return 0, 0 end
    return cache.monitor.getSize()
end

-- ============================================
-- DIAGNOSTIC
-- ============================================

-- Tester un périphérique
function peripherals.testPeripheral(name)
    local p = peripheral.wrap(name)
    if not p then
        return false, "Cannot wrap peripheral"
    end
    
    local methods = peripheral.getMethods(name)
    return true, methods
end

-- Obtenir le cache
function peripherals.getCache()
    return cache
end

-- Obtenir la config redstone
function peripherals.getRedstoneConfig()
    return redstoneConfig
end

return peripherals
