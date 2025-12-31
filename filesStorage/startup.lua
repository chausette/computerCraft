-- ============================================
-- SERVEUR DE STOCKAGE - PROGRAMME PRINCIPAL
-- ============================================

if not fs.exists("storage_data") then
    fs.makeDir("storage_data")
end

local config = require("config")
local storage = require("storage")
local network = require("network")
local ui = require("ui_monitor")

-- === VARIABLES GLOBALES ===
local running = true
local currentPage = "main"
local inventoryPage = 1
local totalPages = 1
local scrollOffset = 0
local connectedChests = {}
local selectedItem = nil
local selectedItemDisplay = nil
local selectedItemStock = 0
local selectedItemThreshold = 0

-- === INITIALISATION ===

local function init()
    config.load()
    
    print("Initialisation du reseau...")
    if not network.init(true) then
        print("ERREUR: Aucun modem trouve!")
        return false
    end
    print("Reseau OK - Protocole: " .. config.PROTOCOL)
    
    print("Initialisation du moniteur...")
    if ui.init() then
        print("Moniteur OK - " .. ui.width .. "x" .. ui.height)
        ui.drawLoading("Demarrage du systeme...")
    else
        print("ATTENTION: Aucun moniteur trouve")
    end
    
    print("Scan de l'inventaire...")
    storage.scanAll()
    local stats = storage.getStats()
    print("Inventaire OK - " .. storage.countUniqueItems() .. " types d'items")
    
    return true
end

-- === GESTION DES REQUETES RESEAU ===

local function handleNetworkRequests()
    while running do
        local clientId, request = network.waitForRequest(0.5)
        
        if clientId and request then
            print("[" .. os.date("%H:%M:%S") .. "] Requete: " .. (request.type or "?"))
            local response = network.handleRequest(storage, request)
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
                totalPages = ui.drawInventoryPage(byCategory, inventoryPage)
            elseif currentPage == "favorites" then
                local favorites = storage.getFavorites()
                ui.drawFavoritesPage(favorites)
            elseif currentPage == "chests" then
                connectedChests = storage.listConnectedChests()
                scrollOffset = ui.drawChestsPage(connectedChests, config.storage_chests, scrollOffset)
            elseif currentPage == "categories" then
                scrollOffset = ui.drawCategoriesPage(config.categories, storage.inventory, scrollOffset)
            elseif currentPage == "category_select" then
                ui.drawCategorySelectPage(config.categories, selectedItem, selectedItemDisplay)
            elseif currentPage == "alerts" then
                scrollOffset = ui.drawAlertsPage(storage.inventory, config.stock_alerts, scrollOffset)
            elseif currentPage == "alert_edit" then
                ui.drawAlertEditPage(selectedItem, selectedItemDisplay, selectedItemStock, selectedItemThreshold)
            end
        end
        
        sleep(config.display.refresh_rate)
    end
end

-- === TRI AUTOMATIQUE ===

local function autoSort()
    while running do
        local sorted, err = storage.sortInputChest()
        if sorted > 0 then
            print("[" .. os.date("%H:%M:%S") .. "] Tri auto: " .. sorted .. " items")
        end
        sleep(5)
    end
end

-- === GESTION TACTILE DU MONITEUR ===

