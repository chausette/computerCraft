-- ============================================
-- MOB TOWER MANAGER v1.1
-- Programme principal
-- Version 1.21 NeoForge
-- Par MikeChausette
-- ============================================

-- Chemins
local CONFIG_FILE = "/mobTower/config.lua"
local CONFIG_DATA = "/mobTower/data/config.dat"

-- Charger les modules avec dofile
local utils = dofile("/mobTower/lib/utils.lua")
local peripherals = dofile("/mobTower/lib/peripherals.lua")
local storage = dofile("/mobTower/lib/storage.lua")
local ui = dofile("/mobTower/lib/ui.lua")

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
    print("   MOB TOWER MANAGER v1.1 - Setup Wizard")
    print("   Version 1.21 NeoForge")
    print("============================================")
    print("")
    
    -- Charger la config par défaut
    config = dofile(CONFIG_FILE)
    
    -- Etape 1: Nom du joueur
    print("[1/7] Quel est ton pseudo Minecraft?")
    write("  Pseudo: ")
    local playerName = read()
    if playerName and #playerName > 0 then
        config.player.name = playerName
    end
    print("  -> " .. config.player.name)
    
    -- Etape 2: Scan des périphériques
    print("")
    print("[2/7] Scan des peripheriques...")
    sleep(0.5)
    local allPeripherals = peripherals.listAll()
    
    -- Etape 3: Player Detector
    print("")
    print("[3/7] Player Detector (Advanced Peripherals)")
    if #allPeripherals.playerDetectors == 0 then
        print("  /!\\ Aucun Player Detector trouve!")
        print("  Continuer sans? (o/n)")
        local answer = read()
        if answer:lower() ~= "o" then
            return false
        end
    else
        for i, detector in ipairs(allPeripherals.playerDetectors) do
            print("  " .. i .. ". " .. detector.name)
        end
        write("  Choix (1-" .. #allPeripherals.playerDetectors .. "): ")
        local choice = tonumber(read())
        if choice and allPeripherals.playerDetectors[choice] then
            config.peripherals.playerDetector = allPeripherals.playerDetectors[choice].name
            print("  -> " .. config.peripherals.playerDetector)
        end
    end
    
    -- Etape 4: Moniteur
    print("")
    print("[4/7] Moniteur")
    if #allPeripherals.monitors == 0 then
        print("  /!\\ Aucun moniteur trouve!")
        return false
    end
    
    for i, mon in ipairs(allPeripherals.monitors) do
        print("  " .. i .. ". " .. mon.name)
    end
    write("  Choix (1-" .. #allPeripherals.monitors .. "): ")
    local choice = tonumber(read())
    if choice and allPeripherals.monitors[choice] then
        config.peripherals.monitor = allPeripherals.monitors[choice].name
        print("  -> " .. config.peripherals.monitor)
    end
    
    -- Etape 5: Configuration Redstone
    print("")
    print("[5/7] Configuration Redstone (lampes)")
    print("  Quel cote du computer pour les lampes?")
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
    print("  Inverser le signal? (o/n)")
    local answer = read()
    config.redstone.inverted = (answer:lower() == "o")
    print("  -> Inversion: " .. tostring(config.redstone.inverted))
    
    -- Etape 6: Coffre collecteur
    print("")
    print("[6/7] Coffre collecteur")
    if #allPeripherals.inventories == 0 then
        print("  /!\\ Aucun inventaire trouve!")
        print("  Connectez vos coffres avec des wired modems.")
        return false
    end
    
    for i, inv in ipairs(allPeripherals.inventories) do
        print("  " .. i .. ". " .. inv.name .. " (" .. inv.size .. " slots)")
    end
    write("  Choix (1-" .. #allPeripherals.inventories .. "): ")
    choice = tonumber(read())
    if choice and allPeripherals.inventories[choice] then
        config.storage.collectorChest = allPeripherals.inventories[choice].name
        print("  -> " .. config.storage.collectorChest)
    end
    
    -- Etape 7: Attribution des barils
    print("")
    print("[7/7] Attribution des barils")
    print("Pour chaque item, selectionnez un baril.")
    print("Appuyez sur Entree pour passer un item.")
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
        print("  Barils: " .. #remainingInv)
        for i, inv in ipairs(remainingInv) do
            if i <= 5 then
                print("    " .. i .. ". " .. inv.name)
            end
        end
        if #remainingInv > 5 then
            print("    ... et " .. (#remainingInv - 5) .. " autres")
        end
        print("    0. Passer")
        
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
    utils.ensureDir("/mobTower/data")
    utils.saveTable(CONFIG_DATA, config)
    
    print("Configuration terminee!")
    print("")
    print("Materiel configure:")
    print("  - Player Detector: " .. (config.peripherals.playerDetector or "Non"))
    print("  - Moniteur: " .. (config.peripherals.monitor or "Non"))
    print("  - Redstone: " .. config.redstone.side)
    print("  - Coffre collecteur: " .. (config.storage.collectorChest or "Non"))
    print("  - Regles de tri: " .. #config.storage.sortingRules)
    print("")
    print("Appuyez sur une touche pour demarrer...")
    os.pullEvent("key")
    
    return true
end

-- ============================================
-- CHARGEMENT
-- ============================================

local function loadConfig()
    -- Essayer de charger la config sauvegardée
    if fs.exists(CONFIG_DATA) then
        local loaded = utils.loadTable(CONFIG_DATA)
        if loaded and loaded.setupComplete then
            config = loaded
            return true
        end
    end
    
    -- Charger la config par défaut
    config = dofile(CONFIG_FILE)
    return false
end

local function initialize()
    utils.log("=== Demarrage Mob Tower Manager v1.1 ===")
    
    -- Créer le dossier data
    utils.ensureDir("/mobTower/data")
    
    -- Charger la config
    if not loadConfig() or not config.setupComplete then
        utils.log("Premier lancement, demarrage du wizard")
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
    if spawnOn then
        peripherals.setSpawnOn()
    else
        peripherals.setSpawnOff()
    end
    
    utils.log("Initialisation terminee")
    return true
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

local function updateDisplay()
    local stats = storage.getStats()
    
    -- Vérifier présence joueur
    local playerPresent = false
    if config.peripherals.playerDetector then
        playerPresent = peripherals.isPlayerPresent(config.player.name, config.player.detectionRange)
    end
    
    -- Données pour l'affichage
    local displayData = {
        spawnOn = spawnOn,
        sessionTime = storage.getSessionTime(),
        playerPresent = playerPresent,
        stats = {
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
        running = false
        
    elseif key == keys.s then
        local success, newState = peripherals.toggleSpawn(spawnOn)
        if success then
            spawnOn = newState
            utils.log("Spawn toggle: " .. tostring(spawnOn))
        end
        
    elseif key == keys.r then
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
        term.clear()
        term.setCursorPos(1, 1)
        print("Relancer la configuration?")
        print("[O] Oui  [N] Non")
        
        while true do
            local _, k = os.pullEvent("key")
            if k == keys.o then
                config.setupComplete = false
                utils.saveTable(CONFIG_DATA, config)
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
    if now - lastSaveTime < 60 then return end
    
    lastSaveTime = now
    storage.saveStats()
    storage.recordHourlyStats()
end

local function mainLoop()
    while running do
        sortItems()
        updateDisplay()
        ui.updateAlert()
        autoSave()
        
        local timer = os.startTimer(config.display.refreshRate)
        
        while true do
            local event, p1 = os.pullEvent()
            
            if event == "timer" and p1 == timer then
                break
            elseif event == "key" then
                os.cancelTimer(timer)
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
    print("Mob Tower Manager v1.1")
    print("Version 1.21 NeoForge")
    print("Chargement...")
    
    if not initialize() then
        print("Echec de l'initialisation!")
        return
    end
    
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
    
    local success, error = pcall(mainLoop)
    
    if not success then
        utils.log("Erreur: " .. tostring(error))
        print("Erreur: " .. tostring(error))
    end
    
    storage.saveStats()
    utils.closeLog()
    
    print("")
    print("Mob Tower Manager arrete.")
end

-- Lancer le programme
main()
