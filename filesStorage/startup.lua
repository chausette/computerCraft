-- ============================================
-- SERVEUR DE STOCKAGE - PROGRAMME PRINCIPAL
-- Placez ce fichier dans l'ordinateur principal
-- ============================================

-- Crée le dossier de données si nécessaire
if not fs.exists("storage_data") then
    fs.makeDir("storage_data")
end

-- Charge les modules
local config = require("config")
local storage = require("storage")
local network = require("network")
local ui = require("ui_monitor")

-- === VARIABLES GLOBALES ===
local running = true
local currentPage = "main"
local inventoryPage = 1
local lastActivity = os.clock()

-- === INITIALISATION ===

local function init()
    -- Charge la configuration sauvegardée
    config.load()
    
    -- Initialise le réseau
    print("Initialisation du reseau...")
    if not network.init(true) then
        print("ERREUR: Aucun modem trouve!")
        print("Connectez un modem (wireless ou wired)")
        return false
    end
    print("Reseau OK - Protocole: " .. config.PROTOCOL)
    
    -- Initialise le moniteur
    print("Initialisation du moniteur...")
    if ui.init() then
        print("Moniteur OK - " .. ui.width .. "x" .. ui.height)
        ui.drawLoading("Demarrage du systeme...")
    else
        print("ATTENTION: Aucun moniteur trouve")
    end
    
    -- Scanne l'inventaire initial
    print("Scan de l'inventaire...")
    storage.scanAll()
    local stats = storage.getStats()
    print("Inventaire OK - " .. storage.countUniqueItems() .. " types d'items")
    print("Capacite: " .. stats.usedSlots .. "/" .. stats.totalSlots .. " slots")
    
    return true
end

-- === GESTION DES REQUETES RESEAU ===

local function handleNetworkRequests()
    while running do
        local clientId, request = network.waitForRequest(0.5)
        
        if clientId and request then
            lastActivity = os.clock()
            print("[" .. os.date("%H:%M:%S") .. "] Requete de #" .. clientId .. ": " .. (request.type or "?"))
            
            -- Traite la requête
            local response = network.handleRequest(storage, request)
            
            -- Envoie la réponse
            network.sendResponse(clientId, response)
        end
    end
end

-- === GESTION DE L'AFFICHAGE MONITEUR ===

local function updateDisplay()
    while running do
        if ui.monitor then
            local stats = storage.getStats()
            stats.uniqueItems = storage.countUniqueItems()
            
            if currentPage == "main" then
                ui.drawMainPage(storage, stats)
            elseif currentPage == "inventory" then
                local byCategory = storage.getByCategory()
                ui.drawInventoryPage(byCategory, inventoryPage)
            elseif currentPage == "favorites" then
                local favorites = storage.getFavorites()
                ui.drawFavoritesPage(favorites)
            end
        end
        
        sleep(config.display.refresh_rate)
    end
end

-- === TRI AUTOMATIQUE ===

local function autoSort()
    while running do
        -- Trie le coffre d'entrée toutes les 5 secondes
        local sorted, err = storage.sortInputChest()
        if sorted > 0 then
            print("[" .. os.date("%H:%M:%S") .. "] Tri auto: " .. sorted .. " items")
        end
        
        sleep(5)
    end
end

-- === CONTROLE LOCAL (CLAVIER) ===

local function handleLocalInput()
    while running do
        local event, key = os.pullEvent("key")
        
        if key == keys.q then
            running = false
            print("Arret du serveur...")
        elseif key == keys.r then
            print("Rescan de l'inventaire...")
            storage.scanAll()
            print("Scan termine!")
        elseif key == keys.m then
            -- Change de page moniteur
            if currentPage == "main" then
                currentPage = "inventory"
                inventoryPage = 1
            elseif currentPage == "inventory" then
                currentPage = "favorites"
            else
                currentPage = "main"
            end
            print("Page moniteur: " .. currentPage)
        elseif key == keys.left and currentPage == "inventory" then
            inventoryPage = math.max(1, inventoryPage - 1)
        elseif key == keys.right and currentPage == "inventory" then
            inventoryPage = inventoryPage + 1
        elseif key == keys.s then
            -- Force le tri
            local sorted = storage.sortInputChest()
            print("Tri manuel: " .. sorted .. " items")
        end
    end
end

-- === PROGRAMME PRINCIPAL ===

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("========================================")
    print("   SYSTEME DE STOCKAGE - SERVEUR")
    print("========================================")
    print("")
    
    if not init() then
        print("")
        print("Echec de l'initialisation!")
        return
    end
    
    print("")
    print("Serveur demarre avec succes!")
    print("")
    print("Commandes clavier:")
    print("  [Q] Quitter")
    print("  [R] Rescan inventaire")
    print("  [M] Changer page moniteur")
    print("  [S] Forcer le tri")
    print("  [<][>] Navigation pages")
    print("")
    print("En attente de connexions...")
    print("----------------------------------------")
    
    -- Lance les tâches parallèles
    parallel.waitForAny(
        handleNetworkRequests,
        updateDisplay,
        autoSort,
        handleLocalInput
    )
    
    -- Nettoyage
    if ui.monitor then
        ui.clear()
        ui.writeCentered(math.floor(ui.height / 2), "Serveur arrete", colors.red)
    end
    
    print("")
    print("Serveur arrete.")
end

-- Lance le programme
main()
