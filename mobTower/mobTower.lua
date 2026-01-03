-- ============================================
-- MOB TOWER MANAGER v1.0
-- Programme principal
-- Par MikeChausette
-- ============================================

-- Chemins
local BASE_PATH = "mobTower"
local CONFIG_PATH = BASE_PATH .. "/config.lua"
local DATA_PATH = BASE_PATH .. "/data"

-- Charger les modules
package.path = package.path .. ";/" .. BASE_PATH .. "/lib/?.lua"

local utils = require("mobTower.lib.utils")
local peripherals = require("mobTower.lib.peripherals")
local storage = require("mobTower.lib.storage")
local ui = require("mobTower.lib.ui")

-- Variables globales
local config = nil
local running = true
local spawnOn = true
local lastSortTime = 0
local lastSaveTime = 0

-- ============================================
-- SETUP WIZARD
-- ============================================

local function setupWizard()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("============================================")
    print("   MOB TOWER MANAGER - Setup Wizard")
    print("============================================")
    print("")
    
    -- Charger la config par défaut
    config = dofile(CONFIG_PATH)
    
    -- Etape 1: Scan des périphériques
    print("[1/8] Scan des peripheriques...")
    sleep(0.5)
    local allPeripherals = peripherals.listAll()
    
    -- Etape 2: Entity Sensor Haut
    print("")
    print("[2/8] Entity Sensor HAUT (darkroom)")
    if #allPeripherals.entitySensors == 0 then
        print("  /!\\ Aucun Entity Sensor trouve!")
        print("  Verifiez vos connexions et relancez.")
        return false
    end
    
    for i, sensor in ipairs(allPeripherals.entitySensors) do
        print("  " .. i .. ". " .. sensor.name)
    end
    write("  Choix (1-" .. #allPeripherals.entitySensors .. "): ")
    local choice = tonumber(read())
    if choice and allPeripherals.entitySensors[choice] then
        config.peripherals.entitySensorTop = allPeripherals.entitySensors[choice].name
        print("  -> " .. config.peripherals.entitySensorTop)
    end
    
    -- Etape 3: Entity Sensor Bas
    print("")
    print("[3/8] Entity Sensor BAS (zone kill)")
    local remainingSensors = {}
    for i, sensor in ipairs(allPeripherals.entitySensors) do
        if sensor.name ~= config.peripherals.entitySensorTop then
            table.insert(remainingSensors, sensor)
        end
    end
    
    if #remainingSensors == 0 then
        print("  /!\\ Plus de sensors disponibles!")
        print("  Vous avez besoin de 2 Entity Sensors.")
        return false
    end
    
    for i, sensor in ipairs(remainingSensors) do
        print("  " .. i .. ". " .. sensor.name)
    end
    write("  Choix (1-" .. #remainingSensors .. "): ")
    choice = tonumber(read())
    if choice and remainingSensors[choice] then
        config.peripherals.entitySensorBottom = remainingSensors[choice].name
        print("  -> " .. config.peripherals.entitySensorBottom)
    end
    
    -- Etape 4: Inventory Manager
    print("")
    print("[4/8] Inventory Manager")
    if #allPeripherals.inventoryManagers == 0 then
        print("  /!\\ Aucun Inventory Manager trouve!")
        return false
    end
    
    for i, inv in ipairs(allPeripherals.inventoryManagers) do
        print("  " .. i .. ". " .. inv.name)
    end
    write("  Choix (1-" .. #allPeripherals.inventoryManagers .. "): ")
    choice = tonumber(read())
    if choice and allPeripherals.inventoryManagers[choice] then
        config.peripherals.inventoryManager = allPeripherals.inventoryManagers[choice].name
        print("  -> " .. config.peripherals.inventoryManager)
    end
    
    -- Etape 5: Redstone Integrator
    print("")
    print("[5/8] Redstone Integrator")
    if #allPeripherals.redstoneIntegrators == 0 then
        print("  /!\\ Aucun Redstone Integrator trouve!")
        return false
    end
    
    for i, rs in ipairs(allPeripherals.redstoneIntegrators) do
        print("  " .. i .. ". " .. rs.name)
    end
    write("  Choix (1-" .. #allPeripherals.redstoneIntegrators .. "): ")
    choice = tonumber(read())
    if choice and allPeripherals.redstoneIntegrators[choice] then
        config.peripherals.redstoneIntegrator = allPeripherals.redstoneIntegrators[choice].name
        print("  -> " .. config.peripherals.redstoneIntegrator)
    end
    
    -- Configuration Bundled Cable
    print("")
    print("  Cote du bundled cable:")
    local sides = {"top", "bottom", "left", "right", "front", "back"}
    for i, side in ipairs(sides) do
        print("    " .. i .. ". " .. side)
    end
    write("  Choix (1-6): ")
    choice = tonumber(read())
    if choice and sides[choice] then
        config.redstone.side = sides[choice]
        print("  -> " .. config.redstone.side)
    end
    
    print("")
    print("  Couleur du cable:")
    for i, color in ipairs(utils.COLOR_NAMES) do
        print("    " .. i .. ". " .. color)
    end
    write("  Choix (1-16): ")
    choice = tonumber(read())
    if choice and utils.COLOR_NAMES[choice] then
        config.redstone.color = utils.COLOR_NAMES[choice]
        print("  -> " .. config.redstone.color)
    end
    
    -- Etape 6: Moniteur
    print("")
    print("[6/8] Moniteur")
    if #allPeripherals.monitors == 0 then
        print("  /!\\ Aucun moniteur trouve!")
        return false
    end
    
    for i, mon in ipairs(allPeripherals.monitors) do
        print("  " .. i .. ". " .. mon.name)
    end
    write("  Choix (1-" .. #allPeripherals.monitors .. "): ")
    choice = tonumber(read())
    if choice and allPeripherals.monitors[choice] then
        config.peripherals.monitor = allPeripherals.monitors[choice].name
        print("  -> " .. config.peripherals.monitor)
    end
    
    -- Etape 7: Coffre collecteur
    print("")
    print("[7/8] Coffre collecteur")
    if #allPeripherals.inventories == 0 then
        print("  /!\\ Aucun inventaire trouve!")
        return false
    end
    
    for i, inv in ipairs(allPeripherals.inventories) do
        print("  " .. i .. ". " .. inv.name .. " (" .. inv.type .. ")")
    end
    write("  Choix (1-" .. #allPeripherals.inventories .. "): ")
    choice = tonumber(read())
    if choice and allPeripherals.inventories[choice] then
        config.storage.collectorChest = allPeripherals.inventories[choice].name
        print("  -> " .. config.storage.collectorChest)
    end
    
    -- Etape 8: Attribution des barils
    print("")
    print("[8/8] Attribution des barils")
    print("Pour chaque item, selectionnez un baril.")
    print("")
    
    local remainingInv = {}
    for _, inv in ipairs(allPeripherals.inventories) do
        if inv.name ~= config.storage.collectorChest then
            table.insert(remainingInv, inv)
        end
    end
    
    config.storage.sortingRules = {}
    
    for _, item in ipairs(utils.SORTABLE_ITEMS) do
        if #remainingInv == 0 then
            print("  Plus de barils disponibles!")
            break
        end
        
        print("")
        print("  Item: " .. item.name)
        print("  Barils disponibles:")
        for i, inv in ipairs(remainingInv) do
            print("    " .. i .. ". " .. inv.name)
        end
        print("    0. Passer (ne pas trier cet item)")
        
        write("  Choix: ")
        choice = tonumber(read())
        
        if choice and choice > 0 and remainingInv[choice] then
            table.insert(config.storage.sortingRules, {
                itemId = item.id,
                barrel = remainingInv[choice].name,
                pattern = item.pattern or false
            })
            print("  -> " .. remainingInv[choice].name)
            table.remove(remainingInv, choice)
        else
            print("  -> Passe")
        end
    end
    
    -- Sauvegarde
    print("")
    print("============================================")
    print("Sauvegarde de la configuration...")
    
    config.setupComplete = true
    utils.saveTable(CONFIG_PATH, config)
    
    print("Configuration terminee!")
    print("")
    print("Appuyez sur une touche pour demarrer...")
    os.pullEvent("key")
    
    return true
end

-- ============================================
-- CHARGEMENT
-- ============================================

local function loadConfig()
    if fs.exists(CONFIG_PATH) then
        local loaded = utils.loadTable(CONFIG_PATH)
        if loaded then
            config = loaded
            return true
        end
    end
    
    -- Charger la config par défaut
    config = dofile(CONFIG_PATH)
    return false
end

local function initialize()
    utils.log("=== Démarrage Mob Tower Manager ===")
    
    -- Créer le dossier data
    utils.ensureDir(DATA_PATH)
    
    -- Charger la config
    if not loadConfig() or not config.setupComplete then
        utils.log("Premier lancement, démarrage du wizard")
        if not setupWizard() then
            return false
        end
        loadConfig()
    end
    
    -- Initialiser les périphériques
    local status = peripherals.init(config)
    utils.log("Status peripheriques: " .. textutils.serialize(status))
    
    -- Vérifier les périphériques critiques
    if not status.monitor then
        print("Erreur: Moniteur non connecte!")
        return false
    end
    
    -- Initialiser l'UI
    local monitor = peripherals.getMonitor()
    ui.init(monitor)
    
    -- Initialiser le stockage
    storage.init(config)
    
    -- État initial du spawn
    spawnOn = config.initialState.spawnOn
    local colorValue = utils.COLORS[config.redstone.color] or colors.white
    if spawnOn then
        peripherals.setSpawnOn(config.redstone.side, colorValue)
    else
        peripherals.setSpawnOff(config.redstone.side, colorValue)
    end
    
    utils.log("Initialisation terminée")
    return true
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

local function updateDisplay()
    local stats = storage.getStats()
    
    -- Compter les mobs
    local mobsBottom = peripherals.getMobsBottom()
    local mobsWaiting = #mobsBottom
    
    -- Mettre à jour le compteur de kills
    storage.updateMobCount(mobsWaiting)
    
    -- Vérifier présence joueur
    local playerPresent = peripherals.isPlayerPresent(config.player.name)
    
    -- Données pour l'affichage
    local displayData = {
        spawnOn = spawnOn,
        sessionTime = storage.getSessionTime(),
        playerPresent = playerPresent,
        stats = {
            mobsWaiting = mobsWaiting,
            session = stats.session,
            total = stats.total
        },
        hourlyData = storage.getHourlyData(config.display.graphHours),
        storageStatus = storage.getStorageStatus(),
        rareItems = storage.getRecentRares(config.display.rareItemsCount)
    }
    
    -- Dessiner l'écran principal
    ui.drawMainScreen(displayData)
end

local function processInput()
    local event, key = os.pullEvent("key")
    
    if key == keys.q then
        -- Quitter
        running = false
        
    elseif key == keys.s then
        -- Toggle spawn
        local colorValue = utils.COLORS[config.redstone.color] or colors.white
        local success, newState = peripherals.toggleSpawn(
            config.redstone.side,
            colorValue,
            spawnOn
        )
        if success then
            spawnOn = newState
            utils.log("Spawn toggle: " .. tostring(spawnOn))
        end
        
    elseif key == keys.r then
        -- Reset stats (avec confirmation sur terminal)
        term.clear()
        term.setCursorPos(1, 1)
        print("Reset des statistiques de session?")
        print("[O] Oui  [N] Non")
        
        while true do
            local _, k = os.pullEvent("key")
            if k == keys.o then
                storage.resetSession()
                utils.log("Stats session reset")
                break
            elseif k == keys.n then
                break
            end
        end
        
    elseif key == keys.c then
        -- Config (relancer wizard)
        term.clear()
        term.setCursorPos(1, 1)
        print("Relancer la configuration?")
        print("[O] Oui  [N] Non")
        
        while true do
            local _, k = os.pullEvent("key")
            if k == keys.o then
                config.setupComplete = false
                utils.saveTable(CONFIG_PATH, config)
                os.reboot()
                break
            elseif k == keys.n then
                break
            end
        end
    end
end

local function sortItems()
    if not config.sorting.enabled then return end
    
    local now = os.epoch("utc") / 1000
    if now - lastSortTime < config.sorting.interval then return end
    
    lastSortTime = now
    
    local result = storage.sortAll()
    
    -- Alertes pour items rares
    for _, rare in ipairs(result.rares) do
        local name = utils.getShortName(rare.name)
        ui.showAlert("RARE: " .. name .. " x" .. rare.count, config.display.alertDuration)
        utils.log("Item rare: " .. rare.name .. " x" .. rare.count)
    end
end

local function autoSave()
    local now = os.epoch("utc") / 1000
    if now - lastSaveTime < 60 then return end  -- Sauvegarde toutes les minutes
    
    lastSaveTime = now
    storage.saveStats()
    storage.recordHourlyStats()
end

local function mainLoop()
    while running do
        -- Tri automatique
        sortItems()
        
        -- Mise à jour affichage
        updateDisplay()
        
        -- Mise à jour alerte
        ui.updateAlert()
        
        -- Sauvegarde automatique
        autoSave()
        
        -- Attendre input ou timeout
        local timer = os.startTimer(config.display.refreshRate)
        
        while true do
            local event, p1 = os.pullEvent()
            
            if event == "timer" and p1 == timer then
                break
            elseif event == "key" then
                os.cancelTimer(timer)
                -- Remettre l'événement dans la queue
                os.queueEvent("key", p1)
                processInput()
                break
            end
        end
    end
end

-- ============================================
-- POINT D'ENTRÉE
-- ============================================

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("Mob Tower Manager v1.0")
    print("Chargement...")
    
    if not initialize() then
        print("Echec de l'initialisation!")
        return
    end
    
    -- Message de démarrage
    term.clear()
    term.setCursorPos(1, 1)
    print("Mob Tower Manager actif!")
    print("Regardez le moniteur.")
    print("")
    print("Raccourcis clavier:")
    print("  S - Toggle spawn ON/OFF")
    print("  C - Reconfigurer")
    print("  R - Reset stats session")
    print("  Q - Quitter")
    
    -- Boucle principale
    local success, error = pcall(mainLoop)
    
    if not success then
        utils.log("Erreur: " .. tostring(error))
        print("Erreur: " .. tostring(error))
    end
    
    -- Nettoyage
    storage.saveStats()
    utils.closeLog()
    
    print("")
    print("Mob Tower Manager arrete.")
end

-- Lancer le programme
main()
