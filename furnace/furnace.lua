-- ============================================
-- FURNACE MANAGER v2.0
-- Gestionnaire automatique de fours
-- https://github.com/chausette/computerCraft
-- ============================================

local VERSION = "2.0"
local CONFIG_FILE = "furnace_config"
local STATS_FILE = "furnace_stats"

-- Configuration par defaut
local config = {
    inputChest = nil,
    outputChest = nil,
    fuelChest = nil,
    monitor = nil,
    furnaces = {},
    blastFurnaces = {},
    smokers = {},
    smartRouting = true,
    ecoMode = true,
    minFuelLevel = 8,
    updateInterval = 2,
}

-- Variables globales
local monitor = nil
local running = true
local paused = false
local totalFuel = 0
local furnaceData = {}
local allFurnaces = {}
local alerts = {}
local stats = {
    totalCooked = 0,
    sessionCooked = 0,
    startTime = os.epoch("utc"),
    itemsPerHour = 0,
    lastHourItems = {}
}

-- Items pour le routage intelligent
local SMELTABLE_FOODS = {
    ["minecraft:beef"] = true,
    ["minecraft:porkchop"] = true,
    ["minecraft:chicken"] = true,
    ["minecraft:mutton"] = true,
    ["minecraft:rabbit"] = true,
    ["minecraft:cod"] = true,
    ["minecraft:salmon"] = true,
    ["minecraft:potato"] = true,
    ["minecraft:kelp"] = true,
}

