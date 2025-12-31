-- ============================================
-- CLIENT POCKET - CONTROLE DU STOCKAGE
-- Placez ce fichier dans le Pocket Computer
-- ============================================

-- Configuration réseau
local PROTOCOL = "storage_system"
local SERVER_ID = "storage_server"

-- Variables
local serverId = nil
local running = true
local currentMenu = "main"

-- === FONCTIONS RESEAU ===

local function initNetwork()
    -- Cherche un modem
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
    
    -- Cherche le serveur
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

-- === MENUS ===

-- Menu principal
local function menuMain()
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

-- Menu recherche
local function menuSearch()
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
        print("Erreur: " .. (err or response.error or "?"))
        waitKey()
        return
    end
    
    local results = response.data
    
    if #results == 0 then
        print("Aucun resultat")
        waitKey()
        return
    end
    
    -- Affiche les résultats
    displayItemList(results, "RESULTATS")
end

-- Affiche une liste d'items avec sélection
local function displayItemList(items, title)
    local page = 1
    local itemsPerPage = 8
    local totalPages = math.ceil(#items / itemsPerPage)
    
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
        print("[N]Suivant [P]Prec [#]Commander [Q]Retour")
        
        local choice = readInput("> "):lower()
        
        if choice == "n" and page < totalPages then
            page = page + 1
        elseif choice == "p" and page > 1 then
            page = page - 1
        elseif choice == "q" then
            return
        elseif tonumber(choice) then
            local idx = startIdx + tonumber(choice) - 1
            if idx <= #items then
                menuItemAction(items[idx])
            end
        end
    end
end

-- Menu action sur un item
local function menuItemAction(item)
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

-- Menu favoris
local function menuFavorites()
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
                
                -- Rafraîchit les favoris
                response = sendRequest({type = "get_favorites"})
                if response and response.success then
                    favorites = response.data
                end
            end
        end
    end
end

-- Menu catégories
local function menuCategories()
    printHeader("CATEGORIES")
    
    print("Chargement...")
    
    local response, err = sendRequest({type = "get_by_category"})
    
    if not response or not response.success then
        print("Erreur: " .. (err or "?"))
        waitKey()
        return
    end
    
    local byCategory = response.data
    
    -- Liste les catégories non vides
    local categories = {}
    for name, data in pairs(byCategory) do
        if #data.items > 0 then
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

-- Menu statistiques
local function menuStats()
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
    
    -- Alertes
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

-- Menu configuration
local function menuConfig()
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

-- Configuration des coffres
local function menuConfigChests()
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
        print(i .. ". " .. chest.name:sub(1, 20))
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
        local idx = readNumber("Numero a supprimer: ", 1, #chests)
        
        local removeResponse = sendRequest({
            type = "remove_chest",
            chestName = chests[idx].name
        })
        
        if removeResponse and removeResponse.success then
            print("Coffre supprime!")
        else
            print("Erreur: " .. (removeResponse.error or "?"))
        end
        waitKey()
    end
end

-- Configuration des catégories
local function menuConfigCategories()
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
        if #cat.patterns > 0 then
            print("   Patterns: " .. table.concat(cat.patterns, ", "):sub(1, 25))
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

-- Configuration des favoris
local function menuConfigFavorites()
    printHeader("GERER FAVORIS")
    
    local response = sendRequest({type = "get_favorites"})
    
    if response and response.success then
        print("Favoris actuels:")
        for i, fav in ipairs(response.data) do
            print(i .. ". " .. fav.displayName)
        end
    end
    
    print("")
    print("[S]upprimer un favori [Q]uitter")
    print("(Ajouter via recherche)")
    
    local choice = readInput("> "):lower()
    
    if choice == "s" then
        local idx = readNumber("Numero: ", 1, #response.data)
        
        sendRequest({
            type = "remove_favorite",
            itemName = response.data[idx].name
        })
        print("Favori supprime!")
        waitKey()
    end
end

-- === ACTIONS ===

-- Commander un item
local function actionRetrieveItem(item)
    printHeader("COMMANDER")
    
    print("Item: " .. item.displayName)
    print("En stock: " .. item.count)
    print("")
    
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
        print("Erreur: " .. (err or response.error or "?"))
    end
    
    waitKey()
end

-- Vider le coffre d'entrée
local function actionEmptyInput()
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

-- Ajouter aux favoris
local function actionAddFavorite(itemName)
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

-- Retirer des favoris
local function actionRemoveFavorite(itemName)
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

-- Déclarations anticipées pour éviter les erreurs
displayItemList = displayItemList
menuItemAction = menuItemAction
actionRetrieveItem = actionRetrieveItem
actionAddFavorite = actionAddFavorite
actionRemoveFavorite = actionRemoveFavorite
actionEmptyInput = actionEmptyInput

-- Lance le programme
main()
