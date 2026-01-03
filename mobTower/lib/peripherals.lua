-- ============================================
-- MOB TOWER MANAGER - Peripherals Library
-- Gestion des périphériques Tom's Peripherals
-- ============================================

local utils = require("mobTower.lib.utils")

local peripherals = {}

-- Cache des périphériques
local cache = {
    entitySensorTop = nil,
    entitySensorBottom = nil,
    inventoryManager = nil,
    redstoneIntegrator = nil,
    monitor = nil,
    inventories = {}
}

-- Initialiser les périphériques depuis la config
function peripherals.init(config)
    -- Entity Sensor Haut (darkroom)
    if config.peripherals.entitySensorTop then
        cache.entitySensorTop = peripheral.wrap(config.peripherals.entitySensorTop)
        if cache.entitySensorTop then
            utils.log("Entity Sensor Top connecté: " .. config.peripherals.entitySensorTop)
        end
    end
    
    -- Entity Sensor Bas (zone kill)
    if config.peripherals.entitySensorBottom then
        cache.entitySensorBottom = peripheral.wrap(config.peripherals.entitySensorBottom)
        if cache.entitySensorBottom then
            utils.log("Entity Sensor Bottom connecté: " .. config.peripherals.entitySensorBottom)
        end
    end
    
    -- Inventory Manager
    if config.peripherals.inventoryManager then
        cache.inventoryManager = peripheral.wrap(config.peripherals.inventoryManager)
        if cache.inventoryManager then
            utils.log("Inventory Manager connecté: " .. config.peripherals.inventoryManager)
        end
    end
    
    -- Redstone Integrator
    if config.peripherals.redstoneIntegrator then
        cache.redstoneIntegrator = peripheral.wrap(config.peripherals.redstoneIntegrator)
        if cache.redstoneIntegrator then
            utils.log("Redstone Integrator connecté: " .. config.peripherals.redstoneIntegrator)
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
    
    return peripherals.checkAll()
end

-- Vérifier tous les périphériques
function peripherals.checkAll()
    local status = {
        entitySensorTop = cache.entitySensorTop ~= nil,
        entitySensorBottom = cache.entitySensorBottom ~= nil,
        inventoryManager = cache.inventoryManager ~= nil,
        redstoneIntegrator = cache.redstoneIntegrator ~= nil,
        monitor = cache.monitor ~= nil
    }
    return status
end

-- Lister tous les périphériques disponibles
function peripherals.listAll()
    local all = peripheral.getNames()
    local result = {
        entitySensors = {},
        inventoryManagers = {},
        redstoneIntegrators = {},
        monitors = {},
        inventories = {},
        other = {}
    }
    
    for _, name in ipairs(all) do
        local pType = peripheral.getType(name)
        
        if pType == "entityDetector" or pType == "entity_sensor" or string.find(name, "entity") then
            table.insert(result.entitySensors, { name = name, type = pType })
        elseif pType == "inventoryManager" or pType == "inventory_manager" or string.find(name, "inventory") then
            table.insert(result.inventoryManagers, { name = name, type = pType })
        elseif pType == "redstoneIntegrator" or pType == "redstone_integrator" or string.find(name, "redstone") then
            table.insert(result.redstoneIntegrators, { name = name, type = pType })
        elseif pType == "monitor" then
            table.insert(result.monitors, { name = name, type = pType })
        elseif pType == "minecraft:chest" or pType == "minecraft:barrel" or 
               pType == "minecraft:trapped_chest" or string.find(pType or "", "chest") or
               string.find(pType or "", "barrel") or string.find(name, "chest") or 
               string.find(name, "barrel") then
            table.insert(result.inventories, { name = name, type = pType })
        else
            table.insert(result.other, { name = name, type = pType })
        end
    end
    
    return result
end

-- ============================================
-- ENTITY SENSOR FUNCTIONS
-- ============================================

-- Obtenir les mobs dans la zone du sensor haut
function peripherals.getMobsTop(range)
    if not cache.entitySensorTop then return {} end
    range = range or 8
    
    local success, entities = pcall(function()
        return cache.entitySensorTop.sense()
    end)
    
    if not success then return {} end
    
    local mobs = {}
    for _, entity in ipairs(entities or {}) do
        if entity.name and entity.name ~= "item" and entity.name ~= "experience_orb" then
            -- Filtrer les joueurs
            if not string.find(entity.name:lower(), "player") then
                table.insert(mobs, entity)
            end
        end
    end
    
    return mobs
end

-- Obtenir les mobs dans la zone kill
function peripherals.getMobsBottom(range)
    if not cache.entitySensorBottom then return {} end
    range = range or 8
    
    local success, entities = pcall(function()
        return cache.entitySensorBottom.sense()
    end)
    
    if not success then return {} end
    
    local mobs = {}
    for _, entity in ipairs(entities or {}) do
        if entity.name and entity.name ~= "item" and entity.name ~= "experience_orb" then
            if not string.find(entity.name:lower(), "player") then
                table.insert(mobs, entity)
            end
        end
    end
    
    return mobs
end

-- Vérifier si le joueur est présent dans la zone kill
function peripherals.isPlayerPresent(playerName)
    if not cache.entitySensorBottom then return false end
    
    local success, entities = pcall(function()
        return cache.entitySensorBottom.sense()
    end)
    
    if not success then return false end
    
    for _, entity in ipairs(entities or {}) do
        if entity.name == playerName or entity.displayName == playerName then
            return true
        end
    end
    
    return false
end

-- ============================================
-- INVENTORY MANAGER FUNCTIONS
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
                local size = inv.size()
                table.insert(inventories, {
                    name = name,
                    type = pType,
                    size = size
                })
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

-- ============================================
-- REDSTONE INTEGRATOR FUNCTIONS
-- ============================================

-- Allumer les lampes (désactiver le spawn)
function peripherals.setSpawnOff(side, color)
    if not cache.redstoneIntegrator then return false end
    
    local success = pcall(function()
        local current = cache.redstoneIntegrator.getBundledOutput(side) or 0
        cache.redstoneIntegrator.setBundledOutput(side, colors.combine(current, color))
    end)
    
    return success
end

-- Éteindre les lampes (activer le spawn)
function peripherals.setSpawnOn(side, color)
    if not cache.redstoneIntegrator then return false end
    
    local success = pcall(function()
        local current = cache.redstoneIntegrator.getBundledOutput(side) or 0
        cache.redstoneIntegrator.setBundledOutput(side, colors.subtract(current, color))
    end)
    
    return success
end

-- Toggle spawn
function peripherals.toggleSpawn(side, color, currentState)
    if currentState then
        return peripherals.setSpawnOff(side, color), false
    else
        return peripherals.setSpawnOn(side, color), true
    end
end

-- Obtenir l'état actuel du spawn
function peripherals.getSpawnState(side, color)
    if not cache.redstoneIntegrator then return true end
    
    local success, result = pcall(function()
        local current = cache.redstoneIntegrator.getBundledOutput(side) or 0
        return not colors.test(current, color)
    end)
    
    if not success then return true end
    return result
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

return peripherals