local function handleMonitorTouch()
    while running do
        local event, side, x, y = os.pullEvent("monitor_touch")
        
        if ui.monitor then
            local action, data = ui.checkClick(x, y)
            
            if action then
                print("[" .. os.date("%H:%M:%S") .. "] Touch: " .. action)
                
                -- Navigation principale
                if action == "goto_main" then
                    currentPage = "main"
                    scrollOffset = 0
                elseif action == "goto_inventory" then
                    currentPage = "inventory"
                    inventoryPage = 1
                elseif action == "goto_favorites" then
                    currentPage = "favorites"
                elseif action == "goto_chests" then
                    currentPage = "chests"
                    scrollOffset = 0
                    connectedChests = storage.listConnectedChests()
                elseif action == "goto_categories" then
                    currentPage = "categories"
                    scrollOffset = 0
                elseif action == "goto_alerts" then
                    currentPage = "alerts"
                    scrollOffset = 0
                
                -- Pagination inventaire
                elseif action == "prev_page" then
                    inventoryPage = math.max(1, inventoryPage - 1)
                elseif action == "next_page" then
                    inventoryPage = math.min(totalPages, inventoryPage + 1)
                
                -- Scroll haut/bas
                elseif action == "scroll_up" then
                    scrollOffset = math.max(0, scrollOffset - 3)
                elseif action == "scroll_down" then
                    scrollOffset = math.min(ui.maxScroll, scrollOffset + 3)
                
                -- Gestion des coffres
                elseif action == "add_chest" then
                    config.addChest(data, nil)
                    storage.scanAll()
                    print("  Coffre ajoute: " .. data)
                elseif action == "remove_chest" then
                    config.removeChest(data)
                    storage.scanAll()
                    print("  Coffre retire: " .. data)
                
                -- Gestion des catégories
                elseif action == "add_category" then
                    -- Pour l'instant, message (nécessite input texte)
                    print("  Ajout categorie via Pocket")
                elseif action == "change_category" then
                    selectedItem = data.name
                    selectedItemDisplay = data.displayName
                    currentPage = "category_select"
                elseif action == "set_category" then
                    -- Ajouter le pattern pour cet item dans la nouvelle catégorie
                    local itemShort = data.item:gsub("^[^:]+:", "")
                    config.addPatternToCategory(data.category, itemShort)
                    storage.scanAll()
                    currentPage = "categories"
                    scrollOffset = 0
                    print("  Categorie changee: " .. data.item .. " -> " .. data.category)
                
                -- Gestion des alertes
                elseif action == "edit_alert" then
                    selectedItem = data.name
                    selectedItemDisplay = data.displayName
                    selectedItemStock = data.current
                    selectedItemThreshold = data.threshold
                    currentPage = "alert_edit"
                elseif action == "set_alert" then
                    if data.threshold == 0 then
                        config.stock_alerts[data.item] = nil
                    else
                        config.stock_alerts[data.item] = data.threshold
                    end
                    config.save()
                    currentPage = "alerts"
                    scrollOffset = 0
                    print("  Alerte modifiee: " .. data.item .. " = " .. data.threshold)
                
                -- Actions
                elseif action == "sort_input" then
                    local sorted = storage.sortInputChest()
                    print("  Tri manuel: " .. sorted .. " items")
                end
            end
        end
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
            if currentPage == "main" then
                currentPage = "inventory"
                inventoryPage = 1
            elseif currentPage == "inventory" then
                currentPage = "favorites"
            elseif currentPage == "favorites" then
                currentPage = "chests"
            elseif currentPage == "chests" then
                currentPage = "categories"
            elseif currentPage == "categories" then
                currentPage = "alerts"
            else
                currentPage = "main"
            end
            scrollOffset = 0
            print("Page: " .. currentPage)
        elseif key == keys.left then
            if currentPage == "inventory" then
                inventoryPage = math.max(1, inventoryPage - 1)
            else
                scrollOffset = math.max(0, scrollOffset - 3)
            end
        elseif key == keys.right then
            if currentPage == "inventory" then
                inventoryPage = inventoryPage + 1
            else
                scrollOffset = scrollOffset + 3
            end
        elseif key == keys.up then
            scrollOffset = math.max(0, scrollOffset - 1)
        elseif key == keys.down then
            scrollOffset = scrollOffset + 1
        elseif key == keys.s then
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
    print("Serveur demarre!")
    print("")
    print("Commandes clavier:")
    print("  [Q] Quitter")
    print("  [R] Rescan inventaire")
    print("  [M] Changer page")
    print("  [S] Forcer le tri")
    print("  [Fleches] Navigation")
    print("")
    print("MONITEUR TACTILE ACTIF")
    print("----------------------------------------")
    
    parallel.waitForAny(
        handleNetworkRequests,
        updateDisplay,
        autoSort,
        handleLocalInput,
        handleMonitorTouch
    )
    
    if ui.monitor then
        ui.clear()
        ui.writeCentered(math.floor(ui.height / 2), "Serveur arrete", colors.red)
    end
    
    print("")
    print("Serveur arrete.")
end

main()