local SMELTABLE_ORES = {
    ["minecraft:raw_iron"] = true,
    ["minecraft:raw_gold"] = true,
    ["minecraft:raw_copper"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:ancient_debris"] = true,
}

-- Temps de cuisson par type de four (en ticks, 20 ticks = 1 seconde)
local COOK_TIMES = {
    furnace = 200,      -- 10 secondes
    blast_furnace = 100, -- 5 secondes
    smoker = 100,        -- 5 secondes
}

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

local function log(message)
    local time = textutils.formatTime(os.time(), true)
    print("[" .. time .. "] " .. message)
end

local function loadConfig()
    if fs.exists(CONFIG_FILE) then
        local file = fs.open(CONFIG_FILE, "r")
        local data = textutils.unserialise(file.readAll())
        file.close()
        if data then
            for k, v in pairs(data) do
                config[k] = v
            end
            return true
        end
    end
    return false
end

local function saveConfig()
    config.stats = stats
    local file = fs.open(CONFIG_FILE, "w")
    file.write(textutils.serialise(config))
    file.close()
end

local function loadStats()
    if config.stats then
        stats.totalCooked = config.stats.totalCooked or 0
        stats.startTime = config.stats.startTime or os.epoch("utc")
    end
    stats.sessionCooked = 0
    stats.lastHourItems = {}
end

local function getItemName(item)
    if item == nil then return "Vide" end
    local name = item.name or "Inconnu"
    name = string.gsub(name, "minecraft:", "")
    name = string.gsub(name, "_", " ")
    -- Capitaliser et tronquer
    name = name:sub(1,1):upper() .. name:sub(2)
    return name
end

local function formatTime(seconds)
    if seconds < 0 then seconds = 0 end
    if seconds < 60 then
        return string.format("%ds", math.floor(seconds))
    elseif seconds < 3600 then
        return string.format("%dm%ds", math.floor(seconds / 60), math.floor(seconds % 60))
    else
        return string.format("%dh%dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function getFurnaceType(name)
    if string.find(name, "blast") then
        return "blast_furnace"
    elseif string.find(name, "smoker") then
        return "smoker"
    else
        return "furnace"
    end
end

-- ============================================
-- DETECTION DES PERIPHERIQUES
-- ============================================

local function detectPeripherals()
    log("Detection des peripheriques...")
    
    -- Moniteur
    if config.monitor then
        monitor = peripheral.wrap(config.monitor)
    end
    
    if not monitor then
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "monitor" then
                monitor = peripheral.wrap(name)
                config.monitor = name
                break
            end
        end
    end
    
    -- Construire la liste des fours
    allFurnaces = {}
    
    local function addFurnaces(list, fType)
        for _, name in ipairs(list or {}) do
            if peripheral.wrap(name) then
                table.insert(allFurnaces, {
                    name = name,
                    type = fType
                })
                furnaceData[name] = {
                    item = "Vide",
                    itemName = nil,
                    count = 0,
                    progress = 0,
                    fuel = 0,
                    cooking = false,
                    startTime = 0,
                    cookTime = COOK_TIMES[fType] / 20,
                    type = fType
                }
            end
        end
    end
    
    addFurnaces(config.furnaces, "furnace")
    addFurnaces(config.blastFurnaces, "blast_furnace")
    addFurnaces(config.smokers, "smoker")
    
    -- Si pas de config, detecter automatiquement
    if #allFurnaces == 0 then
        for _, name in ipairs(peripheral.getNames()) do
            local pType = peripheral.getType(name)
            local fType = nil
            
            if string.find(name, "blast") or string.find(pType, "blast") then
                fType = "blast_furnace"
            elseif string.find(name, "smoker") or string.find(pType, "smoker") then
                fType = "smoker"
            elseif string.find(name, "furnace") or string.find(pType, "furnace") then
                fType = "furnace"
            end
            
            if fType then
                table.insert(allFurnaces, { name = name, type = fType })
                furnaceData[name] = {
                    item = "Vide",
                    itemName = nil,
                    count = 0,
                    progress = 0,
                    fuel = 0,
                    cooking = false,
                    startTime = 0,
                    cookTime = COOK_TIMES[fType] / 20,
                    type = fType
                }
            end
        end
    end
    
    log("Detecte: " .. #allFurnaces .. " four(s)")
    
    return #allFurnaces > 0
end

-- ============================================
-- GESTION DES ALERTES
-- ============================================

local function addAlert(id, message, level)
    alerts[id] = {
        message = message,
        level = level or "warning", -- warning, error, info
        time = os.clock()
    }
end

local function removeAlert(id)
    alerts[id] = nil
end

local function checkAlerts()
    -- Alerte carburant bas
    if totalFuel < 16 then
        addAlert("fuel_low", "Carburant bas!", "error")
    elseif totalFuel < 32 then
        addAlert("fuel_low", "Carburant bas", "warning")
    else
        removeAlert("fuel_low")
    end
    
    -- Verifier coffre d'entree vide
    local inputChest = peripheral.wrap(config.inputChest)
    if inputChest then
        local hasItems = false
        for _, _ in pairs(inputChest.list()) do
            hasItems = true
            break
        end
        if not hasItems then
            addAlert("input_empty", "Coffre entree vide", "info")
        else
            removeAlert("input_empty")
        end
    end
    
    -- Verifier coffre de sortie plein
    local outputChest = peripheral.wrap(config.outputChest)
    if outputChest then
        local size = outputChest.size()
        local used = 0
        for _, _ in pairs(outputChest.list()) do
            used = used + 1
        end
        if used >= size then
            addAlert("output_full", "Coffre sortie plein!", "error")
        elseif used >= size * 0.9 then
            addAlert("output_full", "Coffre sortie presque plein", "warning")
        else
            removeAlert("output_full")
        end
    end
end

-- ============================================
-- GESTION DES FOURS
-- ============================================

local function getFurnaceStatus(furnaceName)
    local furnace = peripheral.wrap(furnaceName)
    if not furnace then return nil end
    
    local data = furnaceData[furnaceName]
    if not data then return nil end
    
    local items = furnace.list()
    local inputItem = items[1]
    local fuelItem = items[2]
    local outputItem = items[3]
    
    local oldItem = data.itemName
    local newItemName = inputItem and inputItem.name or nil
    
    -- Detecter nouveau item
    if newItemName and newItemName ~= oldItem then
        data.startTime = os.clock()
        data.cooking = true
        data.itemName = newItemName
        data.item = getItemName(inputItem)
        data.count = inputItem.count
    elseif not newItemName then
        -- Item termine
        if data.cooking and oldItem then
            stats.sessionCooked = stats.sessionCooked + 1
            stats.totalCooked = stats.totalCooked + 1
            table.insert(stats.lastHourItems, os.epoch("utc"))
        end
        data.cooking = false
        data.progress = 0
        data.itemName = nil
        data.item = "Vide"
        data.count = 0
    elseif inputItem then
        data.count = inputItem.count
    end
    
    data.fuel = fuelItem and fuelItem.count or 0
    
    -- Calculer progression et temps restant
    if data.cooking then
        local elapsed = os.clock() - data.startTime
        local cookTime = data.cookTime
        data.progress = math.min(100, math.floor((elapsed / cookTime) * 100))
        data.timeRemaining = math.max(0, cookTime - elapsed)
        
        -- Reset si item termine
        if data.progress >= 100 then
            data.startTime = os.clock()
        end
    else
        data.timeRemaining = 0
    end
    
    return data
end

local function countFuel()
    local fuelChest = peripheral.wrap(config.fuelChest)
    if not fuelChest then return 0 end
    
    local total = 0
    for _, item in pairs(fuelChest.list()) do
        if item then
            total = total + item.count
        end
    end
    return total
end

local function refuelFurnaces()
    if paused then return end
    
    local fuelChest = peripheral.wrap(config.fuelChest)
    if not fuelChest then return end
    
    for _, furnaceInfo in ipairs(allFurnaces) do
        local furnace = peripheral.wrap(furnaceInfo.name)
        if furnace then
            local items = furnace.list()
            local fuelCount = items[2] and items[2].count or 0
            local data = furnaceData[furnaceInfo.name]
            
            -- Mode economie: ne remplir que si le four a quelque chose a cuire
            local shouldRefuel = true
            if config.ecoMode then
                shouldRefuel = items[1] ~= nil or fuelCount == 0
            end
            
            if shouldRefuel and fuelCount < config.minFuelLevel then
                local needed = config.minFuelLevel - fuelCount
                for slot, item in pairs(fuelChest.list()) do
                    if item and needed > 0 then
                        local toTransfer = math.min(item.count, needed)
                        local transferred = fuelChest.pushItems(furnaceInfo.name, slot, toTransfer, 2)
                        needed = needed - transferred
                        if needed <= 0 then break end
                    end
                end
            end
        end
    end
end

local function getBestFurnace(itemName)
    if not config.smartRouting then
        -- Sans routage intelligent, trouver n'importe quel four disponible
        for _, furnaceInfo in ipairs(allFurnaces) do
            local furnace = peripheral.wrap(furnaceInfo.name)
            if furnace then
                local items = furnace.list()
                if not items[1] or (items[1].name == itemName and items[1].count < 64) then
                    return furnaceInfo.name
                end
            end
        end
        return nil
    end
    
    -- Routage intelligent
    local targetType = "furnace"
    
    if SMELTABLE_FOODS[itemName] then
        targetType = "smoker"
    elseif SMELTABLE_ORES[itemName] then
        targetType = "blast_furnace"
    end
    
    -- Chercher d'abord le type optimal
    for _, furnaceInfo in ipairs(allFurnaces) do
        if furnaceInfo.type == targetType then
            local furnace = peripheral.wrap(furnaceInfo.name)
            if furnace then
                local items = furnace.list()
                if not items[1] or (items[1].name == itemName and items[1].count < 64) then
                    return furnaceInfo.name
                end
            end
        end
    end
    
    -- Si pas de four optimal, utiliser un four normal
    for _, furnaceInfo in ipairs(allFurnaces) do
        if furnaceInfo.type == "furnace" then
            local furnace = peripheral.wrap(furnaceInfo.name)
            if furnace then
                local items = furnace.list()
                if not items[1] or (items[1].name == itemName and items[1].count < 64) then
                    return furnaceInfo.name
                end
            end
        end
    end
    
    -- Dernier recours: n'importe quel four
    for _, furnaceInfo in ipairs(allFurnaces) do
        local furnace = peripheral.wrap(furnaceInfo.name)
        if furnace then
            local items = furnace.list()
            if not items[1] or (items[1].name == itemName and items[1].count < 64) then
                return furnaceInfo.name
            end
        end
    end
    
    return nil
end

local function distributeItems()
    if paused then return end
    
    local inputChest = peripheral.wrap(config.inputChest)
    if not inputChest then return end
    
    for slot, item in pairs(inputChest.list()) do
        if item then
            local targetFurnace = getBestFurnace(item.name)
            if targetFurnace then
                local furnace = peripheral.wrap(targetFurnace)
                if furnace then
                    local furnaceItems = furnace.list()
                    local inputSlot = furnaceItems[1]
                    local toTransfer = inputSlot and (64 - inputSlot.count) or item.count
                    toTransfer = math.min(toTransfer, item.count)
                    
                    local transferred = inputChest.pushItems(targetFurnace, slot, toTransfer, 1)
                    if transferred > 0 then
                        log("-> " .. transferred .. "x " .. getItemName(item) .. " vers " .. targetFurnace)
                    end
                end
            end
        end
    end
end

local function collectOutput()
    if paused then return end
    
    local outputChest = peripheral.wrap(config.outputChest)
    if not outputChest then return end
    
    for _, furnaceInfo in ipairs(allFurnaces) do
        local furnace = peripheral.wrap(furnaceInfo.name)
        if furnace then
            local items = furnace.list()
            if items[3] then
                local transferred = furnace.pushItems(config.outputChest, 3)
                if transferred > 0 then
                    log("<- " .. transferred .. "x depuis " .. furnaceInfo.name)
                end
            end
        end
    end
end

local function calculateStats()
    -- Nettoyer les items de plus d'une heure
    local oneHourAgo = os.epoch("utc") - 3600000
    local newList = {}
    for _, timestamp in ipairs(stats.lastHourItems) do
        if timestamp > oneHourAgo then
            table.insert(newList, timestamp)
        end
    end
    stats.lastHourItems = newList
    stats.itemsPerHour = #stats.lastHourItems
end

-- ============================================
-- INTERFACE MONITEUR
-- ============================================

local function drawProgressBar(mon, x, y, width, progress)
    local filled = math.floor((progress / 100) * width)
    
    mon.setCursorPos(x, y)
    mon.setBackgroundColor(colors.lime)
    mon.write(string.rep(" ", filled))
    mon.setBackgroundColor(colors.gray)
    mon.write(string.rep(" ", width - filled))
    mon.setBackgroundColor(colors.black)
end

local function getAlertColor(level)
    if level == "error" then return colors.red
    elseif level == "warning" then return colors.orange
    else return colors.yellow end
end

local function updateMonitor()
    if not monitor then return end
    
    monitor.setTextScale(0.5)
    local w, h = monitor.getSize()
    
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    -- === HEADER ===
    monitor.setTextColor(colors.yellow)
    local title = "FURNACE MANAGER v" .. VERSION
    monitor.setCursorPos(math.floor((w - #title) / 2) + 1, 1)
    monitor.write(title)
    
    -- Indicateur pause
    if paused then
        monitor.setTextColor(colors.red)
        monitor.setCursorPos(w - 6, 1)
        monitor.write("PAUSE")
    end
    
    -- Ligne
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(1, 2)
    monitor.write(string.rep("-", w))
    
    -- === STATS GENERALES ===
    local yPos = 3
    
    -- Fours actifs
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1, yPos)
    monitor.write("Fours: ")
    monitor.setTextColor(colors.lime)
    monitor.write(tostring(#allFurnaces))
    
    -- Stock carburant
    totalFuel = countFuel()
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(w - 12, yPos)
    monitor.write("Fuel: ")
    if totalFuel > 32 then
        monitor.setTextColor(colors.lime)
    elseif totalFuel > 8 then
        monitor.setTextColor(colors.orange)
    else
        monitor.setTextColor(colors.red)
    end
    monitor.write(string.format("%3d", totalFuel))
    
    yPos = yPos + 1
    
    -- Stats production
    monitor.setTextColor(colors.white)
    monitor.setCursorPos(1, yPos)
    monitor.write("Cuits: ")
    monitor.setTextColor(colors.cyan)
    monitor.write(tostring(stats.sessionCooked))
    monitor.setTextColor(colors.gray)
    monitor.write(" (" .. tostring(stats.totalCooked) .. " total)")
    
    -- Items/heure
    monitor.setCursorPos(w - 10, yPos)
    monitor.setTextColor(colors.white)
    monitor.write(tostring(stats.itemsPerHour) .. "/h")
    
    yPos = yPos + 1
    
    -- === ALERTES ===
    local hasAlerts = false
    for _, alert in pairs(alerts) do
        hasAlerts = true
        break
    end
    
    if hasAlerts then
        monitor.setCursorPos(1, yPos)
        monitor.setTextColor(colors.gray)
        monitor.write(string.rep("-", w))
        yPos = yPos + 1
        
        local blink = math.floor(os.clock() * 2) % 2 == 0
        for id, alert in pairs(alerts) do
            if yPos < h - 2 then
                local color = getAlertColor(alert.level)
                if alert.level == "error" and not blink then
                    color = colors.black
                end
                monitor.setTextColor(color)
                monitor.setCursorPos(2, yPos)
                monitor.write("! " .. alert.message)
                yPos = yPos + 1
            end
        end
    end
    
    -- === LIGNE SEPARATION ===
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(1, yPos)
    monitor.write(string.rep("-", w))
    yPos = yPos + 1
    
    -- === ETAT DES FOURS ===
    monitor.setTextColor(colors.cyan)
    monitor.setCursorPos(1, yPos)
    monitor.write("FOURS:")
    yPos = yPos + 1
    
    for i, furnaceInfo in ipairs(allFurnaces) do
        if yPos >= h - 1 then break end
        
        local data = getFurnaceStatus(furnaceInfo.name)
        if data then
            -- Icone type
            local icon = "F"
            local iconColor = colors.orange
            if furnaceInfo.type == "blast_furnace" then
                icon = "B"
                iconColor = colors.lightBlue
            elseif furnaceInfo.type == "smoker" then
                icon = "S"
                iconColor = colors.brown
            end
            
            monitor.setCursorPos(1, yPos)
            monitor.setTextColor(iconColor)
            monitor.write(icon)
            
            -- Numero
            monitor.setTextColor(colors.white)
            monitor.write(tostring(i) .. " ")
            
            -- Item en cours
            if data.cooking then
                monitor.setTextColor(colors.yellow)
            else
                monitor.setTextColor(colors.lightGray)
            end
            
            local itemDisplay = data.item
            if data.count > 1 then
                itemDisplay = itemDisplay .. " x" .. data.count
            end
            if #itemDisplay > 14 then
                itemDisplay = itemDisplay:sub(1, 12) .. ".."
            end
            monitor.write(itemDisplay)
            
            yPos = yPos + 1
            if yPos >= h - 1 then break end
            
            -- Barre de progression + temps
            monitor.setCursorPos(3, yPos)
            if data.cooking then
                drawProgressBar(monitor, 3, yPos, 8, data.progress)
                
                monitor.setTextColor(colors.white)
                monitor.setCursorPos(12, yPos)
                monitor.write(string.format("%3d%%", data.progress))
                
                -- Temps restant
                monitor.setTextColor(colors.lightGray)
                monitor.setCursorPos(17, yPos)
                monitor.write("~" .. formatTime(data.timeRemaining))
            else
                monitor.setTextColor(colors.gray)
                monitor.write("[ Inactif ]")
            end
            
            -- Carburant du four
            monitor.setCursorPos(w - 4, yPos)
            monitor.setTextColor(colors.white)
            monitor.write("F:")
            if data.fuel > 4 then
                monitor.setTextColor(colors.lime)
            elseif data.fuel > 0 then
                monitor.setTextColor(colors.orange)
            else
                monitor.setTextColor(colors.red)
            end
            monitor.write(string.format("%2d", data.fuel))
            
            yPos = yPos + 1
        end
    end
    
    -- === FOOTER ===
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(1, h)
    monitor.write(string.rep("-", w))
    
    -- Heure
    local timeStr = textutils.formatTime(os.time(), true)
    monitor.setCursorPos(w - #timeStr, h)
    monitor.setTextColor(colors.lightGray)
    monitor.write(timeStr)
    
    -- Instructions
    monitor.setTextColor(colors.gray)
    monitor.setCursorPos(1, h)
    monitor.write("Touch: Pause")
end

-- ============================================
-- BOUCLES PRINCIPALES
-- ============================================

local function mainLoop()
    while running do
        if not paused then
            refuelFurnaces()
            distributeItems()
            collectOutput()
        end
        
        checkAlerts()
        calculateStats()
        updateMonitor()
        
        -- Sauvegarder les stats periodiquement
        if os.clock() % 60 < config.updateInterval then
            saveConfig()
        end
        
        sleep(config.updateInterval)
    end
end

local function inputLoop()
    while running do
        local event, key = os.pullEvent("key")
        if key == keys.q then
            running = false
            log("Arret du programme...")
        elseif key == keys.r then
            log("Rafraichissement...")
            detectPeripherals()
        elseif key == keys.p or key == keys.space then
            paused = not paused
            log(paused and "PAUSE" or "REPRISE")
        elseif key == keys.s then
            saveConfig()
            log("Configuration sauvegardee")
        end
    end
end

local function touchLoop()
    while running do
        local event, side, x, y = os.pullEvent("monitor_touch")
        -- Toggle pause sur touch
        paused = not paused
        log(paused and "PAUSE (touch)" or "REPRISE (touch)")
    end
end

-- ============================================
-- DEMARRAGE
-- ============================================

local function printHelp()
    print("")
    print("Commandes clavier:")
    print("  Q - Quitter")
    print("  P/Space - Pause/Reprendre")
    print("  R - Rafraichir peripheriques")
    print("  S - Sauvegarder config")
    print("")
end

local function start()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("========================================")
    print("   FURNACE MANAGER v" .. VERSION)
    print("   Gestionnaire de fours automatique")
    print("========================================")
    
    -- Charger la configuration
    if not loadConfig() then
        print("")
        print("ERREUR: Pas de configuration!")
        print("")
        print("Lancez 'setup' pour configurer le systeme.")
        return
    end
    
    loadStats()
    
    -- Detecter les peripheriques
    if not detectPeripherals() then
        print("")
        print("ERREUR: Aucun four detecte!")
        print("")
        print("Verifiez les connexions et relancez 'setup'.")
        return
    end
    
    printHelp()
    
    -- Afficher config
    print("Configuration:")
    print("  Input:  " .. (config.inputChest or "?"))
    print("  Output: " .. (config.outputChest or "?"))
    print("  Fuel:   " .. (config.fuelChest or "?"))
    print("  Fours:  " .. #allFurnaces)
    print("  Smart:  " .. (config.smartRouting and "Oui" or "Non"))
    print("  Eco:    " .. (config.ecoMode and "Oui" or "Non"))
    print("")
    print("Demarrage...")
    
    -- Lancer les boucles
    local ok, err = pcall(function()
        parallel.waitForAny(mainLoop, inputLoop, touchLoop)
    end)
    
    if not ok then
        log("Erreur: " .. tostring(err))
    end
    
    -- Sauvegarde finale
    saveConfig()
    
    -- Nettoyage moniteur
    if monitor then
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.setTextColor(colors.red)
        monitor.write("SYSTEME ARRETE")
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    print("Furnace Manager arrete.")
    print("Stats session: " .. stats.sessionCooked .. " items cuits")
end

start()
