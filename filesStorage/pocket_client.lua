-- ============================================
-- CLIENT POCKET - CONTROLE DU STOCKAGE
-- ============================================

local PROTOCOL = "storage_system"
local SERVER_ID = "storage_server"

local serverId = nil
local running = true

-- === FONCTIONS RESEAU ===

local function initNetwork()
    local modemSide = nil
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            modemSide = side
            break
        end
    end
    
    if not modemSide then
        return false, "Aucun modem trouve"
    end
    
    rednet.open(modemSide)
    serverId = rednet.lookup(PROTOCOL, SERVER_ID)
    
    if not serverId then
        return false, "Serveur non trouve"
    end
    
    return true, nil
end

local function sendRequest(request)
    if not serverId then
        return nil, "Non connecte"
    end
    
    rednet.send(serverId, request, PROTOCOL)
    local sender, response = rednet.receive(PROTOCOL, 5)
    
    if sender == serverId then
        return response, nil
    end
    
    return nil, "Timeout"
end

-- === FONCTIONS D'AFFICHAGE ===

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function printHeader(title)
    clearScreen()
    local w, h = term.getSize()
    print(string.rep("=", w))
    local padding = math.floor((w - #title) / 2)
    print(string.rep(" ", padding) .. title)
    print(string.rep("=", w))
    print("")
end

local function printOption(num, text)
    print("[" .. num .. "] " .. text)
end

local function waitKey(message)
    print("")
    print(message or "Appuyez sur une touche...")
    os.pullEvent("key")
end

local function readInput(prompt)
    term.write(prompt)
    return read()
end

local function readNumber(prompt, min, max)
    while true do
        local input = readInput(prompt)
        local num = tonumber(input)
        if num and num >= min and num <= max then
            return num
        end
        print("Entrez un nombre entre " .. min .. " et " .. max)
    end
end

-- === DECLARATIONS ANTICIPEES ===
local menuMain
local menuSearch
local menuFavorites
local menuCategories
local menuStats
local menuConfig
local menuConfigChests
local menuConfigCategories
local menuConfigFavorites
local displayItemList
local menuItemAction
local actionRetrieveItem
local actionAddFavorite
local actionRemoveFavorite
local actionEmptyInput

-- === ACTIONS ===

actionRetrieveItem = function(item)
    printHeader("COMMANDER")
    
    print("Item: " .. item.displayName)
    print("En stock: " .. item.count)
    print("")
    
    if item.count == 0 then
        print("Stock vide!")
        waitKey()
        return
    end
    
    local max = math.min(item.count, 64)
    local count = readNumber("Quantite (1-" .. max .. "): ", 1, max)
    
    print("")
    print("Envoi de la commande...")
    
    local response, err = sendRequest({
        type = "retrieve_item",
        itemName = item.name,
        count = count
    })
    
    if response and response.success then
        print("OK! " .. response.data .. " items envoyes")
        print("Recuperez dans le coffre de sortie")
    else
        print("Erreur: " .. (err or (response and response.error) or "?"))
    end
    
    waitKey()
end

actionAddFavorite = function(itemName)
    local response = sendRequest({
        type = "add_favorite",
        itemName = itemName
    })
    
    if response and response.success then
        print("Ajoute aux favoris!")
    else
        print("Erreur: " .. (response and response.error or "?"))
    end
    waitKey()
end

actionRemoveFavorite = function(itemName)
    local response = sendRequest({
        type = "remove_favorite",
        itemName = itemName
    })
    
    if response and response.success then
        print("Retire des favoris!")
    else
        print("Erreur: " .. (response and response.error or "?"))
    end
    waitKey()
end

actionEmptyInput = function()
    printHeader("VIDER ENTREE")
    
    print("Tri du coffre d'entree...")
    
    local response, err = sendRequest({type = "empty_input"})
    
    if response then
        print(response.data .. " items tries")
        if response.error then
            print("Note: " .. response.error)
        end
    else
        print("Erreur: " .. (err or "?"))
    end
    
    waitKey()
end

-- === MENU ACTION ITEM ===

menuItemAction = function(item)
    printHeader(item.displayName)
    
    print("En stock: " .. item.count)
    print("")
    
    printOption(1, "Commander")
    printOption(2, "Ajouter aux favoris")
    printOption(3, "Retirer des favoris")
    printOption(0, "Retour")
    
    print("")
    local choice = readInput("> ")
    
    if choice == "1" then
        actionRetrieveItem(item)
    elseif choice == "2" then
        actionAddFavorite(item.name)
    elseif choice == "3" then
        actionRemoveFavorite(item.name)
    end
end

-- === AFFICHAGE LISTE ITEMS ===

displayItemList = function(items, title)
    local page = 1
    local itemsPerPage = 8
    local totalPages = math.ceil(#items / itemsPerPage)
    if totalPages == 0 then totalPages = 1 end
    
    while true do
        printHeader(title .. " (" .. #items .. ")")
        
        local startIdx = (page - 1) * itemsPerPage + 1
        local endIdx = math.min(startIdx + itemsPerPage - 1, #items)
        
        for i = startIdx, endIdx do
            local item = items[i]
            local name = item.displayName or item.name
            if #name > 18 then
                name = name:sub(1, 16) .. ".."
            end
            print("[" .. (i - startIdx + 1) .. "] " .. name .. " x" .. item.count)
        end
        
        print("")
        print("Page " .. page .. "/" .. totalPages)
        print("[N]Suivant [P]Prec [#]Choisir [Q]Retour")
        
        local choice = readInput("> "):lower()
        
        if choice == "n" and page < totalPages then
            page = page + 1
        elseif choice == "p" and page > 1 then
            page = page - 1
        elseif choice == "q" then
            return
        elseif tonumber(choice) then
            local idx = startIdx + tonumber(choice) - 1
            if idx >= 1 and idx <= #items then
                menuItemAction(items[idx])
            end
        end
    end
end

-- === MENU RECHERCHE ===

menuSearch = function()
    printHeader("RECHERCHE")
    
    local query = readInput("Recherche: ")
    
    if query == "" then return end
    
    print("")
    print("Recherche en cours...")
    
    local response, err = sendRequest({
        type = "search",
        query = query
    })
    
    if not response or not response.success then
        print("Erreur: " .. (err or (response and response.error) or "?"))
        waitKey()
        return
    end
    
    local results = response.data
    
    if #results == 0 then
        print("Aucun resultat")
        waitKey()
        return
    end
    
    displayItemList(results, "RESULTATS")
end

-- === MENU FAVORIS ===

menuFavorites = function()
    printHeader("FAVORIS")
    
    print("Chargement...")
    
    local response, err = sendRequest({type = "get_favorites"})
    
    if not response or not response.success then
        print("Erreur: " .. (err or "?"))
        waitKey()
        return
    end
    
    local favorites = response.data
    
    if #favorites == 0 then
        print("Aucun favori configure")
        waitKey()
        return
    end
    
    while true do
        printHeader("FAVORIS")
        
        for i, fav in ipairs(favorites) do
            local status = fav.inStock and ("x" .. fav.count) or "(vide)"
            local name = fav.displayName
            if #name > 15 then
                name = name:sub(1, 13) .. ".."
            end
            print("[" .. i .. "] " .. name .. " " .. status)
        end
        
        print("")
        print("[#] Commander [Q] Retour")
        
        local choice = readInput("> "):lower()
        
        if choice == "q" then
            return
        elseif tonumber(choice) then
            local idx = tonumber(choice)
            if favorites[idx] and favorites[idx].inStock then
                actionRetrieveItem(favorites[idx])
                
                response = sendRequest({type = "get_favorites"})
                if response and response.success then
                    favorites = response.data
                end
            elseif favorites[idx] then
                print("Stock vide!")
                waitKey()
            end
        end
    end
end

-- === MENU CATEGORIES ===

menuCategories = function()
    printHeader("CATEGORIES")
    
    print("Chargement...")
    
    local response, err = sendRequest({type = "get_by_category"})
    
    if not response or not response.success then
        print("Erreur: " .. (err or "?"))
        waitKey()
        return
    end
    
    local byCategory = response.data
    
    local categories = {}
    for name, data in pairs(byCategory) do
        if data.items and #data.items > 0 then
            table.insert(categories, {name = name, count = #data.items, items = data.items})
        end
    end
    
    if #categories == 0 then
        print("Aucun item en stock")
        waitKey()
        return
    end
    
    while true do
        printHeader("CATEGORIES")
        
        for i, cat in ipairs(categories) do
            local name = cat.name
            if #name > 16 then
                name = name:sub(1, 14) .. ".."
            end
            print("[" .. i .. "] " .. name .. " (" .. cat.count .. ")")
        end
        
        print("")
        print("[#] Voir [Q] Retour")
        
        local choice = readInput("> "):lower()
        
        if choice == "q" then
            return
        elseif tonumber(choice) then
            local idx = tonumber(choice)
            if categories[idx] then
                displayItemList(categories[idx].items, categories[idx].name)
            end
        end
    end
end

-- === MENU STATISTIQUES ===

menuStats = function()
    printHeader("STATISTIQUES")
    
    print("Chargement...")
    
    local response, err = sendRequest({type = "get_stats"})
    
    if not response or not response.success then
        print("Erreur: " .. (err or "?"))
        waitKey()
        return
    end
    
    local stats = response.data
    
    clearScreen()
    printHeader("STATISTIQUES")
    
    print("Items totaux: " .. stats.totalItems)
    print("Types uniques: " .. stats.uniqueItems)
    print("")
    print("Slots utilises: " .. stats.usedSlots)
    print("Slots libres: " .. stats.freeSlots)
    print("Capacite totale: " .. stats.totalSlots)
    print("")
    
    local percent = math.floor((stats.usedSlots / math.max(stats.totalSlots, 1)) * 100)
    print("Utilisation: " .. percent .. "%")
    
    local alertResponse = sendRequest({type = "get_alerts"})
    if alertResponse and alertResponse.success and #alertResponse.data > 0 then
        print("")
        print("--- ALERTES ---")
        for _, alert in ipairs(alertResponse.data) do
            print("! " .. alert.displayName .. ": " .. alert.current .. "/" .. alert.minimum)
        end
    end
    
    waitKey()
end

-- === MENU CONFIG COFFRES ===

menuConfigChests = function()
    printHeader("COFFRES")
    
    print("Chargement...")
    
    local response, err = sendRequest({type = "list_chests"})
    
    if not response or not response.success then
        print("Erreur: " .. (err or "?"))
        waitKey()
        return
    end
    
    local chests = response.data
    
    clearScreen()
    printHeader("COFFRES CONNECTES")
    
    for i, chest in ipairs(chests) do
        local status = chest.isUsed and "[ACTIF]" or "[LIBRE]"
        local name = chest.name
        if #name > 20 then
            name = ".." .. name:sub(-18)
        end
        print(i .. ". " .. name)
        print("   " .. status .. " " .. chest.size .. " slots")
    end
    
    print("")
    print("[A]jouter [S]upprimer [Q]uitter")
    
    local choice = readInput("> "):lower()
    
    if choice == "a" then
        print("")
        print("Coffres libres:")
        local freeChests = {}
        for _, c in ipairs(chests) do
            if not c.isUsed then
                table.insert(freeChests, c)
                print(#freeChests .. ". " .. c.name)
            end
        end
        
        if #freeChests == 0 then
            print("Aucun coffre libre")
            waitKey()
            return
        end
        
        local idx = readNumber("Numero: ", 1, #freeChests)
        
        local addResponse = sendRequest({
            type = "add_chest",
            chestName = freeChests[idx].name
        })
        
        if addResponse and addResponse.success then
            print("Coffre ajoute!")
        else
            print("Erreur")
        end
        waitKey()
        
    elseif choice == "s" then
        local activeChests = {}
        for _, c in ipairs(chests) do
            if c.isUsed then
                table.insert(activeChests, c)
            end
        end
        
        if #activeChests == 0 then
            print("Aucun coffre actif")
            waitKey()
            return
        end
        
        print("")
        print("Coffres actifs:")
        for i, c in ipairs(activeChests) do
            print(i .. ". " .. c.name)
        end
        
        local idx = readNumber("Numero a supprimer: ", 1, #activeChests)
        
        local removeResponse = sendRequest({
            type = "remove_chest",
            chestName = activeChests[idx].name
        })
        
        if removeResponse and removeResponse.success then
            print("Coffre supprime!")
        else
            print("Erreur: " .. (removeResponse and removeResponse.error or "?"))
        end
        waitKey()
    end
end

-- === MENU CONFIG CATEGORIES ===

menuConfigCategories = function()
    printHeader("CATEGORIES")
    
    local response = sendRequest({type = "get_categories"})
    
    if not response or not response.success then
        print("Erreur de chargement")
        waitKey()
        return
    end
    
    local categories = response.data
    
    for i, cat in ipairs(categories) do
        print(i .. ". " .. cat.name)
        if cat.patterns and #cat.patterns > 0 then
            local patternsStr = table.concat(cat.patterns, ", ")
            if #patternsStr > 25 then
                patternsStr = patternsStr:sub(1, 22) .. "..."
            end
            print("   " .. patternsStr)
        end
    end
    
    print("")
    print("[A]jouter cat [P]attern [Q]uitter")
    
    local choice = readInput("> "):lower()
    
    if choice == "a" then
        local name = readInput("Nom: ")
        if name ~= "" then
            sendRequest({
                type = "add_category",
                name = name,
                patterns = {}
            })
            print("Categorie ajoutee!")
        end
        waitKey()
        
    elseif choice == "p" then
        local catIdx = readNumber("Categorie #: ", 1, #categories)
        local pattern = readInput("Pattern: ")
        
        if pattern ~= "" then
            sendRequest({
                type = "add_pattern",
                categoryName = categories[catIdx].name,
                pattern = pattern
            })
            print("Pattern ajoute!")
        end
        waitKey()
    end
end

-- === MENU CONFIG FAVORIS ===

menuConfigFavorites = function()
    printHeader("GERER FAVORIS")
    
    local response = sendRequest({type = "get_favorites"})
    
    if response and response.success then
        print("Favoris actuels:")
        for i, fav in ipairs(response.data) do
            print(i .. ". " .. fav.displayName)
        end
        
        if #response.data == 0 then
            print("(aucun)")
        end
    end
    
    print("")
    print("[S]upprimer un favori [Q]uitter")
    print("(Ajouter via recherche)")
    
    local choice = readInput("> "):lower()
    
    if choice == "s" and response and #response.data > 0 then
        local idx = readNumber("Numero: ", 1, #response.data)
        
        sendRequest({
            type = "remove_favorite",
            itemName = response.data[idx].name
        })
        print("Favori supprime!")
        waitKey()
    end
end

-- === MENU CONFIGURATION ===

menuConfig = function()
    while true do
        printHeader("CONFIGURATION")
        
        printOption(1, "Gerer les coffres")
        printOption(2, "Gerer les categories")
        printOption(3, "Gerer les favoris")
        printOption(0, "Retour")
        
        print("")
        local choice = readInput("> ")
        
        if choice == "1" then
            menuConfigChests()
        elseif choice == "2" then
            menuConfigCategories()
        elseif choice == "3" then
            menuConfigFavorites()
        elseif choice == "0" then
            return
        end
    end
end

-- === MENU PRINCIPAL ===

menuMain = function()
    printHeader("STOCKAGE")
    
    printOption(1, "Rechercher un item")
    printOption(2, "Favoris")
    printOption(3, "Par categorie")
    printOption(4, "Vider coffre entree")
    printOption(5, "Statistiques")
    printOption(6, "Configuration")
    printOption(0, "Quitter")
    
    print("")
    local choice = readInput("> ")
    
    if choice == "1" then
        menuSearch()
    elseif choice == "2" then
        menuFavorites()
    elseif choice == "3" then
        menuCategories()
    elseif choice == "4" then
        actionEmptyInput()
    elseif choice == "5" then
        menuStats()
    elseif choice == "6" then
        menuConfig()
    elseif choice == "0" then
        running = false
    end
end

-- === PROGRAMME PRINCIPAL ===

local function main()
    clearScreen()
    print("Connexion au serveur...")
    
    local ok, err = initNetwork()
    
    if not ok then
        print("")
        print("ERREUR: " .. err)
        print("")
        print("Verifiez que:")
        print("- Le modem est connecte")
        print("- Le serveur est demarre")
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return
    end
    
    print("Connecte au serveur #" .. serverId)
    sleep(0.5)
    
    while running do
        menuMain()
    end
    
    clearScreen()
    print("Deconnecte.")
end

main()
