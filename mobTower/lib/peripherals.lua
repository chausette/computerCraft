-- ============================================
-- MOB TOWER MANAGER v1.1 - Peripherals Library
-- Gestion des périphériques pour 1.21 NeoForge
-- ============================================

-- Charger utils
local utils = dofile("/mobTower/lib/utils.lua")

local peripherals = {}

-- Cache des périphériques
local cache = {
    playerDetector = nil,
    monitor = nil
}

-- Configuration redstone
local redstoneConfig = {
    side = "back",
    inverted = false
}

-- Initialiser les périphériques depuis la config
function peripherals.init(config)
    -- Player Detector (Advanced Peripherals)
    if config.peripherals.playerDetector then
        cache.playerDetector = peripheral.wrap(config.peripherals.playerDetector)
        if cache.playerDetector then
            utils.log("Player Detector connecte: " .. config.peripherals.playerDetector)
        end
    end
    
    -- Monitor
    if config.peripherals.monitor then
        cache.monitor = peripheral.wrap(config.peripherals.monitor)
        if cache.monitor then
            cache.monitor.setTextScale(0.5)
            utils.log("Monitor connecte: " .. config.peripherals.monitor)
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
        other = {}
    }
    
    for _, name in ipairs(all) do
        local pType = peripheral.getType(name)
        
        if pType == "playerDetector" then
            table.insert(result.playerDetectors, { name = name, type = pType })
        elseif pType == "monitor" then
            table.insert(result.monitors, { name = name, type = pType })
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
-- PLAYER DETECTOR FUNCTIONS
-- ============================================

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

function peripherals.getInventoryContents(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return nil end
    
    local success, items = pcall(function()
        return inv.list()
    end)
    
    if not success then return nil end
    return items
end

function peripherals.getItemDetail(invName, slot)
    local inv = peripheral.wrap(invName)
    if not inv then return nil end
    
    local success, item = pcall(function()
        return inv.getItemDetail(slot)
    end)
    
    if not success then return nil end
    return item
end

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
-- REDSTONE FUNCTIONS (CC:Tweaked natif)
-- ============================================

function peripherals.setSpawnOff()
    local signal = not redstoneConfig.inverted
    redstone.setOutput(redstoneConfig.side, signal)
    return true
end

function peripherals.setSpawnOn()
    local signal = redstoneConfig.inverted
    redstone.setOutput(redstoneConfig.side, signal)
    return true
end

function peripherals.toggleSpawn(currentState)
    if currentState then
        peripherals.setSpawnOff()
        return true, false
    else
        peripherals.setSpawnOn()
        return true, true
    end
end

function peripherals.getSpawnState()
    local output = redstone.getOutput(redstoneConfig.side)
    if redstoneConfig.inverted then
        return output
    else
        return not output
    end
end

function peripherals.setRedstoneSide(side)
    redstoneConfig.side = side
end

function peripherals.setRedstoneInverted(inverted)
    redstoneConfig.inverted = inverted
end

-- ============================================
-- MONITOR FUNCTIONS
-- ============================================

function peripherals.getMonitor()
    return cache.monitor
end

function peripherals.getMonitorSize()
    if not cache.monitor then return 0, 0 end
    return cache.monitor.getSize()
end

return peripherals
