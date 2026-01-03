-- ============================================
-- MOB TOWER MANAGER - Storage Library
-- Gestion du tri et des inventaires
-- ============================================

local utils = require("mobTower.lib.utils")
local peripherals = require("mobTower.lib.peripherals")

local storage = {}

-- Cache local
local sortingRules = {}
local collectorChest = nil
local stats = {
    session = {
        startTime = 0,
        mobsKilled = 0,
        itemsCollected = 0,
        raresFound = 0,
        lastMobCount = 0
    },
    total = {
        mobsKilled = 0,
        itemsCollected = 0,
        raresFound = 0,
        totalTime = 0
    },
    hourly = {},
    rareItems = {}
}

local DATA_FILE = "mobTower/data/stats.dat"

-- ============================================
-- INITIALISATION
-- ============================================

function storage.init(config)
    collectorChest = config.storage.collectorChest
    sortingRules = config.storage.sortingRules or {}
    
    -- Charger les stats sauvegardées
    storage.loadStats()
    
    -- Initialiser la session
    stats.session.startTime = os.epoch("utc") / 1000
    stats.session.mobsKilled = 0
    stats.session.itemsCollected = 0
    stats.session.raresFound = 0
    stats.session.lastMobCount = 0
    
    utils.log("Storage initialisé avec " .. #sortingRules .. " règles de tri")
end

-- ============================================
-- STATISTIQUES
-- ============================================

function storage.loadStats()
    local loaded = utils.loadTable(DATA_FILE)
    if loaded then
        stats.total = loaded.total or stats.total
        stats.hourly = loaded.hourly or {}
        stats.rareItems = loaded.rareItems or {}
        utils.log("Stats chargées: " .. stats.total.mobsKilled .. " mobs total")
    end
end

function storage.saveStats()
    local toSave = {
        total = stats.total,
        hourly = stats.hourly,
        rareItems = stats.rareItems,
        lastSave = os.epoch("utc") / 1000
    }
    utils.saveTable(DATA_FILE, toSave)
end

function storage.getStats()
    return stats
end

function storage.getSessionTime()
    if stats.session.startTime == 0 then return 0 end
    return (os.epoch("utc") / 1000) - stats.session.startTime
end

function storage.resetSession()
    -- Ajouter le temps de session au total
    stats.total.totalTime = stats.total.totalTime + storage.getSessionTime()
    
    -- Reset session
    stats.session.startTime = os.epoch("utc") / 1000
    stats.session.mobsKilled = 0
    stats.session.itemsCollected = 0
    stats.session.raresFound = 0
    stats.session.lastMobCount = 0
    
    storage.saveStats()
end

function storage.resetAll()
    stats = {
        session = {
            startTime = os.epoch("utc") / 1000,
            mobsKilled = 0,
            itemsCollected = 0,
            raresFound = 0,
            lastMobCount = 0
        },
        total = {
            mobsKilled = 0,
            itemsCollected = 0,
            raresFound = 0,
            totalTime = 0
        },
        hourly = {},
        rareItems = {}
    }
    storage.saveStats()
end

-- Enregistrer une heure de production
function storage.recordHourlyStats()
    local currentHour = os.date("%Y-%m-%d-%H")
    
    if not stats.hourly[currentHour] then
        stats.hourly[currentHour] = {
            mobs = 0,
            items = 0
        }
    end
    
    -- Nettoyer les anciennes entrées (garder 24h)
    local cutoff = os.epoch("utc") / 1000 - (24 * 3600)
    local toRemove = {}
    
    for hour, _ in pairs(stats.hourly) do
        -- Parser l'heure
        local y, m, d, h = hour:match("(%d+)-(%d+)-(%d+)-(%d+)")
        if y then
            local timestamp = os.time({
                year = tonumber(y),
                month = tonumber(m),
                day = tonumber(d),
                hour = tonumber(h)
            })
            if timestamp < cutoff then
                table.insert(toRemove, hour)
            end
        end
    end
    
    for _, hour in ipairs(toRemove) do
        stats.hourly[hour] = nil
    end
end

-- Obtenir les données horaires pour le graphique
function storage.getHourlyData(hours)
    hours = hours or 12
    local data = {}
    local now = os.epoch("utc") / 1000
    
    for i = hours - 1, 0, -1 do
        local timestamp = now - (i * 3600)
        local hourKey = os.date("%Y-%m-%d-%H", timestamp)
        local hourData = stats.hourly[hourKey]
        
        table.insert(data, {
            hour = os.date("%H:00", timestamp),
            mobs = hourData and hourData.mobs or 0,
            items = hourData and hourData.items or 0
        })
    end
    
    return data
end

-- Incrémenter le compteur de mobs tués
function storage.addKill(count)
    count = count or 1
    stats.session.mobsKilled = stats.session.mobsKilled + count
    stats.total.mobsKilled = stats.total.mobsKilled + count
    
    -- Ajouter aux stats horaires
    local currentHour = os.date("%Y-%m-%d-%H")
    if not stats.hourly[currentHour] then
        stats.hourly[currentHour] = { mobs = 0, items = 0 }
    end
    stats.hourly[currentHour].mobs = stats.hourly[currentHour].mobs + count
end

-- Incrémenter le compteur d'items
function storage.addItems(count)
    count = count or 1
    stats.session.itemsCollected = stats.session.itemsCollected + count
    stats.total.itemsCollected = stats.total.itemsCollected + count
    
    -- Ajouter aux stats horaires
    local currentHour = os.date("%Y-%m-%d-%H")
    if not stats.hourly[currentHour] then
        stats.hourly[currentHour] = { mobs = 0, items = 0 }
    end
    stats.hourly[currentHour].items = stats.hourly[currentHour].items + count
end

-- Enregistrer un item rare
function storage.addRareItem(itemName, count)
    count = count or 1
    stats.session.raresFound = stats.session.raresFound + count
    stats.total.raresFound = stats.total.raresFound + count
    
    -- Ajouter à la liste des items rares
    table.insert(stats.rareItems, 1, {
        name = itemName,
        count = count,
        time = os.epoch("utc") / 1000
    })
    
    -- Garder seulement les 50 derniers
    while #stats.rareItems > 50 do
        table.remove(stats.rareItems)
    end
end

-- Obtenir les derniers items rares
function storage.getRecentRares(count)
    count = count or 5
    local result = {}
    
    for i = 1, math.min(count, #stats.rareItems) do
        table.insert(result, stats.rareItems[i])
    end
    
    return result
end

-- ============================================
-- TRI DES ITEMS
-- ============================================

-- Trouver le baril destination pour un item
function storage.findDestination(itemName)
    -- Chercher une règle exacte
    for _, rule in ipairs(sortingRules) do
        if rule.pattern then
            -- Règle avec pattern
            if string.find(itemName, rule.itemId) then
                return rule.barrel
            end
        else
            -- Règle exacte
            if itemName == rule.itemId then
                return rule.barrel
            end
        end
    end
    
    return nil
end

-- Trier un slot du coffre collecteur
function storage.sortSlot(slot, item)
    if not collectorChest then return false, "No collector chest" end
    
    local destination = storage.findDestination(item.name)
    if not destination then
        return false, "No destination for " .. item.name
    end
    
    local transferred = peripherals.transferItems(collectorChest, slot, destination, item.count)
    
    if transferred > 0 then
        storage.addItems(transferred)
        
        -- Vérifier si item rare
        if utils.isRareItem(item.name, item.nbt) then
            storage.addRareItem(item.name, transferred)
            return true, "rare", transferred
        end
        
        return true, "sorted", transferred
    end
    
    return false, "Transfer failed"
end

-- Trier tout le coffre collecteur
function storage.sortAll()
    if not collectorChest then 
        return { sorted = 0, failed = 0, rares = {} }
    end
    
    local contents = peripherals.getInventoryContents(collectorChest)
    if not contents then 
        return { sorted = 0, failed = 0, rares = {} }
    end
    
    local result = {
        sorted = 0,
        failed = 0,
        rares = {}
    }
    
    for slot, item in pairs(contents) do
        local success, status, count = storage.sortSlot(slot, item)
        
        if success then
            result.sorted = result.sorted + (count or item.count)
            if status == "rare" then
                table.insert(result.rares, {
                    name = item.name,
                    count = count or item.count
                })
            end
        else
            result.failed = result.failed + 1
        end
    end
    
    return result
end

-- ============================================
-- SURVEILLANCE STOCKAGE
-- ============================================

-- Obtenir l'état de tous les barils
function storage.getStorageStatus()
    local status = {
        total = {
            capacity = 0,
            used = 0,
            percent = 0
        },
        barrels = {},
        warnings = {}
    }
    
    for _, rule in ipairs(sortingRules) do
        local percent = peripherals.getFillPercent(rule.barrel)
        
        status.total.capacity = status.total.capacity + 100
        status.total.used = status.total.used + percent
        
        local barrelStatus = {
            name = rule.barrel,
            itemId = rule.itemId,
            itemName = utils.getShortName(rule.itemId),
            percent = percent
        }
        
        table.insert(status.barrels, barrelStatus)
        
        -- Warnings
        if percent >= 100 then
            table.insert(status.warnings, {
                level = "critical",
                barrel = rule.barrel,
                item = utils.getShortName(rule.itemId),
                percent = percent
            })
        elseif percent >= 80 then
            table.insert(status.warnings, {
                level = "warning",
                barrel = rule.barrel,
                item = utils.getShortName(rule.itemId),
                percent = percent
            })
        end
    end
    
    if status.total.capacity > 0 then
        status.total.percent = math.floor(status.total.used / status.total.capacity * 100)
    end
    
    return status
end

-- ============================================
-- DETECTION MOBS TUES
-- ============================================

-- Mettre à jour le compteur de mobs (appelé depuis la boucle principale)
function storage.updateMobCount(currentCount)
    local lastCount = stats.session.lastMobCount
    
    -- Si le nombre a diminué, des mobs ont été tués
    if lastCount > currentCount then
        local killed = lastCount - currentCount
        storage.addKill(killed)
    end
    
    stats.session.lastMobCount = currentCount
end

-- ============================================
-- CONFIGURATION
-- ============================================

function storage.setSortingRules(rules)
    sortingRules = rules
end

function storage.getSortingRules()
    return sortingRules
end

function storage.setCollectorChest(chest)
    collectorChest = chest
end

function storage.getCollectorChest()
    return collectorChest
end

return storage
